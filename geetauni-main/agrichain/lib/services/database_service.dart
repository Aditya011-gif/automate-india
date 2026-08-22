import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/config_manager.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigManager _configManager = ConfigManager();

  // Collection names
  static const String _usersCollection = 'users';
  static const String _securityLogsCollection = 'security_logs';
  static const String _sessionsCollection = 'sessions';
  static const String _kycDataCollection = 'kyc_data';
  static const String _profileDataCollection = 'profile_data';
  static const String _loansCollection = 'loans';
  static const String _loanRequestsCollection = 'loan_requests';
  static const String _cropsCollection = 'crops';
  static const String _transactionsCollection = 'transactions';
  static const String _ratingsCollection = 'ratings';
  static const String _ratingStatsCollection = 'rating_stats';

  /// Initialize Firestore settings
  Future<void> initialize() async {
    try {
      // Configure Firestore settings with timeout
      await _firestore.enableNetwork().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint(
            '⚠️ Firestore network enable timeout - continuing in offline mode',
          );
        },
      );

      // Set up offline persistence for better user experience
      if (!kIsWeb) {
        try {
          _firestore.settings = const Settings(
            persistenceEnabled: true,
            cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          );
        } catch (e) {
          debugPrint('⚠️ Firestore persistence setup failed: $e');
          // Continue without persistence
        }
      }

      debugPrint('✅ Firestore initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Firestore initialization error: $e');
      debugPrint('📱 App will continue in offline mode');
      // Don't throw exception - allow app to continue in offline mode
    }
  }

  // User operations

  /// Create a new user
  Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      final userId = userData['id'] as String;
      await _firestore.collection(_usersCollection).doc(userId).set(userData);

      debugPrint('✅ User created successfully: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Create user error: $e');
      return false;
    }
  }

  /// Get user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
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
      debugPrint('❌ Get user by email error: $e');
      return null;
    }
  }

  /// Get user by phone
  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get user by phone error: $e');
      return null;
    }
  }

  /// Get user by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get user by ID error: $e');
      return null;
    }
  }

  /// Get user by Firebase UID
  Future<Map<String, dynamic>?> getUserByFirebaseUid(String firebaseUid) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('firebaseUid', isEqualTo: firebaseUid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get user by Firebase UID error: $e');
      return null;
    }
  }

  /// Update user data
  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();

      await _firestore.collection(_usersCollection).doc(userId).update(updates);

      debugPrint('✅ User updated successfully: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Update user error: $e');
      return false;
    }
  }

  /// Delete user (soft delete by setting isActive to false)
  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ User soft deleted successfully: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Delete user error: $e');
      return false;
    }
  }

  /// Get all active users
  Future<List<Map<String, dynamic>>> getAllActiveUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Get all active users error: $e');
      return [];
    }
  }

  /// Get users by type
  Future<List<Map<String, dynamic>>> getUsersByType(String userType) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('userType', isEqualTo: userType)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Get users by type error: $e');
      return [];
    }
  }

  // Security log operations

  /// Create security log entry
  Future<bool> createSecurityLog(Map<String, dynamic> logData) async {
    try {
      final logId = logData['id'] as String;
      await _firestore
          .collection(_securityLogsCollection)
          .doc(logId)
          .set(logData);

      return true;
    } catch (e) {
      debugPrint('❌ Create security log error: $e');
      return false;
    }
  }

  /// Get recent security logs for a user
  Future<List<Map<String, dynamic>>> getRecentSecurityLogs({
    required String userId,
    int hours = 24,
  }) async {
    try {
      final cutoffTime = DateTime.now()
          .subtract(Duration(hours: hours))
          .toIso8601String();

      final querySnapshot = await _firestore
          .collection(_securityLogsCollection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: cutoffTime)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Get recent security logs error: $e');
      return [];
    }
  }

  /// Get security logs by event type
  Future<List<Map<String, dynamic>>> getSecurityLogsByEvent({
    required String userId,
    required String event,
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_securityLogsCollection)
          .where('userId', isEqualTo: userId)
          .where('event', isEqualTo: event)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Get security logs by event error: $e');
      return [];
    }
  }

  /// Get all security logs for admin
  Future<List<Map<String, dynamic>>> getAllSecurityLogs({
    int limit = 100,
    String? severity,
  }) async {
    try {
      Query query = _firestore
          .collection(_securityLogsCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (severity != null) {
        query = query.where('severity', isEqualTo: severity);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('❌ Get all security logs error: $e');
      return [];
    }
  }

  // Session operations

  /// Create session
  Future<bool> createSession(Map<String, dynamic> sessionData) async {
    try {
      final sessionId = sessionData['id'] as String;
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .set(sessionData);

      return true;
    } catch (e) {
      debugPrint('❌ Create session error: $e');
      return false;
    }
  }

  /// Get active session by user ID
  Future<Map<String, dynamic>?> getActiveSessionByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_sessionsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get active session by user ID error: $e');
      return null;
    }
  }

  /// Invalidate session
  Future<bool> invalidateSession(String sessionId) async {
    try {
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('❌ Invalidate session error: $e');
      return false;
    }
  }

  /// Invalidate all sessions for a user
  Future<bool> invalidateAllUserSessions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_sessionsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('❌ Invalidate all user sessions error: $e');
      return false;
    }
  }

  /// Clean expired sessions
  Future<void> cleanExpiredSessions() async {
    try {
      final now = DateTime.now().toIso8601String();

      final querySnapshot = await _firestore
          .collection(_sessionsCollection)
          .where('expiresAt', isLessThan: now)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      await batch.commit();
      debugPrint('✅ Cleaned ${querySnapshot.docs.length} expired sessions');
    } catch (e) {
      debugPrint('❌ Clean expired sessions error: $e');
    }
  }

  // KYC operations

  /// Create KYC data
  Future<bool> createKycData(Map<String, dynamic> kycData) async {
    try {
      final kycId = kycData['id'] as String;
      await _firestore.collection(_kycDataCollection).doc(kycId).set(kycData);

      debugPrint('✅ KYC data created successfully: $kycId');
      return true;
    } catch (e) {
      debugPrint('❌ Create KYC data error: $e');
      return false;
    }
  }

  /// Get KYC data by user ID
  Future<Map<String, dynamic>?> getKycDataByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_kycDataCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get KYC data error: $e');
      return null;
    }
  }

  /// Update KYC data
  Future<bool> updateKycData(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();

      final querySnapshot = await _firestore
          .collection(_kycDataCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update(updates);
        debugPrint('✅ KYC data updated successfully for user: $userId');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Update KYC data error: $e');
      return false;
    }
  }

  /// Get all pending KYC verifications
  Future<List<Map<String, dynamic>>> getPendingKycVerifications() async {
    try {
      final querySnapshot = await _firestore
          .collection(_kycDataCollection)
          .where('verificationStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Get pending KYC verifications error: $e');
      return [];
    }
  }

  // Profile operations

  /// Create profile data
  Future<bool> createProfileData(Map<String, dynamic> profileData) async {
    try {
      final profileId = profileData['id'] as String;
      await _firestore
          .collection(_profileDataCollection)
          .doc(profileId)
          .set(profileData);

      debugPrint('✅ Profile data created successfully: $profileId');
      return true;
    } catch (e) {
      debugPrint('❌ Create profile data error: $e');
      return false;
    }
  }

  /// Get profile data by user ID
  Future<Map<String, dynamic>?> getProfileDataByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_profileDataCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get profile data error: $e');
      return null;
    }
  }

  /// Update profile data
  Future<bool> updateProfileData(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();

      final querySnapshot = await _firestore
          .collection(_profileDataCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update(updates);
        debugPrint('✅ Profile data updated successfully for user: $userId');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Update profile data error: $e');
      return false;
    }
  }

  // Loan operations

  /// Create loan request
  Future<bool> createLoanRequest(Map<String, dynamic> loanData) async {
    try {
      final loanId = loanData['id'] as String;
      await _firestore
          .collection(_loanRequestsCollection)
          .doc(loanId)
          .set(loanData);

      debugPrint('✅ Loan request created successfully: $loanId');
      return true;
    } catch (e) {
      debugPrint('❌ Create loan request error: $e');
      return false;
    }
  }

  /// Get loan requests by user ID
  Future<List<Map<String, dynamic>>> getLoanRequestsByUserId(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_loanRequestsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Get loan requests by user ID error: $e');
      return [];
    }
  }

  /// Get all loan requests
  Future<List<Map<String, dynamic>>> getAllLoanRequests({
    String? status,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection(_loanRequestsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('❌ Get all loan requests error: $e');
      return [];
    }
  }

  /// Update loan request status
  Future<bool> updateLoanRequestStatus(
    String loanId,
    String status, {
    String? remarks,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (remarks != null) {
        updateData['remarks'] = remarks;
      }

      await _firestore
          .collection(_loanRequestsCollection)
          .doc(loanId)
          .update(updateData);

      debugPrint('✅ Loan request status updated: $loanId -> $status');
      return true;
    } catch (e) {
      debugPrint('❌ Update loan request status error: $e');
      return false;
    }
  }

  // Crop operations

  /// Create crop listing
  Future<bool> createCrop(Map<String, dynamic> cropData) async {
    try {
      // Generate a new document ID if the provided ID is empty
      final docRef = _firestore.collection(_cropsCollection).doc();
      final cropId = cropData['id'] as String;
      final finalCropId = cropId.isEmpty ? docRef.id : cropId;

      // Update the crop data with the final ID
      cropData['id'] = finalCropId;

      await docRef.set(cropData);

      debugPrint('✅ Crop created successfully: $finalCropId');
      return true;
    } catch (e) {
      debugPrint('❌ Create crop error: $e');
      return false;
    }
  }

  /// Get crops by farmer ID
  Future<List<Map<String, dynamic>>> getCropsByFarmerId(String farmerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_cropsCollection)
          .where('farmerId', isEqualTo: farmerId)
          .get();

      final crops = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Sort by createdAt in memory to avoid composite index requirement
      crops.sort((a, b) {
        final aCreatedAt = a['createdAt'];
        final bCreatedAt = b['createdAt'];

        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;

        DateTime aDate, bDate;
        if (aCreatedAt is Timestamp) {
          aDate = aCreatedAt.toDate();
        } else if (aCreatedAt is String) {
          aDate = DateTime.parse(aCreatedAt);
        } else {
          return 0;
        }

        if (bCreatedAt is Timestamp) {
          bDate = bCreatedAt.toDate();
        } else if (bCreatedAt is String) {
          bDate = DateTime.parse(bCreatedAt);
        } else {
          return 0;
        }

        return bDate.compareTo(aDate); // Descending order
      });

      return crops;
    } catch (e) {
      debugPrint('❌ Get crops by farmer ID error: $e');
      return [];
    }
  }

  /// Get all available crops
  Future<List<Map<String, dynamic>>> getAllAvailableCrops() async {
    try {
      final querySnapshot = await _firestore
          .collection(_cropsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final crops = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Sort by createdAt in memory to avoid composite index requirement
      crops.sort((a, b) {
        final aCreatedAt = a['createdAt'];
        final bCreatedAt = b['createdAt'];

        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;

        DateTime aDate, bDate;
        if (aCreatedAt is Timestamp) {
          aDate = aCreatedAt.toDate();
        } else if (aCreatedAt is String) {
          aDate = DateTime.parse(aCreatedAt);
        } else {
          return 0;
        }

        if (bCreatedAt is Timestamp) {
          bDate = bCreatedAt.toDate();
        } else if (bCreatedAt is String) {
          bDate = DateTime.parse(bCreatedAt);
        } else {
          return 0;
        }

        return bDate.compareTo(aDate); // Descending order
      });

      return crops;
    } catch (e) {
      debugPrint('❌ Get all available crops error: $e');
      return [];
    }
  }

  /// Update crop data
  Future<bool> updateCrop(String cropId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();

      await _firestore.collection(_cropsCollection).doc(cropId).update(updates);

      debugPrint('✅ Crop updated successfully: $cropId');
      return true;
    } catch (e) {
      debugPrint('❌ Update crop error: $e');
      return false;
    }
  }

  // Transaction operations

  /// Create transaction
  Future<bool> createTransaction(Map<String, dynamic> transactionData) async {
    try {
      final transactionId = transactionData['id'] as String;
      await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .set(transactionData);

      debugPrint('✅ Transaction created successfully: $transactionId');
      return true;
    } catch (e) {
      debugPrint('❌ Create transaction error: $e');
      return false;
    }
  }

  /// Get transactions by user ID
  Future<List<Map<String, dynamic>>> getTransactionsByUserId(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Get transactions by user ID error: $e');
      return [];
    }
  }

  // Rating management methods

  /// Add a new rating
  Future<bool> addRating(Map<String, dynamic> ratingData) async {
    try {
      ratingData['createdAt'] = FieldValue.serverTimestamp();
      ratingData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_ratingsCollection).add(ratingData);

      debugPrint('✅ Rating added successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Add rating error: $e');
      return false;
    }
  }

  /// Get ratings for a user
  Future<List<Map<String, dynamic>>> getRatingsForUser(
    String userId, {
    String? ratingType,
  }) async {
    try {
      Query query = _firestore
          .collection(_ratingsCollection)
          .where('toUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (ratingType != null) {
        query = query.where('ratingType', isEqualTo: ratingType);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      debugPrint('❌ Get ratings for user error: $e');
      return [];
    }
  }

  /// Get all ratings (for admin/overview purposes)
  Future<List<Map<String, dynamic>>> getAllRatings({String? filterType}) async {
    try {
      Query query = _firestore
          .collection(_ratingsCollection)
          .orderBy('createdAt', descending: true)
          .limit(100);

      if (filterType != null) {
        query = query.where('ratingType', isEqualTo: filterType);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      debugPrint('❌ Get all ratings error: $e');
      return [];
    }
  }

  /// Get user rating statistics
  Future<Map<String, dynamic>?> getUserRatingStats(String userId) async {
    try {
      final doc = await _firestore
          .collection(_ratingStatsCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }

      return null;
    } catch (e) {
      debugPrint('❌ Get user rating stats error: $e');
      return null;
    }
  }

  /// Update user rating statistics
  Future<bool> updateUserRatingStats(
    String userId,
    Map<String, dynamic> stats,
  ) async {
    try {
      stats['lastUpdated'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_ratingStatsCollection)
          .doc(userId)
          .set(stats, SetOptions(merge: true));

      debugPrint('✅ User rating stats updated successfully: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Update user rating stats error: $e');
      return false;
    }
  }

  /// Calculate and update rating statistics for a user
  Future<bool> calculateRatingStats(String userId) async {
    try {
      // Get all ratings for the user
      final ratings = await getRatingsForUser(userId);

      if (ratings.isEmpty) {
        // Create empty stats
        final emptyStats = {
          'userId': userId,
          'averageRating': 0.0,
          'totalRatings': 0,
          'ratingsByType': <String, double>{},
          'countsByType': <String, int>{},
          'fiveStarCount': 0,
          'fourStarCount': 0,
          'threeStarCount': 0,
          'twoStarCount': 0,
          'oneStarCount': 0,
        };

        return await updateUserRatingStats(userId, emptyStats);
      }

      // Calculate statistics
      double totalRating = 0.0;
      int totalCount = ratings.length;
      Map<String, double> ratingsByType = {};
      Map<String, int> countsByType = {};
      Map<int, int> starCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final rating in ratings) {
        final ratingValue = (rating['rating'] as num?)?.toDouble() ?? 0.0;
        final ratingType = rating['ratingType'] as String?;

        totalRating += ratingValue;

        // Count by star rating
        final starRating = ratingValue.round().clamp(1, 5);
        starCounts[starRating] = (starCounts[starRating] ?? 0) + 1;

        // Count by type
        if (ratingType != null) {
          ratingsByType[ratingType] =
              (ratingsByType[ratingType] ?? 0.0) + ratingValue;
          countsByType[ratingType] = (countsByType[ratingType] ?? 0) + 1;
        }
      }

      // Calculate averages by type
      ratingsByType.forEach((type, total) {
        final count = countsByType[type] ?? 1;
        ratingsByType[type] = total / count;
      });

      final stats = {
        'userId': userId,
        'averageRating': totalRating / totalCount,
        'totalRatings': totalCount,
        'ratingsByType': ratingsByType,
        'countsByType': countsByType,
        'fiveStarCount': starCounts[5] ?? 0,
        'fourStarCount': starCounts[4] ?? 0,
        'threeStarCount': starCounts[3] ?? 0,
        'twoStarCount': starCounts[2] ?? 0,
        'oneStarCount': starCounts[1] ?? 0,
      };

      return await updateUserRatingStats(userId, stats);
    } catch (e) {
      debugPrint('❌ Calculate rating stats error: $e');
      return false;
    }
  }

  // Database maintenance and statistics

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final futures = await Future.wait([
        _getCollectionCount(_usersCollection, where: {'isActive': true}),
        _getCollectionCount(_securityLogsCollection),
        _getCollectionCount(_sessionsCollection, where: {'isActive': true}),
        _getCollectionCount(_kycDataCollection),
        _getCollectionCount(_profileDataCollection),
        _getCollectionCount(_loanRequestsCollection),
        _getCollectionCount(_cropsCollection),
        _getCollectionCount(_transactionsCollection),
      ]);

      return {
        'users': futures[0],
        'logs': futures[1],
        'sessions': futures[2],
        'kyc': futures[3],
        'profiles': futures[4],
        'loanRequests': futures[5],
        'crops': futures[6],
        'transactions': futures[7],
      };
    } catch (e) {
      debugPrint('❌ Get database stats error: $e');
      return {};
    }
  }

  /// Get collection document count
  Future<int> _getCollectionCount(
    String collection, {
    Map<String, dynamic>? where,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (where != null) {
        where.forEach((key, value) {
          query = query.where(key, isEqualTo: value);
        });
      }

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Get collection count error for $collection: $e');
      return 0;
    }
  }

  /// Backup data to a backup collection
  Future<bool> backupData() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupCollectionPrefix = 'backup_$timestamp';

      final collections = [
        _usersCollection,
        _securityLogsCollection,
        _sessionsCollection,
        _kycDataCollection,
        _profileDataCollection,
        _loanRequestsCollection,
        _cropsCollection,
        _transactionsCollection,
      ];

      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          final backupDocRef = _firestore
              .collection('${backupCollectionPrefix}_$collection')
              .doc(doc.id);
          batch.set(backupDocRef, doc.data());
        }

        await batch.commit();
      }

      debugPrint('✅ Data backup completed successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Backup data error: $e');
      return false;
    }
  }

  /// Clean up old data (for maintenance)
  Future<void> cleanupOldData({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now()
          .subtract(Duration(days: daysToKeep))
          .toIso8601String();

      // Clean old security logs
      final oldLogs = await _firestore
          .collection(_securityLogsCollection)
          .where('timestamp', isLessThan: cutoffDate)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldLogs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Cleaned up ${oldLogs.docs.length} old security logs');
    } catch (e) {
      debugPrint('❌ Cleanup old data error: $e');
    }
  }

  /// Test Firestore connection
  Future<bool> testConnection() async {
    try {
      await _firestore.collection('test').doc('connection').set({
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'connected',
      });

      await _firestore.collection('test').doc('connection').delete();

      debugPrint('✅ Firestore connection test successful');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore connection test failed: $e');
      return false;
    }
  }

  /// Enable offline persistence
  Future<void> enableOfflinePersistence() async {
    try {
      if (!kIsWeb) {
        await _firestore.enablePersistence();
        debugPrint('✅ Offline persistence enabled');
      }
    } catch (e) {
      debugPrint('❌ Enable offline persistence error: $e');
    }
  }

  /// Disable network (for testing offline functionality)
  Future<void> disableNetwork() async {
    try {
      await _firestore.disableNetwork();
      debugPrint('✅ Firestore network disabled');
    } catch (e) {
      debugPrint('❌ Disable network error: $e');
    }
  }

  /// Enable network
  Future<void> enableNetwork() async {
    try {
      await _firestore.enableNetwork();
      debugPrint('✅ Firestore network enabled');
    } catch (e) {
      debugPrint('❌ Enable network error: $e');
    }
  }
}
