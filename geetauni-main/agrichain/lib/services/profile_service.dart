import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'security_service.dart';
import 'firebase_service.dart';

class ProfileService {
  final DatabaseService _databaseService = DatabaseService();
  final SecurityService _securityService = SecurityService();
  final FirebaseService _firebaseService = FirebaseService();

  /// Complete user profile setup
  Future<Map<String, dynamic>> completeProfile({
    required String userId,
    required String userType,
    required String address,
    required String city,
    required String state,
    required String pincode,
    String? farmSize,
    String? cropTypes,
    String? businessType,
    String? gstNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Validate input data
      if (userId.isEmpty ||
          userType.isEmpty ||
          address.isEmpty ||
          city.isEmpty ||
          state.isEmpty ||
          pincode.isEmpty) {
        throw Exception('Required profile fields cannot be empty');
      }

      // Validate pincode format
      if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
        throw Exception('Invalid pincode format');
      }

      // Prepare profile data content
      final profileDataContent = <String, Object>{
        'userType': userType,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'profileCompleted': 1,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Add user type specific data
      if (userType == 'farmer') {
        profileDataContent['farmSize'] = farmSize ?? '';
        profileDataContent['cropTypes'] = cropTypes ?? '';
      } else if (userType == 'buyer') {
        profileDataContent['businessType'] = businessType ?? '';
        profileDataContent['gstNumber'] = gstNumber ?? '';
      }

      // Add additional data if provided
      if (additionalData != null && additionalData.isNotEmpty) {
        // Filter out null values before casting
        final filteredData = <String, Object>{};
        additionalData.forEach((key, value) {
          if (value != null) {
            filteredData[key] = value;
          }
        });
        profileDataContent.addAll(filteredData);
      }

      // Encrypt sensitive data
      if (gstNumber != null && gstNumber.isNotEmpty) {
        profileDataContent['gstNumber'] = await _securityService.encryptData(
          gstNumber,
        );
      }

      // Prepare database record according to schema
      final profileRecord = <String, dynamic>{
        'id': _generateId(),
        'userId': userId,
        'profileData': jsonEncode(profileDataContent),
        'isComplete': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Save to database
      await _databaseService.createProfileData(profileRecord);

      // Sync profile data to Firebase
      try {
        debugPrint('🔄 Starting Firebase profile sync for user: $userId');
        debugPrint(
          '🔄 Profile data being synced: ${profileDataContent.toString()}',
        );

        final firebaseResult = await _firebaseService.createProfileData(
          userId: userId,
          profileData: profileDataContent,
        );

        debugPrint('🔄 Firebase profile sync result: $firebaseResult');

        if (firebaseResult) {
          debugPrint('✅ Profile synced to Firebase successfully');
        } else {
          debugPrint('❌ Firebase profile sync failed');
          // Continue with local profile creation even if Firebase sync fails
        }
      } catch (e) {
        debugPrint('❌ Firebase profile sync error: $e');
        // Continue with local profile creation even if Firebase sync fails
      }

      if (kDebugMode) {
        print('Profile completed successfully for user: $userId');
      }

      return {
        'success': true,
        'message': 'Profile completed successfully',
        'profileData': profileDataContent,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error completing profile: $e');
      }

      return {
        'success': false,
        'message': 'Failed to complete profile: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final profileRecord = await _databaseService.getProfileDataByUserId(
        userId,
      );

      if (profileRecord == null || profileRecord['profileData'] == null) {
        return null;
      }

      // Parse profile data from JSON
      Map<String, dynamic> profileData;
      try {
        profileData = jsonDecode(profileRecord['profileData']);
      } catch (e) {
        debugPrint('Error parsing profile data JSON: $e');
        return null;
      }

      // Decrypt sensitive data if present
      if (profileData['gstNumber'] != null &&
          profileData['gstNumber'].toString().isNotEmpty) {
        try {
          profileData['gstNumber'] = await _securityService.decryptData(
            profileData['gstNumber'].toString(),
          );
        } catch (e) {
          debugPrint('Error decrypting GST number: $e');
          // Keep encrypted value if decryption fails
        }
      }

      return profileData;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
      return null;
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> updates,
  ) async {
    try {
      final userId = updates['userId'];
      if (userId == null) {
        throw Exception('User ID is required for profile update');
      }

      // Get existing profile record from database
      final existingProfileRecord = await _databaseService
          .getProfileDataByUserId(userId);
      if (existingProfileRecord == null) {
        throw Exception('Profile not found');
      }

      // Parse existing profile data
      Map<String, dynamic> existingProfileData = {};
      if (existingProfileRecord['profileData'] != null) {
        try {
          existingProfileData = jsonDecode(
            existingProfileRecord['profileData'],
          );
        } catch (e) {
          debugPrint('Error parsing existing profile data: $e');
        }
      }

      // Merge updates with existing profile data
      final updatedProfileData = <String, dynamic>{
        ...existingProfileData,
        ...updates,
      };
      updatedProfileData['updatedAt'] = DateTime.now().toIso8601String();

      // Encrypt sensitive data if present
      if (updates['gstNumber'] != null &&
          updates['gstNumber'].toString().isNotEmpty) {
        updatedProfileData['gstNumber'] = await _securityService.encryptData(
          updates['gstNumber'].toString(),
        );
      }

      // Prepare updated profile record
      final updatedProfileRecord = <String, dynamic>{
        ...existingProfileRecord,
        'profileData': jsonEncode(updatedProfileData),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Save updated profile to local database
      await _databaseService.updateProfileData(userId, updatedProfileRecord);

      // Sync to Firebase
      try {
        debugPrint(
          '🔄 Starting Firebase profile update sync for user: $userId',
        );

        final firebaseResult = await _firebaseService.updateProfileData(
          userId: userId,
          profileData: updatedProfileData,
        );

        if (firebaseResult) {
          debugPrint('✅ Profile updated and synced to Firebase successfully');
        } else {
          debugPrint('❌ Firebase profile update sync failed');
        }
      } catch (e) {
        debugPrint('❌ Firebase profile update sync error: $e');
        // Continue even if Firebase sync fails
      }

      return {
        'success': true,
        'message': 'Profile updated successfully',
        'profileData': updatedProfileData,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile: $e');
      }

      return {
        'success': false,
        'message': 'Failed to update profile: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Check if profile is complete
  Future<bool> isProfileComplete(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile?['profileCompleted'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking profile completion: $e');
      }
      return false;
    }
  }

  /// Validate profile data
  bool validateProfileData(Map<String, dynamic> profileData) {
    final requiredFields = [
      'userId',
      'userType',
      'address',
      'city',
      'state',
      'pincode',
    ];

    for (final field in requiredFields) {
      if (!profileData.containsKey(field) ||
          profileData[field] == null ||
          profileData[field].toString().isEmpty) {
        return false;
      }
    }

    // Validate pincode
    final pincode = profileData['pincode'].toString();
    if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
      return false;
    }

    return true;
  }

  /// Get profile completion percentage
  Future<double> getProfileCompletionPercentage(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return 0.0;

      final requiredFields = [
        'userId',
        'userType',
        'address',
        'city',
        'state',
        'pincode',
      ];
      final optionalFields = [
        'farmSize',
        'cropTypes',
        'businessType',
        'gstNumber',
      ];

      int completedRequired = 0;
      int completedOptional = 0;

      for (final field in requiredFields) {
        if (profile[field] != null && profile[field].toString().isNotEmpty) {
          completedRequired++;
        }
      }

      for (final field in optionalFields) {
        if (profile[field] != null && profile[field].toString().isNotEmpty) {
          completedOptional++;
        }
      }

      // Required fields count for 80%, optional for 20%
      final requiredPercentage =
          (completedRequired / requiredFields.length) * 0.8;
      final optionalPercentage =
          (completedOptional / optionalFields.length) * 0.2;

      return (requiredPercentage + optionalPercentage) * 100;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating profile completion: $e');
      }
      return 0.0;
    }
  }

  /// Generate unique ID for profile records
  String _generateId() {
    return 'PROFILE_${DateTime.now().millisecondsSinceEpoch}';
  }
}
