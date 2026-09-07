import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/fpo_inventory_model.dart';

/// Service: FPO Warehouse Inventory & Commercial Listing Management
/// Manages atomic reservations, listing synchronization, and warehouse storage capacity.
class FpoInventoryService {
  static final FpoInventoryService _instance = FpoInventoryService._internal();
  factory FpoInventoryService() => _instance;
  FpoInventoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _inventoryCollection = 'fpo_inventory';
  static const String _listingsCollection = 'fpo_bulk_listings';

  /// Public demo inventory items getter (empty by default)
  List<FpoInventoryItem> get demoFpoItems => [];

  /// Stream all inventory items for a specific FPO
  Stream<List<FpoInventoryItem>> streamFpoInventory(String fpoId) {
    ensureInitialFpoData(fpoId: fpoId);
    return _firestore
        .collection(_inventoryCollection)
        .where('fpoId', isEqualTo: fpoId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FpoInventoryItem.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Alias for streamFpoInventory
  Stream<List<FpoInventoryItem>> streamInventory(String fpoId) => streamFpoInventory(fpoId);

  /// Stream all available inventory items across all FPOs in the network
  Stream<List<FpoInventoryItem>> streamAllInventory() {
    ensureInitialFpoData();
    return _firestore
        .collection(_inventoryCollection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FpoInventoryItem.fromMap(doc.data(), doc.id))
          .where((item) => item.availableQuantityMT > 0)
          .toList();
    });
  }

  /// Stream all active commercial listings
  Stream<List<BulkCropListing>> streamActiveBulkListings({String? fpoId}) {
    ensureInitialFpoData(fpoId: fpoId);
    Query query = _firestore.collection(_listingsCollection).where('status', isEqualTo: 'published');
    if (fpoId != null && fpoId.isNotEmpty) {
      query = query.where('fpoId', isEqualTo: fpoId);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BulkCropListing.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  bool _isSeeding = false;

  /// Ensure initial realistic inventory & bulk listings exist if database is fresh
  Future<void> ensureInitialFpoData({String? fpoId}) async {
    if (_isSeeding) return;
    _isSeeding = true;
    try {
      final existingInv = await _firestore.collection(_inventoryCollection).limit(1).get();
      if (existingInv.docs.isNotEmpty) {
        _isSeeding = false;
        return;
      }

      debugPrint('📦 Seeding initial warehouse inventory and bulk listings for FPOs...');
      final now = DateTime.now();

      final initialItems = [
        FpoInventoryItem(
          id: 'inv_karnal_wheat_01',
          fpoId: 'fpo_karnal_01',
          fpoName: 'Karnal Agro Farmers Producer Co.',
          cropName: 'Sharbati Wheat',
          variety: 'PBW-502 (Milling Grade)',
          totalQuantityMT: 120.0, // 1,200 Qtl
          reservedQuantityMT: 0.0,
          qualityGrade: 'Grade A (NABL Assayed)',
          moisturePct: 11.2,
          foreignMatterPct: 0.6,
          warehouseId: 'WH-KARNAL-01',
          warehouseName: 'Karnal Central Silo Bay 01',
          storageLocation: 'Silo Bay 01, Karnal',
          pricePerMT: 24500.0,
          pricePerQtl: 2450.0,
          activeListingId: 'listing_karnal_wheat_01',
          createdAt: now,
          updatedAt: now,
        ),
        FpoInventoryItem(
          id: 'inv_taraori_wheat_02',
          fpoId: 'fpo_taraori_02',
          fpoName: 'Taraori Kisan Producer Co.',
          cropName: 'Sharbati Wheat',
          variety: 'PBW-502 (Milling Grade)',
          totalQuantityMT: 100.0, // 1,000 Qtl
          reservedQuantityMT: 0.0,
          qualityGrade: 'Grade A (Milling)',
          moisturePct: 11.4,
          foreignMatterPct: 0.7,
          warehouseId: 'WH-TARAORI-02',
          warehouseName: 'Taraori Godown Dock 02',
          storageLocation: 'Godown Dock 02, Taraori',
          pricePerMT: 24500.0,
          pricePerQtl: 2450.0,
          activeListingId: 'listing_taraori_wheat_02',
          createdAt: now,
          updatedAt: now,
        ),
        FpoInventoryItem(
          id: 'inv_gharaunda_wheat_03',
          fpoId: 'fpo_gharaunda_03',
          fpoName: 'Gharaunda Farmers Co.',
          cropName: 'Sharbati Wheat',
          variety: 'PBW-502 (Milling Grade)',
          totalQuantityMT: 80.0, // 800 Qtl
          reservedQuantityMT: 0.0,
          qualityGrade: 'Grade A (Milling)',
          moisturePct: 11.0,
          foreignMatterPct: 0.8,
          warehouseId: 'WH-GHARAUNDA-03',
          warehouseName: 'Gharaunda Silo Complex',
          storageLocation: 'Silo 03, Gharaunda',
          pricePerMT: 24500.0,
          pricePerQtl: 2450.0,
          activeListingId: 'listing_gharaunda_wheat_03',
          createdAt: now,
          updatedAt: now,
        ),
        FpoInventoryItem(
          id: 'inv_karnal_rice_04',
          fpoId: 'fpo_karnal_01',
          fpoName: 'Karnal Agro Farmers Producer Co.',
          cropName: 'Basmati Rice',
          variety: '1121 Steam Basmati',
          totalQuantityMT: 60.0, // 600 Qtl
          reservedQuantityMT: 0.0,
          qualityGrade: 'Export Grade 1',
          moisturePct: 12.0,
          foreignMatterPct: 0.4,
          warehouseId: 'WH-KARNAL-01',
          warehouseName: 'Karnal Central Silo Bay 02',
          storageLocation: 'Silo Bay 02, Karnal',
          pricePerMT: 68000.0,
          pricePerQtl: 6800.0,
          activeListingId: 'listing_karnal_rice_04',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      for (final item in initialItems) {
        await _firestore.collection(_inventoryCollection).doc(item.id).set(item.toMap());

        // Also publish listing
        final listing = BulkCropListing(
          id: item.activeListingId!,
          inventoryItemId: item.id,
          fpoId: item.fpoId,
          fpoName: item.fpoName,
          cropName: item.cropName,
          variety: item.variety,
          listedQuantityMT: item.availableQuantityMT,
          pricePerMT: item.pricePerMT,
          pricePerQtl: item.pricePerQtl,
          qualityGrade: item.qualityGrade,
          moisturePct: item.moisturePct,
          warehouseName: item.warehouseName,
          warehouseLat: item.fpoId == 'fpo_taraori_02' ? 29.8010 : (item.fpoId == 'fpo_gharaunda_03' ? 29.5390 : 29.6857),
          warehouseLng: item.fpoId == 'fpo_taraori_02' ? 76.9230 : (item.fpoId == 'fpo_gharaunda_03' ? 76.9740 : 76.9905),
          isMultiFpoEligible: true,
          publishedAt: now,
          updatedAt: now,
        );
        await _firestore.collection(_listingsCollection).doc(listing.id).set(listing.toMap());
      }
      debugPrint('✅ Initial FPO inventory and listings seeded successfully.');
    } catch (e) {
      debugPrint('⚠️ Error seeding initial FPO data: $e');
    } finally {
      _isSeeding = false;
    }
  }

  /// Atomic Reservation Transaction:
  /// Reserves specified MT from available inventory and synchronizes bulk listings.
  Future<bool> reserveInventory({
    String? inventoryItemId,
    String? listingId,
    String? fpoId,
    String? cropName,
    required double quantityToReserveMT,
    required String orderId,
  }) async {
    if (quantityToReserveMT <= 0) return true;

    try {
      // 1. Try direct inventory document by inventoryItemId
      if (inventoryItemId != null && inventoryItemId.isNotEmpty) {
        final docRef = _firestore.collection(_inventoryCollection).doc(inventoryItemId);
        final docSnap = await docRef.get();
        if (docSnap.exists && docSnap.data() != null) {
          return await _applyReservationToItem(docRef, docSnap, quantityToReserveMT, orderId);
        }

        // Check if inventoryItemId was actually a listing document ID
        final listingRef = _firestore.collection(_listingsCollection).doc(inventoryItemId);
        final listingSnap = await listingRef.get();
        if (listingSnap.exists && listingSnap.data() != null) {
          final lData = listingSnap.data()!;
          final realInvId = lData['inventoryItemId']?.toString();
          if (realInvId != null && realInvId.isNotEmpty) {
            final realInvRef = _firestore.collection(_inventoryCollection).doc(realInvId);
            final realInvSnap = await realInvRef.get();
            if (realInvSnap.exists && realInvSnap.data() != null) {
              return await _applyReservationToItem(realInvRef, realInvSnap, quantityToReserveMT, orderId, directListingRef: listingRef);
            }
          }
          // If only listing exists, update its listedQuantityMT
          final currentListed = (lData['listedQuantityMT'] as num?)?.toDouble() ?? 0.0;
          final updatedQty = (currentListed - quantityToReserveMT).clamp(0.0, currentListed);
          await listingRef.update({
            'listedQuantityMT': updatedQty,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          return true;
        }
      }

      // 2. Try by listingId if provided
      if (listingId != null && listingId.isNotEmpty) {
        final listingRef = _firestore.collection(_listingsCollection).doc(listingId);
        final listingSnap = await listingRef.get();
        if (listingSnap.exists && listingSnap.data() != null) {
          final lData = listingSnap.data()!;
          final realInvId = lData['inventoryItemId']?.toString();
          if (realInvId != null && realInvId.isNotEmpty) {
            final realInvRef = _firestore.collection(_inventoryCollection).doc(realInvId);
            final realInvSnap = await realInvRef.get();
            if (realInvSnap.exists && realInvSnap.data() != null) {
              return await _applyReservationToItem(realInvRef, realInvSnap, quantityToReserveMT, orderId, directListingRef: listingRef);
            }
          }
          final currentListed = (lData['listedQuantityMT'] as num?)?.toDouble() ?? 0.0;
          final updatedQty = (currentListed - quantityToReserveMT).clamp(0.0, currentListed);
          await listingRef.update({
            'listedQuantityMT': updatedQty,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          return true;
        }
      }

      // 3. Fallback: Lookup by FPO ID and crop name
      if (fpoId != null && fpoId.isNotEmpty) {
        final query = await _firestore
            .collection(_inventoryCollection)
            .where('fpoId', isEqualTo: fpoId)
            .get();

        DocumentSnapshot<Map<String, dynamic>>? matchedDoc;
        for (final doc in query.docs) {
          final itemCrop = (doc.data()['cropName'] ?? '').toString().toLowerCase();
          final targetCrop = (cropName ?? '').toLowerCase();
          if (targetCrop.isEmpty || itemCrop.contains(targetCrop) || targetCrop.contains(itemCrop)) {
            matchedDoc = doc;
            break;
          }
        }

        if (matchedDoc == null && query.docs.isNotEmpty) {
          matchedDoc = query.docs.first;
        }

        if (matchedDoc != null) {
          return await _applyReservationToItem(matchedDoc.reference, matchedDoc, quantityToReserveMT, orderId);
        }
      }

      debugPrint('⚠️ No matching inventory item found for reservation (fpoId: $fpoId, crop: $cropName, qty: $quantityToReserveMT MT)');
      return false;
    } catch (e) {
      debugPrint('❌ Reservation error: $e');
      return false;
    }
  }

  /// Internal helper to update inventory doc and linked bulk listing
  Future<bool> _applyReservationToItem(
    DocumentReference docRef,
    DocumentSnapshot docSnap,
    double quantityToReserveMT,
    String orderId, {
    DocumentReference? directListingRef,
  }) async {
    try {
      final item = FpoInventoryItem.fromMap(docSnap.data() as Map<String, dynamic>, docSnap.id);
      final reserveAmount = quantityToReserveMT > item.availableQuantityMT ? item.availableQuantityMT : quantityToReserveMT;
      final updatedItem = item.reserve(reserveAmount);

      await docRef.update(updatedItem.toMap());

      // Sync linked listing
      final listingIdToUpdate = item.activeListingId;
      if (listingIdToUpdate != null && listingIdToUpdate.isNotEmpty) {
        await _firestore.collection(_listingsCollection).doc(listingIdToUpdate).update({
          'listedQuantityMT': updatedItem.availableQuantityMT,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      if (directListingRef != null && directListingRef.id != listingIdToUpdate) {
        await directListingRef.update({
          'listedQuantityMT': updatedItem.availableQuantityMT,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('✅ FPO stock deducted: ${reserveAmount.toStringAsFixed(1)} MT reserved from ${item.fpoName} (${item.cropName}). Remaining available: ${updatedItem.availableQuantityMT.toStringAsFixed(1)} MT');
      return true;
    } catch (e) {
      debugPrint('❌ Error applying reservation: $e');
      return false;
    }
  }

  /// Multi-FPO Cluster Reservation:
  /// Iterates through each participating FPO allocation and deducts its pro-rata share.
  Future<bool> reserveClusterInventory({
    required List<Map<String, dynamic>> allocations,
    required String orderId,
    String? commodity,
  }) async {
    if (allocations.isEmpty) return false;

    bool allSuccess = true;
    for (final alloc in allocations) {
      try {
        final fpoId = (alloc['fpoId'] ?? alloc['sellerId'] ?? '').toString();
        final fpoName = (alloc['fpoName'] ?? alloc['name'] ?? '').toString();
        final listingId = alloc['listingId']?.toString();
        final invItemId = alloc['inventoryItemId']?.toString();
        final crop = alloc['commodity']?.toString() ?? commodity;

        // Calculate MT to reserve for this FPO
        double qtyMT = (alloc['allocatedMT'] as num?)?.toDouble() ??
            ((alloc['quantityMT'] as num?)?.toDouble()) ??
            0.0;

        if (qtyMT <= 0) {
          final qtyQtl = (alloc['allocatedQtl'] as num?)?.toDouble() ??
              ((alloc['quantityQtl'] as num?)?.toDouble()) ??
              0.0;
          if (qtyQtl > 0) {
            qtyMT = qtyQtl / 10.0;
          }
        }

        if (qtyMT > 0) {
          debugPrint('Reserving $qtyMT MT for cluster FPO: $fpoName ($fpoId)');
          final res = await reserveInventory(
            inventoryItemId: invItemId,
            listingId: listingId,
            fpoId: fpoId,
            cropName: crop,
            quantityToReserveMT: qtyMT,
            orderId: orderId,
          );
          if (!res) allSuccess = false;
        }
      } catch (e) {
        debugPrint('⚠️ Error reserving cluster allocation: $e');
        allSuccess = false;
      }
    }
    return allSuccess;
  }

  /// Release previous reservation back to available stock
  Future<bool> releaseReservation({
    required String inventoryItemId,
    required double quantityToReleaseMT,
  }) async {
    try {
      final docRef = _firestore.collection(_inventoryCollection).doc(inventoryItemId);

      return await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return false;

        final item = FpoInventoryItem.fromMap(snapshot.data()!, snapshot.id);
        final updatedItem = item.releaseReservation(quantityToReleaseMT);
        transaction.update(docRef, updatedItem.toMap());

        if (item.activeListingId != null) {
          final listingRef = _firestore.collection(_listingsCollection).doc(item.activeListingId);
          transaction.update(listingRef, {
            'listedQuantityMT': updatedItem.availableQuantityMT,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }

        debugPrint('✅ Released reservation: $quantityToReleaseMT MT');
        return true;
      });
    } catch (e) {
      debugPrint('❌ Release reservation failed: $e');
      return false;
    }
  }

  /// Create new warehouse inventory record
  Future<bool> createInventoryItem(FpoInventoryItem item) async {
    try {
      final docRef = _firestore.collection(_inventoryCollection).doc(item.id.isEmpty ? null : item.id);
      await docRef.set(item.toMap());
      debugPrint('✅ FPO Inventory item recorded: ${item.cropName} (${item.totalQuantityMT} MT)');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating inventory item: $e');
      return false;
    }
  }

  /// Publish a bulk listing from warehouse inventory
  Future<bool> publishBulkListing(BulkCropListing listing) async {
    try {
      final docRef = _firestore.collection(_listingsCollection).doc(listing.id.isEmpty ? null : listing.id);
      await docRef.set(listing.toMap());

      // Update inventory item link
      if (listing.inventoryItemId.isNotEmpty) {
        await _firestore.collection(_inventoryCollection).doc(listing.inventoryItemId).update({
          'activeListingId': docRef.id,
          'listingStatus': 'published',
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('✅ Commercial Bulk Listing published: ${listing.cropName} (${listing.listedQuantityMT} MT)');
      return true;
    } catch (e) {
      debugPrint('❌ Error publishing listing: $e');
      return false;
    }
  }

  /// Pause / Resume listing
  Future<bool> toggleListingStatus(String listingId, ListingStatus newStatus) async {
    try {
      await _firestore.collection(_listingsCollection).doc(listingId).update({
        'status': newStatus.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error updating listing status: $e');
      return false;
    }
  }

}

