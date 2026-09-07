import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/firestore_models.dart';

class AuthResult {
  final bool success;
  final String? message;
  final String? userId;
  final String? token;
  final Map<String, dynamic>? userData;

  AuthResult({
    required this.success,
    this.message,
    this.userId,
    this.token,
    this.userData,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String _usersCollection = 'users';
  static const String _securityLogsCollection = 'security_logs';
  static const String _sessionsCollection = 'sessions';

  // Security constants
  static const int _maxLoginAttempts = 5;
  static const int _lockoutDurationMinutes = 30;

  // Current user data
  User? _currentFirebaseUser;
  Map<String, dynamic>? _currentUserData;

  /// Get current Firebase user
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Get current user data
  Map<String, dynamic>? get currentUserData => _currentUserData;

  /// Check if user is signed in
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  /// Sign up a new user with Firebase Auth and Firestore
  Future<AuthResult> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required UserType userType,
    required String aadhaarNumber,
    required String panNumber,
  }) async {
    try {
      // Input validation
      final validationResult = _validateSignUpInput(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        aadhaarNumber: aadhaarNumber,
        panNumber: panNumber,
      );

      if (!validationResult.success) {
        return validationResult;
      }

      // Check if user already exists in Firestore
      final existingUser = await _getUserByEmail(email);
      if (existingUser != null) {
        return AuthResult(
          success: false,
          message: 'User with this email already exists',
        );
      }

      // Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create Firebase user');
      }

      // Set user ID to Firebase Auth UID
      final userId = firebaseUser.uid;
      final now = DateTime.now().toIso8601String();

      // Prepare user data for Firestore
      final userData = {
        'id': userId,
        'firebaseUid': firebaseUser.uid,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'userType': userType.toString().split('.').last,
        'aadhaarNumber': aadhaarNumber,
        'panNumber': panNumber,
        'isEmailVerified': firebaseUser.emailVerified,
        'isPhoneVerified': false,
        'isKycVerified': false,
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
        'loginAttempts': 0,
        'lastLoginAttempt': null,
        'lastLogin': null,
        'isLocked': false,
        'lockoutUntil': null,
      };

      // Store user data in Firestore directly using Firebase UID as doc ID
      await _firestore.collection(_usersCollection).doc(firebaseUser.uid).set(userData);

      // Update Firebase user profile
      await firebaseUser.updateDisplayName('$firstName $lastName');

      // Send email verification
      await firebaseUser.sendEmailVerification();

      // Log security event
      await _logSecurityEvent(
        userId: userId,
        event: 'USER_REGISTRATION',
        details: 'New user registered successfully',
        severity: 'info',
      );

      _currentFirebaseUser = firebaseUser;
      _currentUserData = userData;

      return AuthResult(
        success: true,
        message: 'User registered successfully. Please verify your email.',
        userId: userId,
        token: await firebaseUser.getIdToken(),
        userData: userData,
      );
    } catch (e) {
      debugPrint('Sign up error: $e');
      return AuthResult(
        success: false,
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  /// Sign in user with Firebase Auth
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Input validation
      if (email.isEmpty || password.isEmpty) {
        return AuthResult(
          success: false,
          message: 'Email and password are required',
        );
      }

      // Check rate limiting
      final userData = await _getUserByEmail(email);
      if (userData != null) {
        final rateLimitResult = await _checkRateLimit(userData);
        if (!rateLimitResult.success) {
          return rateLimitResult;
        }
      }

      // Sign in with Firebase Auth
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to sign in');
      }

      // Get user data from Firestore directly by UID
      var docSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(firebaseUser.uid)
          .get();

      Map<String, dynamic>? userDataFromFirestore = docSnapshot.data();
      if (userDataFromFirestore == null) {
        final userDoc = await _firestore
            .collection(_usersCollection)
            .where('firebaseUid', isEqualTo: firebaseUser.uid)
            .limit(1)
            .get();
        if (userDoc.docs.isNotEmpty) {
          userDataFromFirestore = userDoc.docs.first.data();
        }
      }

      if (userDataFromFirestore == null) {
        throw Exception('User data not found');
      }

      final userId = userDataFromFirestore['id'] ?? firebaseUser.uid;

      // Update login information
      final now = DateTime.now().toIso8601String();
      await _firestore.collection(_usersCollection).doc(userId).update({
        'lastLogin': now,
        'updatedAt': now,
        'loginAttempts': 0,
        'lastLoginAttempt': null,
        'isLocked': false,
        'lockoutUntil': null,
      });

      // Log security event
      await _logSecurityEvent(
        userId: userId,
        event: 'USER_LOGIN',
        details: 'User logged in successfully',
        severity: 'info',
      );

      // Create session
      await _createSession(userId, firebaseUser.uid);

      _currentFirebaseUser = firebaseUser;
      _currentUserData = userDataFromFirestore;

      return AuthResult(
        success: true,
        message: 'Signed in successfully',
        userId: userId,
        token: await firebaseUser.getIdToken(),
        userData: userDataFromFirestore,
      );
    } catch (e) {
      debugPrint('Sign in error: $e');

      // Handle failed login attempt
      if (email.isNotEmpty) {
        await _handleFailedLoginAttempt(email);
      }

      return AuthResult(
        success: false,
        message: 'Sign in failed: ${e.toString()}',
      );
    }
  }

  /// Sign out user
  Future<AuthResult> signOut() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && _currentUserData != null) {
        // Log security event
        await _logSecurityEvent(
          userId: _currentUserData!['id'],
          event: 'USER_LOGOUT',
          details: 'User logged out successfully',
          severity: 'info',
        );

        // Invalidate session
        await _invalidateSession(_currentUserData!['id']);
      }

      await _firebaseAuth.signOut();
      _currentFirebaseUser = null;
      _currentUserData = null;

      return AuthResult(success: true, message: 'Signed out successfully');
    } catch (e) {
      debugPrint('Sign out error: $e');
      return AuthResult(
        success: false,
        message: 'Sign out failed: ${e.toString()}',
      );
    }
  }

  /// Reset password
  Future<AuthResult> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);

      // Log security event
      final userData = await _getUserByEmail(email);
      if (userData != null) {
        await _logSecurityEvent(
          userId: userData['id'],
          event: 'PASSWORD_RESET_REQUEST',
          details: 'Password reset email sent',
          severity: 'info',
        );
      }

      return AuthResult(
        success: true,
        message: 'Password reset email sent successfully',
      );
    } catch (e) {
      debugPrint('Reset password error: $e');
      return AuthResult(
        success: false,
        message: 'Failed to send password reset email: ${e.toString()}',
      );
    }
  }

  /// Update user profile
  Future<AuthResult> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || _currentUserData == null) {
        return AuthResult(success: false, message: 'User not signed in');
      }

      final userId = _currentUserData!['id'];
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (phone != null) updateData['phone'] = phone;

      // Update display name in Firebase Auth
      if (firstName != null || lastName != null) {
        final newFirstName = firstName ?? _currentUserData!['firstName'];
        final newLastName = lastName ?? _currentUserData!['lastName'];
        await user.updateDisplayName('$newFirstName $newLastName');
      }

      // Update user data in Firestore
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update(updateData);

      // Update local user data
      _currentUserData!.addAll(updateData);

      return AuthResult(
        success: true,
        message: 'Profile updated successfully',
        userData: _currentUserData,
      );
    } catch (e) {
      debugPrint('Update profile error: $e');
      return AuthResult(
        success: false,
        message: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  /// Verify email
  Future<AuthResult> verifyEmail() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return AuthResult(success: false, message: 'User not signed in');
      }

      await user.sendEmailVerification();
      return AuthResult(
        success: true,
        message: 'Verification email sent successfully',
      );
    } catch (e) {
      debugPrint('Verify email error: $e');
      return AuthResult(
        success: false,
        message: 'Failed to send verification email: ${e.toString()}',
      );
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    await user.reload();
    return user.emailVerified;
  }

  // Private helper methods

  /// Validate sign up input
  AuthResult _validateSignUpInput({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String aadhaarNumber,
    required String panNumber,
  }) {
    if (firstName.trim().isEmpty) {
      return AuthResult(success: false, message: 'First name is required');
    }
    if (lastName.trim().isEmpty) {
      return AuthResult(success: false, message: 'Last name is required');
    }
    if (!_isValidEmail(email)) {
      return AuthResult(success: false, message: 'Invalid email format');
    }
    if (!_isValidPhone(phone)) {
      return AuthResult(success: false, message: 'Invalid phone number format');
    }
    if (!_isValidPassword(password)) {
      return AuthResult(
        success: false,
        message:
            'Password must be at least 8 characters with uppercase, lowercase, number, and special character',
      );
    }
    if (!_isValidAadhaar(aadhaarNumber)) {
      return AuthResult(
        success: false,
        message: 'Invalid Aadhaar number format',
      );
    }
    if (!_isValidPAN(panNumber)) {
      return AuthResult(success: false, message: 'Invalid PAN number format');
    }

    return AuthResult(success: true);
  }

  /// Get user by email from Firestore
  Future<Map<String, dynamic>?> _getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrint('Get user by email error: $e');
      return null;
    }
  }

  /// Check rate limiting for login attempts
  Future<AuthResult> _checkRateLimit(Map<String, dynamic> userData) async {
    final loginAttempts = userData['loginAttempts'] ?? 0;
    final isLocked = userData['isLocked'] ?? false;
    final lockoutUntil = userData['lockoutUntil'];

    if (isLocked && lockoutUntil != null) {
      final lockoutTime = DateTime.parse(lockoutUntil);
      if (DateTime.now().isBefore(lockoutTime)) {
        return AuthResult(
          success: false,
          message: 'Account is locked. Please try again later.',
        );
      } else {
        // Unlock account
        await _firestore
            .collection(_usersCollection)
            .doc(userData['id'])
            .update({
              'isLocked': false,
              'lockoutUntil': null,
              'loginAttempts': 0,
            });
      }
    }

    if (loginAttempts >= _maxLoginAttempts) {
      return AuthResult(
        success: false,
        message: 'Too many login attempts. Account is locked.',
      );
    }

    return AuthResult(success: true);
  }

  /// Handle failed login attempt
  Future<void> _handleFailedLoginAttempt(String email) async {
    try {
      final userData = await _getUserByEmail(email);
      if (userData == null) return;

      final currentAttempts = (userData['loginAttempts'] ?? 0) + 1;
      final now = DateTime.now();

      final updateData = {
        'loginAttempts': currentAttempts,
        'lastLoginAttempt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      if (currentAttempts >= _maxLoginAttempts) {
        updateData['isLocked'] = true;
        updateData['lockoutUntil'] = now
            .add(Duration(minutes: _lockoutDurationMinutes))
            .toIso8601String();
      }

      await _firestore
          .collection(_usersCollection)
          .doc(userData['id'])
          .update(updateData);

      // Log security event
      await _logSecurityEvent(
        userId: userData['id'],
        event: 'FAILED_LOGIN_ATTEMPT',
        details: 'Failed login attempt #$currentAttempts',
        severity: currentAttempts >= _maxLoginAttempts ? 'high' : 'medium',
      );
    } catch (e) {
      debugPrint('Handle failed login attempt error: $e');
    }
  }

  /// Create session in Firestore
  Future<void> _createSession(String userId, String firebaseUid) async {
    try {
      final sessionId = _generateSessionId();
      final now = DateTime.now();

      final sessionData = {
        'id': sessionId,
        'userId': userId,
        'firebaseUid': firebaseUid,
        'createdAt': now.toIso8601String(),
        'expiresAt': now.add(Duration(hours: 24)).toIso8601String(),
        'isActive': true,
        'lastActivity': now.toIso8601String(),
      };

      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .set(sessionData);
    } catch (e) {
      debugPrint('Create session error: $e');
    }
  }

  /// Invalidate session
  Future<void> _invalidateSession(String userId) async {
    try {
      final sessions = await _firestore
          .collection(_sessionsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in sessions.docs) {
        await doc.reference.update({
          'isActive': false,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Invalidate session error: $e');
    }
  }

  /// Log security event to Firestore
  Future<void> _logSecurityEvent({
    required String userId,
    required String event,
    required String details,
    required String severity,
  }) async {
    try {
      final logId = _generateLogId();
      final logData = {
        'id': logId,
        'userId': userId,
        'event': event,
        'details': details,
        'severity': severity,
        'timestamp': DateTime.now().toIso8601String(),
        'ipAddress': null, // Can be added if needed
        'userAgent': null, // Can be added if needed
      };

      await _firestore
          .collection(_securityLogsCollection)
          .doc(logId)
          .set(logData);
    } catch (e) {
      debugPrint('Log security event error: $e');
    }
  }

  // Validation methods
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(
      r'^\+?[1-9]\d{1,14}$',
    ).hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }

  bool _isValidPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  bool _isValidAadhaar(String aadhaar) {
    return RegExp(r'^\d{12}$').hasMatch(aadhaar);
  }

  bool _isValidPAN(String pan) {
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan);
  }

  // ID generation methods
  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000)).round()}';
  }

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000)).round()}';
  }

  String _generateLogId() {
    return 'log_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000)).round()}';
  }
}
