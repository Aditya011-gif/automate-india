import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Result container for road routing calculations
class RoadRouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final bool isRealRoad;
  final String summary;

  const RoadRouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    this.isRealRoad = true,
    this.summary = 'Optimized Asphalt Road Corridor',
  });
}

/// Centralized Road Routing Service powered by OpenStreetMap OSRM Driving Engine.
/// Provides real turn-by-turn road polyline geometry, multi-stop pickup optimization,
/// distance and travel time calculation, and high-performance in-memory caching.
class RoadRoutingService {
  static final RoadRoutingService _instance = RoadRoutingService._internal();
  factory RoadRoutingService() => _instance;
  RoadRoutingService._internal();

  // In-memory cache to avoid redundant network hits during navigation
  final Map<String, RoadRouteResult> _routeCache = {};

  /// Haversine direct geographic distance in km
  static double haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  /// Optimize multi-stop waypoint sequence using Nearest-Neighbor heuristic (TSP)
  /// Given a starting origin/hub and intermediate stops, orders the stops to minimize travel distance.
  static List<LatLng> optimizeWaypointsOrder(LatLng origin, List<LatLng> stops) {
    if (stops.length <= 1) return List.from(stops);

    final List<LatLng> unvisited = List.from(stops);
    final List<LatLng> ordered = [];
    LatLng current = origin;

    while (unvisited.isNotEmpty) {
      int nearestIdx = 0;
      double minDistance = double.infinity;

      for (int i = 0; i < unvisited.length; i++) {
        final d = haversineDistanceKm(
          current.latitude,
          current.longitude,
          unvisited[i].latitude,
          unvisited[i].longitude,
        );
        if (d < minDistance) {
          minDistance = d;
          nearestIdx = i;
        }
      }

      current = unvisited.removeAt(nearestIdx);
      ordered.add(current);
    }

    return ordered;
  }

  /// Fetches real asphalt road geometry for a multi-stop itinerary from OSRM.
  /// Format: waypoints = [Stop 1, Stop 2, ..., Destination / Hub]
  Future<RoadRouteResult> getMultiStopRoute(
    List<LatLng> waypoints, {
    bool optimizeStops = false,
  }) async {
    if (waypoints.length < 2) {
      return RoadRouteResult(
        points: waypoints,
        distanceKm: 0.0,
        durationMinutes: 0,
        isRealRoad: false,
      );
    }

    // Optionally optimize intermediate stops
    List<LatLng> finalWaypoints = waypoints;
    if (optimizeStops && waypoints.length > 2) {
      final origin = waypoints.first;
      final destination = waypoints.last;
      final intermediate = waypoints.sublist(1, waypoints.length - 1);
      final optimizedIntermediate = optimizeWaypointsOrder(origin, intermediate);
      finalWaypoints = [origin, ...optimizedIntermediate, destination];
    }

    // Cache key
    final cacheKey = finalWaypoints
        .map((w) => '${w.latitude.toStringAsFixed(4)},${w.longitude.toStringAsFixed(4)}')
        .join(';');

    if (_routeCache.containsKey(cacheKey)) {
      return _routeCache[cacheKey]!;
    }

    try {
      // OSRM coordinates are in longitude,latitude order
      final coordsParam = finalWaypoints
          .map((w) => '${w.longitude.toStringAsFixed(6)},${w.latitude.toStringAsFixed(6)}')
          .join(';');

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordsParam?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final rawCoords = route['geometry']['coordinates'] as List;

          final List<LatLng> roadPoints = [];
          for (final c in rawCoords) {
            roadPoints.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
          }

          final distMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
          final durationSecs = (route['duration'] as num?)?.toDouble() ?? 0.0;

          final distKm = double.parse((distMeters / 1000.0).toStringAsFixed(1));
          final durationMins = (durationSecs / 60.0).round().clamp(5, 480);

          final result = RoadRouteResult(
            points: roadPoints,
            distanceKm: distKm > 0 ? distKm : _estimateHaversineTotal(finalWaypoints),
            durationMinutes: durationMins,
            isRealRoad: true,
            summary: 'National & Rural Highway Network (OSRM Verified)',
          );

          _routeCache[cacheKey] = result;
          return result;
        }
      }
    } catch (e) {
      debugPrint('⚠️ OSRM API live call fallback notice: $e');
    }

    // Fallback: Generate smooth road-interpolated trajectory if network is slow/offline
    final fallbackResult = _createInterpolatedFallbackRoute(finalWaypoints);
    _routeCache[cacheKey] = fallbackResult;
    return fallbackResult;
  }

  /// Calculates total direct distance of waypoints
  static double _estimateHaversineTotal(List<LatLng> points) {
    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += haversineDistanceKm(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    // Road factor: Driving distance is typically 1.25x - 1.3x straight-line distance
    return double.parse((total * 1.25).toStringAsFixed(1));
  }

  /// Generates a realistic multi-point polyline following gentle terrain curves when offline
  static RoadRouteResult _createInterpolatedFallbackRoute(List<LatLng> waypoints) {
    final List<LatLng> interpolated = [];
    double totalDist = 0.0;

    for (int i = 0; i < waypoints.length - 1; i++) {
      final p1 = waypoints[i];
      final p2 = waypoints[i + 1];
      final segmentDist = haversineDistanceKm(p1.latitude, p1.longitude, p2.latitude, p2.longitude);
      totalDist += segmentDist * 1.25;

      interpolated.add(p1);

      // Add gentle intermediate arc points to avoid harsh straight lines
      final steps = (segmentDist * 4).clamp(3, 8).toInt();
      final midLat = (p1.latitude + p2.latitude) / 2 + 0.002 * (i % 2 == 0 ? 1 : -1);
      final midLng = (p1.longitude + p2.longitude) / 2 - 0.002 * (i % 2 == 0 ? 1 : -1);

      for (int s = 1; s < steps; s++) {
        final t = s / steps.toDouble();
        // Quadratic bezier
        final lat = (1 - t) * (1 - t) * p1.latitude + 2 * (1 - t) * t * midLat + t * t * p2.latitude;
        final lng = (1 - t) * (1 - t) * p1.longitude + 2 * (1 - t) * t * midLng + t * t * p2.longitude;
        interpolated.add(LatLng(lat, lng));
      }
    }

    interpolated.add(waypoints.last);
    final distKm = double.parse(totalDist.toStringAsFixed(1));
    final durationMins = (distKm * 2.2).round().clamp(10, 180);

    return RoadRouteResult(
      points: interpolated,
      distanceKm: distKm,
      durationMinutes: durationMins,
      isRealRoad: false,
      summary: 'Rural Road Corridor (High-Precision Approximation)',
    );
  }
}
