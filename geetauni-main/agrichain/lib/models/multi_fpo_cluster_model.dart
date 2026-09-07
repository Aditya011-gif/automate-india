import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Represents a single FPO warehouse node participating in a multi-FPO aggregation cluster.
class FpoNode {
  final String fpoId;
  final String fpoName;
  final String warehouseName;
  final double latitude;
  final double longitude;
  final String commodity;
  final String variety;
  final double availableQuantityQtl;
  final double pricePerQtl;
  final double moisturePct;
  final String qualityGrade;
  final String? imageUrl;
  final String? listingId;
  final int dispatchLeadDays;
  final bool isMultiFpoEligible;

  const FpoNode({
    required this.fpoId,
    required this.fpoName,
    required this.warehouseName,
    required this.latitude,
    required this.longitude,
    required this.commodity,
    required this.variety,
    required this.availableQuantityQtl,
    required this.pricePerQtl,
    this.moisturePct = 11.2,
    this.qualityGrade = 'Grade A (Milling)',
    this.imageUrl,
    this.listingId,
    this.dispatchLeadDays = 2,
    this.isMultiFpoEligible = true,
  });

  LatLng get position => LatLng(latitude, longitude);

  double get availableQuantityMT => availableQuantityQtl / 10.0;
  double get pricePerMT => pricePerQtl * 10.0;
}

/// Represents a single stop in the multi-stop FTL collection route.
class ClusterRouteStop {
  final int stopSequence;
  final String fpoId;
  final String stopName;
  final String address;
  final double latitude;
  final double longitude;
  final double pickupQuantityQtl;
  final int estimatedArrivalMinutes;
  final int dwellTimeMinutes;
  final double segmentDistanceKm;
  final String stopType; // 'fpo_pickup', 'destination_plant'

  const ClusterRouteStop({
    required this.stopSequence,
    required this.fpoId,
    required this.stopName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.pickupQuantityQtl,
    required this.estimatedArrivalMinutes,
    required this.dwellTimeMinutes,
    required this.segmentDistanceKm,
    this.stopType = 'fpo_pickup',
  });

  LatLng get position => LatLng(latitude, longitude);
}

/// Verification report validating the feasibility and safety of a multi-FPO cluster.
class ClusterValidationResult {
  final bool isProximityPassed; // True if all FPOs are within 7-10 km range
  final double maxPairwiseDistanceKm;
  final bool isCommodityCompatible; // Same commodity and compatible variety/grade
  final bool isMoistureCompatible; // Moisture variance <= 1.5% to avoid spoilage
  final double moistureVariancePct;
  final bool isTravelTimeAcceptable; // Total collection transit <= 4 hours
  final int totalCollectionTimeMinutes;
  final bool isVolumeViable; // >= 150 Qtl for FTL commercial viability
  final List<String> passedChecks;
  final List<String> warnings;

  const ClusterValidationResult({
    required this.isProximityPassed,
    required this.maxPairwiseDistanceKm,
    required this.isCommodityCompatible,
    required this.isMoistureCompatible,
    required this.moistureVariancePct,
    required this.isTravelTimeAcceptable,
    required this.totalCollectionTimeMinutes,
    required this.isVolumeViable,
    required this.passedChecks,
    required this.warnings,
  });

  bool get isFullyApproved =>
      isProximityPassed &&
      isCommodityCompatible &&
      isMoistureCompatible &&
      isTravelTimeAcceptable &&
      isVolumeViable;
}

/// Aggregated Multi-FPO Cluster model resulting from running the clustering engine
/// across verified FPO warehouse locations.
class MultiFpoCluster {
  final String clusterId;
  final String clusterName;
  final String commodity;
  final String variety;
  final List<FpoNode> participatingFpos;
  final double totalVolumeQtl;
  final double weightedPricePerQtl;
  final double averageMoisturePct;
  final double maxRadialDistanceKm;
  final double totalRouteDistanceKm;
  final int drivingTimeMinutes;
  final int dwellTimeMinutes;
  final int totalTransitMinutes;
  final int ftlTrucksRequired;
  final double singleTripFreightEstimate;
  final double separateTripsFreightEstimate;
  final double freightSavingsAmount;
  final double freightSavingsPct;
  final ClusterValidationResult validation;
  final List<ClusterRouteStop> routeStops;
  final LatLng centroid;

  const MultiFpoCluster({
    required this.clusterId,
    required this.clusterName,
    required this.commodity,
    required this.variety,
    required this.participatingFpos,
    required this.totalVolumeQtl,
    required this.weightedPricePerQtl,
    required this.averageMoisturePct,
    required this.maxRadialDistanceKm,
    required this.totalRouteDistanceKm,
    required this.drivingTimeMinutes,
    required this.dwellTimeMinutes,
    required this.totalTransitMinutes,
    required this.ftlTrucksRequired,
    required this.singleTripFreightEstimate,
    required this.separateTripsFreightEstimate,
    required this.freightSavingsAmount,
    required this.freightSavingsPct,
    required this.validation,
    required this.routeStops,
    required this.centroid,
  });

  double get totalVolumeMT => totalVolumeQtl / 10.0;
  double get weightedPricePerMT => weightedPricePerQtl * 10.0;

  String get formattedTotalDuration {
    final hours = totalTransitMinutes ~/ 60;
    final mins = totalTransitMinutes % 60;
    if (hours == 0) return '$mins mins';
    if (mins == 0) return '$hours hrs';
    return '${hours}h ${mins}m';
  }

  String get formattedDrivingTime {
    final hours = drivingTimeMinutes ~/ 60;
    final mins = drivingTimeMinutes % 60;
    if (hours == 0) return '$mins mins drive';
    return '${hours}h ${mins}m drive';
  }
}
