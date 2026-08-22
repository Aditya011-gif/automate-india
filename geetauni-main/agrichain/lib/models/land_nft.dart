import 'package:cloud_firestore/cloud_firestore.dart';

class LandNFT {
  final String id;
  final String tokenId;
  final String ownerAddress;
  final String ownerName;
  final String ownerFirebaseUid;
  final LandDetails landDetails;
  final LegalDocuments legalDocuments;
  final ValuationDetails valuation;
  final String ipfsHash;
  final String contractAddress;
  final DateTime mintedAt;
  final bool isCollateralized;
  final String? activeLoanId;
  final List<TransferHistory> transferHistory;
  final Map<String, dynamic> metadata;

  LandNFT({
    required this.id,
    required this.tokenId,
    required this.ownerAddress,
    required this.ownerName,
    required this.ownerFirebaseUid,
    required this.landDetails,
    required this.legalDocuments,
    required this.valuation,
    required this.ipfsHash,
    required this.contractAddress,
    required this.mintedAt,
    this.isCollateralized = false,
    this.activeLoanId,
    this.transferHistory = const [],
    this.metadata = const {},
  });

  factory LandNFT.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LandNFT(
      id: doc.id,
      tokenId: data['tokenId'] ?? '',
      ownerAddress: data['ownerAddress'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerFirebaseUid: data['ownerFirebaseUid'] ?? '',
      landDetails: LandDetails.fromMap(data['landDetails'] ?? {}),
      legalDocuments: LegalDocuments.fromMap(data['legalDocuments'] ?? {}),
      valuation: ValuationDetails.fromMap(data['valuation'] ?? {}),
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
      'landDetails': landDetails.toMap(),
      'legalDocuments': legalDocuments.toMap(),
      'valuation': valuation.toMap(),
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
      'name': 'Land Certificate #$tokenId',
      'description': 'Digital certificate for land ownership - ${landDetails.address}',
      'image': 'https://ipfs.io/ipfs/$ipfsHash',
      'external_url': 'https://agrichain.app/land/$tokenId',
      'attributes': [
        {'trait_type': 'Land Type', 'value': landDetails.landType},
        {'trait_type': 'Area (Acres)', 'value': landDetails.areaInAcres.toString()},
        {'trait_type': 'Location', 'value': landDetails.address},
        {'trait_type': 'Survey Number', 'value': landDetails.surveyNumber},
        {'trait_type': 'Soil Type', 'value': landDetails.soilType},
        {'trait_type': 'Water Source', 'value': landDetails.waterSource},
        {'trait_type': 'Current Valuation', 'value': '₹${valuation.currentValue.toStringAsFixed(0)}'},
        {'trait_type': 'Registration Date', 'value': legalDocuments.registrationDate.toIso8601String().split('T')[0]},
        {'trait_type': 'Ownership Type', 'value': legalDocuments.ownershipType},
        {'trait_type': 'Collateralized', 'value': isCollateralized ? 'Yes' : 'No'},
      ],
      'properties': {
        'land_details': landDetails.toMap(),
        'legal_documents': legalDocuments.toMap(),
        'valuation': valuation.toMap(),
      },
    };
  }
}

class LandDetails {
  final String address;
  final String surveyNumber;
  final String subDivision;
  final String village;
  final String district;
  final String state;
  final String pincode;
  final double areaInAcres;
  final String landType; // Agricultural, Residential, Commercial, Industrial
  final String soilType;
  final String waterSource;
  final List<String> boundaries;
  final GeoLocation coordinates;
  final String landUse; // Current use of land
  final bool hasIrrigation;
  final String accessRoad;

  LandDetails({
    required this.address,
    required this.surveyNumber,
    required this.subDivision,
    required this.village,
    required this.district,
    required this.state,
    required this.pincode,
    required this.areaInAcres,
    required this.landType,
    required this.soilType,
    required this.waterSource,
    required this.boundaries,
    required this.coordinates,
    required this.landUse,
    required this.hasIrrigation,
    required this.accessRoad,
  });

  factory LandDetails.fromMap(Map<String, dynamic> map) {
    return LandDetails(
      address: map['address'] ?? '',
      surveyNumber: map['surveyNumber'] ?? '',
      subDivision: map['subDivision'] ?? '',
      village: map['village'] ?? '',
      district: map['district'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      areaInAcres: (map['areaInAcres'] ?? 0.0).toDouble(),
      landType: map['landType'] ?? '',
      soilType: map['soilType'] ?? '',
      waterSource: map['waterSource'] ?? '',
      boundaries: List<String>.from(map['boundaries'] ?? []),
      coordinates: GeoLocation.fromMap(map['coordinates'] ?? {}),
      landUse: map['landUse'] ?? '',
      hasIrrigation: map['hasIrrigation'] ?? false,
      accessRoad: map['accessRoad'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'surveyNumber': surveyNumber,
      'subDivision': subDivision,
      'village': village,
      'district': district,
      'state': state,
      'pincode': pincode,
      'areaInAcres': areaInAcres,
      'landType': landType,
      'soilType': soilType,
      'waterSource': waterSource,
      'boundaries': boundaries,
      'coordinates': coordinates.toMap(),
      'landUse': landUse,
      'hasIrrigation': hasIrrigation,
      'accessRoad': accessRoad,
    };
  }
}

class LegalDocuments {
  final String registrationNumber;
  final DateTime registrationDate;
  final String registrarOffice;
  final String ownershipType; // Freehold, Leasehold, Joint
  final List<String> previousOwners;
  final String titleDeedHash; // IPFS hash of title deed
  final String surveySettlementHash; // IPFS hash of survey settlement
  final String encumbranceCertificateHash; // IPFS hash of encumbrance certificate
  final bool hasLegalDisputes;
  final String? disputeDetails;
  final DateTime? disputeResolutionDate;
  final List<String> mortgageDetails;
  final bool isEncumbered;

  LegalDocuments({
    required this.registrationNumber,
    required this.registrationDate,
    required this.registrarOffice,
    required this.ownershipType,
    required this.previousOwners,
    required this.titleDeedHash,
    required this.surveySettlementHash,
    required this.encumbranceCertificateHash,
    required this.hasLegalDisputes,
    this.disputeDetails,
    this.disputeResolutionDate,
    required this.mortgageDetails,
    required this.isEncumbered,
  });

  factory LegalDocuments.fromMap(Map<String, dynamic> map) {
    return LegalDocuments(
      registrationNumber: map['registrationNumber'] ?? '',
      registrationDate: map['registrationDate'] != null
          ? DateTime.parse(map['registrationDate'])
          : DateTime.now(),
      registrarOffice: map['registrarOffice'] ?? '',
      ownershipType: map['ownershipType'] ?? '',
      previousOwners: List<String>.from(map['previousOwners'] ?? []),
      titleDeedHash: map['titleDeedHash'] ?? '',
      surveySettlementHash: map['surveySettlementHash'] ?? '',
      encumbranceCertificateHash: map['encumbranceCertificateHash'] ?? '',
      hasLegalDisputes: map['hasLegalDisputes'] ?? false,
      disputeDetails: map['disputeDetails'],
      disputeResolutionDate: map['disputeResolutionDate'] != null
          ? DateTime.parse(map['disputeResolutionDate'])
          : null,
      mortgageDetails: List<String>.from(map['mortgageDetails'] ?? []),
      isEncumbered: map['isEncumbered'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'registrationNumber': registrationNumber,
      'registrationDate': registrationDate.toIso8601String(),
      'registrarOffice': registrarOffice,
      'ownershipType': ownershipType,
      'previousOwners': previousOwners,
      'titleDeedHash': titleDeedHash,
      'surveySettlementHash': surveySettlementHash,
      'encumbranceCertificateHash': encumbranceCertificateHash,
      'hasLegalDisputes': hasLegalDisputes,
      'disputeDetails': disputeDetails,
      'disputeResolutionDate': disputeResolutionDate?.toIso8601String(),
      'mortgageDetails': mortgageDetails,
      'isEncumbered': isEncumbered,
    };
  }
}

class ValuationDetails {
  final double currentValue;
  final DateTime valuationDate;
  final String valuationMethod; // Market, Income, Cost
  final String valuedBy; // Government, Private Appraiser, Bank
  final String valuationCertificateHash; // IPFS hash
  final double marketRate; // Per acre
  final double guidanceValue; // Government guidance value
  final List<ValuationHistory> history;
  final Map<String, double> comparableProperties;

  ValuationDetails({
    required this.currentValue,
    required this.valuationDate,
    required this.valuationMethod,
    required this.valuedBy,
    required this.valuationCertificateHash,
    required this.marketRate,
    required this.guidanceValue,
    required this.history,
    required this.comparableProperties,
  });

  factory ValuationDetails.fromMap(Map<String, dynamic> map) {
    return ValuationDetails(
      currentValue: (map['currentValue'] ?? 0.0).toDouble(),
      valuationDate: map['valuationDate'] != null
          ? DateTime.parse(map['valuationDate'])
          : DateTime.now(),
      valuationMethod: map['valuationMethod'] ?? '',
      valuedBy: map['valuedBy'] ?? '',
      valuationCertificateHash: map['valuationCertificateHash'] ?? '',
      marketRate: (map['marketRate'] ?? 0.0).toDouble(),
      guidanceValue: (map['guidanceValue'] ?? 0.0).toDouble(),
      history: (map['history'] as List<dynamic>?)
              ?.map((e) => ValuationHistory.fromMap(e))
              .toList() ??
          [],
      comparableProperties: Map<String, double>.from(map['comparableProperties'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentValue': currentValue,
      'valuationDate': valuationDate.toIso8601String(),
      'valuationMethod': valuationMethod,
      'valuedBy': valuedBy,
      'valuationCertificateHash': valuationCertificateHash,
      'marketRate': marketRate,
      'guidanceValue': guidanceValue,
      'history': history.map((e) => e.toMap()).toList(),
      'comparableProperties': comparableProperties,
    };
  }
}

class ValuationHistory {
  final double value;
  final DateTime date;
  final String method;
  final String valuedBy;

  ValuationHistory({
    required this.value,
    required this.date,
    required this.method,
    required this.valuedBy,
  });

  factory ValuationHistory.fromMap(Map<String, dynamic> map) {
    return ValuationHistory(
      value: (map['value'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date']),
      method: map['method'] ?? '',
      valuedBy: map['valuedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'date': date.toIso8601String(),
      'method': method,
      'valuedBy': valuedBy,
    };
  }
}

class GeoLocation {
  final double latitude;
  final double longitude;
  final double? altitude;

  GeoLocation({
    required this.latitude,
    required this.longitude,
    this.altitude,
  });

  factory GeoLocation.fromMap(Map<String, dynamic> map) {
    return GeoLocation(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      altitude: map['altitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
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