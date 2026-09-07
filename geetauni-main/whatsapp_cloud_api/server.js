const express = require('express');
const axios = require('axios');
const https = require('https');
const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

const app = express();
app.use(express.json());

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

    // Mark as read
    await markMessageAsRead(messageId);

    // Extract text content
    let textBody = '';
    if (type === 'text') {
      textBody = messageObj.text.body.trim();
    } else if (type === 'interactive') {
      textBody = messageObj.interactive?.button_reply?.title || messageObj.interactive?.list_reply?.title || '';
    } else {
      console.log(`[Media attachment received: ${type}]`);
      textBody = '';
    }

    if (!textBody) return;
    console.log(`💬 Content: "${textBody}"`);

    // STEP 1: Handshake Check - 1-Tap Account Linking
    if (textBody.includes('#UID:')) {
      await handleFarmerHandshake(from, textBody, senderProfileName);
      return;
    }

    // STEP 2: Lookup Verified Farmer Profile
    const farmer = await getLinkedFarmer(from);

    // STEP 3: Agronomic & Trade Parsing with Gemini 2.5 Flash
    await processFarmerMessage(from, textBody, farmer);

  } catch (err) {
    console.error('❌ Error in WhatsApp webhook handler:', err.message);
  }
});

// ---------------------------------------------------------------------------
// 3. Send WhatsApp Reply via Meta Graph API
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
// 4. Firestore Live Sync Helper (Direct REST API)
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
// 5. Account Linking & Verification
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
इस चैट में आप बोलकर या लिखकर जो भी फसल भेजेंगे:
👉 वह सीधे **आपके AgriChain ऐप खाते** में दर्ज होगी और 'My Crops' में दिखेगी!
👉 जब भी कोई खरीदार आपकी फसल खरीदेगा, आपको तुरंत WhatsApp पर रसीद मिलेगी।

💡 *फसल लिस्ट करने के लिए लिखें:*
👉 *"करनाल में 50 क्विंटल शरबती गेहूं ₹2600 भाव"*`;

  await sendWhatsAppMessage(phone, welcomeMsg);
}

async function getLinkedFarmer(phone) {
  const doc = await firestoreGet('whatsapp_farmers', phone);
  if (doc && doc.fields) {
    return {
      userId: doc.fields.userId?.stringValue,
      name: doc.fields.name?.stringValue,
      location: doc.fields.location?.stringValue || 'Haryana'
    };
  }
  return null;
}

// ---------------------------------------------------------------------------
// 6. Gemini 2.5 Flash Processing & Automated Crop Listing
// ---------------------------------------------------------------------------
async function processFarmerMessage(from, text, farmer) {
  const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });
  const prompt = `You are AgriChain Kisan AI, the smart assistant for Indian farmers.
Parse this Hindi/English message from an Indian farmer: "${text}".
Farmer Profile: ${farmer ? `${farmer.name} from ${farmer.location}` : 'Unlinked Farmer'}.

Return ONLY pure JSON (no markdown fences):
{
  "intent": "listing" | "price_inquiry" | "escrow_inquiry" | "agronomic_advisory" | "general",
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
    const result = await model.generateContent(prompt);
    const cleanJson = result.response.text().replace(/```json/g, '').replace(/```/g, '').trim();
    const aiResult = JSON.parse(cleanJson);

    // Intent 1: Price Inquiry (Bhav Check)
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

💡 *फसल बेचने के लिए लिखें:*
👉 *"50 क्विंटल ${aiResult.crop} करनाल में बेचना है"*`;

      await sendWhatsAppMessage(from, bhavMsg);
      return;
    }

    // Intent 2: Agronomic Advisory
    if (aiResult.intent === 'agronomic_advisory' && aiResult.advisoryReply) {
      await sendWhatsAppMessage(from, `🌾 *AgriChain कृषि सलाहकार* 🌾\n\n${aiResult.advisoryReply}`);
      return;
    }

    // Intent 3: Crop Listing
    if (aiResult.intent === 'listing' && aiResult.quantityQuintals > 0) {
      const listingId = `LOT-${Math.floor(100000 + Math.random() * 900000)}`;
      const farmerId = farmer ? farmer.userId : '90Eajo6VcCRtbzxthkWCxAwHsBs2';
      const farmerName = farmer ? farmer.name : 'aryan sharma';
      const location = aiResult.location || (farmer ? farmer.location : 'Karnal, Haryana');
      const pricePerQuintal = aiResult.expectedPricePerQuintal || 2400;
      const pricePerKg = pricePerQuintal > 300 ? Math.round(pricePerQuintal / 100) : pricePerQuintal;
      const totalKg = Math.round(aiResult.quantityQuintals * 100);
      const totalValuation = Math.round(totalKg * pricePerKg).toLocaleString('en-IN');

      // Save directly to Google Cloud Firestore (live sync with Flutter app)
      await firestorePatch('crops', listingId, {
        id: { stringValue: listingId },
        name: { stringValue: `${aiResult.crop} ${aiResult.variety ? `(${aiResult.variety})` : ''}`.trim() },
        cropType: { stringValue: aiResult.crop.toLowerCase() },
        farmerId: { stringValue: farmerId },
        farmerName: { stringValue: farmerName },
        quantity: { stringValue: `${totalKg} kg` },
        price: { doubleValue: Number(pricePerKg) },
        qualityGrade: { stringValue: 'grade1' },
        status: { stringValue: 'active' },
        isActive: { booleanValue: true },
        location: { stringValue: location },
        createdAt: { timestampValue: new Date().toISOString() }
      });

      console.log(`✅ Synced crop ${listingId} (${aiResult.crop}) to Firestore for ${farmerName} (${farmerId})`);

      const confirmationCard = 
`🌾 *AgriChain कृषि-साथी पुष्टि* 🌾

नमस्ते ${farmerName}! आपकी फसल सफलतापूर्वक AgriChain डिजिटल मंडी में दर्ज हो गई है:

📋 *लॉट ID*: \`${listingId}\`
🌾 *फसल*: ${aiResult.crop.toUpperCase()} ${aiResult.variety ? `(${aiResult.variety})` : ''}
⚖️ *मात्रा*: ${aiResult.quantityQuintals} क्विंटल (${totalKg} kg)
💰 *आपका भाव*: ₹${pricePerKg}/kg (₹${pricePerQuintal}/क्विंटल)
💵 *कुल मूल्य*: ₹${totalValuation}
📍 *स्थान*: ${location}
👤 *खाता*: ✅ ${farmerName}

📲 *यह फसल आपके AgriChain ऐप में 'My Crops' में लाइव दिखाई दे रही है।*

🤝 *आगे क्या होगा?*
1. खरीदार के एस्क्रो में भुगतान लॉक होते ही आपको WhatsApp पर सूचना मिलेगी।
2. आपके खेत से सीधा ट्रक पिकअप होगा।`;

      await sendWhatsAppMessage(from, confirmationCard);
      return;
    }

    // Default Friendly Prompt
    const greeting = farmer ? `नमस्ते ${farmer.name} जी! 🙏` : 'नमस्ते किसान भाई! 🙏';
    await sendWhatsAppMessage(
      from,
      `${greeting}\nAgriChain कृषि-साथी में आपका स्वागत है।\n\nअपनी फसल लिस्ट करने के लिए मात्रा और भाव लिखें:\n👉 *"30 kg wheat 38/kg"*`
    );

  } catch (err) {
    console.error('NLP Error:', err.message);
  }
}

// ---------------------------------------------------------------------------
// 7. Health Check Endpoint
// ---------------------------------------------------------------------------
app.get('/', (req, res) => {
  res.json({
    status: 'ONLINE',
    service: 'AgriChain Meta WhatsApp Cloud API Gateway',
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, () => {
  console.log(`\n=============================================================`);
  console.log(`🚀 AgriChain Official WhatsApp Cloud API Webhook is LIVE on port ${PORT}!`);
  console.log(`📡 Webhook Endpoint: http://localhost:${PORT}/webhook`);
  console.log(`=============================================================\n`);
});
