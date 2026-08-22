# DigiLocker Sandbox Setup Guide for Hackathon

## Overview

This guide will help you set up DigiLocker sandbox integration for your AgriChain hackathon project. The sandbox environment allows you to test KYC functionality without requiring real documents.

## Quick Setup Steps

### 1. Register for DigiLocker Developer Account

1. Visit [DigiLocker Developer Portal](https://digitallocker.gov.in/developer)
2. Click on "Register as Developer"
3. Fill in your details and verify your email
4. Wait for approval (usually takes 1-2 business days)

### 2. Create Sandbox Application

1. Login to the Developer Portal
2. Go to "My Applications" → "Create New Application"
3. Fill in application details:
   - **Application Name**: AgriChain Hackathon
   - **Application Type**: Mobile Application
   - **Platform**: Android/iOS
   - **Callback URL**: `https://yourapp.com/auth/digilocker/callback`
   - **Description**: Agricultural supply chain management app for hackathon

4. Submit the application and wait for approval

### 3. Get Your Credentials

Once approved, you'll receive:
- **Client ID**: Your unique application identifier
- **Client Secret**: Your application secret key

### 4. Update Configuration

Update the sandbox configuration in your project:

```dart
// lib/config/digilocker_sandbox_config.dart
class DigiLockerSandboxConfig {
  // Replace these with your actual sandbox credentials
  static const String sandboxClientId = 'your_actual_client_id_here';
  static const String sandboxClientSecret = 'your_actual_client_secret_here';
  static const String sandboxRedirectUri = 'https://yourapp.com/auth/digilocker/callback';
  
  // ... rest of the configuration
}
```

### 5. Test the Integration

Run the following code to test your configuration:

```dart
import 'package:agrichain/config/digilocker_sandbox_config.dart';

void main() {
  // Print configuration summary
  DigiLockerSandboxConfig.printConfigSummary();
  
  // Validate configuration
  if (DigiLockerSandboxConfig.validateConfig()) {
    print('✅ DigiLocker sandbox is ready!');
  } else {
    print('❌ Configuration needs to be updated');
    print(DigiLockerSandboxConfig.getSetupInstructions());
  }
}
```

## Sandbox Features

### Mock Documents Available

The sandbox provides test documents for:
- **Aadhaar**: 123456789012
- **PAN**: ABCDE1234F
- **Driving License**: DL1420110012345
- **Voter ID**: ABC1234567
- **Passport**: A1234567

### Mock User Data

```json
{
  "name": "Test User",
  "dateOfBirth": "1990-01-01",
  "gender": "M",
  "address": {
    "street": "123 Test Street",
    "city": "Test City",
    "state": "Test State",
    "pincode": "123456"
  },
  "phone": "+91-9876543210",
  "email": "testuser@example.com"
}
```

## OAuth Flow for Hackathon

### 1. Authorization Request

```dart
final authUrl = DigiLockerSandboxConfig.getAuthorizationUrl(
  state: 'hackathon_demo',
  scopes: ['aadhaar', 'pan'],
);

// Open this URL in a web browser or WebView
print('Authorization URL: $authUrl');
```

### 2. Handle Callback

When user authorizes, DigiLocker will redirect to your callback URL with an authorization code:

```
https://yourapp.com/auth/digilocker/callback?code=AUTH_CODE&state=hackathon_demo
```

### 3. Exchange Code for Token

```dart
final tokenConfig = DigiLockerSandboxConfig.getTokenConfig();
final response = await http.post(
  Uri.parse(tokenConfig['tokenUrl']),
  headers: {'Content-Type': 'application/x-www-form-urlencoded'},
  body: {
    'grant_type': tokenConfig['grantType'],
    'client_id': tokenConfig['clientId'],
    'client_secret': tokenConfig['clientSecret'],
    'code': authCode,
    'redirect_uri': tokenConfig['redirectUri'],
  },
);
```

### 4. Access Documents

```dart
final apiConfig = DigiLockerSandboxConfig.getApiConfig();
final endpoints = DigiLockerSandboxConfig.getDocumentEndpoints();

// Get Aadhaar data
final aadhaarResponse = await http.get(
  Uri.parse(endpoints['aadhaar']!),
  headers: {
    'Authorization': 'Bearer $accessToken',
    ...apiConfig['headers'],
  },
);
```

## Testing Without Real Integration

For hackathon demos, you can use mock responses:

```dart
// Get mock Aadhaar response
final mockAadhaar = DigiLockerSandboxConfig.getMockDocumentResponse('aadhaar');
print('Mock Aadhaar Data: $mockAadhaar');

// Get mock PAN response
final mockPan = DigiLockerSandboxConfig.getMockDocumentResponse('pan');
print('Mock PAN Data: $mockPan');
```

## Troubleshooting

### Common Issues

1. **"Invalid Client ID" Error**
   - Ensure you've updated `sandboxClientId` with your actual client ID
   - Check that your application is approved in the developer portal

2. **"Redirect URI Mismatch" Error**
   - Ensure the redirect URI in your code matches the one registered in the developer portal
   - Use HTTPS for production URLs

3. **"Invalid Scope" Error**
   - Check that the requested scopes are supported
   - Ensure your application has permission for the requested document types

### Debug Configuration

```dart
void debugDigiLockerConfig() {
  print('🔍 DigiLocker Debug Information:');
  
  final config = DigiLockerSandboxConfig.getApiConfig();
  print('Base URL: ${config['baseUrl']}');
  
  final tokenConfig = DigiLockerSandboxConfig.getTokenConfig();
  print('Token URL: ${tokenConfig['tokenUrl']}');
  print('Client ID: ${tokenConfig['clientId']}');
  
  final endpoints = DigiLockerSandboxConfig.getDocumentEndpoints();
  print('Available Endpoints:');
  endpoints.forEach((key, value) {
    print('  $key: $value');
  });
}
```

## Demo Flow for Hackathon

For your hackathon presentation, you can demonstrate:

1. **User Registration**: Show KYC verification flow
2. **Document Upload**: Simulate document verification
3. **Profile Creation**: Auto-populate user profile from DigiLocker data
4. **Verification Status**: Show verified user badge

### Sample Demo Script

```dart
// Demo: KYC Verification Flow
void demonstrateKycFlow() async {
  print('🎯 Starting KYC Demo...');
  
  // Step 1: Show authorization URL
  final authUrl = DigiLockerSandboxConfig.getAuthorizationUrl();
  print('1. User clicks "Verify with DigiLocker"');
  print('   Redirect to: $authUrl');
  
  // Step 2: Simulate successful authorization
  print('2. User authorizes access to documents');
  
  // Step 3: Show mock document data
  final aadhaarData = DigiLockerSandboxConfig.getMockDocumentResponse('aadhaar');
  print('3. Retrieved Aadhaar data: ${aadhaarData['data']['name']}');
  
  // Step 4: Show verification complete
  print('4. ✅ KYC Verification Complete!');
  print('   User profile updated with verified information');
}
```

## Environment Variables (Optional)

For better security, you can use environment variables:

```bash
# .env file (don't commit to git)
DIGILOCKER_CLIENT_ID=your_sandbox_client_id
DIGILOCKER_CLIENT_SECRET=your_sandbox_client_secret
DIGILOCKER_REDIRECT_URI=https://yourapp.com/auth/digilocker/callback
```

Then update your configuration:

```dart
static const String sandboxClientId = String.fromEnvironment(
  'DIGILOCKER_CLIENT_ID',
  defaultValue: 'your_sandbox_client_id_here',
);
```

## Next Steps

1. **Get Sandbox Credentials**: Register and get your client ID/secret
2. **Update Configuration**: Replace placeholder values with real credentials
3. **Test Integration**: Use the provided test methods
4. **Build Demo**: Create a compelling demo for your hackathon presentation
5. **Document Usage**: Show how KYC verification enhances your AgriChain app

## Support

For hackathon support:
- Check DigiLocker Developer Documentation
- Use the mock responses for demo purposes
- Focus on the user experience rather than complex integration details

Remember: The goal is to demonstrate the concept and user experience. The sandbox environment is perfect for hackathon presentations!

---

**Happy Hacking! 🚀**