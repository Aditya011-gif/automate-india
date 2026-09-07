import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Model representing a bulk buyer's verified food processing plant, silo, or warehouse.
/// Used for precision road routing, ULIP toll tracking, and escrow delivery settlements.
class BuyerDeliveryPlant {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final bool isPrimary;
  final String corridorName;

  const BuyerDeliveryPlant({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.isPrimary = false,
    this.corridorName = 'National Highway Corridor',
  });

  BuyerDeliveryPlant copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    bool? isPrimary,
    String? corridorName,
  }) {
    return BuyerDeliveryPlant(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPrimary: isPrimary ?? this.isPrimary,
      corridorName: corridorName ?? this.corridorName,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'address': address,
    'city': city,
    'state': state,
    'latitude': latitude,
    'longitude': longitude,
    'isPrimary': isPrimary,
    'corridorName': corridorName,
  };

  factory BuyerDeliveryPlant.fromMap(Map<String, dynamic> map) => BuyerDeliveryPlant(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    address: map['address'] ?? '',
    city: map['city'] ?? '',
    state: map['state'] ?? '',
    latitude: (map['latitude'] as num?)?.toDouble() ?? 28.8785,
    longitude: (map['longitude'] as num?)?.toDouble() ?? 77.1275,
    isPrimary: map['isPrimary'] == true,
    corridorName: map['corridorName'] ?? 'National Highway Corridor',
  );

  static const String _prefKey = 'agrichain_buyer_saved_plants';

  /// Default verified processing facilities and silos for bulk buyer profile
  static List<BuyerDeliveryPlant> defaultBuyerPlants() => const [
    BuyerDeliveryPlant(
      id: 'PLANT-KUNDLI',
      name: 'Kundli Food Processing Terminal',
      address: 'Phase IV, Kundli Industrial Area, Sonipat, Haryana',
      city: 'Sonipat',
      state: 'Haryana',
      latitude: 28.8785,
      longitude: 77.1275,
      isPrimary: true,
      corridorName: 'NH-44 North Corridor (Haryana)',
    ),
    BuyerDeliveryPlant(
      id: 'PLANT-PUNE',
      name: 'Pune Main Processing Facility',
      address: 'Plot 42, MIDC Chakan, Pune, Maharashtra',
      city: 'Pune',
      state: 'Maharashtra',
      latitude: 18.7606,
      longitude: 73.8567,
      isPrimary: false,
      corridorName: 'NH-48 Inter-State West Corridor',
    ),
    BuyerDeliveryPlant(
      id: 'PLANT-BHIWANDI',
      name: 'Bhiwandi Central Silo & Storage',
      address: 'Warehouse Bay 12, Bhiwandi, Thane, Maharashtra',
      city: 'Bhiwandi',
      state: 'Maharashtra',
      latitude: 19.2967,
      longitude: 73.0631,
      isPrimary: false,
      corridorName: 'Western Dedicated Freight Corridor',
    ),
    BuyerDeliveryPlant(
      id: 'PLANT-NAGPUR',
      name: 'Nagpur Dal & Oil Mill',
      address: 'Agro Industrial Park, Butibori, Nagpur, Maharashtra',
      city: 'Nagpur',
      state: 'Maharashtra',
      latitude: 20.9238,
      longitude: 78.9806,
      isPrimary: false,
      corridorName: 'NH-44 Central India Corridor',
    ),
  ];

  /// Loads saved plants from SharedPreferences, or returns defaults
  static Future<List<BuyerDeliveryPlant>> loadSavedPlants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        final plants = list.map((item) => BuyerDeliveryPlant.fromMap(Map<String, dynamic>.from(item as Map))).toList();
        if (plants.isNotEmpty) return plants;
      }
    } catch (_) {}
    return defaultBuyerPlants();
  }

  /// Persists the list of plants to SharedPreferences
  static Future<void> savePlants(List<BuyerDeliveryPlant> plants) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(plants.map((p) => p.toMap()).toList());
      await prefs.setString(_prefKey, jsonStr);
    } catch (_) {}
  }

  /// Sets a specific plant as primary and saves
  static Future<List<BuyerDeliveryPlant>> setPrimary(String plantId) async {
    final plants = await loadSavedPlants();
    final updated = plants.map((p) => p.copyWith(isPrimary: p.id == plantId)).toList();
    await savePlants(updated);
    return updated;
  }
}
