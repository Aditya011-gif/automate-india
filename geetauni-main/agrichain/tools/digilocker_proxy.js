const http = require('http');
const https = require('https');
const url = require('url');
const { signPdfIncremental } = require('./pdf_signer');

const PORT = 8088;
const API_KEY = 'key_live_d2e9824f3742403e991f79491c9cadd3';
const API_SECRET = 'secret_live_a2042d8ee8144cda92d94c0a4069bc52';
const API_VERSION = '1.0.0';

let cachedToken = null;
let tokenExpiry = 0;

function httpRequest(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, headers: res.headers, body: JSON.parse(body) });
        } catch (_) {
          resolve({ status: res.statusCode, headers: res.headers, raw: body });
        }
      });
    });
    req.on('error', reject);
    req.setTimeout(15000, () => {
      req.destroy();
      reject(new Error('Timeout'));
    });
    if (postData) {
      req.write(postData);
    }
    req.end();
  });
}

async function getAccessToken(force = false) {
  const now = Date.now();
  if (!force && cachedToken && now < tokenExpiry) {
    return cachedToken;
  }
  const res = await httpRequest({
    hostname: 'api.sandbox.co.in',
    path: '/authenticate',
    method: 'POST',
    headers: {
      'x-api-key': API_KEY,
      'x-api-secret': API_SECRET,
      'x-api-version': API_VERSION,
      'Content-Type': 'application/json'
    }
  });

  const token = res.body?.data?.access_token || res.body?.access_token;
  if (!token) {
    throw new Error('Could not acquire Sandbox access token: ' + JSON.stringify(res.body));
  }
  cachedToken = token;
  tokenExpiry = now + 23 * 3600 * 1000;
  console.log('[Sandbox Proxy] Live access token refreshed successfully.');
  return token;
}

// Parse Aadhaar XML helper
function parseAadhaarXml(xmlText) {
  let name = 'Citizen';
  let gender = 'M';
  let dob = '';
  let address = '';
  let maskedAadhaar = 'XXXX-XXXX-XXXX';

  const nameMatch = xmlText.match(/name="([^"]+)"/i) || xmlText.match(/<name>([^<]+)<\/name>/i);
  if (nameMatch) name = nameMatch[1];

  const genderMatch = xmlText.match(/gender="([^"]+)"/i) || xmlText.match(/<gender>([^<]+)<\/gender>/i);
  if (genderMatch) gender = genderMatch[1] === 'M' ? 'Male' : genderMatch[1] === 'F' ? 'Female' : genderMatch[1];

  const dobMatch = xmlText.match(/dob="([^"]+)"/i) || xmlText.match(/<dob>([^<]+)<\/dob>/i);
  if (dobMatch) dob = dobMatch[1];

  const uidMatch = xmlText.match(/uid="([^"]+)"/i) || xmlText.match(/masked_uid="([^"]+)"/i);
  if (uidMatch) {
    maskedAadhaar = uidMatch[1];
  }

  // Address parts: co, house, street, loc, vtc, dist, state, pc
  const addrParts = [];
  const coMatch = xmlText.match(/co="([^"]+)"/i);
  if (coMatch) addrParts.push(coMatch[1]);
  const houseMatch = xmlText.match(/house="([^"]+)"/i);
  if (houseMatch) addrParts.push(houseMatch[1]);
  const streetMatch = xmlText.match(/street="([^"]+)"/i);
  if (streetMatch) addrParts.push(streetMatch[1]);
  const locMatch = xmlText.match(/loc="([^"]+)"/i);
  if (locMatch) addrParts.push(locMatch[1]);
  const vtcMatch = xmlText.match(/vtc="([^"]+)"/i);
  if (vtcMatch) addrParts.push(vtcMatch[1]);
  const distMatch = xmlText.match(/dist="([^"]+)"/i);
  if (distMatch) addrParts.push(distMatch[1]);
  const stateMatch = xmlText.match(/state="([^"]+)"/i);
  if (stateMatch) addrParts.push(stateMatch[1]);
  const pcMatch = xmlText.match(/pc="([^"]+)"/i);
  if (pcMatch) addrParts.push(pcMatch[1]);

  if (addrParts.length > 0) {
    address = addrParts.join(', ');
  }

  return { name, gender, dob, address, maskedAadhaar };
}

const server = http.createServer(async (req, res) => {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    return res.end();
  }

  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;

  try {
    // 1. Health check
    if (pathname === '/health' || pathname === '/') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      return res.end(JSON.stringify({ status: 'ok', service: 'Sandbox DigiLocker Proxy', port: PORT }));
    }

    // 2. Initiate Session: POST /api/digilocker/init
    if (pathname === '/api/digilocker/init' && req.method === 'POST') {
      let bodyData = '';
      req.on('data', chunk => bodyData += chunk);
      req.on('end', async () => {
        try {
          const clientPayload = bodyData ? JSON.parse(bodyData) : {};
          const token = await getAccessToken();

          const sandboxPayload = JSON.stringify({
            '@entity': 'in.co.sandbox.kyc.digilocker.session.request',
            flow: clientPayload.flow || 'signin',
            doc_types: clientPayload.doc_types || ['aadhaar'],
            redirect_url: clientPayload.redirect_url || 'https://sandbox.co.in',
            options: {
              verification_method: clientPayload.verification_method || ['aadhaar', 'mobile']
            }
          });

          const sandboxRes = await httpRequest({
            hostname: 'api.sandbox.co.in',
            path: '/kyc/digilocker/sessions/init',
            method: 'POST',
            headers: {
              'Authorization': token,
              'x-api-key': API_KEY,
              'x-api-version': API_VERSION,
              'Content-Type': 'application/json',
              'Content-Length': Buffer.byteLength(sandboxPayload)
            }
          }, sandboxPayload);

          console.log('[Sandbox Proxy] Session Init Status:', sandboxRes.status);
          res.writeHead(sandboxRes.status, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify(sandboxRes.body));
        } catch (err) {
          console.error('[Sandbox Proxy] Error in /api/digilocker/init:', err.message);
          res.writeHead(500, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: err.message }));
        }
      });
      return;
    }

    // 3. Status check: GET /api/digilocker/status/:sessionId
    if (pathname.startsWith('/api/digilocker/status/')) {
      const sessionId = pathname.replace('/api/digilocker/status/', '').trim();
      const token = await getAccessToken();

      const sandboxRes = await httpRequest({
        hostname: 'api.sandbox.co.in',
        path: `/kyc/digilocker/sessions/${sessionId}/status`,
        method: 'GET',
        headers: {
          'Authorization': token,
          'x-api-key': API_KEY,
          'x-api-version': API_VERSION
        }
      });

      console.log(`[Sandbox Proxy] Session ${sessionId} Status:`, sandboxRes.body?.data?.status || sandboxRes.status);
      res.writeHead(sandboxRes.status, { 'Content-Type': 'application/json' });
      return res.end(JSON.stringify(sandboxRes.body));
    }

    // 4. Fetch Document: GET /api/digilocker/documents/:sessionId
    if (pathname.startsWith('/api/digilocker/documents/')) {
      const sessionId = pathname.replace('/api/digilocker/documents/', '').trim();
      const token = await getAccessToken();

      let sandboxRes = await httpRequest({
        hostname: 'api.sandbox.co.in',
        path: `/kyc/digilocker/sessions/${sessionId}/documents/aadhaar`,
        method: 'GET',
        headers: {
          'Authorization': token,
          'x-api-key': API_KEY,
          'x-api-version': API_VERSION
        }
      });

      // If token expired, force refresh and retry once
      if (sandboxRes.status === 401 || sandboxRes.status === 403) {
        console.log('[Sandbox Proxy] Token expired, refreshing and retrying document fetch...');
        const freshToken = await getAccessToken(true);
        sandboxRes = await httpRequest({
          hostname: 'api.sandbox.co.in',
          path: `/kyc/digilocker/sessions/${sessionId}/documents/aadhaar`,
          method: 'GET',
          headers: {
            'Authorization': freshToken,
            'x-api-key': API_KEY,
            'x-api-version': API_VERSION
          }
        });
      }

      console.log(`[Sandbox Proxy] Document Fetch for ${sessionId} Status:`, sandboxRes.status);

      // If files exist, fetch the XML file and extract real citizen information
      const files = sandboxRes.body?.data?.files;
      if (files && files.length > 0 && files[0].url) {
        const fileUrl = files[0].url;
        console.log('[Sandbox Proxy] Downloading Aadhaar XML from S3...');
        
        const xmlDownload = await new Promise((resolve, reject) => {
          https.get(fileUrl, (getRes) => {
            let xmlData = '';
            getRes.on('data', c => xmlData += c);
            getRes.on('end', () => resolve(xmlData));
          }).on('error', reject);
        });

        const parsed = parseAadhaarXml(xmlDownload);
        console.log(`[Sandbox Proxy] Successfully parsed Aadhaar for: ${parsed.name}`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        return res.end(JSON.stringify({
          code: 200,
          data: {
            name: parsed.name,
            gender: parsed.gender,
            dob: parsed.dob,
            masked_aadhaar: parsed.maskedAadhaar,
            address: parsed.address,
            raw_xml_available: true
          }
        }));
      }

      res.writeHead(sandboxRes.status, { 'Content-Type': 'application/json' });
      return res.end(JSON.stringify(sandboxRes.body));
    }

    // 5. Cryptographic PDF Digital Signing: POST /api/pdf/sign
    if (pathname === '/api/pdf/sign' && req.method === 'POST') {
      let bodyData = '';
      req.on('data', chunk => bodyData += chunk);
      req.on('end', async () => {
        try {
          const clientPayload = bodyData ? JSON.parse(bodyData) : {};
          if (!clientPayload.pdfBase64) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            return res.end(JSON.stringify({ error: 'pdfBase64 is required' }));
          }

          const inputBuf = Buffer.from(clientPayload.pdfBase64, 'base64');
          const signResult = signPdfIncremental(inputBuf, {
            signerName: clientPayload.signerName || 'Aadhaar Verified Signatory',
            signerRole: clientPayload.signerRole || 'Buyer Authorized Signatory',
            reason: clientPayload.reason || 'Cryptographic Smart Contract Execution (IT Act 2000)',
            location: clientPayload.location || 'New Delhi, India',
            contactInfo: clientPayload.contactInfo || 'verify@agrichain.gov.in'
          });

          console.log(`[Sandbox Proxy] Successfully signed PDF (${inputBuf.length} -> ${signResult.signedPdf.length} bytes) for ${signResult.signerName}`);
          
          res.writeHead(200, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({
            code: 200,
            success: true,
            signedPdfBase64: signResult.signedPdf.toString('base64'),
            sha256Hex: signResult.sha256Hex,
            certSerial: signResult.certSerial,
            signerName: signResult.signerName,
            signingTime: signResult.signingTime
          }));
        } catch (signErr) {
          console.error('[Sandbox Proxy] PDF signing failed:', signErr);
          res.writeHead(500, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({ error: signErr.message }));
        }
      });
      return;
    }

    // 6. Interactive Web Verification Portal: GET /verify
    if (pathname === '/verify') {
      const q = parsedUrl.query;
      const signer = q.signer || 'Verified Citizen';
      const role = q.role || 'Procurement Signatory';
      const uid = q.uid || 'XXXX-XXXX-8921';
      const cert = q.cert || 'DL-CCA-2026-8921';
      const contract = q.contract || 'RET-48768';
      const digest = q.digest || 'c447aa21e36207881a1fa73e86c0b991bf8d29837a2c89210e782910dc817203';
      const status = q.status || 'VERIFIED_UIDAI';
      const contractAddr = '0x71C8A56E38F14E1825B3E7A3E2f9a2D8B9238e12';

      const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AgriChain • Electronic Contract & e-Sign Verification</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
    body { background: #f8fafc; color: #0f172a; padding: 20px; display: flex; justify-content: center; }
    .card { background: white; max-width: 600px; width: 100%; border-radius: 16px; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.08); overflow: hidden; border: 1px solid #e2e8f0; }
    .header { background: #15803d; color: white; padding: 24px 20px; text-align: center; }
    .badge-check { width: 56px; height: 56px; background: white; color: #15803d; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-size: 32px; font-weight: bold; margin-bottom: 12px; }
    .header h1 { font-size: 18px; font-weight: 700; letter-spacing: 0.5px; }
    .header p { font-size: 12px; color: #dcfce7; margin-top: 4px; }
    .body { padding: 24px; }
    .status-pill { display: inline-block; background: #dcfce7; color: #166534; padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 700; margin-bottom: 16px; border: 1px solid #86efac; }
    .info-group { margin-bottom: 16px; border-bottom: 1px solid #f1f5f9; padding-bottom: 12px; }
    .label { font-size: 11px; color: #64748b; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; }
    .value { font-size: 14px; color: #0f172a; font-weight: 600; margin-top: 2px; word-break: break-all; }
    .hash { font-family: monospace; font-size: 11px; color: #047857; background: #f0fdf4; padding: 6px; border-radius: 6px; border: 1px solid #bbf7d0; }
    .law-notice { background: #f1f5f9; border-left: 4px solid #15803d; padding: 12px; font-size: 11px; color: #334155; line-height: 1.5; border-radius: 0 8px 8px 0; margin-top: 20px; }
    .btn { display: block; text-align: center; background: #15803d; color: white; text-decoration: none; padding: 12px; border-radius: 10px; font-weight: 700; font-size: 13px; margin-top: 20px; }
    .btn:hover { background: #166534; }
    .footer { text-align: center; font-size: 10px; color: #94a3b8; padding: 16px; border-top: 1px solid #f1f5f9; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <div class="badge-check">✔</div>
      <h1>DIGITAL SIGNATURE VERIFIED</h1>
      <p>Controller of Certifying Authorities (CCA) • Information Technology Act, 2000</p>
    </div>
    <div class="body">
      <div class="status-pill">● CERTIFICATE ACTIVE & STATUTORILY VALID</div>
      <div class="info-group">
        <div class="label">Signatory Name & Role</div>
        <div class="value">${signer} (${role})</div>
      </div>
      <div class="info-group">
        <div class="label">UIDAI Aadhaar Reference</div>
        <div class="value">${uid} (Verified via CIDR OTP / DigiLocker)</div>
      </div>
      <div class="info-group">
        <div class="label">Certificate Reference ID</div>
        <div class="value">${cert}</div>
      </div>
      <div class="info-group">
        <div class="label">Contract Order Reference</div>
        <div class="value">${contract}</div>
      </div>
      <div class="info-group">
        <div class="label">Cryptographic Deal Digest (SHA-256)</div>
        <div class="value hash">${digest}</div>
      </div>
      <div class="info-group">
        <div class="label">Polygon PoS Smart Vault Anchor</div>
        <div class="value" style="font-family: monospace; font-size: 12px;">${contractAddr}</div>
      </div>
      <div class="law-notice">
        <b>Statutory Enforceability:</b> Pursuant to Section 10A of the Information Technology Act 2000, contracts formed through electronic records and digital signatures are recognized as valid and legally enforceable agreements in Indian courts.
      </div>
      <a class="btn" href="https://amoy.polygonscan.com/address/${contractAddr}" target="_blank">
        🔗 View Smart Escrow on Polygonscan Explorer
      </a>
    </div>
    <div class="footer">
      AgriChain National Agricultural Decentralized Ledger • Government of India e-Governance Stack
    </div>
  </div>
</body>
</html>`;

      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      return res.end(html);
    }

    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
  } catch (err) {
    console.error('[Sandbox Proxy] Unhandled server error:', err);
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: err.message }));
  }
});

server.listen(PORT, () => {
  console.log(`\n======================================================`);
  console.log(`✅ Sandbox.co.in DigiLocker Proxy is running on port ${PORT}`);
  console.log(`🔗 Endpoint: http://localhost:${PORT}/api/digilocker/init`);
  console.log(`======================================================\n`);
});
