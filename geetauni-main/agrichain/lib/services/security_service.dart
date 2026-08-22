import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import '../config/config_manager.dart';
import 'database_service.dart';

class PasswordValidationResult {
  final bool isValid;
  final String message;

  PasswordValidationResult({required this.isValid, required this.message});
}

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal() {
    _initializeEncryption();
  }

  final DatabaseService _databaseService = DatabaseService();
  final ConfigManager _configManager = ConfigManager();

  // Encryption
  late final encrypt.Encrypter _encrypter;
  late final encrypt.IV _iv;

  // Rate limiting
  final Map<String, List<DateTime>> _rateLimitMap = {};

  // CSRF tokens
  final Map<String, DateTime> _csrfTokens = {};

  void _initializeEncryption() {
    try {
      // Get encryption key from configuration
      final securityConfig = _configManager.getSecurityConfig();
      final encryptionKeyString = securityConfig['encryptionKey'] as String?;

      encrypt.Key key;
      if (encryptionKeyString != null && encryptionKeyString.isNotEmpty) {
        // Use configured key
        final keyBytes = base64.decode(encryptionKeyString);
        key = encrypt.Key(Uint8List.fromList(keyBytes));
      } else {
        // Fallback to random key (not recommended for production)
        key = encrypt.Key.fromSecureRandom(32);
        debugPrint(
          'Warning: Using random encryption key. Configure a proper key for production.',
        );
      }

      _encrypter = encrypt.Encrypter(encrypt.AES(key));
      _iv = encrypt.IV.fromSecureRandom(16);
    } catch (e) {
      debugPrint('Encryption initialization error: $e');
      // Fallback to random key
      final key = encrypt.Key.fromSecureRandom(32);
      _encrypter = encrypt.Encrypter(encrypt.AES(key));
      _iv = encrypt.IV.fromSecureRandom(16);
    }
  }

  /// Hash password with salt using bcrypt-like approach
  Future<String> hashPassword(String password) async {
    try {
      // Generate salt
      final salt = _generateSalt();

      // Combine password and salt
      final combined = password + salt;

      // Hash multiple times for security
      var hash = sha256.convert(utf8.encode(combined)).toString();
      for (int i = 0; i < 10000; i++) {
        hash = sha256.convert(utf8.encode(hash + salt)).toString();
      }

      // Return salt + hash
      return '$salt:$hash';
    } catch (e) {
      debugPrint('Password hashing error: $e');
      throw Exception('Failed to hash password');
    }
  }

  /// Verify password against hash
  Future<bool> verifyPassword(String password, String hashedPassword) async {
    try {
      final parts = hashedPassword.split(':');
      if (parts.length != 2) return false;

      final salt = parts[0];
      final hash = parts[1];

      // Hash the provided password with the same salt
      final combined = password + salt;
      var testHash = sha256.convert(utf8.encode(combined)).toString();
      for (int i = 0; i < 10000; i++) {
        testHash = sha256.convert(utf8.encode(testHash + salt)).toString();
      }

      return testHash == hash;
    } catch (e) {
      debugPrint('Password verification error: $e');
      return false;
    }
  }

  /// Validate password strength
  PasswordValidationResult validatePassword(String password) {
    final securityConfig = _configManager.getSecurityConfig();
    final passwordPolicy =
        securityConfig['passwordPolicy'] as Map<String, dynamic>? ?? {};
    final minLength = passwordPolicy['minLength'] as int? ?? 8;

    if (password.length < minLength) {
      return PasswordValidationResult(
        isValid: false,
        message: 'Password must be at least $minLength characters long',
      );
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return PasswordValidationResult(
        isValid: false,
        message: 'Password must contain at least one uppercase letter',
      );
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return PasswordValidationResult(
        isValid: false,
        message: 'Password must contain at least one lowercase letter',
      );
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return PasswordValidationResult(
        isValid: false,
        message: 'Password must contain at least one number',
      );
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return PasswordValidationResult(
        isValid: false,
        message: 'Password must contain at least one special character',
      );
    }

    // Check for common weak passwords
    final commonPasswords = [
      'password',
      '123456',
      '123456789',
      'qwerty',
      'abc123',
      'password123',
      'admin',
      'letmein',
      'welcome',
      'monkey',
    ];

    if (commonPasswords.contains(password.toLowerCase())) {
      return PasswordValidationResult(
        isValid: false,
        message: 'Password is too common. Please choose a stronger password',
      );
    }

    return PasswordValidationResult(
      isValid: true,
      message: 'Password is strong',
    );
  }

  /// Encrypt sensitive data
  Future<String> encryptData(String data) async {
    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint('Encryption error: $e');
      throw Exception('Failed to encrypt data');
    }
  }

  /// Decrypt sensitive data
  Future<String> decryptData(String encryptedData) async {
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      debugPrint('Decryption error: $e');
      throw Exception('Failed to decrypt data');
    }
  }

  /// Sanitize user input to prevent XSS and injection attacks
  String sanitizeInput(String input) {
    return input
        .replaceAll(
          RegExp(
            r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('&', '&amp;')
        .trim();
  }

  /// Validate and sanitize email
  String? validateAndSanitizeEmail(String email) {
    final sanitized = email.toLowerCase().trim();

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(sanitized)) {
      return null;
    }

    return sanitized;
  }

  /// Validate and sanitize phone number
  String? validateAndSanitizePhone(String phone) {
    final sanitized = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(sanitized)) {
      return null;
    }

    return sanitized;
  }

  /// Rate limiting check
  bool checkRateLimit(String identifier, {int? maxRequests}) {
    final securityConfig = _configManager.getSecurityConfig();
    final rateLimitConfig =
        securityConfig['rateLimit'] as Map<String, dynamic>? ?? {};
    final defaultMaxRequests =
        rateLimitConfig['maxRequestsPerMinute'] as int? ?? 60;
    final effectiveMaxRequests = maxRequests ?? defaultMaxRequests;

    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(Duration(minutes: 1));

    // Clean old entries
    _rateLimitMap[identifier]?.removeWhere(
      (time) => time.isBefore(oneMinuteAgo),
    );

    // Check current requests
    final requests = _rateLimitMap[identifier] ?? [];
    if (requests.length >= effectiveMaxRequests) {
      return false;
    }

    // Add current request
    requests.add(now);
    _rateLimitMap[identifier] = requests;

    return true;
  }

  /// Check login rate limit
  bool checkLoginRateLimit(String identifier) {
    final securityConfig = _configManager.getSecurityConfig();
    final rateLimitConfig =
        securityConfig['rateLimit'] as Map<String, dynamic>? ?? {};
    final maxLoginAttempts =
        rateLimitConfig['maxLoginAttemptsPerMinute'] as int? ?? 5;

    return checkRateLimit('login_$identifier', maxRequests: maxLoginAttempts);
  }

  /// Generate CSRF token
  String generateCSRFToken() {
    final securityConfig = _configManager.getSecurityConfig();
    final csrfConfig = securityConfig['csrf'] as Map<String, dynamic>? ?? {};
    final tokenValidityMinutes =
        csrfConfig['tokenValidityMinutes'] as int? ?? 30;

    final bytes = List<int>.generate(32, (i) => Random().nextInt(256));
    final token = base64Url.encode(bytes);

    _csrfTokens[token] = DateTime.now().add(
      Duration(minutes: tokenValidityMinutes),
    );

    // Clean expired tokens
    _cleanExpiredCSRFTokens();

    return token;
  }

  /// Validate CSRF token
  bool validateCSRFToken(String token) {
    final expiry = _csrfTokens[token];
    if (expiry == null) return false;

    if (DateTime.now().isAfter(expiry)) {
      _csrfTokens.remove(token);
      return false;
    }

    return true;
  }

  /// Consume CSRF token (one-time use)
  bool consumeCSRFToken(String token) {
    if (!validateCSRFToken(token)) return false;

    _csrfTokens.remove(token);
    return true;
  }

  /// Log security events
  Future<void> logSecurityEvent({
    required String userId,
    required String event,
    required Map<String, dynamic> details,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final logEntry = {
        'id': _generateLogId(),
        'userId': userId,
        'event': event,
        'details': jsonEncode(details),
        'ipAddress': ipAddress ?? 'unknown',
        'userAgent': userAgent ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
        'severity': _getEventSeverity(event),
      };

      await _databaseService.createSecurityLog(logEntry);

      // Alert on critical events
      if (_isCriticalEvent(event)) {
        await _alertCriticalEvent(logEntry);
      }
    } catch (e) {
      debugPrint('Security logging error: $e');
    }
  }

  /// Detect suspicious activity
  Future<bool> detectSuspiciousActivity(String userId) async {
    try {
      final recentLogs = await _databaseService.getRecentSecurityLogs(
        userId: userId,
        hours: 1,
      );

      // Check for multiple failed login attempts
      final failedLogins = recentLogs
          .where((log) => log['event'] == 'LOGIN_FAILED')
          .length;

      if (failedLogins >= 3) return true;

      // Check for rapid successive requests
      final allRequests = recentLogs.length;
      if (allRequests >= 50) return true;

      // Check for unusual patterns
      final uniqueIPs = recentLogs
          .map((log) => log['ipAddress'])
          .toSet()
          .length;

      if (uniqueIPs >= 5) return true;

      return false;
    } catch (e) {
      debugPrint('Suspicious activity detection error: $e');
      return false;
    }
  }

  /// Generate secure random string
  String generateSecureRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Validate file upload security
  bool validateFileUpload({
    required String fileName,
    required String mimeType,
    required int fileSize,
    int maxSizeBytes = 5 * 1024 * 1024, // 5MB default
  }) {
    // Check file size
    if (fileSize > maxSizeBytes) return false;

    // Check file extension
    final allowedExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.pdf',
      '.doc',
      '.docx',
    ];
    final extension = fileName.toLowerCase().substring(
      fileName.lastIndexOf('.'),
    );
    if (!allowedExtensions.contains(extension)) return false;

    // Check MIME type
    final allowedMimeTypes = [
      'image/jpeg',
      'image/png',
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ];
    if (!allowedMimeTypes.contains(mimeType.toLowerCase())) return false;

    return true;
  }

  /// Get security headers for HTTP requests
  Map<String, String> getSecurityHeaders() {
    return {
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
      'Content-Security-Policy':
          "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';",
      'Referrer-Policy': 'strict-origin-when-cross-origin',
    };
  }

  // Private helper methods

  String _generateSalt() {
    final bytes = List<int>.generate(16, (i) => Random.secure().nextInt(256));
    return base64Url.encode(bytes);
  }

  String _generateLogId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'log_${timestamp}_$random';
  }

  String _getEventSeverity(String event) {
    const criticalEvents = [
      'LOGIN_FAILED',
      'ACCOUNT_LOCKED',
      'SUSPICIOUS_ACTIVITY',
      'UNAUTHORIZED_ACCESS',
    ];

    const warningEvents = ['PASSWORD_CHANGED', 'PROFILE_UPDATED', 'KYC_FAILED'];

    if (criticalEvents.contains(event)) return 'CRITICAL';
    if (warningEvents.contains(event)) return 'WARNING';
    return 'INFO';
  }

  bool _isCriticalEvent(String event) {
    const criticalEvents = [
      'ACCOUNT_LOCKED',
      'SUSPICIOUS_ACTIVITY',
      'UNAUTHORIZED_ACCESS',
      'DATA_BREACH_ATTEMPT',
    ];
    return criticalEvents.contains(event);
  }

  Future<void> _alertCriticalEvent(Map<String, dynamic> logEntry) async {
    // In production, this would send alerts to administrators
    debugPrint(
      'CRITICAL SECURITY EVENT: ${logEntry['event']} for user ${logEntry['userId']}',
    );

    // Could implement:
    // - Email alerts to administrators
    // - Push notifications to security team
    // - Integration with security monitoring systems
    // - Automatic account suspension for severe threats
  }

  void _cleanExpiredCSRFTokens() {
    final now = DateTime.now();
    _csrfTokens.removeWhere((token, expiry) => now.isAfter(expiry));
  }
}
