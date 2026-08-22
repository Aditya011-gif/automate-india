import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'mock_crop_listings.dart';
import 'mock_loan_offers.dart';

class MockDataInitializer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cropsCollection = 'crops';
  static const String _loanOffersCollection = 'loan_offers';

  /// Initialize mock crop data in Firebase
  static Future<bool> initializeMockCrops() async {
    try {
      debugPrint('🌱 Starting mock crop data initialization...');
      
      // Get mock crops
      final mockCrops = MockCropListings.getAllCrops();
      
      // Check if mock data already exists and remove it for fresh initialization
      final existingCrops = await _firestore
          .collection(_cropsCollection)
          .where('description', isEqualTo: 'Mock listing for testing purposes')
          .get();
      
      if (existingCrops.docs.isNotEmpty) {
        debugPrint('📋 Removing existing mock crop data for fresh initialization...');
        for (final doc in existingCrops.docs) {
          await doc.reference.delete();
        }
        debugPrint('✅ Existing mock data removed.');
      }
      
      // Add each mock crop to Firebase
      for (final crop in mockCrops) {
        final cropData = crop.toFirestore();
        
        // Generate a new document reference
        final docRef = _firestore.collection(_cropsCollection).doc();
        
        // Update the crop data with the generated ID
        cropData['id'] = docRef.id;
        
        // Add to Firebase
        await docRef.set(cropData);
        
        debugPrint('✅ Added mock crop: ${crop.name} - ₹${crop.price}/quintal');
      }
      
      debugPrint('🎉 Mock crop data initialization completed successfully!');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error initializing mock crop data: $e');
      return false;
    }
  }

  /// Remove all mock crop data from Firebase
  static Future<bool> removeMockCrops() async {
    try {
      debugPrint('🗑️ Removing mock crop data...');
      
      // Find all mock crops
      final mockCrops = await _firestore
          .collection(_cropsCollection)
          .where('description', isEqualTo: 'Mock listing for testing purposes')
          .get();
      
      // Delete each mock crop
      for (final doc in mockCrops.docs) {
        await doc.reference.delete();
        debugPrint('🗑️ Removed mock crop: ${doc.id}');
      }
      
      debugPrint('✅ Mock crop data removal completed!');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error removing mock crop data: $e');
      return false;
    }
  }

  /// Check if mock data exists
  static Future<bool> mockDataExists() async {
    try {
      final existingCrops = await _firestore
          .collection(_cropsCollection)
          .where('description', isEqualTo: 'Mock listing for testing purposes')
          .get();
      
      return existingCrops.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking mock data existence: $e');
      return false;
    }
  }

  /// Initialize mock loan offers data in Firebase
  static Future<bool> initializeMockLoanOffers() async {
    try {
      debugPrint('💰 Starting mock loan offers data initialization...');
      
      // Get mock loan offers
      final mockLoanOffers = MockLoanOffers.getAllLoanOffers();
      
      // Check if mock loan offers already exist and remove them for fresh initialization
      final existingOffers = await _firestore
          .collection(_loanOffersCollection)
          .where('description', isEqualTo: 'Mock loan offer for testing purposes')
          .get();
      
      if (existingOffers.docs.isNotEmpty) {
        debugPrint('📋 Removing existing mock loan offers for fresh initialization...');
        for (final doc in existingOffers.docs) {
          await doc.reference.delete();
        }
        debugPrint('✅ Existing mock loan offers removed.');
      }
      
      // Add each mock loan offer to Firebase
      for (final offer in mockLoanOffers) {
        final docRef = _firestore.collection(_loanOffersCollection).doc(offer['id']);
        await docRef.set(offer);
        
        debugPrint('✅ Added mock loan offer: ${offer['buyerName']} - ₹${offer['offeredAmount']} at ${offer['interestRate']}');
      }
      
      debugPrint('🎉 Mock loan offers data initialization completed successfully!');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error initializing mock loan offers data: $e');
      return false;
    }
  }
}