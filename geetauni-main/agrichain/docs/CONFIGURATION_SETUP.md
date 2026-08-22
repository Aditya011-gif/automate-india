# AgriChain Configuration Setup Guide

## Table of Contents
1. [Overview](#overview)
2. [Environment Configuration](#environment-configuration)
3. [Database Configuration](#database-configuration)
4. [Security Configuration](#security-configuration)
5. [API Configuration](#api-configuration)
6. [KYC Configuration](#kyc-configuration)
7. [Deployment Configuration](#deployment-configuration)
8. [Troubleshooting](#troubleshooting)

## Overview

This guide provides detailed instructions for configuring the AgriChain application across different environments. The configuration system is designed to be flexible, secure, and environment-aware.

### Configuration Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    Configuration Manager                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   App Config    │  │ Environment     │  │ Database Init   │ │
│  │                 │  │ Config          │  │                 │ │
│  │ - Database      │  │                 │  │ - Setup         │ │
│  │ - Security      │  │ - Development   │  │ - Validation    │ │
│  │ - API           │  │ - Staging       │  │ - Maintenance   │ │
│  │ - KYC           │  │ - Production    │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Environment Configuration

### Setting Up Environments

The application supports three environments: Development, Staging, and Production.

#### Development Environment
```dart
// lib/config/environment_config.dart
static final development = EnvironmentConfig(
  name: 'development',
  apiBaseUrl: 'http://localhost:3000',
  databaseName: 'agrichain_dev.db',
  enableLogging: true,
  enableDebugMode: true,
  enableMockData: true,
  skipKycVerification: true,
  sessionTimeoutMinutes: 60,
  maxLoginAttempts: 10,
  // API Keys (use test keys)
  digiLockerApiKey: 'test_digi_locker_key',
  digiLockerClientId: 'test_client_id',
  blockchainApiKey: 'test_blockchain_key',
  paymentGatewayKey: 'test_payment_key',
);
```

#### Staging Environment
```dart
static final staging = EnvironmentConfig(
  name: 'staging',
  apiBaseUrl: 'https://staging-api.agrichain.com',
  databaseName: 'agrichain_staging.db',
  enableLogging: true,
  enableDebugMode: false,
  enableMockData: false,
  skipKycVerification: false,
  sessionTimeoutMinutes: 30,
  maxLoginAttempts: 5,
  // API Keys (use staging keys)
  digiLockerApiKey: 'staging_digi_locker_key',
  digiLockerClientId: 'staging_client_id',
  blockchainApiKey: 'staging_blockchain_key',
  paymentGatewayKey: 'staging_payment_key',
);
```

#### Production Environment
```dart
static final production = EnvironmentConfig(
  name: 'production',
  apiBaseUrl: 'https://api.agrichain.com',
  databaseName: 'agrichain.db',
  enableLogging: false,
  enableDebugMode: false,
  enableMockData: false,
  skipKycVerification: false,
  sessionTimeoutMinutes: 15,
  maxLoginAttempts: 3,
  // API Keys (use production keys - should be loaded from secure storage)
  digiLockerApiKey: Platform.environment['DIGI_LOCKER_API_KEY'] ?? '',
  digiLockerClientId: Platform.environment['DIGI_LOCKER_CLIENT_ID'] ?? '',
  blockchainApiKey: Platform.environment['BLOCKCHAIN_API_KEY'] ?? '',
  paymentGatewayKey: Platform.environment['PAYMENT_GATEWAY_KEY'] ?? '',
);
```

### Environment Selection

The environment is automatically selected based on build configuration:

```dart
// lib/config/config_manager.dart
EnvironmentConfig get environment {
  if (kDebugMode) {
    return EnvironmentConfig.development;
  } else if (kProfileMode) {
    return EnvironmentConfig.staging;
  } else {
    return EnvironmentConfig.production;
  }
}
```

### Custom Environment Variables

For production deployments, use environment variables:

```bash
# .env file (not committed to version control)
DIGI_LOCKER_API_KEY=your_production_digi_locker_key
DIGI_LOCKER_CLIENT_ID=your_production_client_id
BLOCKCHAIN_API_KEY=your_production_blockchain_key
PAYMENT_GATEWAY_KEY=your_production_payment_key
DATABASE_ENCRYPTION_KEY=your_32_byte_base64_encoded_key
JWT_SECRET=your_jwt_secret_key
```

## Database Configuration

### Basic Database Settings

```dart
// lib/config/app_config.dart
static const Map<String, dynamic> _databaseConfig = {
  'name': 'agrichain.db',
  'version': 1,
  'timeout': 30000, // 30 seconds
  'maxConnections': 10,
  'enableWAL': true, // Write-Ahead Logging
  'enableForeignKeys': true,
  'pageSize': 4096,
  'cacheSize': 2000,
};
```

### Database Path Configuration

The database path is automatically determined based on the platform:

```dart
// lib/config/app_config.dart
static Future<String> getDatabasePath(String databaseName) async {
  if (Platform.isAndroid || Platform.isIOS) {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, databaseName);
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final directory = await getApplicationSupportDirectory();
    return path.join(directory.path, 'AgriChain', databaseName);
  } else {
    throw UnsupportedError('Platform not supported');
  }
}
```

### Database Initialization

```dart
// Initialize database with configuration
final databaseInitializer = DatabaseInitializer();
final success = await databaseInitializer.initialize();

if (!success) {
  throw Exception('Failed to initialize database');
}

// Get database statistics
final stats = await databaseInitializer.getDatabaseStats();
print('Database initialized: ${stats['database_name']}');
print('Total users: ${stats['users_count']}');
```

### Database Maintenance Configuration

```dart
static const Map<String, dynamic> _maintenanceConfig = {
  'autoVacuum': true,
  'vacuumInterval': Duration(days: 7),
  'analyzeInterval': Duration(days: 1),
  'sessionCleanupInterval': Duration(hours: 6),
  'logRetentionPeriod': Duration(days: 30),
};
```

## Security Configuration

### Encryption Configuration

```dart
// lib/config/app_config.dart
static const Map<String, dynamic> _securityConfig = {
  'encryptionKey': 'base64_encoded_32_byte_key', // Generate with: base64.encode(List.generate(32, (i) => Random().nextInt(256)))
  'jwtSecret': 'your_jwt_secret_key',
  'sessionTimeout': Duration(minutes: 30),
  
  'passwordPolicy': {
    'minLength': 8,
    'requireUppercase': true,
    'requireLowercase': true,
    'requireNumbers': true,
    'requireSpecialChars': true,
    'maxAge': Duration(days: 90),
  },
  
  'accountLockout': {
    'maxAttempts': 5,
    'lockoutDuration': Duration(minutes: 15),
    'resetAfter': Duration(hours: 24),
  },
  
  'rateLimit': {
    'maxRequestsPerMinute': 60,
    'maxLoginAttemptsPerMinute': 5,
    'maxApiCallsPerHour': 1000,
  },
  
  'csrf': {
    'tokenValidityMinutes': 30,
    'enableForAllRequests': true,
  },
  
  'securityHeaders': {
    'enableHSTS': true,
    'enableCSP': true,
    'enableXFrameOptions': true,
    'enableXContentTypeOptions': true,
  },
};
```

### Generating Encryption Keys

Use this script to generate secure encryption keys:

```dart
import 'dart:convert';
import 'dart:math';

String generateEncryptionKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (i) => random.nextInt(256));
  return base64.encode(bytes);
}

String generateJWTSecret() {
  final random = Random.secure();
  final bytes = List<int>.generate(64, (i) => random.nextInt(256));
  return base64.encode(bytes);
}

void main() {
  print('Encryption Key: ${generateEncryptionKey()}');
  print('JWT Secret: ${generateJWTSecret()}');
}
```

### Security Validation

```dart
// Validate security configuration
final configManager = ConfigManager();
final isValid = configManager.validateConfiguration();

if (!isValid) {
  throw Exception('Invalid security configuration');
}

// Check specific security settings
final securityConfig = configManager.getSecurityConfig();
final encryptionKey = securityConfig['encryptionKey'];

if (encryptionKey == null || encryptionKey.isEmpty) {
  throw Exception('Encryption key not configured');
}
```

## API Configuration

### API Endpoints Configuration

```dart
// lib/config/app_config.dart
static const Map<String, dynamic> _apiConfig = {
  'baseUrl': 'https://api.agrichain.com',
  'timeout': Duration(seconds: 30),
  'retryAttempts': 3,
  'retryDelay': Duration(seconds: 2),
  
  'endpoints': {
    'auth': '/api/v1/auth',
    'users': '/api/v1/users',
    'kyc': '/api/v1/kyc',
    'marketplace': '/api/v1/marketplace',
    'blockchain': '/api/v1/blockchain',
    'payments': '/api/v1/payments',
  },
  
  'headers': {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'AgriChain-Mobile/1.0',
  },
};
```

### HTTP Client Configuration

```dart
// Configure HTTP client with timeouts and retries
final httpClient = HttpClient();
httpClient.connectionTimeout = Duration(seconds: 30);
httpClient.idleTimeout = Duration(seconds: 60);

// Add authentication headers
final headers = {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
};
```

## KYC Configuration

### DigiLocker Integration

```dart
// lib/config/app_config.dart
static const Map<String, dynamic> _kycConfig = {
  'digiLocker': {
    'apiUrl': 'https://api.digitallocker.gov.in',
    'clientId': 'your_client_id',
    'clientSecret': 'your_client_secret',
    'redirectUri': 'https://yourapp.com/callback',
    'scope': 'aadhaar pan driving_license',
  },
  
  'verification': {
    'enableAadhaarVerification': true,
    'enablePanVerification': true,
    'enableBankVerification': true,
    'autoApproveInDev': true,
  },
  
  'documents': {
    'maxFileSize': 5 * 1024 * 1024, // 5MB
    'allowedFormats': ['pdf', 'jpg', 'jpeg', 'png'],
    'compressionQuality': 0.8,
  },
};
```

### KYC Service Configuration

```dart
// Initialize KYC service
final kycService = KycService();
await kycService.initializeDigiLocker();

// Configure verification settings
final kycConfig = configManager.getKycConfig();
final enableAadhaar = kycConfig['verification']['enableAadhaarVerification'];
final enablePan = kycConfig['verification']['enablePanVerification'];
```

## Deployment Configuration

### Build Configuration

#### Android (android/app/build.gradle)
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.agrichain.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    
    buildTypes {
        debug {
            debuggable true
            minifyEnabled false
            buildConfigField "String", "API_BASE_URL", '"http://localhost:3000"'
            buildConfigField "String", "ENVIRONMENT", '"development"'
        }
        
        staging {
            debuggable false
            minifyEnabled true
            buildConfigField "String", "API_BASE_URL", '"https://staging-api.agrichain.com"'
            buildConfigField "String", "ENVIRONMENT", '"staging"'
        }
        
        release {
            debuggable false
            minifyEnabled true
            shrinkResources true
            buildConfigField "String", "API_BASE_URL", '"https://api.agrichain.com"'
            buildConfigField "String", "ENVIRONMENT", '"production"'
            
            signingConfig signingConfigs.release
        }
    }
}
```

#### iOS (ios/Runner/Info.plist)
```xml
<dict>
    <key>CFBundleName</key>
    <string>AgriChain</string>
    <key>CFBundleIdentifier</key>
    <string>com.agrichain.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    
    <!-- Environment-specific configurations -->
    <key>API_BASE_URL</key>
    <string>$(API_BASE_URL)</string>
    <key>ENVIRONMENT</key>
    <string>$(ENVIRONMENT)</string>
</dict>
```

### Environment-Specific Builds

#### Development Build
```bash
# Android
flutter build apk --debug --flavor development

# iOS
flutter build ios --debug --flavor development
```

#### Staging Build
```bash
# Android
flutter build apk --release --flavor staging

# iOS
flutter build ios --release --flavor staging
```

#### Production Build
```bash
# Android
flutter build apk --release --flavor production

# iOS
flutter build ios --release --flavor production
```

### Docker Configuration (for backend services)

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

# Environment variables
ENV NODE_ENV=production
ENV API_PORT=3000
ENV DATABASE_URL=postgresql://user:pass@localhost:5432/agrichain
ENV JWT_SECRET=your_jwt_secret
ENV ENCRYPTION_KEY=your_encryption_key

EXPOSE 3000

CMD ["npm", "start"]
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/agrichain
      - JWT_SECRET=${JWT_SECRET}
      - ENCRYPTION_KEY=${ENCRYPTION_KEY}
    depends_on:
      - db
      - redis

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=agrichain
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

## Troubleshooting

### Common Configuration Issues

#### 1. Database Connection Errors
```dart
// Check database path and permissions
final databasePath = await AppConfig.getDatabasePath('agrichain.db');
print('Database path: $databasePath');

// Verify database file exists and is accessible
final file = File(databasePath);
if (!await file.exists()) {
  print('Database file does not exist');
}
```

#### 2. Encryption Key Issues
```dart
// Validate encryption key format
final securityConfig = configManager.getSecurityConfig();
final encryptionKey = securityConfig['encryptionKey'];

try {
  final keyBytes = base64.decode(encryptionKey);
  if (keyBytes.length != 32) {
    throw Exception('Encryption key must be 32 bytes');
  }
} catch (e) {
  print('Invalid encryption key format: $e');
}
```

#### 3. API Configuration Issues
```dart
// Test API connectivity
final apiConfig = configManager.getApiConfig();
final baseUrl = apiConfig['baseUrl'];

try {
  final response = await http.get(Uri.parse('$baseUrl/health'));
  if (response.statusCode == 200) {
    print('API is accessible');
  } else {
    print('API returned status: ${response.statusCode}');
  }
} catch (e) {
  print('API connection error: $e');
}
```

#### 4. Environment Detection Issues
```dart
// Check current environment
final configManager = ConfigManager();
final environment = configManager.environment;
print('Current environment: ${environment.name}');
print('Debug mode: ${environment.enableDebugMode}');
print('API URL: ${environment.apiBaseUrl}');
```

### Configuration Validation

```dart
// Comprehensive configuration validation
Future<bool> validateConfiguration() async {
  final configManager = ConfigManager();
  
  try {
    // Initialize configuration
    await configManager.initialize();
    
    // Validate all configurations
    final isValid = configManager.validateConfiguration();
    
    if (!isValid) {
      print('Configuration validation failed');
      return false;
    }
    
    // Test database connection
    final databaseInitializer = DatabaseInitializer();
    final dbSuccess = await databaseInitializer.initialize();
    
    if (!dbSuccess) {
      print('Database initialization failed');
      return false;
    }
    
    // Test security service
    final securityService = SecurityService();
    final testData = 'test';
    final encrypted = await securityService.encryptData(testData);
    final decrypted = await securityService.decryptData(encrypted);
    
    if (decrypted != testData) {
      print('Security service validation failed');
      return false;
    }
    
    print('All configurations validated successfully');
    return true;
    
  } catch (e) {
    print('Configuration validation error: $e');
    return false;
  }
}
```

### Debug Information

```dart
// Get comprehensive debug information
Map<String, dynamic> getDebugInfo() {
  final configManager = ConfigManager();
  
  return {
    'environment': configManager.environment.name,
    'database_config': configManager.getDatabaseConfig(),
    'api_config': configManager.getApiConfig(),
    'security_config': {
      'encryption_key_configured': configManager.getSecurityConfig()['encryptionKey'] != null,
      'jwt_secret_configured': configManager.getSecurityConfig()['jwtSecret'] != null,
      'password_policy': configManager.getSecurityConfig()['passwordPolicy'],
    },
    'kyc_config': configManager.getKycConfig(),
    'feature_flags': configManager.getFeatureFlags(),
    'timestamp': DateTime.now().toIso8601String(),
  };
}
```

### Performance Monitoring

```dart
// Monitor configuration loading performance
final stopwatch = Stopwatch()..start();

final configManager = ConfigManager();
await configManager.initialize();

stopwatch.stop();
print('Configuration loaded in ${stopwatch.elapsedMilliseconds}ms');

// Monitor database initialization performance
final dbStopwatch = Stopwatch()..start();

final databaseInitializer = DatabaseInitializer();
await databaseInitializer.initialize();

dbStopwatch.stop();
print('Database initialized in ${dbStopwatch.elapsedMilliseconds}ms');
```

---

This configuration guide provides comprehensive instructions for setting up the AgriChain application across different environments. For additional support, refer to the API Integration Guide or contact the development team.