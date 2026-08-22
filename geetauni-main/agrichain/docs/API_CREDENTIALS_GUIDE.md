# API Credentials and Services Setup Guide

## Overview

This guide will help you obtain all the required API keys, credentials, and services for your AgriChain hackathon project. We'll cover both free/sandbox options and production services.

## 🔑 Required APIs and Services

### 1. DigiLocker API (KYC Verification)

**Purpose**: Document verification and KYC compliance

#### Option A: API Setu Sandbox (Recommended for Hackathons)

1. **Visit API Setu Platform**

   - URL: https://sandbox.api-setu.in/
   - Sign up for developer account
2. **Access DigiLocker Collection**

   - Navigate to: https://sandbox.api-setu.in/api-collection/digilocker/0
   - **⚠️ Current Status**: DigiLocker API is temporarily unavailable in API Setu sandbox
3. **Fallback Strategy for Hackathon**

   ```
   Since API Setu DigiLocker is currently unavailable:
   - Use our built-in Mock DigiLocker Service
   - Provides realistic demo data
   - Simulates actual API responses
   - Perfect for hackathon presentations
   ```

#### Option B: Direct DigiLocker API (Production)

1. **Visit DigiLocker Developer Portal**

   - URL: https://digitallocker.gov.in/developer
   - Click "Register as Developer"
2. **Registration Process**

   ```
   Required Information:
   - Full Name
   - Email Address
   - Phone Number
   - Organization/Company Name
   - Purpose: "Hackathon - Agricultural Supply Chain App"
   ```
3. **Create Application**

   ```
   Application Details:
   - App Name: AgriChain Hackathon
   - App Type: Mobile Application
   - Platform: Android/iOS
   - Callback URL: https://yourapp.com/auth/digilocker/callback
   - Documents Required: Aadhaar, PAN, Driving License
   ```
4. **Get Credentials**

   ```
   You'll receive:
   - Client ID: e.g., "DL_CLIENT_12345"
   - Client Secret: e.g., "DL_SECRET_abcdef123456"
   ```

**⏱️ Timeline**:

- API Setu: Immediate (when available)
- Direct DigiLocker: 1-2 business days for approval

**💰 Cost**: Free for sandbox/testing

**🎯 Hackathon Recommendation**: Use the Mock DigiLocker Service for your demo!

---

### 2. Firebase Services

**Purpose**: Authentication, real-time database, push notifications

#### Setting up Firebase:

1. **Go to Firebase Console**

   - URL: https://console.firebase.google.com/
   - Sign in with Google account
2. **Create New Project**

   ```
   Project Setup:
   - Project Name: AgriChain-Hackathon
   - Enable Google Analytics: Yes (optional)
   - Choose Analytics account or create new
   ```
3. **Add Android App**

   ```
   Android Package Name: com.agrichain.hackathon
   App Nickname: AgriChain Android
   Debug Signing Certificate: (optional for development)
   ```
4. **Add iOS App** (if needed)

   ```
   iOS Bundle ID: com.agrichain.hackathon
   App Nickname: AgriChain iOS
   ```
5. **Enable Required Services**

   ```
   Authentication:
   - Go to Authentication > Sign-in method
   - Enable Email/Password, Google, Phone

   Realtime Database:
   - Go to Realtime Database > Create Database
   - Start in test mode for development

   Cloud Messaging:
   - Automatically enabled with project creation
   ```
6. **Get Configuration Files**

   ```
   Android: Download google-services.json
   iOS: Download GoogleService-Info.plist
   ```

**⏱️ Timeline**: Immediate

**💰 Cost**: Free tier (generous limits for hackathons)

---

### 3. Razorpay Payment Gateway

**Purpose**: Payment processing for marketplace transactions

#### Getting Razorpay Test Account:

1. **Sign up for Razorpay**

   - URL: https://razorpay.com/
   - Click "Sign Up" → "Get Started for Free"
2. **Account Setup**

   ```

   Business Information:
   - Business Name: AgriChain Hackathon
   - Business Type: Technology/Software
   - Website: https://github.com/yourusername/agrichain (or any URL)
   - Business Category: E-commerce/Marketplace
   ```
3. **Get Test Credentials**

   ```
   Dashboard > Settings > API Keys > Test Mode
   - Key ID: rzp_test_xxxxxxxxxx
   - Key Secret: xxxxxxxxxxxxxxxxxx
   ```
4. **Webhook Setup** (optional)

   ```
   Dashboard > Settings > Webhooks
   - Webhook URL: https://yourapi.com/webhooks/razorpay
   - Events: payment.captured, payment.failed
   ```

**⏱️ Timeline**: Immediate for test mode

**💰 Cost**: Free for testing, 2% transaction fee for live

---

### 4. Blockchain API (Optional)

**Purpose**: Supply chain transparency and traceability

#### Option A: Infura (Ethereum)

1. **Sign up for Infura**

   - URL: https://infura.io/
   - Create free account
2. **Create Project**

   ```
   Project Settings:
   - Project Name: AgriChain Hackathon
   - Network: Ethereum Mainnet + Testnets
   ```
3. **Get API Key**

   ```
   Project Settings > Keys
   - Project ID: your_project_id
   - Project Secret: your_project_secret
   - Endpoints: https://mainnet.infura.io/v3/YOUR_PROJECT_ID
   ```

#### Option B: Alchemy

1. **Sign up for Alchemy**

   - URL: https://www.alchemy.com/
   - Create free account
2. **Create App**

   ```
   App Settings:
   - Name: AgriChain Hackathon
   - Chain: Ethereum
   - Network: Ethereum Mainnet
   ```
3. **Get API Key**

   ```
   Dashboard > Apps > View Key
   - API Key: your_api_key
   - HTTP URL: https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY
   ```

**⏱️ Timeline**: Immediate

**💰 Cost**: Free tier available

---

### 5. Google Maps API (Location Services)

**Purpose**: Farm location tracking, delivery routing

#### Setting up Google Maps:

1. **Go to Google Cloud Console**

   - URL: https://console.cloud.google.com/
   - Create new project or select existing
2. **Enable APIs**

   ```
   APIs & Services > Library
   Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API
   - Directions API
   ```
3. **Create API Key**

   ```
   APIs & Services > Credentials > Create Credentials > API Key
   - Restrict key to specific APIs (recommended)
   - Add application restrictions (Android/iOS package names)
   ```
4. **Get API Key**

   ```
   Your API Key: AIzaSyxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

**⏱️ Timeline**: Immediate

**💰 Cost**: $200 free credit monthly

---

### 6. Weather API (Optional)

**Purpose**: Weather data for farming decisions

#### Option A: OpenWeatherMap

1. **Sign up**

   - URL: https://openweathermap.org/api
   - Create free account
2. **Get API Key**

   ```
   Account > API Keys
   - API Key: your_api_key_here
   - Free tier: 1000 calls/day
   ```

#### Option B: WeatherAPI

1. **Sign up**

   - URL: https://www.weatherapi.com/
   - Free plan available
2. **Get API Key**

   ```
   Dashboard > API Key
   - Key: your_weather_api_key
   - Free tier: 1 million calls/month
   ```

**⏱️ Timeline**: Immediate

**💰 Cost**: Free tier available

---

## 🛠️ Configuration Setup

### Step 1: Update Environment Configuration

```dart
// lib/config/environment_config.dart
static const EnvironmentConfig development = EnvironmentConfig(
  // ... other config
  apiKeys: {
    'digiLocker': 'YOUR_DIGILOCKER_CLIENT_ID',
    'razorpay': 'YOUR_RAZORPAY_TEST_KEY',
    'firebase': 'YOUR_FIREBASE_PROJECT_ID',
    'googleMaps': 'YOUR_GOOGLE_MAPS_API_KEY',
    'weather': 'YOUR_WEATHER_API_KEY',
    'blockchain': 'YOUR_BLOCKCHAIN_API_KEY',
  },
  secrets: {
    'digiLockerSecret': 'YOUR_DIGILOCKER_CLIENT_SECRET',
    'razorpaySecret': 'YOUR_RAZORPAY_SECRET_KEY',
    'blockchainSecret': 'YOUR_BLOCKCHAIN_SECRET',
    // ... other secrets
  },
);
```

### Step 2: Update DigiLocker Sandbox Config

```dart
// lib/config/digilocker_sandbox_config.dart
class DigiLockerSandboxConfig {
  static const String sandboxClientId = 'YOUR_ACTUAL_DIGILOCKER_CLIENT_ID';
  static const String sandboxClientSecret = 'YOUR_ACTUAL_DIGILOCKER_CLIENT_SECRET';
  static const String sandboxRedirectUri = 'https://yourapp.com/auth/digilocker/callback';
  // ... rest of config
}
```

### Step 3: Add Firebase Configuration Files

```
Android: android/app/google-services.json
iOS: ios/Runner/GoogleService-Info.plist
```

### Step 4: Environment Variables (Recommended)

Create a `.env` file (don't commit to git):

```bash
# .env
DIGILOCKER_CLIENT_ID=your_digilocker_client_id
DIGILOCKER_CLIENT_SECRET=your_digilocker_client_secret
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
WEATHER_API_KEY=your_weather_api_key
BLOCKCHAIN_API_KEY=your_blockchain_api_key
```

---

## 🚀 Quick Start for Hackathon

### Minimum Required APIs:

1. **DigiLocker** (for KYC) - Essential for user verification
2. **Firebase** (for backend) - Essential for data storage
3. **Razorpay** (for payments) - Essential for marketplace

### Optional APIs:

4. **Google Maps** - Nice to have for location features
5. **Weather API** - Good for farming insights
6. **Blockchain API** - Great for supply chain transparency

### Hackathon Timeline:

```
Day 1: Set up Firebase and Razorpay (immediate)
Day 2: Apply for DigiLocker (1-2 days approval)
Day 3-4: Integrate APIs while waiting for DigiLocker approval
Day 5+: Complete integration and testing
```

---

## 🔒 Security Best Practices

### 1. Never Commit Secrets

```gitignore
# .gitignore
.env
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
lib/config/secrets.dart
```

### 2. Use Environment Variables

```dart
static const String apiKey = String.fromEnvironment('API_KEY', defaultValue: 'test_key');
```

### 3. Restrict API Keys

- Add package name restrictions for mobile APIs
- Use HTTP referrer restrictions for web APIs
- Enable only required API services

---

## 🆘 Troubleshooting

### Common Issues:

1. **DigiLocker Application Rejected**

   - Ensure you provide a valid callback URL
   - Use a proper business email address
   - Clearly mention it's for hackathon/educational purposes
2. **Firebase Setup Issues**

   - Ensure package names match exactly
   - Download fresh config files after any changes
   - Check that required services are enabled
3. **Razorpay Test Mode Issues**

   - Ensure you're using test keys (start with rzp_test_)
   - Use test card numbers for testing
   - Check webhook URLs are accessible
4. **API Rate Limits**

   - Most free tiers have generous limits for hackathons
   - Implement caching to reduce API calls
   - Use mock data for development

---

## 📞 Support Contacts

### DigiLocker Support:

- Email: support@digitallocker.gov.in
- Developer Portal: https://digitallocker.gov.in/developer

### Firebase Support:

- Documentation: https://firebase.google.com/docs
- Community: https://firebase.google.com/support

### Razorpay Support:

- Email: support@razorpay.com
- Documentation: https://razorpay.com/docs

---

## 🎯 Hackathon Tips

1. **Start with Firebase** - It's immediate and provides most backend needs
2. **Use Razorpay Test Mode** - Perfect for demo transactions
3. **Apply for DigiLocker Early** - It takes 1-2 days for approval
4. **Have Backup Plans** - Use mock data if APIs aren't ready
5. **Focus on UX** - Judges care more about user experience than complex integrations

**Remember**: The goal is to demonstrate your concept effectively. Don't let API setup block your progress - use mock data and focus on building a great user experience!

---

**Good luck with your hackathon! 🚀**
