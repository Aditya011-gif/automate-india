/// DigiLocker Sandbox Configuration for Hackathon
/// 
/// This file contains sandbox-specific configuration for DigiLocker integration.
/// Replace the placeholder values with your actual sandbox credentials.
library;

class DigiLockerSandboxConfig {
  // API Setu Sandbox Environment URLs
  static const String sandboxBaseUrl = 'https://sandbox.api-setu.in';
  static const String sandboxOAuthUrl = 'https://sandbox.api-setu.in/api/digilocker/oauth2/1/authorize';
  static const String sandboxTokenUrl = 'https://sandbox.api-setu.in/api/digilocker/oauth2/1/token';
  static const String sandboxApiUrl = 'https://sandbox.api-setu.in/api/digilocker/v1';
  
  // API Setu Sandbox Credentials (Replace with actual API Setu credentials)
  static const String sandboxClientId = 'API_SETU_CLIENT_ID';
  static const String sandboxClientSecret = 'API_SETU_CLIENT_SECRET';
  static const String sandboxRedirectUri = 'https://agrichain-hackathon.com/auth/digilocker/callback';
  
  // API Setu specific configuration
  static const String apiSetuBaseUrl = 'https://sandbox.api-setu.in/api-collection/digilocker/0';
  static const bool isApiSetuSandbox = true;
  
  // OAuth Scopes for DigiLocker
  static const List<String> requiredScopes = [
    'aadhaar',
    'pan',
    'driving_license',
    'voter_id',
    'passport',
  ];
  
  // Sandbox Configuration
  static const Map<String, dynamic> sandboxConfig = {
    'environment': 'sandbox',
    'enableMockResponses': true,
    'enableTestDocuments': true,
    'skipActualVerification': true,
    'autoApproveDocuments': true,
    'simulateNetworkDelay': true,
    'networkDelayMs': 1000,
  };
  
  // Test Document IDs for Sandbox
  static const Map<String, String> testDocumentIds = {
    'aadhaar': '123456789012',
    'pan': 'ABCDE1234F',
    'driving_license': 'DL1420110012345',
    'voter_id': 'ABC1234567',
    'passport': 'A1234567',
  };
  
  // Mock User Data for Testing
  static const Map<String, dynamic> mockUserData = {
    'name': 'Test User',
    'dateOfBirth': '1990-01-01',
    'gender': 'M',
    'address': {
      'street': '123 Test Street',
      'city': 'Test City',
      'state': 'Test State',
      'pincode': '123456',
    },
    'phone': '+91-9876543210',
    'email': 'testuser@example.com',
  };
  
  /// Get OAuth authorization URL for sandbox
  static String getAuthorizationUrl({
    String? state,
    List<String>? scopes,
  }) {
    final scopeString = (scopes ?? requiredScopes).join(' ');
    final stateParam = state ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    final params = {
      'response_type': 'code',
      'client_id': sandboxClientId,
      'redirect_uri': sandboxRedirectUri,
      'scope': scopeString,
      'state': stateParam,
    };
    
    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$sandboxOAuthUrl?$queryString';
  }
  
  /// Get token exchange configuration
  static Map<String, dynamic> getTokenConfig() {
    return {
      'tokenUrl': sandboxTokenUrl,
      'clientId': sandboxClientId,
      'clientSecret': sandboxClientSecret,
      'redirectUri': sandboxRedirectUri,
      'grantType': 'authorization_code',
    };
  }
  
  /// Get API configuration for document access
  static Map<String, dynamic> getApiConfig() {
    return {
      'baseUrl': sandboxApiUrl,
      'timeout': const Duration(seconds: 30),
      'retryAttempts': 3,
      'headers': {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'AgriChain-Hackathon/1.0',
      },
    };
  }
  
  /// Get document endpoints
  static Map<String, String> getDocumentEndpoints() {
    return {
      'aadhaar': '$sandboxApiUrl/aadhaar',
      'pan': '$sandboxApiUrl/pan',
      'driving_license': '$sandboxApiUrl/driving_license',
      'voter_id': '$sandboxApiUrl/voter_id',
      'passport': '$sandboxApiUrl/passport',
      'profile': '$sandboxApiUrl/profile',
    };
  }
  
  /// Validate sandbox configuration
  static bool validateConfig() {
    if (sandboxClientId == 'your_sandbox_client_id_here') {
      print('⚠️  Warning: Please update sandboxClientId with your actual sandbox client ID');
      return false;
    }
    
    if (sandboxClientSecret == 'your_sandbox_client_secret_here') {
      print('⚠️  Warning: Please update sandboxClientSecret with your actual sandbox client secret');
      return false;
    }
    
    if (!sandboxRedirectUri.startsWith('https://')) {
      print('⚠️  Warning: Redirect URI should use HTTPS in production');
    }
    
    return true;
  }
  
  /// Get setup instructions for developers
  static String getSetupInstructions() {
    return '''
DigiLocker Sandbox Setup Instructions:

1. Register for DigiLocker Developer Account:
   - Visit: https://digitallocker.gov.in/developer
   - Create a developer account
   - Apply for sandbox access

2. Create a Sandbox Application:
   - Login to DigiLocker Developer Portal
   - Create a new application
   - Note down your Client ID and Client Secret

3. Update Configuration:
   - Replace 'your_sandbox_client_id_here' with your actual Client ID
   - Replace 'your_sandbox_client_secret_here' with your actual Client Secret
   - Update redirect URI to match your app's callback URL

4. Configure Callback URL:
   - In DigiLocker Developer Portal, set callback URL to:
     $sandboxRedirectUri
   - Ensure this matches your app's deep link configuration

5. Test Integration:
   - Use the test document IDs provided in testDocumentIds
   - Sandbox will return mock data for testing
   - No actual documents are accessed in sandbox mode

6. Environment Variables (Optional):
   - Set DIGILOCKER_CLIENT_ID environment variable
   - Set DIGILOCKER_CLIENT_SECRET environment variable
   - Set DIGILOCKER_REDIRECT_URI environment variable

For hackathon purposes, you can use the sandbox environment
which provides mock responses without requiring real documents.
''';
  }
  
  /// Get mock response for testing
  static Map<String, dynamic> getMockDocumentResponse(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'aadhaar':
        return {
          'status': 'success',
          'data': {
            'uid': testDocumentIds['aadhaar'],
            'name': mockUserData['name'],
            'dob': mockUserData['dateOfBirth'],
            'gender': mockUserData['gender'],
            'address': mockUserData['address'],
            'photo': 'base64_encoded_photo_data',
          },
        };
      
      case 'pan':
        return {
          'status': 'success',
          'data': {
            'pan': testDocumentIds['pan'],
            'name': mockUserData['name'],
            'father_name': 'Test Father',
            'dob': mockUserData['dateOfBirth'],
          },
        };
      
      case 'driving_license':
        return {
          'status': 'success',
          'data': {
            'dl_number': testDocumentIds['driving_license'],
            'name': mockUserData['name'],
            'dob': mockUserData['dateOfBirth'],
            'address': mockUserData['address'],
            'vehicle_class': ['LMV', 'MCWG'],
            'issue_date': '2020-01-01',
            'expiry_date': '2040-01-01',
          },
        };
      
      default:
        return {
          'status': 'error',
          'message': 'Document type not supported in sandbox',
        };
    }
  }
  
  /// Print configuration summary
  static void printConfigSummary() {
    print('🔧 DigiLocker Sandbox Configuration:');
    print('   Environment: Sandbox');
    print('   Base URL: $sandboxBaseUrl');
    print('   Client ID: ${sandboxClientId.substring(0, 8)}...');
    print('   Redirect URI: $sandboxRedirectUri');
    print('   Scopes: ${requiredScopes.join(', ')}');
    print('   Mock Responses: ${sandboxConfig['enableMockResponses']}');
    print('   Test Documents: ${sandboxConfig['enableTestDocuments']}');
    
    if (!validateConfig()) {
      print('⚠️  Configuration needs to be updated with actual sandbox credentials');
      print('📖 Run DigiLockerSandboxConfig.getSetupInstructions() for help');
    } else {
      print('✅ Configuration looks good!');
    }
  }
}