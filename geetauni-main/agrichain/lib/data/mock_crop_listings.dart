import '../models/firestore_models.dart';

/// Mock crop listings with current market prices
/// These listings can be used for demonstration and testing purposes
class MockCropListings {
  static List<FirestoreCrop> getMockCrops() {
    final now = DateTime.now();
    
    return [
      // Wheat Listing - ₹2,665/quintal
      FirestoreCrop(
        id: 'wheat_001',
        name: 'Premium Wheat',
        farmerId: 'farmer_001',
        farmerName: 'Rajesh Kumar',
        location: 'Haryana, India',
        price: 26.65, // ₹2,665/quintal = ₹26.65/kg
        quantity: '50 quintals',
        harvestDate: now.subtract(const Duration(days: 15)),
        imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400',
        description: 'High-quality wheat harvested from fertile fields of Haryana. Excellent protein content and suitable for making premium flour.',
        isNFT: false,
        biddingType: BiddingType.fixedPrice,
        cropType: CropType.wheat,
        category: CropCategory.grains,
        certifications: [
          {
            'type': 'Organic',
            'certifiedBy': 'India Organic Certification Agency',
            'validUntil': now.add(const Duration(days: 365)).toIso8601String(),
          }
        ],
        qualityGrade: QualityGrade.premium,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
        isActive: true,
      ),

      // Paddy Listing - ₹2,280/quintal  
      FirestoreCrop(
        id: 'paddy_001',
        name: 'Basmati Paddy',
        farmerId: 'farmer_002',
        farmerName: 'Priya Sharma',
        location: 'Punjab, India',
        price: 22.80, // ₹2,280/quintal = ₹22.80/kg
        quantity: '75 quintals',
        harvestDate: now.subtract(const Duration(days: 20)),
        imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400',
        description: 'Premium Basmati paddy with excellent aroma and long grain characteristics. Perfect for export quality rice production.',
        isNFT: false,
        biddingType: BiddingType.fixedPrice,
        cropType: CropType.rice,
        category: CropCategory.grains,
        certifications: [
          {
            'type': 'FSSAI',
            'certifiedBy': 'Food Safety and Standards Authority of India',
            'validUntil': now.add(const Duration(days: 300)).toIso8601String(),
          }
        ],
        qualityGrade: QualityGrade.grade1,
        createdAt: now.subtract(const Duration(days: 1)),
        isActive: true,
      ),

      // Maize Listing - ₹1,876/quintal
      FirestoreCrop(
        id: 'maize_001',
        name: 'Yellow Maize',
        farmerId: 'farmer_003',
        farmerName: 'Suresh Patel',
        location: 'Maharashtra, India',
        price: 18.76, // ₹1,876/quintal = ₹18.76/kg
        quantity: '100 quintals',
        harvestDate: now.subtract(const Duration(days: 10)),
        imageUrl: 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=400',
        description: 'Fresh yellow maize with high nutritional value. Suitable for animal feed and food processing industries.',
        isNFT: false,
        biddingType: BiddingType.fixedPrice,
        cropType: CropType.maize,
        category: CropCategory.grains,
        certifications: [
          {
            'type': 'AGMARK',
            'certifiedBy': 'Agricultural Marketing Division',
            'validUntil': now.add(const Duration(days: 180)).toIso8601String(),
          }
        ],
        qualityGrade: QualityGrade.grade1,
        createdAt: now.subtract(const Duration(days: 3)),
        isActive: true,
      ),

      // Potato Listing - ₹1,920/quintal
      FirestoreCrop(
        id: 'potato_001',
        name: 'Fresh Potatoes',
        farmerId: 'farmer_004',
        farmerName: 'Amit Singh',
        location: 'Uttar Pradesh, India',
        price: 19.20, // ₹1,920/quintal = ₹19.20/kg
        quantity: '80 quintals',
        harvestDate: now.subtract(const Duration(days: 5)),
        imageUrl: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400',
        description: 'Fresh, high-quality potatoes with excellent storage life. Perfect for retail and wholesale markets.',
        isNFT: false,
        biddingType: BiddingType.fixedPrice,
        cropType: CropType.potato,
        category: CropCategory.vegetables,
        certifications: [
          {
            'type': 'ISO',
            'certifiedBy': 'International Organization for Standardization',
            'validUntil': now.add(const Duration(days: 120)).toIso8601String(),
          }
        ],
        qualityGrade: QualityGrade.grade1,
        createdAt: now.subtract(const Duration(hours: 18)),
        isActive: true,
      ),

      // Mango Listing - ₹4,750/quintal (using average of ₹4,700-4,800)
      FirestoreCrop(
        id: 'mango_001',
        name: 'Alphonso Mangoes',
        farmerId: 'farmer_005',
        farmerName: 'Ganesh Rao',
        location: 'Maharashtra, India',
        price: 47.50, // ₹4,750/quintal = ₹47.50/kg
        quantity: '25 quintals',
        harvestDate: now.subtract(const Duration(days: 3)),
        imageUrl: 'https://images.unsplash.com/photo-1553279768-865429fa0078?w=400',
        description: 'Premium Alphonso mangoes, known as the "King of Mangoes". Sweet, aromatic, and perfect for export markets.',
        isNFT: false,
        biddingType: BiddingType.fixedPrice,
        cropType: CropType.mango,
        category: CropCategory.fruits,
        certifications: [
          {
            'type': 'Organic',
            'certifiedBy': 'India Organic Certification Agency',
            'validUntil': now.add(const Duration(days: 90)).toIso8601String(),
          },
          {
            'type': 'GMP',
            'certifiedBy': 'Good Manufacturing Practice Certification',
            'validUntil': now.add(const Duration(days: 365)).toIso8601String(),
          }
        ],
        qualityGrade: QualityGrade.premium,
        createdAt: now.subtract(const Duration(hours: 6)),
        isActive: true,
      ),
    ];
  }

  /// Get mock crops by category
  static List<FirestoreCrop> getMockCropsByCategory(CropCategory category) {
    return getMockCrops().where((crop) => crop.category == category).toList();
  }

  /// Get mock crops by type
  static List<FirestoreCrop> getMockCropsByType(CropType type) {
    return getMockCrops().where((crop) => crop.cropType == type).toList();
  }

  /// Get mock crop by ID
  static FirestoreCrop? getMockCropById(String id) {
    try {
      return getMockCrops().firstWhere((crop) => crop.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get mock crops sorted by price
  static List<FirestoreCrop> getMockCropsSortedByPrice({bool ascending = true}) {
    final crops = getMockCrops();
    crops.sort((a, b) => ascending ? a.price.compareTo(b.price) : b.price.compareTo(a.price));
    return crops;
  }

  /// Get mock crops for price comparison
  static Map<String, List<FirestoreCrop>> getMockCropsGroupedByName() {
    final crops = getMockCrops();
    final Map<String, List<FirestoreCrop>> grouped = {};
    
    for (final crop in crops) {
      final name = crop.name.toLowerCase();
      if (!grouped.containsKey(name)) {
        grouped[name] = [];
      }
      grouped[name]!.add(crop);
    }
    
    return grouped;
  }

  /// Get all mock crops (alias for getMockCrops for consistency)
  static List<FirestoreCrop> getAllCrops() {
    return getMockCrops();
  }
}