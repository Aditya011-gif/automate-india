import 'package:flutter/foundation.dart';

/// Tracking Provider Types
enum TrackingProviderType {
  simulatedSpatial, // Demo Mode: OSM geometry + simulated spatial movement & geofence events
  ulipFastag,       // Production Vision: ULIP FASTag VRN-based toll plaza checkpoint events
}

/// Normalized Tracking Event Types
enum TrackingEventType {
  fpoPickup,       // FPO loading & weighment
  tollCrossing,    // FASTag / Geofenced Toll Plaza crossing
  inTransit,       // Road segment movement
  weighment,       // Weighbridge electronic slip verified
  inspection,      // Moisture & quality inspection
  routeDeviation,  // Geofence corridor deviation alert
  delivered,       // Factory gate arrival & delivery
}

/// Route Stop Model (FPOs, Toll Plazas, Processing Silos)
class RouteStop {
  final String id;
  final String name;
  final String type; // 'fpo', 'toll', 'destination'
  final double latitude;
  final double longitude;
  final String locationName;
  final double? plannedQuantityMT;
  final String? slipNumber;
  final bool isCompleted;
  final String? arrivalTime;
  final String? notes;

  const RouteStop({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.plannedQuantityMT,
    this.slipNumber,
    this.isCompleted = false,
    this.arrivalTime,
    this.notes,
  });

  RouteStop copyWith({
    bool? isCompleted,
    String? arrivalTime,
    String? slipNumber,
    String? notes,
  }) {
    return RouteStop(
      id: id,
      name: name,
      type: type,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      plannedQuantityMT: plannedQuantityMT,
      slipNumber: slipNumber ?? this.slipNumber,
      isCompleted: isCompleted ?? this.isCompleted,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      notes: notes ?? this.notes,
    );
  }
}

/// GPS / Spatial Coordinate Model
class TrackingCoordinate {
  final double latitude;
  final double longitude;
  final double speedKmH;
  final String segmentName;
  final DateTime timestamp;

  const TrackingCoordinate({
    required this.latitude,
    required this.longitude,
    this.speedKmH = 45.0,
    required this.segmentName,
    required this.timestamp,
  });
}

/// Normalized Tracking Event (Exact match to AgriChain Official Architecture)
class TrackingEvent {
  final String shipmentId;
  final String vehicleNumber;
  final TrackingEventType eventType;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String source; // 'ULIP / FASTag' or 'Simulated Spatial Tracking'
  final String? tollName;
  final String? routeStopId;
  final String status;
  final String eta;
  final double? speedKmH;
  final String? description;
  final String? slipNumber;
  final double? cumulativeLoadedMT;

  const TrackingEvent({
    required this.shipmentId,
    required this.vehicleNumber,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.source,
    this.tollName,
    this.routeStopId,
    required this.status,
    required this.eta,
    this.speedKmH,
    this.description,
    this.slipNumber,
    this.cumulativeLoadedMT,
  });

  String get eventTypeTitle {
    switch (eventType) {
      case TrackingEventType.fpoPickup:
        return 'FPO Harvest Loaded';
      case TrackingEventType.tollCrossing:
        return 'Toll Plaza Passed';
      case TrackingEventType.weighment:
        return 'Weighbridge Certified';
      case TrackingEventType.inTransit:
        return 'In-Transit on Highway';
      case TrackingEventType.inspection:
        return 'Quality Verified';
      case TrackingEventType.routeDeviation:
        return 'Corridor Alert';
      case TrackingEventType.delivered:
        return 'Destination Reached';
    }
  }
}

/// Multi-FPO Aggregated Shipment Route
class MultiFpoShipmentRoute {
  final String shipmentId;
  final String orderId;
  final String commodity;
  final double totalRequiredMT;
  final double currentLoadedMT;
  final String vehicleNumber;
  final String driverName;
  final String driverPhone;
  final double currentLatitude;
  final double currentLongitude;
  final double currentSpeedKmH;
  final String currentLocationName;
  final String eta;
  final String status;
  final TrackingProviderType activeProvider;
  final List<RouteStop> stops;
  final List<TrackingEvent> eventHistory;
  final List<List<double>>? roadGeometry;
  final double remainingDistanceKm;
  final double totalRouteDistanceKm;
  final String nextStopName;
  final double nextStopDistanceKm;
  final String nextStopEta;
  final String remainingDurationFormatted;
  final double cargoMoisturePct;
  final double ambientTempC;
  final double fuelConsumedLiters;

  const MultiFpoShipmentRoute({
    required this.shipmentId,
    required this.orderId,
    required this.commodity,
    required this.totalRequiredMT,
    required this.currentLoadedMT,
    required this.vehicleNumber,
    required this.driverName,
    required this.driverPhone,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.currentSpeedKmH,
    required this.currentLocationName,
    required this.eta,
    required this.status,
    required this.activeProvider,
    required this.stops,
    required this.eventHistory,
    this.roadGeometry,
    this.remainingDistanceKm = 74.8,
    this.totalRouteDistanceKm = 168.0,
    this.nextStopName = 'Toll 3: Murthal Toll Plaza (NH-44)',
    this.nextStopDistanceKm = 14.2,
    this.nextStopEta = '15 mins',
    this.remainingDurationFormatted = '1h 18m',
    this.cargoMoisturePct = 12.2,
    this.ambientTempC = 28.5,
    this.fuelConsumedLiters = 22.4,
  });

  String get sourceBadgeTitle {
    return activeProvider == TrackingProviderType.ulipFastag
        ? 'Source: ULIP / FASTag'
        : 'Source: Google Road / Spatial Tracking';
  }

  String get activeTrackingSource {
    return activeProvider == TrackingProviderType.ulipFastag
        ? 'ULIP / FASTag'
        : 'Google Road Snapping (NH-44)';
  }

  MultiFpoShipmentRoute copyWith({
    double? currentLatitude,
    double? currentLongitude,
    double? currentSpeedKmH,
    String? currentLocationName,
    String? eta,
    String? status,
    double? currentLoadedMT,
    TrackingProviderType? activeProvider,
    List<RouteStop>? stops,
    List<TrackingEvent>? eventHistory,
    List<List<double>>? roadGeometry,
    double? remainingDistanceKm,
    double? totalRouteDistanceKm,
    String? nextStopName,
    double? nextStopDistanceKm,
    String? nextStopEta,
    String? remainingDurationFormatted,
    double? cargoMoisturePct,
    double? ambientTempC,
    double? fuelConsumedLiters,
  }) {
    return MultiFpoShipmentRoute(
      shipmentId: shipmentId,
      orderId: orderId,
      commodity: commodity,
      totalRequiredMT: totalRequiredMT,
      currentLoadedMT: currentLoadedMT ?? this.currentLoadedMT,
      vehicleNumber: vehicleNumber,
      driverName: driverName,
      driverPhone: driverPhone,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      currentSpeedKmH: currentSpeedKmH ?? this.currentSpeedKmH,
      currentLocationName: currentLocationName ?? this.currentLocationName,
      eta: eta ?? this.eta,
      status: status ?? this.status,
      activeProvider: activeProvider ?? this.activeProvider,
      stops: stops ?? this.stops,
      eventHistory: eventHistory ?? this.eventHistory,
      roadGeometry: roadGeometry ?? this.roadGeometry,
      remainingDistanceKm: remainingDistanceKm ?? this.remainingDistanceKm,
      totalRouteDistanceKm: totalRouteDistanceKm ?? this.totalRouteDistanceKm,
      nextStopName: nextStopName ?? this.nextStopName,
      nextStopDistanceKm: nextStopDistanceKm ?? this.nextStopDistanceKm,
      nextStopEta: nextStopEta ?? this.nextStopEta,
      remainingDurationFormatted: remainingDurationFormatted ?? this.remainingDurationFormatted,
      cargoMoisturePct: cargoMoisturePct ?? this.cargoMoisturePct,
      ambientTempC: ambientTempC ?? this.ambientTempC,
      fuelConsumedLiters: fuelConsumedLiters ?? this.fuelConsumedLiters,
    );
  }
}
