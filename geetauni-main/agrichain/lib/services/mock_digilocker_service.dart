import 'dart:async';
import 'dart:math';
import '../config/digilocker_sandbox_config.dart';

/// Mock DigiLocker Service for Hackathon Demo
///
/// This service simulates DigiLocker API responses for demonstration purposes
/// when the actual sandbox is unavailable. It provides realistic mock data
/// and simulates API delays for a convincing demo experience.
class MockDigiLockerService {
  static const String _tag = 'MockDigiLockerService';

  // Mock user data for demo
  static const Map<String, dynamic> _mockUserProfile = {
    'name': 'Rajesh Kumar',
    'dob': '1985-06-15',
    'gender': 'M',
    'address':
        'Village Khetpura, Tehsil Sohna, District Gurugram, Haryana - 122103',
    'phone': '+91-9876543210',
    'email': 'rajesh.kumar@example.com',
    'aadhaar_last_4': '1234',
    'pan': 'ABCDE1234F',
  };

  // Mock documents available in DigiLocker
  static const List<Map<String, dynamic>> _mockDocuments = [
    {
      'docType': 'AADHAAR',
      'docId': 'AADHAAR-123456789012',
      'docName': 'Aadhaar Card',
      'issuer': 'UIDAI',
      'issueDate': '2020-03-15',
      'docUri': 'mock://aadhaar/123456789012',
      'verified': true,
    },
    {
      'docType': 'PAN',
      'docId': 'PAN-ABCDE1234F',
      'docName': 'PAN Card',
      'issuer': 'Income Tax Department',
      'issueDate': '2019-08-22',
      'docUri': 'mock://pan/ABCDE1234F',
      'verified': true,
    },
    {
      'docType': 'DRIVING_LICENSE',
      'docId': 'DL-HR0619850123456',
      'docName': 'Driving License',
      'issuer': 'Transport Department, Haryana',
      'issueDate': '2021-01-10',
      'expiryDate': '2041-01-10',
      'docUri': 'mock://dl/HR0619850123456',
      'verified': true,
    },
  ];

  /// Generate mock authorization URL
  static String generateAuthorizationUrl({
    required String clientId,
    required String redirectUri,
    required String state,
    List<String> scopes = const ['profile', 'documents'],
  }) {
    final scopeString = scopes.join(' ');
    return '${DigiLockerSandboxConfig.sandboxOAuthUrl}'
        '?client_id=$clientId'
        '&redirect_uri=$redirectUri'
        '&response_type=code'
        '&scope=$scopeString'
        '&state=$state'
        '&mock=true'; // Indicates this is a mock URL
  }

  /// Simulate OAuth token exchange
  static Future<Map<String, dynamic>> exchangeCodeForToken({
    required String code,
    required String clientId,
    required String clientSecret,
    required String redirectUri,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Validate mock authorization code
    if (!code.startsWith('MOCK_AUTH_CODE_')) {
      throw Exception('Invalid authorization code');
    }

    // Generate mock access token
    final accessToken = _generateMockToken('ACCESS');
    final refreshToken = _generateMockToken('REFRESH');

    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': 'Bearer',
      'expires_in': 3600,
      'scope': 'profile documents',
      'mock': true,
    };
  }

  /// Get mock user profile
  static Future<Map<String, dynamic>> getUserProfile(String accessToken) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1500));

    _validateMockToken(accessToken);

    return {
      'status': 'success',
      'data': {
        'user': _mockUserProfile,
        'verification_status': 'verified',
        'kyc_level': 'full',
        'last_updated': DateTime.now().toIso8601String(),
      },
      'mock': true,
    };
  }

  /// Get mock user documents
  static Future<Map<String, dynamic>> getUserDocuments(
    String accessToken,
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 2000));

    _validateMockToken(accessToken);

    return {
      'status': 'success',
      'data': {
        'documents': _mockDocuments,
        'total_count': _mockDocuments.length,
        'verified_count': _mockDocuments
            .where((doc) => doc['verified'] == true)
            .length,
      },
      'mock': true,
    };
  }

  /// Get specific document details
  static Future<Map<String, dynamic>> getDocumentDetails({
    required String accessToken,
    required String docId,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1000));

    _validateMockToken(accessToken);

    final document = _mockDocuments.firstWhere(
      (doc) => doc['docId'] == docId,
      orElse: () => throw Exception('Document not found'),
    );

    return {
      'status': 'success',
      'data': {
        'document': document,
        'content': _generateMockDocumentContent(document['docType']),
        'verification': {
          'verified': true,
          'verification_date': DateTime.now()
              .subtract(const Duration(days: 30))
              .toIso8601String(),
          'verification_method': 'digital_signature',
        },
      },
      'mock': true,
    };
  }

  /// Verify document authenticity (mock)
  static Future<Map<String, dynamic>> verifyDocument({
    required String accessToken,
    required String docId,
  }) async {
    // Simulate verification delay
    await Future.delayed(const Duration(seconds: 3));

    _validateMockToken(accessToken);

    // Simulate 95% success rate
    final isVerified = Random().nextDouble() > 0.05;

    return {
      'status': 'success',
      'data': {
        'doc_id': docId,
        'verified': isVerified,
        'verification_score': isVerified
            ? (0.85 + Random().nextDouble() * 0.15)
            : (Random().nextDouble() * 0.5),
        'verification_details': {
          'digital_signature': isVerified,
          'issuer_verification': isVerified,
          'tamper_check': isVerified,
          'expiry_check': true,
        },
        'verification_timestamp': DateTime.now().toIso8601String(),
      },
      'mock': true,
    };
  }

  /// Generate mock authorization code (for demo purposes)
  static String generateMockAuthCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'MOCK_AUTH_CODE_${timestamp}_$random';
  }

  /// Check if service is in mock mode
  static bool get isMockMode => DigiLockerSandboxConfig.isApiSetuSandbox;

  /// Get mock service status
  static Map<String, dynamic> getServiceStatus() {
    return {
      'service': 'DigiLocker Mock Service',
      'status': 'active',
      'mode': 'mock',
      'api_setu_available': false,
      'mock_users': 1,
      'mock_documents': _mockDocuments.length,
      'uptime': '100%',
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  // Private helper methods

  static String _generateMockToken(String type) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999999).toString();
    return 'MOCK_${type}_TOKEN_${timestamp}_$random';
  }

  static void _validateMockToken(String token) {
    if (!token.startsWith('MOCK_') || !token.contains('TOKEN')) {
      throw Exception('Invalid or expired access token');
    }
  }

  static Map<String, dynamic> _generateMockDocumentContent(String docType) {
    switch (docType) {
      case 'AADHAAR':
        return {
          'name': _mockUserProfile['name'],
          'dob': _mockUserProfile['dob'],
          'gender': _mockUserProfile['gender'],
          'address': _mockUserProfile['address'],
          'aadhaar_number': '****-****-1234',
          'photo_available': true,
        };
      case 'PAN':
        return {
          'name': _mockUserProfile['name'],
          'father_name': 'Suresh Kumar',
          'dob': _mockUserProfile['dob'],
          'pan_number': _mockUserProfile['pan'],
          'signature_available': true,
        };
      case 'DRIVING_LICENSE':
        return {
          'name': _mockUserProfile['name'],
          'dob': _mockUserProfile['dob'],
          'address': _mockUserProfile['address'],
          'license_number': 'HR0619850123456',
          'vehicle_class': 'LMV',
          'issue_date': '2021-01-10',
          'expiry_date': '2041-01-10',
          'photo_available': true,
        };
      default:
        return {'document_type': docType, 'content': 'Mock document content'};
    }
  }
}

/// Mock DigiLocker API Response Models
class MockDigiLockerResponse {
  final bool success;
  final Map<String, dynamic> data;
  final String? error;
  final bool isMock;

  MockDigiLockerResponse({
    required this.success,
    required this.data,
    this.error,
    this.isMock = true,
  });

  factory MockDigiLockerResponse.success(Map<String, dynamic> data) {
    return MockDigiLockerResponse(success: true, data: data, isMock: true);
  }

  factory MockDigiLockerResponse.error(String error) {
    return MockDigiLockerResponse(
      success: false,
      data: {},
      error: error,
      isMock: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'error': error,
      'mock': isMock,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
