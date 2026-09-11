const fs = require('fs');
const forge = require('node-forge');
const crypto = require('crypto');

function signPdfIncremental(pdfBuffer, options = {}) {
  const signerName = options.signerName || 'Aadhaar Verified Citizen';
  const reason = options.reason || 'Aadhaar e-KYC Verified Smart Contract (IT Act 2000 Sec 3A)';
  const location = options.location || 'India';
  const contactInfo = options.contactInfo || 'https://agrichain.gov.in/verify';

  // 1. Generate on-the-fly X.509 Certificate and RSA Keypair for the signer
  const pki = forge.pki;
  const keys = pki.rsa.generateKeyPair(2048);
  const cert = pki.createCertificate();
  cert.publicKey = keys.publicKey;
  cert.serialNumber = Date.now().toString(16);
  
  const now = new Date();
  cert.validity.notBefore = new Date(now.getTime() - 10 * 60 * 1000); // 10 min ago
  cert.validity.notAfter = new Date(now.getTime() + 365 * 24 * 3600 * 1000); // 1 year

  const attrs = [
    { name: 'commonName', value: signerName },
    { name: 'organizationName', value: 'AgriChain Decentralized Ledger Authority' },
    { name: 'organizationalUnitName', value: 'Aadhaar e-KYC Certified eSign CA' },
    { name: 'countryName', value: 'IN' }
  ];
  cert.setSubject(attrs);
  cert.setIssuer(attrs);

  // Add standard X509v3 extensions for digital signature
  cert.setExtensions([
    { name: 'basicConstraints', cA: false },
    { name: 'keyUsage', digitalSignature: true, nonRepudiation: true },
    { name: 'extKeyUsage', serverAuth: false, clientAuth: true, codeSigning: false, emailProtection: true },
    { name: 'subjectAltName', altNames: [{ type: 1, value: `${signerName.toLowerCase().replace(/\s+/g, '.')}@esign.agrichain.gov.in` }] }
  ]);

  cert.sign(keys.privateKey, forge.md.sha256.create());

  // Format signing date for PDF: (D:YYYYMMDDHHmmSS+05'30')
  const pad = (n) => String(n).padStart(2, '0');
  const pdfDate = `D:${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}+05'30'`;

  // Parse existing PDF to find Root, Info, Pages, and trailer
  const pdfStr = pdfBuffer.toString('binary');
  
  // Find highest object number
  let maxObj = 0;
  const objMatches = pdfStr.matchAll(/(\d+)\s+0\s+obj/g);
  for (const match of objMatches) {
    const num = parseInt(match[1], 10);
    if (num > maxObj) maxObj = num;
  }

  // Find Root object ref
  const rootMatch = pdfStr.match(/\/Root\s+(\d+)\s+0\s+R/);
  if (!rootMatch) throw new Error('Could not locate /Root in PDF');
  const rootNum = parseInt(rootMatch[1], 10);

  // Find last startxref
  const lastStartXrefIdx = pdfStr.lastIndexOf('startxref');
  if (lastStartXrefIdx === -1) throw new Error('Could not find startxref in PDF');
  const prevXrefOffsetMatch = pdfStr.slice(lastStartXrefIdx).match(/startxref\s+(\d+)/);
  const prevXrefOffset = prevXrefOffsetMatch ? parseInt(prevXrefOffsetMatch[1], 10) : 0;

  // New object numbers
  const acroFormNum = maxObj + 1;
  const sigFieldNum = maxObj + 2;
  const sigDictNum = maxObj + 3;
  const newMaxObj = maxObj + 4; // trailer /Size

  // 8192 bytes reserved for PKCS7 hex signature (4096 bytes binary)
  const SIG_HEX_LEN = 8192;
  const placeholderSig = '0'.repeat(SIG_HEX_LEN);

  // Format signature dictionary (exact 38 chars)
  const byteRangePlaceholder = '[ 0 0000000000 0000000000 0000000000 ]';

  // Construct incremental objects
  const origLen = pdfBuffer.length;

  let inc = '\n';
  const offsets = {};

  // Object acroFormNum
  offsets[acroFormNum] = origLen + Buffer.byteLength(inc);
  inc += `${acroFormNum} 0 obj\n<< /Fields [ ${sigFieldNum} 0 R ] /SigFlags 3 >>\nendobj\n`;

  // Object sigFieldNum
  offsets[sigFieldNum] = origLen + Buffer.byteLength(inc);
  inc += `${sigFieldNum} 0 obj\n<< /Type /Annot /Subtype /Widget /FT /Sig /Rect [ 0 0 0 0 ] /T (Aadhaar_eSign_Buyer) /F 4 /V ${sigDictNum} 0 R >>\nendobj\n`;

  // Object sigDictNum
  offsets[sigDictNum] = origLen + Buffer.byteLength(inc);
  inc += `${sigDictNum} 0 obj\n<<\n/Type /Sig\n/Filter /Adobe.PPKLite\n/SubFilter /adbe.pkcs7.detached\n/ByteRange ${byteRangePlaceholder}\n/Contents <${placeholderSig}>\n/Reason (${reason.replace(/[()]/g, '')})\n/M (${pdfDate})\n/Name (${signerName.replace(/[()]/g, '')})\n/Location (${location.replace(/[()]/g, '')})\n/ContactInfo (${contactInfo})\n>>\nendobj\n`;

  // Object Root (incremental update pointing to new AcroForm)
  offsets[rootNum] = origLen + Buffer.byteLength(inc);
  // Find original Root object body to preserve other entries
  const rootRegex = new RegExp(`${rootNum}\\s+0\\s+obj\\s*<<([\\s\\S]*?)>>\\s*endobj`);
  const origRootMatch = pdfStr.match(rootRegex);
  let rootEntries = origRootMatch ? origRootMatch[1] : '';
  rootEntries = rootEntries.replace(/\/AcroForm\s+\d+\s+\d+\s+R/g, '').trim();
  inc += `${rootNum} 0 obj\n<< ${rootEntries} /AcroForm ${acroFormNum} 0 R >>\nendobj\n`;

  // Xref table
  const newXrefOffset = origLen + Buffer.byteLength(inc);
  inc += `xref\n`;
  inc += `${rootNum} 1\n${String(offsets[rootNum]).padStart(10, '0')} 00000 n \n`;
  inc += `${acroFormNum} 3\n`;
  inc += `${String(offsets[acroFormNum]).padStart(10, '0')} 00000 n \n`;
  inc += `${String(offsets[sigFieldNum]).padStart(10, '0')} 00000 n \n`;
  inc += `${String(offsets[sigDictNum]).padStart(10, '0')} 00000 n \n`;

  inc += `trailer\n<< /Size ${newMaxObj} /Root ${rootNum} 0 R /Prev ${prevXrefOffset} >>\n`;
  inc += `startxref\n${newXrefOffset}\n%%EOF\n`;

  // Combine original PDF buffer and incremental string
  let fullPdf = Buffer.concat([pdfBuffer, Buffer.from(inc, 'binary')]);

  // Now locate the placeholder in fullPdf
  const contentsMarker = '/Contents <';
  const contentsIdx = fullPdf.indexOf(Buffer.from(contentsMarker));
  if (contentsIdx === -1) throw new Error('Could not find /Contents in incremental PDF');

  const hexStart = contentsIdx + contentsMarker.length;
  const hexEnd = hexStart + SIG_HEX_LEN; // right before '>'

  // ByteRange: [ 0, hexStart - 1, hexEnd + 1, totalLength - (hexEnd + 1) ]
  const byteRange1 = hexStart - 1; // includes '<'
  const byteRange2Start = hexEnd + 1; // right after '>'
  const byteRange2Len = fullPdf.length - byteRange2Start;

  const actualByteRangeStr = `[ 0 ${String(byteRange1).padStart(10, '0')} ${String(byteRange2Start).padStart(10, '0')} ${String(byteRange2Len).padStart(10, '0')} ]`;
  
  const byteRangeMarker = '/ByteRange ';
  const byteRangeIdx = fullPdf.indexOf(Buffer.from(byteRangeMarker));
  if (byteRangeIdx === -1) throw new Error('Could not find /ByteRange in incremental PDF');

  fullPdf.write(actualByteRangeStr, byteRangeIdx + byteRangeMarker.length, 'binary');

  // Compute SHA-256 hash of range 1 + range 2
  const part1 = fullPdf.subarray(0, byteRange1);
  const part2 = fullPdf.subarray(byteRange2Start);

  const hash = crypto.createHash('sha256');
  hash.update(part1);
  hash.update(part2);
  const sha256Digest = hash.digest(); // Buffer

  // Build PKCS#7 detached signature with node-forge
  const p7 = forge.pkcs7.createSignedData();
  p7.content = forge.util.createBuffer(sha256Digest.toString('binary'));

  p7.addCertificate(cert);
  p7.addSigner({
    key: keys.privateKey,
    certificate: cert,
    digestAlgorithm: forge.pki.oids.sha256,
    authenticatedAttributes: [
      {
        type: forge.pki.oids.contentType,
        value: forge.pki.oids.data
      },
      {
        type: forge.pki.oids.messageDigest,
        value: sha256Digest.toString('binary')
      },
      {
        type: forge.pki.oids.signingTime,
        value: now
      }
    ]
  });

  p7.sign({ detached: true });

  const asn1 = p7.toAsn1();
  const der = forge.asn1.toDer(asn1).getBytes();
  const hexSig = Buffer.from(der, 'binary').toString('hex');

  if (hexSig.length > SIG_HEX_LEN) {
    throw new Error(`PKCS7 signature size (${hexSig.length}) exceeds allocated buffer (${SIG_HEX_LEN})`);
  }

  // Pad with zeroes
  const paddedHexSig = hexSig.padEnd(SIG_HEX_LEN, '0');
  fullPdf.write(paddedHexSig, hexStart, 'ascii');

  return {
    signedPdf: fullPdf,
    sha256Hex: sha256Digest.toString('hex'),
    certSerial: cert.serialNumber,
    signerName: signerName,
    signingTime: now.toISOString()
  };
}

module.exports = { signPdfIncremental };
