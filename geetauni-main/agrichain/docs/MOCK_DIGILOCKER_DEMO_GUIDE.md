# Mock DigiLocker Service - Hackathon Demo Guide

## 🎯 Overview

Since the API Setu DigiLocker sandbox is currently unavailable, we've created a comprehensive Mock DigiLocker Service that provides realistic demo data and simulates actual API responses. This is perfect for hackathon presentations and demonstrations.

## 🚀 Features

### ✅ What the Mock Service Provides:

- **Realistic User Profiles**: Complete with Indian names, addresses, and phone numbers
- **Authentic Document Types**: Aadhaar, PAN, Driving License
- **Verification Simulation**: 95% success rate with realistic verification scores
- **API Response Delays**: Simulates real network latency for convincing demos
- **Error Handling**: Demonstrates proper error scenarios
- **Complete OAuth Flow**: Mock authorization and token exchange

### 📋 Mock User Data

```json
{
  "name": "Rajesh Kumar",
  "dob": "1985-06-15",
  "gender": "M",
  "address": "Village Khetpura, Tehsil Sohna, District Gurugram, Haryana - 122103",
  "phone": "+91-9876543210",
  "email": "rajesh.kumar@example.com",
  "aadhaar_last_4": "1234",
  "pan": "ABCDE1234F"
}
```

### 📄 Available Mock Documents

1. **Aadhaar Card**
   - Document ID: `AADHAAR-123456789012`
   - Issuer: UIDAI
   - Status: Verified ✅

2. **PAN Card**
   - Document ID: `PAN-ABCDE1234F`
   - Issuer: Income Tax Department
   - Status: Verified ✅

3. **Driving License**
   - Document ID: `DL-HR0619850123456`
   - Issuer: Transport Department, Haryana
   - Status: Verified ✅

## 🎬 Demo Script for Hackathon

### Step 1: User Registration with KYC

```dart
// In your app, when user clicks "Verify with DigiLocker"
String authUrl = MockDigiLockerService.generateAuthorizationUrl(
  clientId: 'API_SETU_CLIENT_ID',
  redirectUri: 'https://agrichain-hackathon.com/auth/digilocker/callback',
  state: 'unique_state_123',
);

// This generates: https://sandbox.api-setu.in/api/digilocker/oauth2/1/authorize?...&mock=true
```

**Demo Narration**: 
> "When a farmer registers on AgriChain, they need to verify their identity using DigiLocker. This ensures only legitimate farmers can access our platform and builds trust in the supply chain."

### Step 2: Mock Authorization Flow

```dart
// Simulate user returning from DigiLocker with auth code
String mockAuthCode = MockDigiLockerService.generateMockAuthCode();
// Returns: "MOCK_AUTH_CODE_1703123456789_123456"

// Exchange code for access token
Map<String, dynamic> tokenResponse = await MockDigiLockerService.exchangeCodeForToken(
  code: mockAuthCode,
  clientId: 'API_SETU_CLIENT_ID',
  clientSecret: 'API_SETU_CLIENT_SECRET',
  redirectUri: 'https://agrichain-hackathon.com/auth/digilocker/callback',
);
```

**Demo Narration**: 
> "The user authorizes our app to access their DigiLocker documents. We receive a secure access token that allows us to fetch their verified documents."

### Step 3: Fetch User Profile

```dart
Map<String, dynamic> profile = await MockDigiLockerService.getUserProfile(accessToken);

// Response includes:
// - Name: Rajesh Kumar
// - Address: Village Khetpura, Tehsil Sohna, District Gurugram, Haryana
// - Verification Status: Verified
// - KYC Level: Full
```

**Demo Narration**: 
> "We can now see Rajesh Kumar's verified profile. Notice his address shows he's from a farming village in Haryana - this helps us verify he's a legitimate farmer and can provide location-based services."

### Step 4: Document Verification

```dart
Map<String, dynamic> documents = await MockDigiLockerService.getUserDocuments(accessToken);

// Shows 3 verified documents:
// - Aadhaar Card (Identity proof)
// - PAN Card (Tax compliance)
// - Driving License (Additional verification)

// Verify a specific document
Map<String, dynamic> verification = await MockDigiLockerService.verifyDocument(
  accessToken: accessToken,
  docId: 'AADHAAR-123456789012',
);

// Returns verification score: 0.92 (92% confidence)
```

**Demo Narration**: 
> "All of Rajesh's documents are verified with high confidence scores. This multi-document verification ensures the highest level of trust in our platform. Buyers can be confident they're dealing with verified farmers."

### Step 5: Complete KYC Integration

```dart
// Check service status
Map<String, dynamic> status = MockDigiLockerService.getServiceStatus();

// Returns:
// - Service: Active
// - Mode: Mock (for demo)
// - Documents Available: 3
// - Uptime: 100%
```

**Demo Narration**: 
> "Our KYC system is fully operational. In production, this would connect to the real DigiLocker API, but for this demo, we're using our mock service that provides the same functionality."

## 🎭 Demo Presentation Tips

### 1. **Start with the Problem**
> "Traditional agriculture lacks transparency and trust. Buyers don't know if farmers are legitimate, and farmers struggle to prove their credibility."

### 2. **Introduce the Solution**
> "AgriChain uses DigiLocker integration to verify farmer identities using government-issued documents, creating a trusted agricultural marketplace."

### 3. **Show the Technology**
> "Our app seamlessly integrates with DigiLocker - India's digital document wallet - to verify farmers in real-time."

### 4. **Demonstrate the Flow**
- Show the "Verify with DigiLocker" button
- Explain the OAuth flow (even though it's mocked)
- Display the verified user profile
- Show the document verification results

### 5. **Highlight the Benefits**
> "This creates a verified ecosystem where:
> - Farmers can prove their legitimacy
> - Buyers can trust their suppliers
> - The entire supply chain becomes transparent
> - Government compliance is automated"

## 🔧 Technical Implementation

### Integration in Your App

```dart
// lib/services/kyc_service.dart
import 'mock_digilocker_service.dart';

class KycService {
  static bool get isMockMode => MockDigiLockerService.isMockMode;
  
  Future<bool> verifyUserWithDigiLocker(String userId) async {
    if (isMockMode) {
      // Use mock service for demo
      String authCode = MockDigiLockerService.generateMockAuthCode();
      var tokenResponse = await MockDigiLockerService.exchangeCodeForToken(
        code: authCode,
        clientId: 'API_SETU_CLIENT_ID',
        clientSecret: 'API_SETU_CLIENT_SECRET',
        redirectUri: 'https://agrichain-hackathon.com/auth/digilocker/callback',
      );
      
      var profile = await MockDigiLockerService.getUserProfile(tokenResponse['access_token']);
      var documents = await MockDigiLockerService.getUserDocuments(tokenResponse['access_token']);
      
      // Process verification results
      return profile['data']['verification_status'] == 'verified';
    } else {
      // Use real DigiLocker API when available
      return await _realDigiLockerVerification(userId);
    }
  }
}
```

### UI Components

```dart
// Show verification status in UI
Widget buildVerificationStatus() {
  return Card(
    child: ListTile(
      leading: Icon(
        Icons.verified_user,
        color: Colors.green,
      ),
      title: Text('KYC Verified'),
      subtitle: Text('Verified via DigiLocker'),
      trailing: MockDigiLockerService.isMockMode 
        ? Chip(
            label: Text('DEMO'),
            backgroundColor: Colors.orange,
          )
        : null,
    ),
  );
}
```

## 🎪 Demo Scenarios

### Scenario 1: Successful Verification
- User: Rajesh Kumar (Farmer from Haryana)
- Documents: All verified ✅
- Verification Score: 92%
- Result: Full access to platform

### Scenario 2: Partial Verification
- User: Modify mock data to show only 2 documents
- Documents: Aadhaar + PAN (missing driving license)
- Verification Score: 78%
- Result: Limited access, prompt for additional documents

### Scenario 3: Verification Failure
- User: Simulate 5% failure rate
- Documents: Verification failed
- Verification Score: 23%
- Result: Manual review required

## 🚨 Important Notes for Judges

1. **This is a Mock Service**: Clearly explain that you're using a mock service because API Setu's DigiLocker is temporarily unavailable.

2. **Production Ready**: Emphasize that switching to the real API requires only changing configuration - no code changes needed.

3. **Security Conscious**: Highlight that you've implemented proper OAuth flows and token handling even in the mock version.

4. **Realistic Data**: The mock data represents real Indian scenarios with authentic addresses and document types.

5. **Scalable Architecture**: The service abstraction allows easy switching between mock and real APIs.

## 🔄 Switching to Real API

When API Setu DigiLocker becomes available:

```dart
// lib/config/digilocker_sandbox_config.dart
class DigiLockerSandboxConfig {
  static const bool isApiSetuSandbox = false; // Change this to false
  // Update with real API Setu credentials
}
```

That's it! The entire app will automatically switch to the real API.

## 🏆 Hackathon Success Tips

1. **Practice the Demo**: Run through the verification flow multiple times
2. **Prepare for Questions**: Be ready to explain the technical architecture
3. **Show the Code**: Judges love seeing clean, well-structured code
4. **Emphasize Real-World Impact**: Connect the technology to actual farmer problems
5. **Have a Backup Plan**: If the demo fails, explain the concept clearly

**Remember**: The goal is to demonstrate your understanding of KYC integration and its importance in agricultural supply chains. The mock service allows you to do this effectively even without the real API!

---

**Good luck with your hackathon! 🚀**