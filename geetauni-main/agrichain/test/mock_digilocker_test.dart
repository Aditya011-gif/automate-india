import 'package:flutter_test/flutter_test.dart';
import 'package:agrichain/services/mock_digilocker_service.dart';

void main() {
  group('Mock DigiLocker Service Tests', () {
    test('should generate valid authorization URL', () {
      final authUrl = MockDigiLockerService.generateAuthorizationUrl(
        clientId: 'test_client_id',
        redirectUri: 'https://test.com/callback',
        state: 'test_state_123',
      );

      expect(authUrl, contains('sandbox.api-setu.in'));
      expect(authUrl, contains('client_id=test_client_id'));
      expect(authUrl, contains('redirect_uri=https://test.com/callback'));
      expect(authUrl, contains('state=test_state_123'));
      expect(authUrl, contains('mock=true'));
    });

    test('should generate mock authorization code', () {
      final authCode = MockDigiLockerService.generateMockAuthCode();
      
      expect(authCode, startsWith('MOCK_AUTH_CODE_'));
      expect(authCode.length, greaterThan(20));
    });

    test('should exchange code for token', () async {
      final authCode = MockDigiLockerService.generateMockAuthCode();
      
      final tokenResponse = await MockDigiLockerService.exchangeCodeForToken(
        code: authCode,
        clientId: 'test_client_id',
        clientSecret: 'test_client_secret',
        redirectUri: 'https://test.com/callback',
      );

      expect(tokenResponse['access_token'], isNotNull);
      expect(tokenResponse['refresh_token'], isNotNull);
      expect(tokenResponse['token_type'], equals('Bearer'));
      expect(tokenResponse['expires_in'], equals(3600));
      expect(tokenResponse['mock'], equals(true));
    });

    test('should get user profile', () async {
      final authCode = MockDigiLockerService.generateMockAuthCode();
      final tokenResponse = await MockDigiLockerService.exchangeCodeForToken(
        code: authCode,
        clientId: 'test_client_id',
        clientSecret: 'test_client_secret',
        redirectUri: 'https://test.com/callback',
      );

      final profile = await MockDigiLockerService.getUserProfile(
        tokenResponse['access_token'],
      );

      expect(profile['status'], equals('success'));
      expect(profile['data']['user']['name'], equals('Rajesh Kumar'));
      expect(profile['data']['verification_status'], equals('verified'));
      expect(profile['data']['kyc_level'], equals('full'));
      expect(profile['mock'], equals(true));
    });

    test('should get user documents', () async {
      final authCode = MockDigiLockerService.generateMockAuthCode();
      final tokenResponse = await MockDigiLockerService.exchangeCodeForToken(
        code: authCode,
        clientId: 'test_client_id',
        clientSecret: 'test_client_secret',
        redirectUri: 'https://test.com/callback',
      );

      final documents = await MockDigiLockerService.getUserDocuments(
        tokenResponse['access_token'],
      );

      expect(documents['status'], equals('success'));
      expect(documents['data']['documents'], isA<List>());
      expect(documents['data']['documents'].length, equals(3));
      expect(documents['data']['total_count'], equals(3));
      expect(documents['data']['verified_count'], equals(3));
      expect(documents['mock'], equals(true));

      // Check document types
      final docTypes = documents['data']['documents']
          .map((doc) => doc['docType'])
          .toList();
      expect(docTypes, contains('AADHAAR'));
      expect(docTypes, contains('PAN'));
      expect(docTypes, contains('DRIVING_LICENSE'));
    });

    test('should verify document', () async {
      final authCode = MockDigiLockerService.generateMockAuthCode();
      final tokenResponse = await MockDigiLockerService.exchangeCodeForToken(
        code: authCode,
        clientId: 'test_client_id',
        clientSecret: 'test_client_secret',
        redirectUri: 'https://test.com/callback',
      );

      final verification = await MockDigiLockerService.verifyDocument(
        accessToken: tokenResponse['access_token'],
        docId: 'AADHAAR-123456789012',
      );

      expect(verification['status'], equals('success'));
      expect(verification['data']['doc_id'], equals('AADHAAR-123456789012'));
      expect(verification['data']['verification_score'], isA<double>());
      expect(verification['data']['verification_details'], isNotNull);
      expect(verification['mock'], equals(true));
    });

    test('should get service status', () {
      final status = MockDigiLockerService.getServiceStatus();

      expect(status['service'], equals('DigiLocker Mock Service'));
      expect(status['status'], equals('active'));
      expect(status['mode'], equals('mock'));
      expect(status['api_setu_available'], equals(false));
      expect(status['mock_users'], equals(1));
      expect(status['mock_documents'], equals(3));
      expect(status['uptime'], equals('100%'));
    });

    test('should handle invalid token', () async {
      expect(
        () => MockDigiLockerService.getUserProfile('invalid_token'),
        throwsException,
      );
    });

    test('should handle invalid authorization code', () async {
      expect(
        () => MockDigiLockerService.exchangeCodeForToken(
          code: 'invalid_code',
          clientId: 'test_client_id',
          clientSecret: 'test_client_secret',
          redirectUri: 'https://test.com/callback',
        ),
        throwsException,
      );
    });

    test('should be in mock mode', () {
      expect(MockDigiLockerService.isMockMode, equals(true));
    });
  });

  group('Mock DigiLocker Response Tests', () {
    test('should create success response', () {
      final response = MockDigiLockerResponse.success({'test': 'data'});

      expect(response.success, equals(true));
      expect(response.data['test'], equals('data'));
      expect(response.error, isNull);
      expect(response.isMock, equals(true));
    });

    test('should create error response', () {
      final response = MockDigiLockerResponse.error('Test error');

      expect(response.success, equals(false));
      expect(response.data, isEmpty);
      expect(response.error, equals('Test error'));
      expect(response.isMock, equals(true));
    });

    test('should convert to JSON', () {
      final response = MockDigiLockerResponse.success({'test': 'data'});
      final json = response.toJson();

      expect(json['success'], equals(true));
      expect(json['data']['test'], equals('data'));
      expect(json['mock'], equals(true));
      expect(json['timestamp'], isNotNull);
    });
  });
}