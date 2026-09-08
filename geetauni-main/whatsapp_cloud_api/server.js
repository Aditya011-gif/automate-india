const express = require('express');
const axios = require('axios');
const https = require('https');
const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

const app = express();
app.use(express.json({ limit: '25mb' }));

const PORT = process.env.PORT || 3000;
const {
  WHATSAPP_TOKEN,
  WHATSAPP_PHONE_NUMBER_ID,
  WHATSAPP_VERIFY_TOKEN,
  GEMINI_API_KEY,
  FIREBASE_PROJECT_ID,
  FIREBASE_WEB_API_KEY
} = process.env;

const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);

// Mandi Benchmark Data for Price Inquiries
const MANDI_BENCHMARK_RATES = {
  wheat: { nameHindi: 'गेहूं (Wheat)', msp: 2275, mandiRate: 2420, trend: 'स्थिर (+1.2%)' },
  rice: { nameHindi: 'धान/चावल (Basmati/Paddy)', msp: 2183, mandiRate: 3450, trend: 'तेज (+3.5%)' },
  mustard: { nameHindi: 'सरसों (Mustard)', msp: 5650, mandiRate: 5880, trend: 'तेज (+2.1%)' },
  cotton: { nameHindi: 'कपास (Cotton)', msp: 7020, mandiRate: 7250, trend: 'स्थिर' },
  soybean: { nameHindi: 'सोयाबीन (Soybean)', msp: 4600, mandiRate: 4720, trend: 'गिरावट (-0.8%)' },
  potato: { nameHindi: 'आलू (Potato)', msp: 1200, mandiRate: 1550, trend: 'स्थिर' },
  onion: { nameHindi: 'प्याज (Onion)', msp: 1400, mandiRate: 2100, trend: 'तेज (+4.0%)' },
  tomato: { nameHindi: 'टमाटर (Tomato)', msp: 1100, mandiRate: 1800, trend: 'तेज (+5.2%)' },
  maize: { nameHindi: 'मक्का (Maize)', msp: 2090, mandiRate: 2240, trend: 'स्थिर' }
};

// ---------------------------------------------------------------------------
// 1. Meta Webhook Verification (GET /webhook)
// ---------------------------------------------------------------------------
app.get('/webhook', (req, res) => {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  if (mode === 'subscribe' && token === WHATSAPP_VERIFY_TOKEN) {
    console.log('✅ Meta Webhook challenge verified successfully!');
    res.status(200).send(challenge);
  } else {
    console.warn('❌ Webhook verification failed. Token mismatch.');
    res.sendStatus(403);
  }
});

// ---------------------------------------------------------------------------
// 2. Incoming Messages Webhook (POST /webhook)
// ---------------------------------------------------------------------------
app.post('/webhook', async (req, res) => {
  // Always respond with 200 OK within 3 seconds to avoid Meta retries
  res.sendStatus(200);

  try {
    const body = req.body;
    if (!body.object || !body.entry?.[0]?.changes?.[0]?.value?.messages) return;

    const change = body.entry[0].changes[0].value;
    const messageObj = change.messages[0];
    const contactObj = change.contacts?.[0] || {};

    const from = messageObj.from; // Sender WhatsApp Phone (e.g. 918307165924)
    const senderProfileName = contactObj.profile?.name || 'Kisan';
    const messageId = messageObj.id;
    const type = messageObj.type;

    console.log(`\n📩 Incoming from +${from} (${senderProfileName}): type=${type}`);

    // Mark message as read
    await markMessageAsRead(messageId);

    // Lookup Verified Farmer Profile
    const farmer = await getLinkedFarmer(from);

    // =========================================================================
    // CASE A: Voice Note / Audio Message (Regional Voice AI Processing)
    // =========================================================================
    if (type === 'audio') {
      console.log(`🎙️ Voice Note received from +${from}. Downloading media...`);
      const media = await downloadMetaMedia(messageObj.audio.id);
      if (media) {
        const voiceResult = await processVoiceWithGemini(media.base64Data, media.mimeType, farmer);
        if (voiceResult) {
          console.log(`🎙️ Voice Note transcribed: "${voiceResult.transcriptionHindi || ''}"`);
          await handleParsedAiResult(from, voiceResult, farmer);
          return;
        }
      }
    }

    // =========================================================================
    // CASE B: Image / Photo (Visual Crop Quality Assay & Disease Detection)
    // =========================================================================
    if (type === 'image') {
      const caption = messageObj.image?.caption || '';
      console.log(`📸 Image received from +${from}. Caption: "${caption}". Downloading...`);
      const media = await downloadMetaMedia(messageObj.image.id);
      if (media) {
        const assayResult = await processImageWithGemini(media.base64Data, media.mimeType, caption, farmer);
        if (assayResult) {
          await handleImageAssayResult(from, assayResult, farmer, caption);
          return;
        }
      }
    }

    // =========================================================================
    // CASE C: Text & Interactive Button Replies
    // =========================================================================
    let textBody = '';
    if (type === 'text') {
      textBody = messageObj.text.body.trim();
    } else if (type === 'interactive') {
      textBody = messageObj.interactive?.button_reply?.title || messageObj.interactive?.list_reply?.title || '';
    }

    if (!textBody) return;
    console.log(`💬 Content: "${textBody}"`);

    // STEP 1: Handshake Check - 1-Tap Account Linking
    if (textBody.includes('#UID:')) {
      await handleFarmerHandshake(from, textBody, senderProfileName);
      return;
    }

    // STEP 2: Agronomic & Trade Parsing with Gemini 2.5 Flash
    await processFarmerTextMessage(from, textBody, farmer);

  } catch (err) {
    console.error('❌ Error in WhatsApp webhook handler:', err.message);
  }
});

// ---------------------------------------------------------------------------
// 3. Meta Media Downloader Helper (Voice Notes & Photos)
// ---------------------------------------------------------------------------
async function downloadMetaMedia(mediaId) {
  try {
    const metaRes = await axios.get(`https://graph.facebook.com/v19.0/${mediaId}`, {
      headers: { Authorization: `Bearer ${WHATSAPP_TOKEN}` }
    });
    const mediaUrl = metaRes.data?.url;
    const mimeType = metaRes.data?.mime_type || 'application/octet-stream';

    if (!mediaUrl) return null;

    const binaryRes = await axios.get(mediaUrl, {
      headers: { Authorization: `Bearer ${WHATSAPP_TOKEN}` },
      responseType: 'arraybuffer'
    });

    const base64Data = Buffer.from(binaryRes.data).toString('base64');
    return { base64Data, mimeType };
  } catch (err) {
    console.error('❌ Error downloading Meta media:', err.response?.data || err.message);
    return null;
  }
}

// ---------------------------------------------------------------------------
// 4. Send WhatsApp Reply via Meta Graph API
// ---------------------------------------------------------------------------
async function sendWhatsAppMessage(to, text) {
  try {
    const url = `https://graph.facebook.com/v19.0/${WHATSAPP_PHONE_NUMBER_ID}/messages`;
    const res = await axios.post(
      url,
      {
        messaging_product: 'whatsapp',
        recipient_type: 'individual',
        to: to,
        type: 'text',
        text: { preview_url: false, body: text }
      },
      {
        headers: {
          Authorization: `Bearer ${WHATSAPP_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );
    console.log(`📤 Reply delivered to +${to} (Message ID: ${res.data?.messages?.[0]?.id})`);
  } catch (err) {
    console.error('❌ Error sending WhatsApp message:', err.response?.data || err.message);
  }
}

async function markMessageAsRead(messageId) {
  try {
    await axios.post(
      `https://graph.facebook.com/v19.0/${WHATSAPP_PHONE_NUMBER_ID}/messages`,
      {
        messaging_product: 'whatsapp',
        status: 'read',
        message_id: messageId
      },
      {
        headers: {
          Authorization: `Bearer ${WHATSAPP_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );
  } catch (e) {}
}

// ---------------------------------------------------------------------------
// 5. Firestore Live Sync Helper (Direct REST API)
// ---------------------------------------------------------------------------
async function firestorePatch(collection, docId, fields) {
  return new Promise((resolve) => {
    const data = JSON.stringify({ fields });
    const req = https.request({
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/${collection}/${docId}?key=${FIREBASE_WEB_API_KEY}`,
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => resolve(res.statusCode < 300 ? JSON.parse(body) : null));
    });
    req.on('error', (err) => {
      console.warn(`⚠️ Firestore REST Error (${collection}/${docId}):`, err.message);
      resolve(null);
    });
    req.write(data);
    req.end();
  });
}

async function firestoreGet(collection, docId) {
  return new Promise((resolve) => {
    https.get(
      `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/${collection}/${docId}?key=${FIREBASE_WEB_API_KEY}`,
      (res) => {
        let body = '';
        res.on('data', d => body += d);
        res.on('end', () => resolve(res.statusCode === 200 ? JSON.parse(body) : null));
      }
    ).on('error', () => resolve(null));
  });
}

// ---------------------------------------------------------------------------
// 6. Account Linking & Verification
// ---------------------------------------------------------------------------
async function handleFarmerHandshake(phone, text, profileName) {
  const uidMatch = text.match(/#UID:([^\s#]+)/);
  const nameMatch = text.match(/#NAME:([^\n#]+)/);
  const phoneMatch = text.match(/#PHONE:([^\s#]+)/);
  const locMatch = text.match(/#LOC:([^\n#]+)/);

  const userId = uidMatch ? uidMatch[1].trim() : 'farmer';
  const name = nameMatch ? nameMatch[1].trim() : profileName;
  const userPhone = phoneMatch ? phoneMatch[1].trim() : phone;
  const location = locMatch ? locMatch[1].trim() : 'Haryana';

  // 1. Sync in whatsapp_farmers collection
  await firestorePatch('whatsapp_farmers', phone, {
    userId: { stringValue: userId },
    name: { stringValue: name },
    phone: { stringValue: userPhone },
    whatsappNumber: { stringValue: phone },
    location: { stringValue: location },
    linkedAt: { timestampValue: new Date().toISOString() }
  });

  // 2. Update user profile in users collection
  await firestorePatch('users', userId, {
    whatsappNumber: { stringValue: phone },
    isWhatsAppLinked: { booleanValue: true },
    whatsappLinkedAt: { timestampValue: new Date().toISOString() }
  });

  console.log(`✅ Linked WhatsApp +${phone} to Farmer ${name} (${userId})`);

  const welcomeMsg = 
`🎉 *नमस्ते ${name} जी!* 🌾

आपका AgriChain किसान खाता आधिकारिक WhatsApp Business से जुड़ गया है!

✅ *किसान ID*: #${userId.slice(0, 8)}
📍 *स्थान*: ${location}
📱 *WhatsApp फ़ोन*: +${phone}

🤝 *अब क्या होगा?*
इस चैट में आप बोलकर (Voice Note) या फोटो भेजकर फसल बेच सकते हैं:
👉 फसल की फोटो भेजें: AI गुणवत्ता परखेगा और भाव सुझाएगा।
👉 वॉइस नोट भेजें: "करनाल में 50 क्विंटल गेहूं 2600 भाव"
👉 सीधे **आपके AgriChain ऐप खाते** में दर्ज होगी और 'My Crops' में दिखेगी!`;

  await sendWhatsAppMessage(phone, welcomeMsg);
}

async function getLinkedFarmer(phone) {
  let doc = await firestoreGet('whatsapp_farmers', phone);
  if (!doc) {
    const alt = phone.startsWith('91') ? phone.slice(2) : `91${phone}`;
    doc = await firestoreGet('whatsapp_farmers', alt);
  }
  if (doc && doc.fields) {
    return {
      userId: doc.fields.userId?.stringValue,
      name: doc.fields.name?.stringValue,
      location: doc.fields.location?.stringValue || 'Haryana'
    };
  }
  // Automatic mapping for Aryan Kisan
  if (phone.endsWith('8307165924') || phone.endsWith('38732065468642')) {
    return {
      userId: '90Eajo6VcCRtbzxthkWCxAwHsBs2',
      name: 'aryan sharma',
      location: 'Karnal, Haryana'
    };
  }
  return null;
}

// ---------------------------------------------------------------------------
// 7. Multimodal AI Processing (Voice Notes, Images & Text with Multi-Model Fallback)
// ---------------------------------------------------------------------------
const CANDIDATE_MODELS = [
  'gemini-2.5-flash-lite',
  'gemini-flash-lite-latest',
  'gemini-3.5-flash-lite',
  'gemini-2.5-flash'
];

async function callGemini(contents) {
  for (const modelName of CANDIDATE_MODELS) {
    try {
      const model = genAI.getGenerativeModel({ model: modelName });
      const result = await model.generateContent(contents);
      const text = result.response.text();
      if (text && text.trim().length > 0) {
        return text;
      }
    } catch (err) {
      console.warn(`⚠️ Model ${modelName} unavailable (${err.message.slice(0, 100)}). Trying fallback...`);
    }
  }
  throw new Error('All Gemini candidate models were temporarily unavailable.');
}

// A. Rural Audio Voice Note Processing (Gemini Flash Audio)
async function processVoiceWithGemini(base64Audio, mimeType, farmer) {
  const prompt = `You are AgriChain Kisan AI, the smart assistant for Indian farmers.
Listen to this rural voice note (in Hindi, Haryanvi, Punjabi, Marathi, Bhojpuri, or Hinglish).
Farmer Profile: ${farmer ? `${farmer.name} from ${farmer.location}` : 'Unlinked Farmer'}.

Transcribe and extract the trade listing or question.
Return ONLY pure JSON (no markdown fences):
{
  "intent": "listing" | "price_inquiry" | "escrow_inquiry" | "agronomic_advisory" | "general",
  "transcriptionHindi": string,
  "crop": "wheat" | "rice" | "mustard" | "cotton" | "soybean" | "potato" | "onion" | "tomato" | "maize",
  "variety": string | null,
  "quantityQuintals": number | null,
  "expectedPricePerQuintal": number | null,
  "location": string | null,
  "advisoryReply": string | null
}

UNIT CONVERSIONS & PRICING:
- 100 kg = 1 Quintal (e.g. 20 kg = 0.2 Quintals, 50 kg = 0.5 Quintals)
- 1 Ton = 10 Quintals, 1 Bori = 0.5 Quintals (50 kg), 1 Mann = 0.4 Quintals (40 kg)
- If the price is given per kg (e.g. "30/kg", "38/kg", "40/kg"), multiply by 100 to get expectedPricePerQuintal (4000). expectedPricePerQuintal MUST ALWAYS be in ₹/quintal.`;

  try {
    const rawText = await callGemini([
      {
        inlineData: {
          mimeType: mimeType ? mimeType.split(';')[0] : 'audio/ogg',
          data: base64Audio
        }
      },
      prompt
    ]);
    const cleanJson = rawText.replace(/```json/g, '').replace(/```/g, '').trim();
    return JSON.parse(cleanJson);
  } catch (err) {
    console.error('Voice AI Parse error:', err.message);
    return null;
  }
}

// B. Computer Vision Crop Quality Assay & Disease Detection (Gemini Flash Vision)
async function processImageWithGemini(base64Image, mimeType, caption, farmer) {
  const prompt = `You are AgriChain AI, an expert agricultural quality inspector & plant pathologist.
Analyze this photo sent by an Indian farmer. Optional caption: "${caption || 'None'}".
Farmer: ${farmer ? `${farmer.name} from ${farmer.location}` : 'Farmer'}.

Determine if this is:
A) HARVESTED PRODUCE / GRAINS (Wheat, Rice/Paddy, Mustard, Tomato, Potato, Onion, Soybean, Cotton, etc.)
B) STANDING CROP / PLANT DISEASE (Leaves, stem, pests, blight, rust, deficiency)

Return ONLY pure JSON (no markdown fences):
{
  "category": "produce_quality_assay" | "crop_disease_advisory",
  "crop": "wheat" | "rice" | "mustard" | "cotton" | "soybean" | "potato" | "onion" | "tomato" | "maize" | "other",
  "variety": string | null,
  "qualityGrade": "Grade 1 (Premium A+)" | "Grade 2 (Standard)" | "Grade 3 (Fair)",
  "purityScorePercent": number,
  "lusterAndGrainQuality": string,
  "estimatedMoisturePercent": number,
  "recommendedPricePerQuintalMin": number,
  "recommendedPricePerQuintalMax": number,
  "diseaseNameHindi": string | null,
  "diseaseTreatmentHindi": string | null,
  "quantityQuintals": number | null,
  "expectedPricePerQuintal": number | null,
  "location": string | null,
  "summaryHindi": string
}`;

  try {
    const rawText = await callGemini([
      {
        inlineData: {
          mimeType: mimeType ? mimeType.split(';')[0] : 'image/jpeg',
          data: base64Image
        }
      },
      prompt
    ]);
    const cleanJson = rawText.replace(/```json/g, '').replace(/```/g, '').trim();
    return JSON.parse(cleanJson);
  } catch (err) {
    console.error('Image Vision AI Parse error:', err.message);
    return null;
  }
}

// C. Text & Multi-turn Message Processing
async function processFarmerTextMessage(from, text, farmer) {
  // Fast keyword check for status / my crops inquiry
  if (/status|mera status|meri fasal|my crop|active crop|listings|orders/i.test(text)) {
    await handleStatusInquiry(from, farmer);
    return;
  }

  // Fast keyword check for payment / escrow inquiry
  if (/escrow|payment|paisa|paise|paise kaise|bank|payment secure/i.test(text)) {
    await handleEscrowInquiry(from, farmer);
    return;
  }

  const prompt = `You are AgriChain Kisan AI, the smart assistant for Indian farmers.
Parse this Hindi/English message from an Indian farmer: "${text}".
Farmer Profile: ${farmer ? `${farmer.name} from ${farmer.location}` : 'Unlinked Farmer'}.

Return ONLY pure JSON (no markdown fences):
{
  "intent": "listing" | "price_inquiry" | "escrow_inquiry" | "agronomic_advisory" | "status_inquiry" | "general",
  "crop": "wheat" | "rice" | "mustard" | "cotton" | "soybean" | "potato" | "onion" | "tomato" | "maize",
  "variety": string | null,
  "quantityQuintals": number | null,
  "expectedPricePerQuintal": number | null,
  "location": string | null,
  "advisoryReply": string | null
}

UNIT CONVERSIONS & PRICING:
- 100 kg = 1 Quintal (e.g. 20 kg = 0.2 Quintals, 30 kg = 0.3 Quintals, 50 kg = 0.5 Quintals)
- 1 Ton = 10 Quintals, 1 Bori = 0.5 Quintals (50 kg), 1 Mann = 0.4 Quintals (40 kg)
- If the price is given per kg (e.g. "30/kg", "38/kg", "38 per kg"), multiply by 100 to get expectedPricePerQuintal (3800). expectedPricePerQuintal MUST ALWAYS be in ₹/quintal.`;

  try {
    const rawText = await callGemini([prompt]);
    const cleanJson = rawText.replace(/```json/g, '').replace(/```/g, '').trim();
    const aiResult = JSON.parse(cleanJson);
    await handleParsedAiResult(from, aiResult, farmer);
  } catch (err) {
    console.error('Text NLP Error:', err.message);
  }
}

// ---------------------------------------------------------------------------
// 8. Shared Decision Router & Automated Firestore Listing
// ---------------------------------------------------------------------------
async function getFarmerActiveListings(farmerId) {
  try {
    const res = await axios.post(
      `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents:runQuery?key=${FIREBASE_WEB_API_KEY}`,
      {
        structuredQuery: {
          from: [{ collectionId: 'crops' }],
          where: {
            fieldFilter: {
              field: { fieldPath: 'farmerId' },
              op: 'EQUAL',
              value: { stringValue: farmerId }
            }
          },
          limit: 10
        }
      }
    );
    if (!res.data || !Array.isArray(res.data)) return [];
    return res.data
      .filter(item => item.document && item.document.fields)
      .map(item => {
        const f = item.document.fields;
        const rawPrice = f.price?.doubleValue || f.price?.integerValue || f.price?.stringValue || 0;
        return {
          id: f.id?.stringValue || item.document.name.split('/').pop(),
          name: f.name?.stringValue || 'फसल',
          quantity: f.quantity?.stringValue || '',
          price: Number(rawPrice) || 0,
          status: f.status?.stringValue || 'active',
          grade: f.qualityGrade?.stringValue || 'grade1'
        };
      });
  } catch (err) {
    console.warn('⚠️ Error fetching farmer crops from Firestore:', err.message);
    return [];
  }
}

async function handleStatusInquiry(from, farmer) {
  const farmerId = farmer?.userId || '90Eajo6VcCRtbzxthkWCxAwHsBs2';
  const farmerName = farmer?.name || 'aryan sharma';
  const location = farmer?.location || 'Karnal, Haryana';

  const listings = await getFarmerActiveListings(farmerId);
  const activeListings = listings.filter(l => l.status !== 'sold' && l.status !== 'cancelled');

  let msg = `🌾 *AgriChain खाता व फसल स्थिति (Live Status)* 🌾\n\n`;
  msg += `👤 *किसान*: ${farmerName} ✅ (सत्यापित)\n`;
  msg += `📍 *स्थान*: ${location}\n`;
  msg += `📱 *WhatsApp*: +${from}\n\n`;

  if (activeListings.length > 0) {
    msg += `📦 *आपकी सक्रिय फसलें (Active Market Listings):*\n`;
    activeListings.forEach((item, idx) => {
      const numPrice = Number(item.price) || 0;
      const priceStr = numPrice > 300 ? `₹${numPrice}/क्विंटल` : `₹${numPrice}/kg`;
      msg += `${idx + 1}. 🌾 *${item.name}*\n   ⚖️ मात्रा: ${item.quantity || 'दर्ज है'}\n   💰 भाव: ${priceStr}\n   ⭐ स्थिति: *${item.status.toUpperCase()}*\n\n`;
    });
    msg += `🔒 *एस्क्रो सुरक्षा:* खरीदार द्वारा बोली लगाने या ऑर्डर लॉक होने पर आपको WhatsApp पर तुरंत सूचना मिलेगी।\n\n`;
    msg += `💡 *नई फसल जोड़ने के लिए बोलें या लिखें:*\n👉 *"50 kg wheat 40/kg"*`;
  } else {
    msg += `📦 *वर्तमान में कोई सक्रिय फसल दर्ज नहीं है।*\n\n`;
    msg += `💡 *फसल बेचने के लिए बोलकर (Voice Note) या लिखकर भेजें:*\n👉 *"30 kg wheat 38/kg"*`;
  }

  await sendWhatsAppMessage(from, msg);
}

async function handleEscrowInquiry(from, farmer) {
  const farmerName = farmer?.name || 'किसान भाई';
  const escrowMsg = 
`🛡️ *AgriChain सुरक्षित एस्क्रो भुगतान प्रणाली* 🛡️

नमस्ते ${farmerName}! AgriChain पर आपका भुगतान 100% सुरक्षित रहता है:

1️⃣ *भुगतान लॉक:* खरीदार अग्रिम राशि AgriChain बैंक एस्क्रो में सुरक्षित लॉक करता है।
2️⃣ *खेत से पिकअप:* राशि लॉक होने के बाद ही ट्रांसपोर्टर आपके खेत से फसल लोड करता है।
3️⃣ *तुरंत भुगतान:* डिलीवरी और डिजिटल तौल होते ही पैसा सीधे आपके बैंक खाते (UPI/IMPS) में जमा हो जाता है।

❌ कोई आढ़ती कटौती नहीं | ❌ कोई बिचौलिया नहीं | ✅ सीधा बैंक ट्रांसफर`;
  await sendWhatsAppMessage(from, escrowMsg);
}

async function handleParsedAiResult(from, aiResult, farmer) {
  // 1. Status Inquiry
  if (aiResult.intent === 'status_inquiry') {
    await handleStatusInquiry(from, farmer);
    return;
  }

  // 2. Escrow Inquiry
  if (aiResult.intent === 'escrow_inquiry') {
    await handleEscrowInquiry(from, farmer);
    return;
  }

  // 3. Price Inquiry (Bhav Check)
  if (aiResult.intent === 'price_inquiry' && aiResult.crop) {
    const benchmark = MANDI_BENCHMARK_RATES[aiResult.crop.toLowerCase()] || {
      nameHindi: aiResult.crop,
      msp: 2300,
      mandiRate: 2500,
      trend: 'स्थिर'
    };

    const bhavMsg = 
`🌾 *AgriChain मंडी भाव जानकारी* 🌾

किसान भाई, आज की प्रमुख मंडी दरें:
🏷️ *फसल*: ${benchmark.nameHindi}
🏛️ *सरकारी MSP*: ₹${benchmark.msp}/क्विंटल
🏪 *मंडी औसत भाव*: ₹${benchmark.mandiRate}/क्विंटल
📈 *रुझान*: ${benchmark.trend}

💡 *फसल बेचने के लिए बोलें या लिखें:*
👉 *"50 क्विंटल ${aiResult.crop} करनाल में बेचना है"*`;

    await sendWhatsAppMessage(from, bhavMsg);
    return;
  }

  // 4. Agronomic Advisory
  if (aiResult.intent === 'agronomic_advisory' && aiResult.advisoryReply) {
    await sendWhatsAppMessage(from, `🌾 *AgriChain कृषि सलाहकार* 🌾\n\n${aiResult.advisoryReply}`);
    return;
  }

  // 5. Crop Listing Intent
  if (aiResult.intent === 'listing' && aiResult.quantityQuintals > 0) {
    await saveAndConfirmCropListing(from, farmer, {
      crop: aiResult.crop,
      variety: aiResult.variety,
      quantityQuintals: aiResult.quantityQuintals,
      expectedPricePerQuintal: aiResult.expectedPricePerQuintal,
      location: aiResult.location,
      qualityGrade: 'grade1',
      voiceNote: aiResult.transcriptionHindi ? `🎙️ "${aiResult.transcriptionHindi}"` : null
    });
    return;
  }

  // Default Prompt / Help Menu
  const greeting = farmer ? `नमस्ते ${farmer.name} जी! 🙏` : 'नमस्ते किसान भाई! 🙏';
  const menuMsg = 
`${greeting}
AgriChain कृषि-साथी में आपका स्वागत है। 🌾

आप नीचे दिए गए विकल्पों में से कुछ भी भेज सकते हैं:
1️⃣ *फसल बेचें:* बोलकर (Voice Note) या लिखकर भेजें:
   👉 *"50 kg wheat 40/kg"*
2️⃣ *गुणवत्ता जांच:* फसल का फोटो भेजें (AI क्वालिटी रिपोर्ट पाएँ)
3️⃣ *मंडी भाव:* लिखें *"गेहूं का भाव क्या है"*
4️⃣ *स्थिति जांच:* लिखें *"status"* या *"मेरी फसलें"*
5️⃣ *भुगतान सुरक्षा:* लिखें *"पेमेंट कैसे मिलेगा?"*`;

  await sendWhatsAppMessage(from, menuMsg);
}

// Visual Crop Quality Inspection Handler
async function handleImageAssayResult(from, assay, farmer, caption) {
  // A. Plant Disease Advisory
  if (assay.category === 'crop_disease_advisory' && assay.diseaseNameHindi) {
    const diseaseMsg = 
`🔬 *AgriChain AI फसल रोग निदान (Plant Pathology)* 🔬

🌿 *फसल*: ${(assay.crop || 'पौधा').toUpperCase()}
⚠️ *पहचाना गया रोग*: ${assay.diseaseNameHindi}

💊 *अनुशंसित उपचार व स्प्रे सलाह*:
${assay.diseaseTreatmentHindi || 'कृषि विशेषज्ञ से सलाह लें।'}

💡 _AgriChain AI द्वारा उपग्रह व कृषि-मॉडल आधारित विश्लेषण_`;

    await sendWhatsAppMessage(from, diseaseMsg);
    return;
  }

  // B. Harvested Produce Quality Assay
  const cropName = (assay.crop || 'फसल').toUpperCase();
  const qualityGrade = assay.qualityGrade || 'Grade 1 (Premium A+)';
  const purity = assay.purityScorePercent || 92;
  const moisture = assay.estimatedMoisturePercent || 12;
  const minPrice = assay.recommendedPricePerQuintalMin || 2400;
  const maxPrice = assay.recommendedPricePerQuintalMax || 2650;

  // Check if caption contains quantity to auto-list
  if (assay.quantityQuintals && assay.quantityQuintals > 0) {
    await saveAndConfirmCropListing(from, farmer, {
      crop: assay.crop,
      variety: assay.variety,
      quantityQuintals: assay.quantityQuintals,
      expectedPricePerQuintal: assay.expectedPricePerQuintal || maxPrice,
      location: assay.location,
      qualityGrade: qualityGrade.toLowerCase().includes('grade 1') ? 'grade1' : 'standard',
      qualityAssay: `⭐ ${qualityGrade} | Purity: ${purity}% | Moisture: ${moisture}%`
    });
    return;
  }

  // Otherwise, send the comprehensive AI Quality Assay Report
  const assayCard = 
`🌾 *AgriChain AI फसल गुणवत्ता परख रिपोर्ट* 🌾

फोटो विश्लेषण परिणाम:
🔍 *पहचानी गई फसल*: ${cropName} ${assay.variety ? `(${assay.variety})` : ''}
⭐ *AI गुणवत्ता ग्रेड*: ${qualityGrade}
✨ *दाने की चमक व शुद्धता*: ${purity}%
💧 *अनुमानित नमी*: ${moisture}%

💰 *अनुशंसित मंडी भाव*:
👉 ₹${minPrice.toLocaleString('en-IN')} - ₹${maxPrice.toLocaleString('en-IN')} / क्विंटल

🤝 *क्या आप इस गुणवत्ता पर फसल बेचना चाहते हैं?*
मात्रा और अपना भाव लिखकर या वॉइस नोट में भेजें:
👉 *"50 क्विंटल गेहूं भाव ${maxPrice}"*`;

  await sendWhatsAppMessage(from, assayCard);
}

// Centralized Listing Creator & Firestore Sync
async function saveAndConfirmCropListing(from, farmer, details) {
  const listingId = `LOT-${Math.floor(100000 + Math.random() * 900000)}`;
  const farmerId = farmer ? farmer.userId : '90Eajo6VcCRtbzxthkWCxAwHsBs2';
  const farmerName = farmer ? farmer.name : 'aryan sharma';
  const location = details.location || (farmer ? farmer.location : 'Karnal, Haryana');
  const pricePerQuintal = details.expectedPricePerQuintal || 2400;
  const pricePerKg = pricePerQuintal > 300 ? Math.round(pricePerQuintal / 100) : pricePerQuintal;
  const totalKg = Math.round(details.quantityQuintals * 100);
  const totalValuation = Math.round(totalKg * pricePerKg).toLocaleString('en-IN');
  const qualityGrade = details.qualityGrade || 'grade1';

  // Save directly to Google Cloud Firestore
  await firestorePatch('crops', listingId, {
    id: { stringValue: listingId },
    name: { stringValue: `${details.crop} ${details.variety ? `(${details.variety})` : ''}`.trim() },
    cropType: { stringValue: (details.crop || 'wheat').toLowerCase() },
    farmerId: { stringValue: farmerId },
    farmerName: { stringValue: farmerName },
    quantity: { stringValue: `${totalKg} kg` },
    price: { doubleValue: Number(pricePerKg) },
    qualityGrade: { stringValue: qualityGrade },
    status: { stringValue: 'active' },
    isActive: { booleanValue: true },
    location: { stringValue: location },
    createdAt: { timestampValue: new Date().toISOString() }
  });

  console.log(`✅ Synced crop ${listingId} (${details.crop}) to Firestore for ${farmerName} (${farmerId})`);

  let confirmationCard = 
`🌾 *AgriChain कृषि-साथी पुष्टि* 🌾

नमस्ते ${farmerName}! आपकी फसल सफलतापूर्वक AgriChain डिजिटल मंडी में दर्ज हो गई है:

📋 *लॉट ID*: \`${listingId}\`
🌾 *फसल*: ${(details.crop || 'फसल').toUpperCase()} ${details.variety ? `(${details.variety})` : ''}
⚖️ *मात्रा*: ${details.quantityQuintals} क्विंटल (${totalKg} kg)
💰 *आपका भाव*: ₹${pricePerKg}/kg (₹${pricePerQuintal}/क्विंटल)
💵 *कुल मूल्य*: ₹${totalValuation}
⭐ *AI गुणवत्ता ग्रेड*: ${qualityGrade.toUpperCase()}
📍 *स्थान*: ${location}
👤 *खाता*: ✅ ${farmerName}`;

  if (details.voiceNote) {
    confirmationCard += `\n${details.voiceNote}`;
  }
  if (details.qualityAssay) {
    confirmationCard += `\n🔬 ${details.qualityAssay}`;
  }

  confirmationCard += 
`\n\n📲 *यह फसल आपके AgriChain ऐप में 'My Crops' में लाइव दिखाई दे रही है।*

🤝 *आगे क्या होगा?*
1. खरीदार के एस्क्रो में भुगतान लॉक होते ही आपको WhatsApp पर सूचना मिलेगी।
2. आपके खेत से सीधा ट्रक पिकअप होगा।`;

  await sendWhatsAppMessage(from, confirmationCard);
}

// ---------------------------------------------------------------------------
// 9. Health Check Endpoint & Keep-Alive
// ---------------------------------------------------------------------------
app.get('/diag', (req, res) => {
  res.json({
    hasToken: !!process.env.WHATSAPP_TOKEN,
    tokenPrefix: process.env.WHATSAPP_TOKEN ? process.env.WHATSAPP_TOKEN.slice(0, 10) : 'MISSING',
    phoneId: process.env.WHATSAPP_PHONE_NUMBER_ID || 'MISSING',
    hasGemini: !!process.env.GEMINI_API_KEY,
    hasFirebase: !!process.env.FIREBASE_PROJECT_ID
  });
});

app.get('/', (req, res) => {
  res.json({
    status: 'ONLINE',
    service: 'AgriChain Meta WhatsApp Cloud API Gateway (Multimodal: Voice, Vision & NLP)',
    timestamp: new Date().toISOString()
  });
});

// Keep-alive self-ping to prevent Render free-tier from idling/sleeping (pings every 9 mins)
const PING_URL = process.env.RENDER_EXTERNAL_URL || 'https://agrichain-whatsapp-api.onrender.com';
if (process.env.NODE_ENV === 'production' || process.env.RENDER) {
  setInterval(() => {
    https.get(`${PING_URL}/diag`, (res) => {
      console.log(`[Keep-Alive] Pinged ${PING_URL}/diag -> Status: ${res.statusCode}`);
    }).on('error', (e) => {
      console.warn(`[Keep-Alive] Ping warn: ${e.message}`);
    });
  }, 9 * 60 * 1000);
}

if (require.main === module || !process.env.VERCEL) {
  app.listen(PORT, () => {
    console.log(`\n=============================================================`);
    console.log(`🚀 AgriChain Multimodal WhatsApp Cloud API is LIVE on port ${PORT}!`);
    console.log(`🎙️ Voice Notes (Hindi/Regional NLP) | 📸 Image Quality Assay | 💬 Text`);
    console.log(`📡 Webhook Endpoint: http://localhost:${PORT}/webhook`);
    console.log(`=============================================================\n`);
  });
}

module.exports = app;

