/// Models for Hyperlocal Farmer Proximity Clustering & Produce Pooling
class FarmerClusterMember {
  final String farmerId;
  final String name;
  final String farmName;
  final String village;
  final double distance; // km from cluster hub
  final double pooledKg;
  final String signatureType;
  final bool isDigiLocker;
  final String? signatureUrl;
  final String certId;
  final double rating;
  final double lat;
  final double lng;

  const FarmerClusterMember({
    required this.farmerId,
    required this.name,
    required this.farmName,
    required this.village,
    required this.distance,
    required this.pooledKg,
    required this.signatureType,
    this.isDigiLocker = true,
    this.signatureUrl,
    required this.certId,
    this.rating = 4.9,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'name': name,
      'farmName': farmName,
      'village': village,
      'distance': distance,
      'pooledKg': pooledKg,
      'signatureType': signatureType,
      'isDigiLocker': isDigiLocker,
      'signatureUrl': signatureUrl,
      'certId': certId,
      'rating': rating,
      'lat': lat,
      'lng': lng,
    };
  }

  factory FarmerClusterMember.fromMap(Map<String, dynamic> map) {
    return FarmerClusterMember(
      farmerId: map['farmerId']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Farmer',
      farmName: map['farmName']?.toString() ?? 'Family Farm',
      village: map['village']?.toString() ?? map['location']?.toString() ?? 'Local Belt',
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      pooledKg: (map['pooledKg'] as num?)?.toDouble() ?? (map['quantity'] as num?)?.toDouble() ?? 100.0,
      signatureType: map['signatureType']?.toString() ?? (map['isDigiLocker'] == true ? 'DigiLocker Aadhaar e-Sign' : 'Uploaded Signature Verified'),
      isDigiLocker: map['isDigiLocker'] as bool? ?? true,
      signatureUrl: map['signatureUrl']?.toString(),
      certId: map['certId']?.toString() ?? 'DL-ESIGN-${map['farmerId'] ?? 'CERT'}',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.9,
      lat: (map['lat'] as num?)?.toDouble() ?? 29.6857,
      lng: (map['lng'] as num?)?.toDouble() ?? 76.9905,
    );
  }
}

class FarmerCluster {
  final String id;
  final String crop;
  final String imageEmoji;
  final String imageUrl;
  final String variety;
  final String grade;
  final String hubLocation;
  final double hubLat;
  final double hubLng;
  final double maxInterFarmDistance; // km
  final String clusterRadius;
  final int totalFarms;
  final double wholesalePrice; // ₹/kg
  final double retailMarketPrice; // ₹/kg
  final double availableStockKg;
  final double minOrderKg;
  final double defaultOrderKg;
  final Map<String, dynamic> conditions;
  final List<FarmerClusterMember> farmers;
  final bool isRealData;

  const FarmerCluster({
    required this.id,
    required this.crop,
    this.imageEmoji = '🌾',
    this.imageUrl = '',
    required this.variety,
    required this.grade,
    required this.hubLocation,
    required this.hubLat,
    required this.hubLng,
    required this.maxInterFarmDistance,
    required this.clusterRadius,
    required this.totalFarms,
    required this.wholesalePrice,
    required this.retailMarketPrice,
    required this.availableStockKg,
    this.minOrderKg = 5.0,
    this.defaultOrderKg = 25.0,
    required this.conditions,
    required this.farmers,
    this.isRealData = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'crop': crop,
      'imageEmoji': imageEmoji,
      'imageUrl': imageUrl,
      'variety': variety,
      'grade': grade,
      'hubLocation': hubLocation,
      'hubLat': hubLat,
      'hubLng': hubLng,
      'maxInterFarmDistance': maxInterFarmDistance,
      'clusterRadius': clusterRadius,
      'totalFarms': totalFarms,
      'wholesalePrice': wholesalePrice,
      'retailMarketPrice': retailMarketPrice,
      'availableStockKg': availableStockKg,
      'minOrderKg': minOrderKg,
      'defaultOrderKg': defaultOrderKg,
      'conditions': conditions,
      'farmers': farmers.map((f) => f.toMap()).toList(),
      'isRealData': isRealData,
    };
  }

  factory FarmerCluster.fromMap(Map<String, dynamic> map) {
    final rawFarmers = map['farmers'] as List<dynamic>? ?? [];
    final farmersList = rawFarmers.map((f) => FarmerClusterMember.fromMap(f as Map<String, dynamic>)).toList();

    return FarmerCluster(
      id: map['id']?.toString() ?? 'CLUSTER-${DateTime.now().millisecondsSinceEpoch}',
      crop: map['crop']?.toString() ?? 'Fresh Produce',
      imageEmoji: map['imageEmoji']?.toString() ?? '🌾',
      imageUrl: map['imageUrl']?.toString() ?? '',
      variety: map['variety']?.toString() ?? 'Certified Quality',
      grade: map['grade']?.toString() ?? 'Grade 1',
      hubLocation: map['hubLocation']?.toString() ?? 'Karnal Agri Hub, Haryana',
      hubLat: (map['hubLat'] as num?)?.toDouble() ?? 29.6857,
      hubLng: (map['hubLng'] as num?)?.toDouble() ?? 76.9905,
      maxInterFarmDistance: (map['maxInterFarmDistance'] as num?)?.toDouble() ?? 4.5,
      clusterRadius: map['clusterRadius']?.toString() ?? '≤ 5 km Radius',
      totalFarms: (map['totalFarms'] as num?)?.toInt() ?? farmersList.length,
      wholesalePrice: (map['wholesalePrice'] as num?)?.toDouble() ?? 30.0,
      retailMarketPrice: (map['retailMarketPrice'] as num?)?.toDouble() ?? 45.0,
      availableStockKg: (map['availableStockKg'] as num?)?.toDouble() ?? 1000.0,
      minOrderKg: (map['minOrderKg'] as num?)?.toDouble() ?? 5.0,
      defaultOrderKg: (map['defaultOrderKg'] as num?)?.toDouble() ?? 25.0,
      conditions: (map['conditions'] as Map<String, dynamic>?) ?? {},
      farmers: farmersList,
      isRealData: map['isRealData'] as bool? ?? false,
    );
  }
}
