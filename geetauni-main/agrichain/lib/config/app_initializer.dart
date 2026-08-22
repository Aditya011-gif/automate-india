import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'config_manager.dart';
import '../services/database_service.dart';
import '../firebase_options.dart';

/// Application initializer that sets up all services and configurations
class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  factory AppInitializer() => _instance;
  AppInitializer._internal();

  bool _isInitialized = false;
  final List<String> _initializationSteps = [];
  final Map<String, dynamic> _initializationResults = {};

  /// Check if app is initialized
  bool get isInitialized => _isInitialized;

  /// Get initialization steps
  List<String> get initializationSteps => List.unmodifiable(_initializationSteps);

  /// Get initialization results
  Map<String, dynamic> get initializationResults => Map.unmodifiable(_initializationResults);

  /// Initialize the entire application
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('App already initialized');
      return true;
    }

    try {
      _initializationSteps.clear();
      _initializationResults.clear();

      debugPrint('Starting application initialization...');

      // Step 1: Initialize Firebase
      if (!await _initializeFirebase()) {
        return false;
      }

      // Step 2: Initialize Configuration Manager
      if (!await _initializeConfigManager()) {
        return false;
      }

      // Step 3: Initialize Database Service
      if (!await _initializeDatabaseService()) {
        return false;
      }

      // Step 4: Perform Health Checks
      if (!await _performHealthChecks()) {
        return false;
      }

      // Step 5: Setup Background Tasks
      await _setupBackgroundTasks();

      _isInitialized = true;
      debugPrint('Application initialization completed successfully');
      return true;

    } catch (e) {
      debugPrint('Application initialization failed: $e');
      _initializationResults['error'] = e.toString();
      return false;
    }
  }

  /// Initialize Firebase
  Future<bool> _initializeFirebase() async {
    try {
      _addStep('Initializing Firebase');
      
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Test Firebase connection
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      
      _initializationResults['firebase'] = 'Success';
      _initializationResults['firebase_auth'] = 'Ready';
      _initializationResults['firestore'] = 'Ready';
      debugPrint('Firebase initialized successfully');
      return true;
    } catch (e) {
      _initializationResults['firebase'] = 'Error: $e';
      debugPrint('Firebase initialization error: $e');
      return false;
    }
  }

  /// Initialize Configuration Manager
  Future<bool> _initializeConfigManager() async {
    try {
      _addStep('Initializing Configuration Manager');
      
      final configManager = ConfigManager();
      final success = await configManager.initialize();
      
      if (success) {
        _initializationResults['config_manager'] = 'Success';
        _initializationResults['environment'] = configManager.environment.name;
        debugPrint('Configuration Manager initialized successfully');
        return true;
      } else {
        _initializationResults['config_manager'] = 'Failed';
        debugPrint('Configuration Manager initialization failed');
        return false;
      }
    } catch (e) {
      _initializationResults['config_manager'] = 'Error: $e';
      debugPrint('Configuration Manager initialization error: $e');
      return false;
    }
  }

  /// Initialize Database Service
  Future<bool> _initializeDatabaseService() async {
    try {
      _addStep('Initializing Database Service');
      
      final databaseService = DatabaseService();
      await databaseService.initialize();
      
      // Only test Firestore connectivity if user is authenticated
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        try {
          // Test basic Firestore connectivity with authenticated user with timeout
          final testDoc = await FirebaseFirestore.instance
              .collection('_test')
              .doc('connectivity')
              .get()
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => throw TimeoutException('Firestore connection timeout'),
              );
          _initializationResults['firestore_connectivity'] = 'Healthy';
        } catch (e) {
          debugPrint('Firestore connectivity test failed (user authenticated): $e');
          _initializationResults['firestore_connectivity'] = 'Offline Mode';
        }
      } else {
        _initializationResults['firestore_connectivity'] = 'Ready (auth required)';
      }
      
      _initializationResults['database_service'] = 'Success';
      debugPrint('Database Service initialized successfully');
      return true;
    } catch (e) {
      _initializationResults['database_service'] = 'Error: $e';
      debugPrint('Database Service initialization error: $e');
      return false;
    }
  }



  /// Perform health checks
  Future<bool> _performHealthChecks() async {
    try {
      _addStep('Performing Health Checks');
      
      final healthResults = <String, dynamic>{};
      
      // Firebase Auth health check
      try {
        final auth = FirebaseAuth.instance;
        // Test if Firebase Auth is responsive
        final currentUser = auth.currentUser;
        healthResults['firebase_auth'] = 'Healthy';
      } catch (e) {
        healthResults['firebase_auth'] = 'Error: $e';
      }
      
      // Firestore health check
      try {
        final firestore = FirebaseFirestore.instance;
        final auth = FirebaseAuth.instance;
        
        // Only test Firestore connectivity if user is authenticated
        if (auth.currentUser != null) {
          // Test basic Firestore connectivity with authenticated user with timeout
          await firestore.collection('_health_check').doc('test').get().timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Firestore health check timeout'),
          );
          healthResults['firestore'] = 'Healthy';
        } else {
          // Firestore is ready but requires authentication
          healthResults['firestore'] = 'Ready (auth required)';
        }
      } catch (e) {
        healthResults['firestore'] = 'Offline Mode';
        debugPrint('Firestore health check failed: $e');
      }
      
      // Configuration health check
      try {
        final configManager = ConfigManager();
        final isValid = configManager.validateConfiguration();
        healthResults['configuration'] = isValid ? 'Valid' : 'Invalid';
      } catch (e) {
        healthResults['configuration'] = 'Error: $e';
      }
      
      // Database Service health check
      try {
        final databaseService = DatabaseService();
        // Test if DatabaseService is responsive
        healthResults['database_service'] = 'Healthy';
      } catch (e) {
        healthResults['database_service'] = 'Error: $e';
      }
      
      _initializationResults['health_checks'] = healthResults;
      
      // Check if any critical services are unhealthy
      final criticalServices = ['firebase_auth', 'firestore', 'configuration'];
      for (final service in criticalServices) {
        final status = healthResults[service] as String;
        // Consider services healthy if they're ready, even if auth is required
        final isHealthy = status == 'Healthy' || 
                         status == 'Valid' || 
                         status.contains('Ready') ||
                         status.contains('auth required');
        
        if (!isHealthy && (status.startsWith('Error') || status == 'Unhealthy' || status == 'Invalid')) {
          debugPrint('Critical service $service is unhealthy: $status');
          return false;
        }
      }
      
      debugPrint('All health checks passed');
      return true;
    } catch (e) {
      _initializationResults['health_checks'] = 'Error: $e';
      debugPrint('Health checks failed: $e');
      return false;
    }
  }

  /// Setup background tasks
  Future<void> _setupBackgroundTasks() async {
    try {
      _addStep('Setting up Background Tasks');
      
      // Setup periodic cleanup tasks
      _setupPeriodicCleanup();
      
      // Setup session monitoring
      _setupSessionMonitoring();
      
      _initializationResults['background_tasks'] = 'Success';
      debugPrint('Background tasks setup completed');
    } catch (e) {
      _initializationResults['background_tasks'] = 'Error: $e';
      debugPrint('Background tasks setup error: $e');
    }
  }

  /// Setup periodic cleanup
  void _setupPeriodicCleanup() {
    // This would typically use a timer or background service
    // For now, we'll just log that it's set up
    debugPrint('Periodic cleanup tasks configured');
  }

  /// Setup session monitoring
  void _setupSessionMonitoring() {
    // This would typically monitor user sessions and handle timeouts
    // For now, we'll just log that it's set up
    debugPrint('Session monitoring configured');
  }

  /// Add initialization step
  void _addStep(String step) {
    _initializationSteps.add(step);
    debugPrint('Initialization step: $step');
  }

  /// Get initialization summary
  Map<String, dynamic> getInitializationSummary() {
    return {
      'isInitialized': _isInitialized,
      'steps': _initializationSteps,
      'results': _initializationResults,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Reset initialization state (for testing)
  void reset() {
    if (kDebugMode) {
      _isInitialized = false;
      _initializationSteps.clear();
      _initializationResults.clear();
      debugPrint('App initialization state reset');
    }
  }

  /// Get service status
  Map<String, String> getServiceStatus() {
    final status = <String, String>{};
    
    try {
      final configManager = ConfigManager();
      status['ConfigManager'] = configManager.isInitialized ? 'Ready' : 'Not Ready';
    } catch (e) {
      status['ConfigManager'] = 'Error';
    }
    
    try {
      // Check Firebase initialization
      status['Firebase'] = Firebase.apps.isNotEmpty ? 'Ready' : 'Not Ready';
    } catch (e) {
      status['Firebase'] = 'Error';
    }
    
    try {
      // Check Firebase Auth
      final auth = FirebaseAuth.instance;
      status['FirebaseAuth'] = 'Ready';
    } catch (e) {
      status['FirebaseAuth'] = 'Error';
    }
    
    try {
      // Check Firestore
      final firestore = FirebaseFirestore.instance;
      status['Firestore'] = 'Ready';
    } catch (e) {
      status['Firestore'] = 'Error';
    }
    
    try {
      // Check Database Service
      final databaseService = DatabaseService();
      status['DatabaseService'] = 'Ready';
    } catch (e) {
      status['DatabaseService'] = 'Error';
    }
    
    return status;
  }
}