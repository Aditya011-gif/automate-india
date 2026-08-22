import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/land_nft.dart' as land_models;
import '../models/crop_nft.dart' as crop_models;
import 'blockchain_service.dart';

class NFTService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _landNFTCollection = 'land_nfts';
  static const String _cropNFTCollection = 'crop_nfts';
  static const String _nftCollateralCollection = 'nft_collateral';

  // Land NFT Operations
  static Future<Map<String, dynamic>> mintLandNFT({
    required String ownerFirebaseUid,
    required String ownerName,
    required String ownerAddress,
    required land_models.LandDetails landDetails,
    required land_models.LegalDocuments legalDocuments,
    required land_models.ValuationDetails valuation,
    required List<String> documentImages, // Local file paths
  }) async {
    try {
      // Step 1: Upload documents and images to IPFS
      final ipfsResult = await _uploadLandDocumentsToIPFS(
        documentImages: documentImages,
        landDetails: landDetails,
        legalDocuments: legalDocuments,
        valuation: valuation,
      );

      if (!ipfsResult['success']) {
        throw Exception('Failed to upload documents to IPFS');
      }

      // Step 2: Mint NFT on blockchain
      final tokenId = _generateTokenId();
      final nftMetadata = {
        'name': 'Land Certificate #$tokenId',
        'description':
            'Digital certificate for land ownership - ${landDetails.address}',
        'image': ipfsResult['imageHash'],
        'attributes': [
          {'trait_type': 'Land Type', 'value': landDetails.landType},
          {
            'trait_type': 'Area (Acres)',
            'value': landDetails.areaInAcres.toString(),
          },
          {'trait_type': 'Location', 'value': landDetails.address},
          {'trait_type': 'Survey Number', 'value': landDetails.surveyNumber},
          {
            'trait_type': 'Current Valuation',
            'value': '₹${valuation.currentValue.toStringAsFixed(0)}',
          },
        ],
      };

      final blockchainResult = await BlockchainService.mintCropNFT(
        cropName: 'Land Certificate',
        farmerAddress: ownerAddress,
        ipfsHash: ipfsResult['metadataHash'],
        metadata: nftMetadata,
      );

      if (!blockchainResult['success']) {
        throw Exception('Failed to mint NFT on blockchain');
      }

      // Step 3: Create LandNFT object
      final landNFT = land_models.LandNFT(
        id: '', // Will be set by Firestore
        tokenId: tokenId,
        ownerAddress: ownerAddress,
        ownerName: ownerName,
        ownerFirebaseUid: ownerFirebaseUid,
        landDetails: landDetails,
        legalDocuments: legalDocuments,
        valuation: valuation,
        ipfsHash: ipfsResult['metadataHash'],
        contractAddress: blockchainResult['contractAddress'],
        mintedAt: DateTime.now(),
      );

      // Step 4: Save to Firestore
      final docRef = await _firestore
          .collection(_landNFTCollection)
          .add(landNFT.toFirestore());

      return {
        'success': true,
        'nftId': docRef.id,
        'tokenId': tokenId,
        'transactionHash': blockchainResult['transactionHash'],
        'contractAddress': blockchainResult['contractAddress'],
        'ipfsHash': ipfsResult['metadataHash'],
        'estimatedValue': valuation.currentValue,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Crop NFT Operations
  static Future<Map<String, dynamic>> mintCropNFT({
    required String ownerFirebaseUid,
    required String ownerName,
    required String ownerAddress,
    required crop_models.CropDetails cropDetails,
    required crop_models.HarvestData harvestData,
    required crop_models.QualityAssurance qualityAssurance,
    required List<String> cropImages, // Local file paths
  }) async {
    try {
      // Step 1: Upload crop images and data to IPFS
      final ipfsResult = await _uploadCropDataToIPFS(
        cropImages: cropImages,
        cropDetails: cropDetails,
        harvestData: harvestData,
        qualityAssurance: qualityAssurance,
      );

      if (!ipfsResult['success']) {
        throw Exception('Failed to upload crop data to IPFS');
      }

      // Step 2: Mint NFT on blockchain
      final tokenId = _generateTokenId();
      final nftMetadata = {
        'name': 'Crop Certificate #$tokenId',
        'description':
            'Digital certificate for ${cropDetails.cropName} harvest',
        'image': ipfsResult['imageHash'],
        'attributes': [
          {'trait_type': 'Crop Name', 'value': cropDetails.cropName},
          {
            'trait_type': 'Quantity',
            'value': '${harvestData.quantity} ${harvestData.unit}',
          },
          {
            'trait_type': 'Quality Grade',
            'value': qualityAssurance.qualityGrade,
          },
          {
            'trait_type': 'Harvest Date',
            'value': harvestData.harvestDate.toIso8601String().split('T')[0],
          },
          {
            'trait_type': 'Organic Certified',
            'value': qualityAssurance.isOrganicCertified ? 'Yes' : 'No',
          },
        ],
      };

      final blockchainResult = await BlockchainService.mintCropNFT(
        cropName: cropDetails.cropName,
        farmerAddress: ownerAddress,
        ipfsHash: ipfsResult['metadataHash'],
        metadata: nftMetadata,
      );

      if (!blockchainResult['success']) {
        throw Exception('Failed to mint NFT on blockchain');
      }

      // Step 3: Create CropNFT object
      final cropNFT = crop_models.CropNFT(
        id: '', // Will be set by Firestore
        tokenId: tokenId,
        ownerAddress: ownerAddress,
        ownerName: ownerName,
        ownerFirebaseUid: ownerFirebaseUid,
        cropDetails: cropDetails,
        harvestData: harvestData,
        qualityAssurance: qualityAssurance,
        ipfsHash: ipfsResult['metadataHash'],
        contractAddress: blockchainResult['contractAddress'],
        mintedAt: DateTime.now(),
      );

      // Step 4: Save to Firestore
      final docRef = await _firestore
          .collection(_cropNFTCollection)
          .add(cropNFT.toFirestore());

      return {
        'success': true,
        'nftId': docRef.id,
        'tokenId': tokenId,
        'transactionHash': blockchainResult['transactionHash'],
        'contractAddress': blockchainResult['contractAddress'],
        'ipfsHash': ipfsResult['metadataHash'],
        'estimatedValue': harvestData.estimatedValue,
        'collateralValue': cropNFT.collateralValue,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Collateral Management
  static Future<Map<String, dynamic>> useAsCollateral({
    required String nftId,
    required String nftType, // 'land' or 'crop'
    required String loanId,
    required double loanAmount,
  }) async {
    try {
      final collection = nftType == 'land'
          ? _landNFTCollection
          : _cropNFTCollection;

      // Step 1: Get NFT details
      final nftDoc = await _firestore.collection(collection).doc(nftId).get();
      if (!nftDoc.exists) {
        throw Exception('NFT not found');
      }

      final nftData = nftDoc.data()!;
      if (nftData['isCollateralized'] == true) {
        throw Exception('NFT is already used as collateral');
      }

      // Step 2: Calculate collateral value
      double collateralValue;
      if (nftType == 'land') {
        final landNFT = land_models.LandNFT.fromFirestore(nftDoc);
        collateralValue = landNFT.valuation.currentValue;
      } else {
        final cropNFT = crop_models.CropNFT.fromFirestore(nftDoc);
        collateralValue = cropNFT.collateralValue;
      }

      // Step 3: Validate loan amount against collateral value
      final maxLoanAmount = collateralValue * 0.8; // 80% LTV ratio
      if (loanAmount > maxLoanAmount) {
        throw Exception(
          'Loan amount exceeds maximum allowed (80% of collateral value)',
        );
      }

      // Step 4: Lock NFT as collateral on blockchain
      final blockchainResult = await BlockchainService.applyForLoan(
        borrowerAddress: nftData['ownerAddress'],
        loanAmount: loanAmount,
        collateralNFTId: nftData['tokenId'],
        durationDays: 365, // Default 1 year
      );

      if (!blockchainResult['success']) {
        throw Exception('Failed to lock collateral on blockchain');
      }

      // Step 5: Update NFT status
      await _firestore.collection(collection).doc(nftId).update({
        'isCollateralized': true,
        'activeLoanId': loanId,
      });

      // Step 6: Create collateral record
      await _firestore.collection(_nftCollateralCollection).add({
        'nftId': nftId,
        'nftType': nftType,
        'tokenId': nftData['tokenId'],
        'loanId': loanId,
        'ownerFirebaseUid': nftData['ownerFirebaseUid'],
        'collateralValue': collateralValue,
        'loanAmount': loanAmount,
        'ltvRatio': loanAmount / collateralValue,
        'lockedAt': Timestamp.now(),
        'blockchainTxHash': blockchainResult['transactionHash'],
        'status': 'locked',
      });

      return {
        'success': true,
        'collateralValue': collateralValue,
        'ltvRatio': loanAmount / collateralValue,
        'transactionHash': blockchainResult['transactionHash'],
        'maxLoanAmount': maxLoanAmount,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> releaseCollateral({
    required String nftId,
    required String nftType,
    required String loanId,
  }) async {
    try {
      final collection = nftType == 'land'
          ? _landNFTCollection
          : _cropNFTCollection;

      // Step 1: Get NFT and collateral details
      final nftDoc = await _firestore.collection(collection).doc(nftId).get();
      if (!nftDoc.exists) {
        throw Exception('NFT not found');
      }

      final collateralQuery = await _firestore
          .collection(_nftCollateralCollection)
          .where('nftId', isEqualTo: nftId)
          .where('loanId', isEqualTo: loanId)
          .where('status', isEqualTo: 'locked')
          .get();

      if (collateralQuery.docs.isEmpty) {
        throw Exception('Collateral record not found');
      }

      final collateralDoc = collateralQuery.docs.first;
      final collateralData = collateralDoc.data();

      // Step 2: Release collateral on blockchain
      final blockchainResult = await BlockchainService.repayLoan(
        loanId: loanId,
        amount: collateralData['loanAmount'],
        borrowerAddress: nftDoc.data()!['ownerAddress'],
      );

      if (!blockchainResult['success']) {
        throw Exception('Failed to release collateral on blockchain');
      }

      // Step 3: Update NFT status
      await _firestore.collection(collection).doc(nftId).update({
        'isCollateralized': false,
        'activeLoanId': null,
      });

      // Step 4: Update collateral record
      await _firestore
          .collection(_nftCollateralCollection)
          .doc(collateralDoc.id)
          .update({
            'status': 'released',
            'releasedAt': Timestamp.now(),
            'releaseTxHash': blockchainResult['transactionHash'],
          });

      return {
        'success': true,
        'transactionHash': blockchainResult['transactionHash'],
        'releasedAt': DateTime.now(),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Query Operations
  static Future<List<land_models.LandNFT>> getUserLandNFTs(
    String firebaseUid,
  ) async {
    final querySnapshot = await _firestore
        .collection(_landNFTCollection)
        .where('ownerFirebaseUid', isEqualTo: firebaseUid)
        .orderBy('mintedAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => land_models.LandNFT.fromFirestore(doc))
        .toList();
  }

  static Future<List<crop_models.CropNFT>> getUserCropNFTs(
    String firebaseUid,
  ) async {
    final querySnapshot = await _firestore
        .collection(_cropNFTCollection)
        .where('ownerFirebaseUid', isEqualTo: firebaseUid)
        .orderBy('mintedAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => crop_models.CropNFT.fromFirestore(doc))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getAvailableCollateral(
    String firebaseUid,
  ) async {
    final landNFTs = await getUserLandNFTs(firebaseUid);
    final cropNFTs = await getUserCropNFTs(firebaseUid);

    List<Map<String, dynamic>> availableCollateral = [];

    // Add available land NFTs
    for (final landNFT in landNFTs) {
      if (!landNFT.isCollateralized) {
        availableCollateral.add({
          'id': landNFT.id,
          'type': 'land',
          'tokenId': landNFT.tokenId,
          'name': 'Land Certificate #${landNFT.tokenId}',
          'description': landNFT.landDetails.address,
          'value': landNFT.valuation.currentValue,
          'maxLoanAmount': landNFT.valuation.currentValue * 0.8,
          'area': '${landNFT.landDetails.areaInAcres} acres',
          'location': landNFT.landDetails.address,
        });
      }
    }

    // Add available crop NFTs
    for (final cropNFT in cropNFTs) {
      if (!cropNFT.isCollateralized) {
        availableCollateral.add({
          'id': cropNFT.id,
          'type': 'crop',
          'tokenId': cropNFT.tokenId,
          'name': 'Crop Certificate #${cropNFT.tokenId}',
          'description':
              '${cropNFT.cropDetails.cropName} - ${cropNFT.harvestData.quantity} ${cropNFT.harvestData.unit}',
          'value': cropNFT.collateralValue,
          'maxLoanAmount': cropNFT.collateralValue * 0.7, // Lower LTV for crops
          'quantity':
              '${cropNFT.harvestData.quantity} ${cropNFT.harvestData.unit}',
          'quality': cropNFT.qualityAssurance.qualityGrade,
        });
      }
    }

    return availableCollateral;
  }

  // Helper Methods
  static Future<Map<String, dynamic>> _uploadLandDocumentsToIPFS({
    required List<String> documentImages,
    required land_models.LandDetails landDetails,
    required land_models.LegalDocuments legalDocuments,
    required land_models.ValuationDetails valuation,
  }) async {
    // Simulate IPFS upload
    await Future.delayed(const Duration(seconds: 2));

    final metadata = {
      'land_details': landDetails.toMap(),
      'legal_documents': legalDocuments.toMap(),
      'valuation': valuation.toMap(),
      'document_images': documentImages
          .map((path) => _generateIPFSHash())
          .toList(),
    };

    return {
      'success': true,
      'metadataHash': _generateIPFSHash(),
      'imageHash': _generateIPFSHash(),
      'documentHashes': documentImages
          .map((path) => _generateIPFSHash())
          .toList(),
    };
  }

  static Future<Map<String, dynamic>> _uploadCropDataToIPFS({
    required List<String> cropImages,
    required crop_models.CropDetails cropDetails,
    required crop_models.HarvestData harvestData,
    required crop_models.QualityAssurance qualityAssurance,
  }) async {
    // Simulate IPFS upload
    await Future.delayed(const Duration(seconds: 2));

    final metadata = {
      'crop_details': cropDetails.toMap(),
      'harvest_data': harvestData.toMap(),
      'quality_assurance': qualityAssurance.toMap(),
      'crop_images': cropImages.map((path) => _generateIPFSHash()).toList(),
    };

    return {
      'success': true,
      'metadataHash': _generateIPFSHash(),
      'imageHash': _generateIPFSHash(),
      'imageHashes': cropImages.map((path) => _generateIPFSHash()).toList(),
    };
  }

  static String _generateTokenId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return '$timestamp$random';
  }

  static String _generateIPFSHash() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return 'Qm${List.generate(44, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  // NFT Transfer Operations
  static Future<Map<String, dynamic>> transferNFT({
    required String nftId,
    required String nftType,
    required String fromAddress,
    required String toAddress,
    required String toFirebaseUid,
    required String transferType,
    double? transferValue,
  }) async {
    try {
      final collection = nftType == 'land'
          ? _landNFTCollection
          : _cropNFTCollection;

      // Step 1: Get NFT details
      final nftDoc = await _firestore.collection(collection).doc(nftId).get();
      if (!nftDoc.exists) {
        throw Exception('NFT not found');
      }

      final nftData = nftDoc.data()!;
      if (nftData['isCollateralized'] == true) {
        throw Exception('Cannot transfer collateralized NFT');
      }

      // Step 2: Transfer on blockchain
      final blockchainResult = await BlockchainService.transferNFT(
        tokenId: nftData['tokenId'],
        fromAddress: fromAddress,
        toAddress: toAddress,
        nftType: nftType,
      );

      if (!blockchainResult['success']) {
        throw Exception('Failed to transfer NFT on blockchain');
      }

      // Step 3: Update ownership in Firestore
      await _firestore.collection(collection).doc(nftId).update({
        'ownerAddress': toAddress,
        'ownerFirebaseUid': toFirebaseUid,
      });

      // Step 4: Add transfer history
      final transferHistory = crop_models.TransferHistory(
        fromAddress: fromAddress,
        toAddress: toAddress,
        timestamp: DateTime.now(),
        transactionHash: blockchainResult['transactionHash'],
        transferType: transferType,
        transferValue: transferValue,
      );

      await _firestore.collection(collection).doc(nftId).update({
        'transferHistory': FieldValue.arrayUnion([transferHistory.toMap()]),
      });

      return {
        'success': true,
        'transactionHash': blockchainResult['transactionHash'],
        'transferredAt': DateTime.now(),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
