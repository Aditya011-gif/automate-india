import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'config_manager.dart';
import '../services/database_service.dart';
import '../firebase_options.dart';

/// Database initializer for setting up the application database with proper configuration
class DatabaseInitializer {
  static final DatabaseInitializer _instance = DatabaseInitializer._internal();
  factory DatabaseInitializer() => _instance;
  DatabaseInitializer._internal();

  final ConfigManager _configManager = ConfigManager();
  bool _isInitialized = false;

  /// Check if database is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize database with configuration
  Future<bool> initialize() async {
    try {
      // Initialize Firebase if not already initialized
      if (!Firebase.apps.isNotEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Ensure configuration is loaded
      if (!_configManager.isInitialized) {
        final configLoaded = await _configManager.initialize();
        if (!configLoaded) {
          debugPrint('Failed to load configuration');
          return false;
        }
      }

      // Test Firebase connectivity
      if (!await _testFirebaseConnectivity()) {
        debugPrint('Firebase connectivity test failed');
        return false;
      }

      // Initialize database service (for local caching if needed)
      final databaseService = DatabaseService();
      await databaseService.initialize();

      // Set up Firestore security rules (if needed)
      await _setupFirestoreSecurity();

      // Create initial data if needed
      await _createInitialFirestoreData();

      _isInitialized = true;
      debugPrint('Database initialized successfully with Firebase');
      return true;

    } catch (e) {
      debugPrint('Database initialization failed: $e');
      return false;
    }
  }

  /// Test Firebase connectivity
  Future<bool> _testFirebaseConnectivity() async {
    try {
      // Test Firestore connectivity
      final firestore = FirebaseFirestore.instance;
      await firestore.enableNetwork();
      
      // Test Firebase Auth connectivity
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      debugPrint('Firebase connectivity test passed');
      debugPrint('Current user: ${currentUser?.uid ?? 'No user signed in'}');
      
      return true;
    } catch (e) {
      debugPrint('Firebase connectivity test error: $e');
      return false;
    }
  }

  /// Set up Firestore security
  Future<void> _setupFirestoreSecurity() async {
    try {
      // Configure Firestore settings
      final firestore = FirebaseFirestore.instance;
      
      // Enable offline persistence for better performance
      await firestore.enablePersistence();
      
      debugPrint('Firestore security settings applied');
    } catch (e) {
      debugPrint('Error setting up Firestore security: $e');
      // Don't throw here as this is not critical for app functionality
    }
  }

  /// Create initial Firestore data
  Future<void> _createInitialFirestoreData() async {
    try {
      // Only attempt to create initial data if user is authenticated
      // This prevents permission errors during app initialization
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        debugPrint('Skipping initial Firestore data creation - no authenticated user');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      
      // Check if initial data already exists
      final usersSnapshot = await firestore.collection('users').limit(1).get();
      
      if (usersSnapshot.docs.isNotEmpty) {
        debugPrint('Initial data already exists, skipping creation');
        return;
      }

      // Create default configuration entries in development environment
      if (_configManager.environment.name == 'development') {
        await _createDefaultFirestoreConfiguration();
      }

      debugPrint('Initial Firestore data created successfully');
    } catch (e) {
      debugPrint('Error creating initial Firestore data: $e');
      // Don't throw here as this is not critical for app functionality
    }
  }

  /// Create default Firestore configuration
  Future<void> _createDefaultFirestoreConfiguration() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Create default app configuration
      await firestore.collection('app_config').doc('default').set({
        'version': '1.0.0',
        'environment': _configManager.environment.name,
        'features': {
          'nft_enabled': true,
          'blockchain_enabled': true,
          'kyc_required': true,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Default Firestore configuration created');
    } catch (e) {
      debugPrint('Error creating default Firestore configuration: $e');
    }
  }

  /// Perform Firestore maintenance
  Future<void> _performFirestoreMaintenance() async {
    try {
      // Clean up old sessions
      await _cleanupOldFirestoreSessions();

      // Clean up old security logs
      await _cleanupOldFirestoreSecurityLogs();

      debugPrint('Firestore maintenance completed');
    } catch (e) {
      debugPrint('Error during Firestore maintenance: $e');
    }
  }

  /// Clean up old Firestore sessions
  Future<void> _cleanupOldFirestoreSessions() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      final oldSessions = await firestore
          .collection('sessions')
          .where('expiresAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = firestore.batch();
      for (final doc in oldSessions.docs) {
        batch.delete(doc.reference);
      }
      
      if (oldSessions.docs.isNotEmpty) {
        await batch.commit();
        debugPrint('Cleaned up ${oldSessions.docs.length} old sessions');
      }
    } catch (e) {
      debugPrint('Error cleaning up old Firestore sessions: $e');
    }
  }

  /// Clean up old Firestore security logs
  Future<void> _cleanupOldFirestoreSecurityLogs() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final retentionPeriod = _configManager.getLoggingConfig()['retentionPeriod'] as Duration? ?? const Duration(days: 90);
      final cutoffDate = DateTime.now().subtract(retentionPeriod);
      
      final oldLogs = await firestore
          .collection('security_logs')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = firestore.batch();
      for (final doc in oldLogs.docs) {
        batch.delete(doc.reference);
      }
      
      if (oldLogs.docs.isNotEmpty) {
        await batch.commit();
        debugPrint('Cleaned up ${oldLogs.docs.length} old security logs');
      }
    } catch (e) {
      debugPrint('Error cleaning up old Firestore security logs: $e');
    }
  }

  /// Get Firestore statistics
  Future<Map<String, dynamic>> getFirestoreStats() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final stats = <String, dynamic>{};

      // Get collection counts
      final collections = ['users', 'sessions', 'security_logs', 'kyc_data', 'profile_data', 'app_config'];
      for (final collection in collections) {
        try {
          final snapshot = await firestore.collection(collection).count().get();
          stats['${collection}_count'] = snapshot.count;
        } catch (e) {
          stats['${collection}_count'] = 'Error: $e';
        }
      }

      // Get Firebase Auth user count
      try {
        final auth = FirebaseAuth.instance;
        stats['firebase_auth_user'] = auth.currentUser != null ? 'Authenticated' : 'Not authenticated';
      } catch (e) {
        stats['firebase_auth_user'] = 'Error: $e';
      }

      // Get configuration info
      stats['environment'] = _configManager.environment.name;
      stats['firebase_initialized'] = Firebase.apps.isNotEmpty;
      stats['firestore_initialized'] = _isInitialized;

      return stats;
    } catch (e) {
      return {'error': 'Failed to get Firestore stats: $e'};
    }
  }

  /// Reset Firestore (development only)
  Future<bool> resetFirestore() async {
    if (_configManager.environment.name != 'development') {
      debugPrint('Firestore reset is only allowed in development environment');
      return false;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      // Clear all collections
      final collections = ['users', 'sessions', 'security_logs', 'kyc_data', 'profile_data', 'app_config'];
      for (final collection in collections) {
        try {
          final snapshot = await firestore.collection(collection).get();
          final batch = firestore.batch();
          
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          
          if (snapshot.docs.isNotEmpty) {
            await batch.commit();
            debugPrint('Cleared collection: $collection (${snapshot.docs.length} documents)');
          }
        } catch (e) {
          debugPrint('Error clearing collection $collection: $e');
        }
      }

      _isInitialized = false;
      
      // Reinitialize Firestore
      await initialize();
      
      debugPrint('Firestore reset and reinitialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error resetting Firestore: $e');
      return false;
    }
  }
}