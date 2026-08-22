import 'package:cloud_firestore/cloud_firestore.dart';

class CropNFT {
  final String id;
  final String tokenId;
  final String ownerAddress;
  final String ownerName;
  final String ownerFirebaseUid;
  final CropDetails cropDetails;
  final HarvestData harvestData;
  final QualityAssurance qualityAssurance;
  final String ipfsHash;
  final String contractAddress;
  final DateTime mintedAt;
  final bool isCollateralized;
  final String? activeLoanId;
  final List<TransferHistory> transferHistory;
  final Map<String, dynamic> metadata;

  CropNFT({
    required this.id,
    required this.tokenId,
    required this.ownerAddress,
    required this.ownerName,
    required this.ownerFirebaseUid,
    required this.cropDetails,
    required this.harvestData,
    required this.qualityAssurance,
    required this.ipfsHash,
    required this.contractAddress,
    required this.mintedAt,
    this.isCollateralized = false,
    this.activeLoanId,
    this.transferHistory = const [],
    this.metadata = const {},
  });

  factory CropNFT.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CropNFT(
      id: doc.id,
      tokenId: data['tokenId'] ?? '',
      ownerAddress: data['ownerAddress'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerFirebaseUid: data['ownerFirebaseUid'] ?? '',
      cropDetails: CropDetails.fromMap(data['cropDetails'] ?? {}),
      harvestData: HarvestData.fromMap(data['harvestData'] ?? {}),
      qualityAssurance: QualityAssurance.fromMap(data['qualityAssurance'] ?? {}),
      ipfsHash: data['ipfsHash'] ?? '',
      contractAddress: data['contractAddress'] ?? '',
      mintedAt: (data['mintedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCollateralized: data['isCollateralized'] ?? false,
      activeLoanId: data['activeLoanId'],
      transferHistory: (data['transferHistory'] as List<dynamic>?)
              ?.map((e) => TransferHistory.fromMap(e))
              .toList() ??
          [],
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tokenId': tokenId,
      'ownerAddress': ownerAddress,
      'ownerName': ownerName,
      'ownerFirebaseUid': ownerFirebaseUid,
      'cropDetails': cropDetails.toMap(),
      'harvestData': harvestData.toMap(),
      'qualityAssurance': qualityAssurance.toMap(),
      'ipfsHash': ipfsHash,
      'contractAddress': contractAddress,
      'mintedAt': Timestamp.fromDate(mintedAt),
      'isCollateralized': isCollateralized,
      'activeLoanId': activeLoanId,
      'transferHistory': transferHistory.map((e) => e.toMap()).toList(),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toNFTMetadata() {
    return {
      'name': 'Crop Certificate #$tokenId',
      'description': 'Digital certificate for ${cropDetails.cropName} harvest - ${harvestData.quantity} ${harvestData.unit}',
      'image': 'https://ipfs.io/ipfs/$ipfsHash',
      'external_url': 'https://agrichain.app/crop/$tokenId',
      'attributes': [
        {'trait_type': 'Crop Name', 'value': cropDetails.cropName},
        {'trait_type': 'Variety', 'value': cropDetails.variety},
        {'trait_type': 'Quantity', 'value': '${harvestData.quantity} ${harvestData.unit}'},
        {'trait_type': 'Quality Grade', 'value': qualityAssurance.qualityGrade},
        {'trait_type': 'Harvest Date', 'value': harvestData.harvestDate.toIso8601String().split('T')[0]},
        {'trait_type': 'Farm Location', 'value': cropDetails.farmLocation},
        {'trait_type': 'Farming Method', 'value': cropDetails.farmingMethod},
        {'trait_type': 'Organic Certified', 'value': qualityAssurance.isOrganicCertified ? 'Yes' : 'No'},
        {'trait_type': 'Market Value', 'value': '₹${harvestData.estimatedValue.toStringAsFixed(0)}'},
        {'trait_type': 'Collateralized', 'value': isCollateralized ? 'Yes' : 'No'},
      ],
      'properties': {
        'crop_details': cropDetails.toMap(),
        'harvest_data': harvestData.toMap(),
        'quality_assurance': qualityAssurance.toMap(),
      },
    };
  }

  double get collateralValue {
    // Calculate collateral value based on market value and quality factors
    double baseValue = harvestData.estimatedValue;
    double qualityMultiplier = _getQualityMultiplier();
    double organicBonus = qualityAssurance.isOrganicCertified ? 1.15 : 1.0;
    
    return baseValue * qualityMultiplier * organicBonus;
  }

  double _getQualityMultiplier() {
    switch (qualityAssurance.qualityGrade.toUpperCase()) {
      case 'A+':
        return 1.2;
      case 'A':
        return 1.1;
      case 'B+':
        return 1.0;
      case 'B':
        return 0.9;
      case 'C':
        return 0.8;
      default:
        return 1.0;
    }
  }
}

class CropDetails {
  final String cropName;
  final String variety;
  final String category; // Grains, Vegetables, Fruits, etc.
  final String farmLocation;
  final String farmingMethod; // Organic, Conventional, Hydroponic
  final DateTime plantingDate;
  final String seedSource;
  final List<String> fertilizersUsed;
  final List<String> pesticidesUsed;
  final String irrigationMethod;
  final double farmAreaUsed; // in acres
  final String soilType;
  final Map<String, dynamic> weatherConditions;

  CropDetails({
    required this.cropName,
    required this.variety,
    required this.category,
    required this.farmLocation,
    required this.farmingMethod,
    required this.plantingDate,
    required this.seedSource,
    required this.fertilizersUsed,
    required this.pesticidesUsed,
    required this.irrigationMethod,
    required this.farmAreaUsed,
    required this.soilType,
    required this.weatherConditions,
  });

  factory CropDetails.fromMap(Map<String, dynamic> map) {
    return CropDetails(
      cropName: map['cropName'] ?? '',
      variety: map['variety'] ?? '',
      category: map['category'] ?? '',
      farmLocation: map['farmLocation'] ?? '',
      farmingMethod: map['farmingMethod'] ?? '',
      plantingDate: map['plantingDate'] != null
          ? DateTime.parse(map['plantingDate'])
          : DateTime.now(),
      seedSource: map['seedSource'] ?? '',
      fertilizersUsed: List<String>.from(map['fertilizersUsed'] ?? []),
      pesticidesUsed: List<String>.from(map['pesticidesUsed'] ?? []),
      irrigationMethod: map['irrigationMethod'] ?? '',
      farmAreaUsed: (map['farmAreaUsed'] ?? 0.0).toDouble(),
      soilType: map['soilType'] ?? '',
      weatherConditions: Map<String, dynamic>.from(map['weatherConditions'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cropName': cropName,
      'variety': variety,
      'category': category,
      'farmLocation': farmLocation,
      'farmingMethod': farmingMethod,
      'plantingDate': plantingDate.toIso8601String(),
      'seedSource': seedSource,
      'fertilizersUsed': fertilizersUsed,
      'pesticidesUsed': pesticidesUsed,
      'irrigationMethod': irrigationMethod,
      'farmAreaUsed': farmAreaUsed,
      'soilType': soilType,
      'weatherConditions': weatherConditions,
    };
  }
}

class HarvestData {
  final DateTime harvestDate;
  final double quantity;
  final String unit; // kg, tons, quintals
  final double yieldPerAcre;
  final double estimatedValue;
  final String storageLocation;
  final String storageMethod;
  final DateTime? expiryDate;
  final List<String> harvestImages; // IPFS hashes
  final Map<String, dynamic> nutritionalInfo;
  final String harvestConditions;

  HarvestData({
    required this.harvestDate,
    required this.quantity,
    required this.unit,
    required this.yieldPerAcre,
    required this.estimatedValue,
    required this.storageLocation,
    required this.storageMethod,
    this.expiryDate,
    required this.harvestImages,
    required this.nutritionalInfo,
    required this.harvestConditions,
  });

  factory HarvestData.fromMap(Map<String, dynamic> map) {
    return HarvestData(
      harvestDate: map['harvestDate'] != null
          ? DateTime.parse(map['harvestDate'])
          : DateTime.now(),
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      yieldPerAcre: (map['yieldPerAcre'] ?? 0.0).toDouble(),
      estimatedValue: (map['estimatedValue'] ?? 0.0).toDouble(),
      storageLocation: map['storageLocation'] ?? '',
      storageMethod: map['storageMethod'] ?? '',
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'])
          : null,
      harvestImages: List<String>.from(map['harvestImages'] ?? []),
      nutritionalInfo: Map<String, dynamic>.from(map['nutritionalInfo'] ?? {}),
      harvestConditions: map['harvestConditions'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'harvestDate': harvestDate.toIso8601String(),
      'quantity': quantity,
      'unit': unit,
      'yieldPerAcre': yieldPerAcre,
      'estimatedValue': estimatedValue,
      'storageLocation': storageLocation,
      'storageMethod': storageMethod,
      'expiryDate': expiryDate?.toIso8601String(),
      'harvestImages': harvestImages,
      'nutritionalInfo': nutritionalInfo,
      'harvestConditions': harvestConditions,
    };
  }
}

class QualityAssurance {
  final String qualityGrade; // A+, A, B+, B, C
  final bool isOrganicCertified;
  final String? organicCertificationBody;
  final String? organicCertificateNumber;
  final List<QualityTest> qualityTests;
  final String? thirdPartyInspection;
  final DateTime? inspectionDate;
  final String? inspectorName;
  final List<String> certificationDocuments; // IPFS hashes
  final Map<String, dynamic> labResults;
  final bool pesticideResidueTest;
  final bool heavyMetalTest;
  final bool microbiologyTest;

  QualityAssurance({
    required this.qualityGrade,
    required this.isOrganicCertified,
    this.organicCertificationBody,
    this.organicCertificateNumber,
    required this.qualityTests,
    this.thirdPartyInspection,
    this.inspectionDate,
    this.inspectorName,
    required this.certificationDocuments,
    required this.labResults,
    required this.pesticideResidueTest,
    required this.heavyMetalTest,
    required this.microbiologyTest,
  });

  factory QualityAssurance.fromMap(Map<String, dynamic> map) {
    return QualityAssurance(
      qualityGrade: map['qualityGrade'] ?? '',
      isOrganicCertified: map['isOrganicCertified'] ?? false,
      organicCertificationBody: map['organicCertificationBody'],
      organicCertificateNumber: map['organicCertificateNumber'],
      qualityTests: (map['qualityTests'] as List<dynamic>?)
              ?.map((e) => QualityTest.fromMap(e))
              .toList() ??
          [],
      thirdPartyInspection: map['thirdPartyInspection'],
      inspectionDate: map['inspectionDate'] != null
          ? DateTime.parse(map['inspectionDate'])
          : null,
      inspectorName: map['inspectorName'],
      certificationDocuments: List<String>.from(map['certificationDocuments'] ?? []),
      labResults: Map<String, dynamic>.from(map['labResults'] ?? {}),
      pesticideResidueTest: map['pesticideResidueTest'] ?? false,
      heavyMetalTest: map['heavyMetalTest'] ?? false,
      microbiologyTest: map['microbiologyTest'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'qualityGrade': qualityGrade,
      'isOrganicCertified': isOrganicCertified,
      'organicCertificationBody': organicCertificationBody,
      'organicCertificateNumber': organicCertificateNumber,
      'qualityTests': qualityTests.map((e) => e.toMap()).toList(),
      'thirdPartyInspection': thirdPartyInspection,
      'inspectionDate': inspectionDate?.toIso8601String(),
      'inspectorName': inspectorName,
      'certificationDocuments': certificationDocuments,
      'labResults': labResults,
      'pesticideResidueTest': pesticideResidueTest,
      'heavyMetalTest': heavyMetalTest,
      'microbiologyTest': microbiologyTest,
    };
  }
}

class QualityTest {
  final String testType;
  final String result;
  final DateTime testDate;
  final String testingLab;
  final String certificateHash; // IPFS hash

  QualityTest({
    required this.testType,
    required this.result,
    required this.testDate,
    required this.testingLab,
    required this.certificateHash,
  });

  factory QualityTest.fromMap(Map<String, dynamic> map) {
    return QualityTest(
      testType: map['testType'] ?? '',
      result: map['result'] ?? '',
      testDate: DateTime.parse(map['testDate']),
      testingLab: map['testingLab'] ?? '',
      certificateHash: map['certificateHash'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'testType': testType,
      'result': result,
      'testDate': testDate.toIso8601String(),
      'testingLab': testingLab,
      'certificateHash': certificateHash,
    };
  }
}

class TransferHistory {
  final String fromAddress;
  final String toAddress;
  final DateTime timestamp;
  final String transactionHash;
  final String transferType; // Sale, Gift, Inheritance, Loan Collateral
  final double? transferValue;

  TransferHistory({
    required this.fromAddress,
    required this.toAddress,
    required this.timestamp,
    required this.transactionHash,
    required this.transferType,
    this.transferValue,
  });

  factory TransferHistory.fromMap(Map<String, dynamic> map) {
    return TransferHistory(
      fromAddress: map['fromAddress'] ?? '',
      toAddress: map['toAddress'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      transactionHash: map['transactionHash'] ?? '',
      transferType: map['transferType'] ?? '',
      transferValue: map['transferValue']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'timestamp': timestamp.toIso8601String(),
      'transactionHash': transactionHash,
      'transferType': transferType,
      'transferValue': transferValue,
    };
  }
}