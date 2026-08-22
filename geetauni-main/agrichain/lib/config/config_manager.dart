import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';
import 'environment_config.dart';
import 'digilocker_sandbox_config.dart';

/// Central configuration manager for the application
class ConfigManager {
  static final ConfigManager _instance = ConfigManager._internal();
  factory ConfigManager() => _instance;
  ConfigManager._internal();

  EnvironmentConfig? _currentEnvironment;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// Get current environment configuration
  EnvironmentConfig get environment {
    if (_currentEnvironment == null) {
      throw StateError('ConfigManager not initialized. Call initialize() first.');
    }
    return _currentEnvironment!;
  }

  /// Check if configuration manager is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize configuration manager
  Future<bool> initialize() async {
    try {
      // Load shared preferences
      _prefs = await SharedPreferences.getInstance();

      // Load environment configuration
      _currentEnvironment = EnvironmentConfig.current;

      // Validate configuration
      if (!AppConfig.validateConfig()) {
        debugPrint('App configuration validation failed');
        return false;
      }

      if (!_currentEnvironment!.validate()) {
        debugPrint('Environment configuration validation failed');
        return false;
      }

      // Log configuration summary in debug mode
      if (kDebugMode) {
        debugPrint('Configuration initialized successfully');
        debugPrint('Environment: ${_currentEnvironment!.name}');
        debugPrint('API Base URL: ${_currentEnvironment!.apiBaseUrl}');
        debugPrint('Database: ${_currentEnvironment!.databaseName}');
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Configuration initialization failed: $e');
      return false;
    }
  }

  /// Get database configuration
  Map<String, dynamic> getDatabaseConfig() {
    _ensureInitialized();
    return {
      ...environment.getDatabaseConfig(),
      'path': AppConfig.getDatabasePath(),
      'enableWAL': environment.name == 'production',
      'busyTimeout': AppConfig.databaseTimeout.inMilliseconds,
    };
  }

  /// Get security configuration
  Map<String, dynamic> getSecurityConfig() {
    _ensureInitialized();
    return {
      ...environment.getSecurityConfig(),
      'encryptionKey': environment.getSecret('encryptionKey'),
      'jwtSecret': environment.getSecret('jwtSecret'),
      'csrfTokenHeader': AppConfig.csrfTokenHeader,
      'securityHeaders': AppConfig.securityHeaders,
    };
  }

  /// Get API configuration
  Map<String, dynamic> getApiConfig() {
    _ensureInitialized();
    return {
      ...environment.getApiConfig(),
      'digiLockerBaseUrl': AppConfig.digiLockerBaseUrl,
      'digiLockerClientId': environment.getApiKey('digiLocker'),
      'digiLockerClientSecret': environment.getSecret('digiLockerSecret'),
      'digiLockerRedirectUri': AppConfig.digiLockerRedirectUri,
    };
  }

  /// Get KYC configuration
  Map<String, dynamic> getKycConfig() {
    _ensureInitialized();
    
    // Use sandbox configuration for development/hackathon
    final useSandbox = environment.name == 'development';
    
    return {
      'enabled': AppConfig.enableKycVerification,
      'skipInDev': environment.skipKycInDev,
      'maxAttempts': AppConfig.maxKycAttempts,
      'cooldownPeriod': AppConfig.kycCooldownPeriod,
      'dataExpiry': AppConfig.kycDataExpiry,
      'supportedDocuments': AppConfig.supportedKycDocuments,
      'digiLockerTimeout': AppConfig.digiLockerTimeout,
      
      // DigiLocker configuration
      'digiLocker': {
        'useSandbox': useSandbox,
        'baseUrl': useSandbox ? DigiLockerSandboxConfig.sandboxBaseUrl : AppConfig.digiLockerBaseUrl,
        'oauthUrl': useSandbox ? DigiLockerSandboxConfig.sandboxOAuthUrl : AppConfig.digiLockerOAuthUrl,
        'tokenUrl': useSandbox ? DigiLockerSandboxConfig.sandboxTokenUrl : AppConfig.digiLockerTokenUrl,
        'apiUrl': useSandbox ? DigiLockerSandboxConfig.sandboxApiUrl : AppConfig.digiLockerApiUrl,
        'clientId': useSandbox ? DigiLockerSandboxConfig.sandboxClientId : environment.getApiKey('digiLocker'),
        'clientSecret': useSandbox ? DigiLockerSandboxConfig.sandboxClientSecret : environment.getSecret('digiLockerSecret'),
        'redirectUri': useSandbox ? DigiLockerSandboxConfig.sandboxRedirectUri : AppConfig.digiLockerRedirectUri,
        'scopes': DigiLockerSandboxConfig.requiredScopes,
        'enableMockResponses': useSandbox && DigiLockerSandboxConfig.sandboxConfig['enableMockResponses'],
        'testDocumentIds': useSandbox ? DigiLockerSandboxConfig.testDocumentIds : null,
      },
    };
  }

  /// Get payment configuration
  Map<String, dynamic> getPaymentConfig() {
    _ensureInitialized();
    
    // Use mock payment service for development and demo
    if (environment.name == 'development' || AppConfig.enableMockData) {
      return {
        'useMockPayment': true,
        'mockGatewayName': 'AgriChain Mock Payment Gateway',
        'mockMerchantId': 'MOCK_MERCHANT_AGRICHAIN_001',
        'mockApiKey': 'MOCK_API_KEY_12345',
        'supportedMethods': ['UPI', 'Credit Card', 'Debit Card', 'Net Banking', 'Wallet', 'Cash on Delivery'],
        'timeout': AppConfig.paymentTimeout,
        'enableTestMode': true,
        'simulateDelay': true,
        'successRate': 0.95, // 95% success rate for demo
        // Fallback to real Razorpay if needed
        'razorpayKeyId': environment.getApiKey('razorpay'),
        'razorpayKeySecret': environment.getSecret('razorpaySecret'),
      };
    }
    
    // Production configuration
    return {
      'useMockPayment': false,
      'razorpayKeyId': environment.getApiKey('razorpay'),
      'razorpayKeySecret': environment.getSecret('razorpaySecret'),
      'timeout': AppConfig.paymentTimeout,
      'enableTestMode': environment.name != 'production',
    };
  }

  /// Get file upload configuration
  Map<String, dynamic> getFileUploadConfig() {
    _ensureInitialized();
    return {
      'maxFileSize': AppConfig.maxFileSize,
      'allowedTypes': AppConfig.allowedFileTypes,
      'allowedExtensions': AppConfig.allowedFileExtensions,
    };
  }

  /// Get logging configuration
  Map<String, dynamic> getLoggingConfig() {
    _ensureInitialized();
    return {
      'enabled': environment.enableLogging,
      'level': environment.name == 'production' ? 'warning' : 'debug',
      'maxFileSize': AppConfig.maxLogFileSize,
      'maxFiles': AppConfig.maxLogFiles,
      'retentionPeriod': AppConfig.logRetentionPeriod,
    };
  }

  /// Get feature flags
  Map<String, bool> getFeatureFlags() {
    _ensureInitialized();
    return {
      'kycVerification': AppConfig.enableKycVerification && !environment.skipKycInDev,
      'biometricAuth': AppConfig.enableBiometricAuth,
      'offlineMode': AppConfig.enableOfflineMode,
      'analytics': AppConfig.enableAnalytics,
      'crashReporting': AppConfig.enableCrashReporting,
      'debugMode': environment.enableDebugMode,
      'mockData': environment.enableMockData,
      'pushNotifications': AppConfig.enablePushNotifications,
    };
  }

  /// Check if a feature is enabled
  bool isFeatureEnabled(String feature) {
    final flags = getFeatureFlags();
    return flags[feature] ?? false;
  }

  /// Get configuration value by key
  T? getConfigValue<T>(String key, {T? defaultValue}) {
    _ensureInitialized();
    
    try {
      switch (key.toLowerCase()) {
        case 'environment':
          return environment.name as T?;
        case 'apibaseurl':
          return environment.apiBaseUrl as T?;
        case 'databasename':
          return environment.databaseName as T?;
        case 'sessiontimeout':
          return environment.sessionTimeout.inMinutes as T?;
        case 'maxloginattempts':
          return environment.maxLoginAttempts as T?;
        case 'enablelogging':
          return environment.enableLogging as T?;
        case 'enabledebugmode':
          return environment.enableDebugMode as T?;
        default:
          return defaultValue;
      }
    } catch (e) {
      debugPrint('Error getting config value for key: $key, error: $e');
      return defaultValue;
    }
  }

  /// Save user preference
  Future<bool> saveUserPreference(String key, dynamic value) async {
    _ensureInitialized();
    
    try {
      if (_prefs == null) return false;

      if (value is String) {
        return await _prefs!.setString(key, value);
      } else if (value is int) {
        return await _prefs!.setInt(key, value);
      } else if (value is double) {
        return await _prefs!.setDouble(key, value);
      } else if (value is bool) {
        return await _prefs!.setBool(key, value);
      } else if (value is List<String>) {
        return await _prefs!.setStringList(key, value);
      }
      
      return false;
    } catch (e) {
      debugPrint('Error saving user preference: $e');
      return false;
    }
  }

  /// Get user preference
  T? getUserPreference<T>(String key, {T? defaultValue}) {
    _ensureInitialized();
    
    try {
      if (_prefs == null) return defaultValue;

      final value = _prefs!.get(key);
      if (value is T) {
        return value;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('Error getting user preference: $e');
      return defaultValue;
    }
  }

  /// Clear user preferences
  Future<bool> clearUserPreferences() async {
    _ensureInitialized();
    
    try {
      if (_prefs == null) return false;
      return await _prefs!.clear();
    } catch (e) {
      debugPrint('Error clearing user preferences: $e');
      return false;
    }
  }

  /// Get platform-specific configuration
  Map<String, dynamic> getPlatformConfig() {
    return {
      'platform': Platform.operatingSystem,
      'isAndroid': Platform.isAndroid,
      'isIOS': Platform.isIOS,
      'isWindows': Platform.isWindows,
      'isMacOS': Platform.isMacOS,
      'isLinux': Platform.isLinux,
      'isWeb': kIsWeb,
      'isDebugMode': kDebugMode,
      'isProfileMode': kProfileMode,
      'isReleaseMode': kReleaseMode,
    };
  }

  /// Export configuration for debugging
  Map<String, dynamic> exportConfig() {
    _ensureInitialized();
    
    return {
      'environment': environment.toMap(),
      'appConfig': AppConfig.getConfigSummary(),
      'platform': getPlatformConfig(),
      'featureFlags': getFeatureFlags(),
      'isInitialized': _isInitialized,
    };
  }

  /// Reload configuration
  Future<bool> reload() async {
    _isInitialized = false;
    _currentEnvironment = null;
    return await initialize();
  }

  /// Validate all configurations
  bool validateAllConfigs() {
    try {
      _ensureInitialized();
      
      // Validate app config
      if (!AppConfig.validateConfig()) {
        debugPrint('App configuration validation failed');
        return false;
      }

      // Validate environment config
      if (!environment.validate()) {
        debugPrint('Environment configuration validation failed');
        return false;
      }

      // Validate required secrets in production
      if (environment.name == 'production') {
        final requiredSecrets = ['encryptionKey', 'jwtSecret', 'digiLockerSecret'];
        for (final secret in requiredSecrets) {
          final value = environment.getSecret(secret);
          if (value == null || value.isEmpty) {
            debugPrint('Missing required secret in production: $secret');
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('Configuration validation error: $e');
      return false;
    }
  }

  /// Ensure configuration manager is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('ConfigManager not initialized. Call initialize() first.');
    }
  }

  /// Validate current configuration
  bool validateConfiguration() {
    try {
      _ensureInitialized();
      
      // Validate app configuration
      if (!AppConfig.validateConfig()) {
        if (kDebugMode) {
          print('App configuration validation failed');
        }
        return false;
      }

      // Validate environment configuration
      if (!_currentEnvironment!.validate()) {
        if (kDebugMode) {
          print('Environment configuration validation failed');
        }
        return false;
      }

      // Additional runtime validation
      if (AppConfig.infuraProjectId.isEmpty || 
          AppConfig.infuraProjectId == 'YOUR_INFURA_PROJECT_ID') {
        if (kDebugMode) {
          print('Infura configuration not properly set');
        }
        return false;
      }

      // Validate database configuration
      if (AppConfig.databaseName.isEmpty) {
        if (kDebugMode) {
          print('Database configuration missing');
        }
        return false;
      }

      // Validate security configuration
      if (AppConfig.jwtSecret.isEmpty || AppConfig.jwtSecret == 'your-super-secret-jwt-key') {
        if (kDebugMode) {
          print('JWT secret not properly configured');
        }
        return false;
      }

      if (kDebugMode) {
        print('Configuration validation passed');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Configuration validation error: $e');
      }
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _prefs = null;
    _currentEnvironment = null;
    _isInitialized = false;
  }
}