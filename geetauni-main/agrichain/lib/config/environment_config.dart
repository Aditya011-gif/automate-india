/// Environment-specific configuration settings
class EnvironmentConfig {
  final String name;
  final String apiBaseUrl;
  final String databaseName;
  final bool enableLogging;
  final bool enableDebugMode;
  final bool enableMockData;
  final bool skipKycInDev;
  final Duration sessionTimeout;
  final int maxLoginAttempts;
  final Map<String, String> apiKeys;
  final Map<String, String> secrets;

  const EnvironmentConfig({
    required this.name,
    required this.apiBaseUrl,
    required this.databaseName,
    required this.enableLogging,
    required this.enableDebugMode,
    required this.enableMockData,
    required this.skipKycInDev,
    required this.sessionTimeout,
    required this.maxLoginAttempts,
    required this.apiKeys,
    required this.secrets,
  });

  /// Development environment configuration (using DigiLocker Sandbox for hackathon)
  static const EnvironmentConfig development = EnvironmentConfig(
    name: 'development',
    apiBaseUrl: 'https://dev-api.agrichain.com',
    databaseName: 'agrichain_dev.db',
    enableLogging: true,
    enableDebugMode: true,
    enableMockData: true,
    skipKycInDev: false, // Enable KYC testing with sandbox
    sessionTimeout: Duration(hours: 8),
    maxLoginAttempts: 10,
    apiKeys: {
      'digiLocker': 'sandbox_client_id', // DigiLocker sandbox client ID
      'digiLockerApiUrl': 'https://api.digitallocker.gov.in/public/oauth2/1/authorize', // Sandbox OAuth URL
      'digiLockerTokenUrl': 'https://api.digitallocker.gov.in/public/oauth2/1/token', // Sandbox token URL
      'digiLockerApiBaseUrl': 'https://api.digitallocker.gov.in/public/oauth2/2', // Sandbox API base URL
      'razorpay': 'rzp_test_key',
      'firebase': 'dev-firebase-key',
    },
    secrets: {
      'encryptionKey': 'dev-test-32-char-encryption-key1',
      'jwtSecret': 'dev-jwt-secret-key-minimum-32-chars',
      'digiLockerSecret': 'sandbox_client_secret', // DigiLocker sandbox client secret
      'digiLockerRedirectUri': 'https://yourapp.com/auth/digilocker/callback', // Your app's callback URL
      'razorpaySecret': 'dev-razorpay-secret',
    },
  );

  /// Staging environment configuration
  static const EnvironmentConfig staging = EnvironmentConfig(
    name: 'staging',
    apiBaseUrl: 'https://staging-api.agrichain.com',
    databaseName: 'agrichain_staging.db',
    enableLogging: true,
    enableDebugMode: false,
    enableMockData: false,
    skipKycInDev: false,
    sessionTimeout: Duration(hours: 12),
    maxLoginAttempts: 5,
    apiKeys: {
      'digiLocker': 'staging-digilocker-key',
      'razorpay': 'rzp_test_key',
      'firebase': 'staging-firebase-key',
    },
    secrets: {
      'encryptionKey': 'staging-32-char-encryption-key',
      'jwtSecret': 'staging-jwt-secret-key-minimum-32-chars',
      'digiLockerSecret': 'staging-digilocker-secret',
      'razorpaySecret': 'staging-razorpay-secret',
    },
  );

  /// Production environment configuration
  static const EnvironmentConfig production = EnvironmentConfig(
    name: 'production',
    apiBaseUrl: 'https://api.agrichain.com',
    databaseName: 'agrichain_prod.db',
    enableLogging: false,
    enableDebugMode: false,
    enableMockData: false,
    skipKycInDev: false,
    sessionTimeout: Duration(hours: 24),
    maxLoginAttempts: 3,
    apiKeys: {
      'digiLocker': 'PROD_DIGILOCKER_KEY',
      'razorpay': 'PROD_RAZORPAY_KEY',
      'firebase': 'PROD_FIREBASE_KEY',
    },
    secrets: {
      'encryptionKey': 'PROD_32_CHAR_ENCRYPTION_KEY',
      'jwtSecret': 'PROD_JWT_SECRET_KEY_MINIMUM_32_CHARS',
      'digiLockerSecret': 'PROD_DIGILOCKER_SECRET',
      'razorpaySecret': 'PROD_RAZORPAY_SECRET',
    },
  );

  /// Get current environment configuration
  static EnvironmentConfig get current {
    const environment = String.fromEnvironment('ENV', defaultValue: 'development');
    
    switch (environment.toLowerCase()) {
      case 'production':
      case 'prod':
        return production;
      case 'staging':
      case 'stage':
        return staging;
      case 'development':
      case 'dev':
      default:
        return development;
    }
  }

  /// Get API key for a specific service
  String? getApiKey(String service) {
    return apiKeys[service];
  }

  /// Get secret for a specific service
  String? getSecret(String service) {
    // In production, these should come from secure environment variables
    if (name == 'production') {
      return String.fromEnvironment('${service.toUpperCase()}_SECRET');
    }
    return secrets[service];
  }

  /// Check if feature is enabled in current environment
  bool isFeatureEnabled(String feature) {
    switch (feature.toLowerCase()) {
      case 'logging':
        return enableLogging;
      case 'debug':
        return enableDebugMode;
      case 'mockdata':
        return enableMockData;
      case 'skipkyc':
        return skipKycInDev;
      default:
        return false;
    }
  }

  /// Get database configuration
  Map<String, dynamic> getDatabaseConfig() {
    return {
      'name': databaseName,
      'version': 1,
      'timeout': const Duration(seconds: 30),
      'maxConnections': name == 'production' ? 20 : 10,
      'enableWAL': name == 'production',
      'enableForeignKeys': true,
    };
  }

  /// Get security configuration
  Map<String, dynamic> getSecurityConfig() {
    return {
      'sessionTimeout': sessionTimeout,
      'maxLoginAttempts': maxLoginAttempts,
      'lockoutDuration': const Duration(minutes: 30),
      'passwordMinLength': 8,
      'passwordMaxLength': 128,
      'enableBiometric': name != 'development',
      'enableTwoFactor': name == 'production',
      'csrfTokenExpiry': const Duration(hours: 1),
      'rateLimitPerMinute': name == 'production' ? 60 : 100,
    };
  }

  /// Get API configuration
  Map<String, dynamic> getApiConfig() {
    return {
      'baseUrl': apiBaseUrl,
      'timeout': const Duration(seconds: 30),
      'retryAttempts': 3,
      'retryDelay': const Duration(seconds: 2),
      'enableCaching': name == 'production',
      'cacheExpiry': const Duration(hours: 1),
    };
  }

  /// Validate environment configuration
  bool validate() {
    try {
      // Check required fields
      if (name.isEmpty || apiBaseUrl.isEmpty || databaseName.isEmpty) {
        return false;
      }

      // Validate secrets in production
      if (name == 'production') {
        final requiredSecrets = ['encryptionKey', 'jwtSecret'];
        for (final secret in requiredSecrets) {
          final value = getSecret(secret);
          if (value == null || value.isEmpty || value.startsWith('PROD_')) {
            print('Missing or invalid secret: $secret');
            return false;
          }
        }
      }

      // Validate encryption key length
      final encryptionKey = getSecret('encryptionKey');
      if (encryptionKey != null && encryptionKey.length != 32) {
        print('Encryption key must be exactly 32 characters');
        return false;
      }

      // Validate JWT secret length
      final jwtSecret = getSecret('jwtSecret');
      if (jwtSecret != null && jwtSecret.length < 32) {
        print('JWT secret must be at least 32 characters');
        return false;
      }

      return true;
    } catch (e) {
      print('Environment validation error: $e');
      return false;
    }
  }

  /// Get configuration summary
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'apiBaseUrl': apiBaseUrl,
      'databaseName': databaseName,
      'enableLogging': enableLogging,
      'enableDebugMode': enableDebugMode,
      'enableMockData': enableMockData,
      'skipKycInDev': skipKycInDev,
      'sessionTimeoutHours': sessionTimeout.inHours,
      'maxLoginAttempts': maxLoginAttempts,
      'apiKeysCount': apiKeys.length,
      'secretsCount': secrets.length,
    };
  }

  @override
  String toString() {
    return 'EnvironmentConfig(name: $name, apiBaseUrl: $apiBaseUrl)';
  }
}