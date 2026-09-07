/// Model: FPO Organization Profile, Verification & Infrastructure
/// Represents an enterprise agricultural producer company/cooperative selling wholesale to institutional buyers.

enum FpoVerificationStatus {
  pendingVerification,
  verified,
  verificationRequired,
  rejected,
}

enum FpoOrganizationType {
  fpc, // Farmer Producer Company (Companies Act)
  cooperative, // Co-operative Society (State / Multi-State Co-op Act)
  trust,
  federation,
}

class FpoWarehouseFacility {
  final String id;
  final String name;
  final String address;
  final double capacityMT;
  final double occupiedMT;
  final List<String> storageTypes; // e.g. Silo, Ventilated Godown, Cold Bay
  final bool hasWeighbridge;
  final double weighbridgeCapacityTons;
  final double latitude;
  final double longitude;

  const FpoWarehouseFacility({
    required this.id,
    required this.name,
    required this.address,
    required this.capacityMT,
    this.occupiedMT = 0.0,
    required this.storageTypes,
    this.hasWeighbridge = true,
    this.weighbridgeCapacityTons = 60.0,
    required this.latitude,
    required this.longitude,
  });

  double get availableCapacityMT => (capacityMT - occupiedMT).clamp(0.0, capacityMT);

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'address': address,
    'capacityMT': capacityMT,
    'occupiedMT': occupiedMT,
    'storageTypes': storageTypes,
    'hasWeighbridge': hasWeighbridge,
    'weighbridgeCapacityTons': weighbridgeCapacityTons,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory FpoWarehouseFacility.fromMap(Map<String, dynamic> map) => FpoWarehouseFacility(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    address: map['address'] ?? '',
    capacityMT: (map['capacityMT'] as num?)?.toDouble() ?? 500.0,
    occupiedMT: (map['occupiedMT'] as num?)?.toDouble() ?? 0.0,
    storageTypes: List<String>.from(map['storageTypes'] ?? ['Silo', 'Bagged Warehouse']),
    hasWeighbridge: map['hasWeighbridge'] ?? true,
    weighbridgeCapacityTons: (map['weighbridgeCapacityTons'] as num?)?.toDouble() ?? 60.0,
    latitude: (map['latitude'] as num?)?.toDouble() ?? 29.6857,
    longitude: (map['longitude'] as num?)?.toDouble() ?? 76.9905,
  );
}

class FpoKycDocument {
  final String documentType; // e.g. 'Certificate of Incorporation', 'GSTIN Certificate', 'FSSAI License'
  final String documentNumber;
  final String fileUrl;
  final DateTime uploadedAt;
  final bool isVerified;

  const FpoKycDocument({
    required this.documentType,
    required this.documentNumber,
    required this.fileUrl,
    required this.uploadedAt,
    this.isVerified = true,
  });

  Map<String, dynamic> toMap() => {
    'documentType': documentType,
    'documentNumber': documentNumber,
    'fileUrl': fileUrl,
    'uploadedAt': uploadedAt.toIso8601String(),
    'isVerified': isVerified,
  };

  factory FpoKycDocument.fromMap(Map<String, dynamic> map) => FpoKycDocument(
    documentType: map['documentType'] ?? '',
    documentNumber: map['documentNumber'] ?? '',
    fileUrl: map['fileUrl'] ?? '',
    uploadedAt: map['uploadedAt'] != null ? DateTime.tryParse(map['uploadedAt']) ?? DateTime.now() : DateTime.now(),
    isVerified: map['isVerified'] ?? false,
  );
}

class FpoBankAccount {
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String branch;
  final bool isVerifiedForEscrow;

  const FpoBankAccount({
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.branch,
    this.isVerifiedForEscrow = true,
  });

  Map<String, dynamic> toMap() => {
    'accountHolderName': accountHolderName,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'ifscCode': ifscCode,
    'branch': branch,
    'isVerifiedForEscrow': isVerifiedForEscrow,
  };

  factory FpoBankAccount.fromMap(Map<String, dynamic> map) => FpoBankAccount(
    accountHolderName: map['accountHolderName'] ?? '',
    bankName: map['bankName'] ?? '',
    accountNumber: map['accountNumber'] ?? '',
    ifscCode: map['ifscCode'] ?? '',
    branch: map['branch'] ?? '',
    isVerifiedForEscrow: map['isVerifiedForEscrow'] ?? true,
  );
}

class FpoOrganization {
  final String id;
  final String name;
  final FpoOrganizationType organizationType;
  final String registrationNumber; // CIN or Society Reg Number
  final DateTime incorporationDate;
  final String authorizedRepresentativeName;
  final String authorizedRepresentativeDesignation;
  final String mobileNumber;
  final String email;
  final String address;
  final String state;
  final String district;
  final String pinCode;
  final String gstin;
  final String pan;
  final FpoVerificationStatus verificationStatus;
  final FpoBankAccount bankAccount;
  final List<FpoWarehouseFacility> warehouses;
  final List<FpoKycDocument> documents;
  final double rating;
  final int totalInstitutionalOrdersFulfilled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FpoOrganization({
    required this.id,
    required this.name,
    this.organizationType = FpoOrganizationType.fpc,
    required this.registrationNumber,
    required this.incorporationDate,
    required this.authorizedRepresentativeName,
    required this.authorizedRepresentativeDesignation,
    required this.mobileNumber,
    required this.email,
    required this.address,
    required this.state,
    required this.district,
    required this.pinCode,
    required this.gstin,
    required this.pan,
    this.verificationStatus = FpoVerificationStatus.verified,
    required this.bankAccount,
    required this.warehouses,
    this.documents = const [],
    this.rating = 4.9,
    this.totalInstitutionalOrdersFulfilled = 38,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get canPublishListings => verificationStatus == FpoVerificationStatus.verified;

  String get verificationBadgeTitle {
    switch (verificationStatus) {
      case FpoVerificationStatus.verified:
        return 'Verified FPO (SFAC / NABARD)';
      case FpoVerificationStatus.pendingVerification:
        return 'Verification In Progress';
      case FpoVerificationStatus.verificationRequired:
        return 'Verification Required';
      case FpoVerificationStatus.rejected:
        return 'Verification Rejected';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'organizationType': organizationType.name,
    'registrationNumber': registrationNumber,
    'incorporationDate': incorporationDate.toIso8601String(),
    'authorizedRepresentativeName': authorizedRepresentativeName,
    'authorizedRepresentativeDesignation': authorizedRepresentativeDesignation,
    'mobileNumber': mobileNumber,
    'email': email,
    'address': address,
    'state': state,
    'district': district,
    'pinCode': pinCode,
    'gstin': gstin,
    'pan': pan,
    'verificationStatus': verificationStatus.name,
    'bankAccount': bankAccount.toMap(),
    'warehouses': warehouses.map((w) => w.toMap()).toList(),
    'documents': documents.map((d) => d.toMap()).toList(),
    'rating': rating,
    'totalInstitutionalOrdersFulfilled': totalInstitutionalOrdersFulfilled,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory FpoOrganization.fromMap(Map<String, dynamic> map, String id) => FpoOrganization(
    id: id,
    name: map['name'] ?? 'Karnal Agro Producer Co. Ltd.',
    organizationType: FpoOrganizationType.values.firstWhere(
      (e) => e.name == map['organizationType'],
      orElse: () => FpoOrganizationType.fpc,
    ),
    registrationNumber: map['registrationNumber'] ?? 'U01409HR2020PTC088219',
    incorporationDate: map['incorporationDate'] != null ? DateTime.tryParse(map['incorporationDate']) ?? DateTime(2020, 5, 12) : DateTime(2020, 5, 12),
    authorizedRepresentativeName: map['authorizedRepresentativeName'] ?? 'Rajeshwar Swaminathan',
    authorizedRepresentativeDesignation: map['authorizedRepresentativeDesignation'] ?? 'Managing Director & CEO',
    mobileNumber: map['mobileNumber'] ?? '+91 98120 77341',
    email: map['email'] ?? 'ops@karnalagro.org',
    address: map['address'] ?? 'Plot 14, Mandi Complex, GT Road',
    state: map['state'] ?? 'Haryana',
    district: map['district'] ?? 'Karnal',
    pinCode: map['pinCode'] ?? '132001',
    gstin: map['gstin'] ?? '06AAECK9928P1Z4',
    pan: map['pan'] ?? 'AAECK9928P',
    verificationStatus: FpoVerificationStatus.values.firstWhere(
      (e) => e.name == map['verificationStatus'],
      orElse: () => FpoVerificationStatus.verified,
    ),
    bankAccount: map['bankAccount'] != null
        ? FpoBankAccount.fromMap(map['bankAccount'])
        : const FpoBankAccount(
            accountHolderName: 'Karnal Agro Producer Co. Ltd.',
            bankName: 'State Bank of India',
            accountNumber: '3948019280192',
            ifscCode: 'SBIN0001290',
            branch: 'Main Branch, Karnal',
          ),
    warehouses: (map['warehouses'] as List<dynamic>?)
            ?.map((w) => FpoWarehouseFacility.fromMap(w as Map<String, dynamic>))
            .toList() ??
        const [
          FpoWarehouseFacility(
            id: 'WH-KAR-01',
            name: 'Central Silo Depot 01',
            address: 'Industrial Area Sector 3, Karnal',
            capacityMT: 500.0,
            occupiedMT: 200.0,
            storageTypes: ['Temperature-Controlled Concrete Silo', 'Ventilated Bay'],
            hasWeighbridge: true,
            weighbridgeCapacityTons: 60.0,
            latitude: 29.6857,
            longitude: 76.9905,
          ),
        ],
    documents: (map['documents'] as List<dynamic>?)
            ?.map((d) => FpoKycDocument.fromMap(d as Map<String, dynamic>))
            .toList() ??
        [
          FpoKycDocument(
            documentType: 'Certificate of Incorporation',
            documentNumber: 'ROC-DEL-088219',
            fileUrl: 'https://mca.gov.in/certs/088219.pdf',
            uploadedAt: DateTime(2020, 5, 15),
            isVerified: true,
          ),
          FpoKycDocument(
            documentType: 'GSTIN Registration',
            documentNumber: '06AAECK9928P1Z4',
            fileUrl: 'https://gst.gov.in/certs/06AAECK9928P1Z4.pdf',
            uploadedAt: DateTime(2020, 6, 1),
            isVerified: true,
          ),
          FpoKycDocument(
            documentType: 'FSSAI Wholesale License',
            documentNumber: '10020021000941',
            fileUrl: 'https://fssai.gov.in/lic/10020021000941.pdf',
            uploadedAt: DateTime(2021, 2, 10),
            isVerified: true,
          ),
        ],
    rating: (map['rating'] as num?)?.toDouble() ?? 4.9,
    totalInstitutionalOrdersFulfilled: (map['totalInstitutionalOrdersFulfilled'] as num?)?.toInt() ?? 38,
    createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) ?? DateTime.now() : DateTime.now(),
    updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now() : DateTime.now(),
  );
}
