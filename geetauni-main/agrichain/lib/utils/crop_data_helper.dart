import '../models/firestore_models.dart';
import '../providers/app_state.dart';

class CropPricing {
  final double msp;
  final double marketPrice;
  final String unit;
  final String season;

  const CropPricing({
    required this.msp,
    required this.marketPrice,
    required this.unit,
    required this.season,
  });

  factory CropPricing.fromMap(Map<String, dynamic> map) {
    return CropPricing(
      msp: (map['msp'] as num?)?.toDouble() ?? 0.0,
      marketPrice: (map['marketPrice'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? 'per quintal',
      season: map['season'] as String? ?? '2025-26',
    );
  }
}

class CropCertification {
  final CertificationType type;
  final String certificationNumber;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String issuingAuthority;

  const CropCertification({
    required this.type,
    required this.certificationNumber,
    required this.issueDate,
    required this.expiryDate,
    required this.issuingAuthority,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'certificationNumber': certificationNumber,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'issuingAuthority': issuingAuthority,
    };
  }

  factory CropCertification.fromMap(Map<String, dynamic> map) {
    return CropCertification(
      type: CertificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => CertificationType.organic,
      ),
      certificationNumber: map['certificationNumber'] as String? ?? '',
      issueDate: DateTime.parse(map['issueDate'] as String? ?? DateTime.now().toIso8601String()),
      expiryDate: DateTime.parse(map['expiryDate'] as String? ?? DateTime.now().add(Duration(days: 365)).toIso8601String()),
      issuingAuthority: map['issuingAuthority'] as String? ?? '',
    );
  }
}

class CropDataHelper {
  // Static map of crop categories and their associated crop types
  static const Map<CropCategory, List<CropType>> cropCategories = {
    CropCategory.grains: [
      CropType.wheat,
      CropType.rice,
      CropType.maize,
    ],
    CropCategory.vegetables: [
      CropType.potato,
      CropType.tomato,
      CropType.onion,
    ],
    CropCategory.fruits: [
      CropType.mango,
      CropType.apple,
      CropType.banana,
    ],
    CropCategory.oilseeds: [
      CropType.cotton,
      CropType.sugarcane,
    ],
    CropCategory.pulses: [
      CropType.soybean,
    ],
  };

  // Get category for a given crop type
  static CropCategory getCategoryForCropType(CropType cropType) {
    for (final entry in cropCategories.entries) {
      if (entry.value.contains(cropType)) {
        return entry.key;
      }
    }
    return CropCategory.grains; // Default fallback
  }

  static CropPricing? getPricingForCropType(CropType cropType) {
    final pricingData = AppState.cropPricing[cropType];
    if (pricingData == null) return null;
    
    return CropPricing.fromMap(pricingData);
  }

  // Get display name for crop type
  static String getCropDisplayName(CropType cropType) {
    switch (cropType) {
      case CropType.wheat:
        return 'Wheat';
      case CropType.rice:
        return 'Rice';
      case CropType.potato:
        return 'Potato';
      case CropType.tomato:
        return 'Tomato';
      case CropType.onion:
        return 'Onion';
      case CropType.maize:
        return 'Maize';
      case CropType.mango:
        return 'Mango';
      case CropType.apple:
        return 'Apple';
      case CropType.banana:
        return 'Banana';
      case CropType.cotton:
        return 'Cotton';
      case CropType.sugarcane:
        return 'Sugarcane';
      case CropType.soybean:
        return 'Soybean';
    }
  }

  // Get display name for crop category
  static String getCategoryDisplayName(CropCategory category) {
    switch (category) {
      case CropCategory.grains:
        return 'Grains & Cereals';
      case CropCategory.vegetables:
        return 'Vegetables';
      case CropCategory.fruits:
        return 'Fruits';
      case CropCategory.pulses:
        return 'Legumes & Pulses';
      case CropCategory.oilseeds:
        return 'Oilseeds';
      case CropCategory.spices:
        return 'Spices';
    }
  }

  // Get display name for quality grade
  static String getQualityGradeDisplayName(QualityGrade grade) {
    switch (grade) {
      case QualityGrade.premium:
        return 'Premium';
      case QualityGrade.grade1:
        return 'Grade 1';
      case QualityGrade.grade2:
        return 'Grade 2';
      case QualityGrade.standard:
        return 'Standard';
    }
  }

  // Get display name for certification type
  static String getCertificationDisplayName(CertificationType certification) {
    switch (certification) {
      case CertificationType.organic:
        return 'Organic';
      case CertificationType.fssai:
        return 'FSSAI';
      case CertificationType.agmark:
        return 'AGMARK';
      case CertificationType.iso:
        return 'ISO';
      case CertificationType.gmp:
        return 'GMP';
      case CertificationType.haccp:
        return 'HACCP';
    }
  }

  static List<CropType> getCropTypesByCategory(CropCategory category) {
    return CropType.values.where((type) => getCategoryForCropType(type) == category).toList();
  }
}