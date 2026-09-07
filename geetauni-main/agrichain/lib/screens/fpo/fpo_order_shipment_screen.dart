import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_theme.dart';
import '../../models/tracking_models.dart';
import '../../services/tracking_service.dart';
import '../../services/database_service.dart';
import '../bulk_buyer/b2b_contract_screen.dart';

class FpoOrderShipmentScreen extends StatefulWidget {
  final String orderId;
  final String buyerName;
  final String commodity;
  final String destination;
  final String vehicleNumber;
  final String driverName;

  const FpoOrderShipmentScreen({
    super.key,
    this.orderId = 'BPO-84920',
    this.buyerName = 'AgroFoods Milling India Pvt Ltd',
    this.commodity = '3,000 Qtl Sharbati Wheat (Milling Quality)',
    this.destination = 'Industrial Processing Plant, NCR Hub',
    this.vehicleNumber = 'HR-05-AB-9842 (Lead) + 2 Fleet Trucks',
    this.driverName = 'Balwinder Singh (+91 98120 44556)',
  });

  @override
  State<FpoOrderShipmentScreen> createState() => _FpoOrderShipmentScreenState();
}

class _FpoOrderShipmentScreenState extends State<FpoOrderShipmentScreen> {
  final TrackingEngine _trackingEngine = TrackingEngine();
  final DatabaseService _dbService = DatabaseService();
  final MapController _mapController = MapController();
  late MultiFpoShipmentRoute _route;
  Map<String, dynamic>? _liveOrder;
  bool _isLoading = true;
  bool _isPlaying = true;
  double _speedMultiplier = 1.0;
  int _selectedMapTileIndex = 0; // 0: Google Roadmap, 1: Google Hybrid, 2: OpenStreetMap, 3: Google Terrain
  bool _autoFollowVehicle = true;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _loadInitialRoute();
  }

  Future<void> _loadInitialRoute() async {
    Map<String, dynamic>? liveOrder;
    try {
      liveOrder = await _dbService.getB2bOrder(widget.orderId);
    } catch (e) {
      debugPrint('Order lookup fallback: $e');
    }

    _trackingEngine.configureForOrder(
      order: liveOrder,
      orderId: widget.orderId,
      commodity: widget.commodity,
      buyerName: widget.buyerName,
      destination: widget.destination,
      vehicleNumber: widget.vehicleNumber,
      driverName: widget.driverName,
    );

    final route = await _trackingEngine.getShipmentRoute();

    if (mounted) {
      setState(() {
        _route = route;
        _liveOrder = liveOrder;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAF7),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppTheme.darkGreen,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Logistics & Fleet Tracking',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Real Road Snapping • Google Maps & OSM API',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View B2B Contract',
            icon: const Icon(Icons.description_outlined, color: AppTheme.primaryGreen),
            onPressed: () {
              final id = _liveOrder?['orderId'] ?? _liveOrder?['id'] ?? widget.orderId;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => B2bContractScreen(orderId: id.toString()),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Refresh Telemetry',
            icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
            onPressed: _loadInitialRoute,
          ),
        ],
      ),
      body: StreamBuilder<MultiFpoShipmentRoute>(
        stream: _trackingEngine.streamRoute(),
        initialData: _route,
        builder: (context, snapshot) {
          final liveRoute = snapshot.data ?? _route;

          if (_autoFollowVehicle && _isMapReady) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_isMapReady && mounted) {
                try {
                  _mapController.move(
                    LatLng(liveRoute.currentLatitude, liveRoute.currentLongitude),
                    _mapController.camera.zoom,
                  );
                } catch (_) {}
              }
            });
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Architecture Provider Switcher Card
              _buildProviderModeCard(liveRoute),
              const SizedBox(height: 14),

              // 2. Multi-FPO Batch Summary (300 MT Cluster Aggregation)
              _buildMultiFpoBatchCard(liveRoute),
              const SizedBox(height: 14),

              // 3. Real Road Snapped Interactive Route Map
              _buildRealOsmRouteMap(liveRoute),
              const SizedBox(height: 14),

              // 3.5 Realistic Highway Telemetry & Dynamic ETA Card
              _buildLiveEtaTelemetryCard(liveRoute),
              const SizedBox(height: 14),

              // 4. Demo Spatial Playback Controls
              if (_trackingEngine.activeProviderType == TrackingProviderType.simulatedSpatial)
                _buildDemoPlaybackControls(liveRoute),
              if (_trackingEngine.activeProviderType == TrackingProviderType.simulatedSpatial)
                const SizedBox(height: 14),

              // 5. Normalized Event Timeline (FPOs, Toll Plazas, Escrow)
              _buildNormalizedTimelineCard(liveRoute),
              const SizedBox(height: 14),

              // 6. Driver & Fleet Telemetry Card
              _buildFleetTelemetryCard(liveRoute),
              const SizedBox(height: 14),

              // 7. Electronic Weighbridge Slips & Digital Escrow
              _buildWeighbridgeCertificateCard(liveRoute),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  /// 1. Architecture Provider Switcher Card
  Widget _buildProviderModeCard(MultiFpoShipmentRoute route) {
    final isUlip = _trackingEngine.activeProviderType == TrackingProviderType.ulipFastag;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isUlip ? Icons.toll : Icons.satellite_outlined,
                color: isUlip ? const Color(0xFF1565C0) : const Color(0xFF2E7D32),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tracking Architecture Engine',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isUlip ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Source: ${route.activeTrackingSource}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUlip ? const Color(0xFF1565C0) : const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Simulated Spatial (Demo)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: !isUlip,
                  selectedColor: const Color(0xFFE8F5E9),
                  onSelected: (selected) async {
                    if (selected) {
                      setState(() {
                        _trackingEngine.setProvider(TrackingProviderType.simulatedSpatial);
                      });
                      final r = await _trackingEngine.getShipmentRoute();
                      if (mounted) setState(() => _route = r);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('ULIP FASTag (Govt API)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: isUlip,
                  selectedColor: const Color(0xFFE3F2FD),
                  onSelected: (selected) async {
                    if (selected) {
                      setState(() {
                        _trackingEngine.setProvider(TrackingProviderType.ulipFastag);
                      });
                      final r = await _trackingEngine.getShipmentRoute();
                      if (mounted) {
                        setState(() => _route = r);
                        if (_isMapReady) {
                          try {
                            _mapController.move(LatLng(r.currentLatitude, r.currentLongitude), 11.0);
                          } catch (_) {}
                        }
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Multi-FPO Aggregation Batch Card (Dynamic Real Order Data with Demo Fallback)
  Widget _buildMultiFpoBatchCard(MultiFpoShipmentRoute route) {
    final orderId = (_liveOrder?['orderId'] ?? _liveOrder?['id'] ?? widget.orderId).toString();
    final commodity = (_liveOrder?['commodity'] ?? _liveOrder?['crop'] ?? widget.commodity).toString();
    final buyer = (_liveOrder?['buyerCompany'] ?? _liveOrder?['buyerName'] ?? widget.buyerName).toString();
    final dest = (_liveOrder?['destination'] ?? _liveOrder?['deliveryLocation'] ?? widget.destination).toString();

    // Batch volume in Quintals & MT
    final qtyQtl = (_liveOrder?['quantityQtl'] as num?)?.toDouble() ??
        (_liveOrder?['totalQuantityQtl'] as num?)?.toDouble() ??
        ((_liveOrder?['quantityMT'] as num?)?.toDouble() != null ? (_liveOrder!['quantityMT'] as num).toDouble() * 10 : null) ??
        3000.0;
    final batchText = '${qtyQtl.toStringAsFixed(0)} Qtl Batch (${(qtyQtl / 10).toStringAsFixed(0)} MT)';

    // Dynamic FPO breakdown
    final rawAllocs = (_liveOrder?['fpoAllocations'] as List<dynamic>?) ??
        (_liveOrder?['contributions'] as List<dynamic>?);

    List<Widget> fpoPills = [];
    if (rawAllocs != null && rawAllocs.isNotEmpty) {
      fpoPills = rawAllocs.map((alloc) {
        final name = (alloc['fpoName'] ?? alloc['name'] ?? 'FPO Partner').toString();
        String shortName = name;
        if (shortName.contains('Taraori')) {
          shortName = 'FPO B (Taraori)';
        } else if (shortName.contains('Karnal')) {
          shortName = 'FPO A (Karnal)';
        } else if (shortName.contains('Gharaunda')) {
          shortName = 'FPO C (Gharaunda)';
        } else if (shortName.length > 18) {
          shortName = shortName.split(' ').first;
        }

        final allocQ = (alloc['allocatedQtl'] as num?)?.toDouble() ??
            ((alloc['quantityQtl'] as num?)?.toDouble()) ??
            ((alloc['allocatedMT'] as num?)?.toDouble() != null ? (alloc['allocatedMT'] as num).toDouble() * 10 : null) ??
            (alloc['volume'] as num?)?.toDouble() ??
            1000.0;
        return _buildFpoPill(shortName, '${allocQ.toStringAsFixed(0)} Qtl', true);
      }).toList();
    } else if (_liveOrder != null && _liveOrder!['isMultiFpo'] != true) {
      final fpoName = (_liveOrder!['fpoName'] ?? _liveOrder!['sellerName'] ?? 'FPO Warehouse').toString();
      fpoPills = [
        _buildFpoPill(fpoName, '${qtyQtl.toStringAsFixed(0)} Qtl', true),
      ];
    } else {
      // Default demo cluster fallback
      fpoPills = [
        _buildFpoPill('FPO B (Taraori)', '1,000 Qtl', true),
        _buildFpoPill('FPO A (Karnal)', '1,200 Qtl', true),
        _buildFpoPill('FPO C (Gharaunda)', '800 Qtl', true),
      ];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Order #$orderId',
                  style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                batchText,
                style: GoogleFonts.inter(color: Colors.lightGreenAccent, fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            commodity,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Buyer: $buyer',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 10, color: Colors.lightGreenAccent),
                    const SizedBox(width: 2),
                    Text(
                      dest.length > 22 ? '${dest.substring(0, 20)}...' : dest,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 9.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // FPO Contributions along NH-44
          Row(
            children: [
              for (int i = 0; i < fpoPills.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                fpoPills[i],
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Interactive Smart Contract View & PDF Download Strip
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => B2bContractScreen(orderId: orderId),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, color: Colors.lightGreenAccent, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Polygon PoS Contract Active',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'View & Download Contract PDF',
                        style: GoogleFonts.inter(color: Colors.lightGreenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, color: Colors.lightGreenAccent, size: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFpoPill(String fpo, String qty, bool done) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(fpo, style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(qty, style: GoogleFonts.inter(color: Colors.lightGreenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  /// 3. Real Road Snapped Interactive Route Map (Google Maps / OSM)
  Widget _buildRealOsmRouteMap(MultiFpoShipmentRoute route) {
    // Exact real road vertices snapped to asphalt turns of NH-44
    final routePoints = route.roadGeometry != null && route.roadGeometry!.isNotEmpty
        ? route.roadGeometry!.map((pt) => LatLng(pt[0], pt[1])).toList()
        : route.stops.map((s) => LatLng(s.latitude, s.longitude)).toList();

    final currentPos = LatLng(route.currentLatitude, route.currentLongitude);

    // Map Tile Source URLs (Google Maps Roadmap, Google Hybrid, OpenStreetMap)
    String tileUrl;
    String layerName;
    switch (_selectedMapTileIndex) {
      case 0:
        tileUrl = 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
        layerName = 'Google Maps Road View';
        break;
      case 1:
        tileUrl = 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
        layerName = 'Google Satellite Hybrid';
        break;
      case 2:
      default:
        tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
        layerName = 'OpenStreetMap Standard';
        break;
    }

    final nodesCount = route.roadGeometry?.length ?? route.stops.length;
    final destStop = route.stops.isNotEmpty ? route.stops.lastWhere((s) => s.type == 'destination', orElse: () => route.stops.last) : null;
    final destTitle = destStop != null ? destStop.name.replaceAll('Destination: ', '') : 'Processing Plant';
    final isInterstate = route.totalRouteDistanceKm > 300 ||
        (destStop != null && (destStop.latitude < 22.0 || destStop.longitude > 78.0));
    final corridorTitle = isInterstate ? 'Inter-State Freight Corridor (Western)' : 'Google Maps Road Tracking (NH-44)';
    final subtitle = 'Snapped road geometry ($nodesCount nodes) • Gate: $destTitle';
    final initialZoom = isInterstate ? 6.5 : 10.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.alt_route, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        corridorTitle,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speed, size: 12, color: AppTheme.primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        '${route.currentSpeedKmH.toStringAsFixed(0)} km/h',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Real FlutterMap Container
          Container(
            height: 290,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: currentPos,
                      initialZoom: initialZoom,
                      onMapReady: () {
                        _isMapReady = true;
                      },
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      // Google Maps / OSM Tiles
                      TileLayer(
                        urlTemplate: tileUrl,
                        userAgentPackageName: 'com.agrichain.app',
                      ),

                      // Geofence Rings & Toll Geofences
                      CircleLayer(
                        circles: [
                          if ((_liveOrder?['isMultiFpo'] == true || _liveOrder?['isPooled'] == true) &&
                              (((_liveOrder?['fpoAllocations'] as List?)?.length ?? 0) > 1 ||
                               ((_liveOrder?['contributions'] as List?)?.length ?? 0) > 1)) ...[
                            // FPO A 7km radius ring (Karnal)
                            CircleMarker(
                              point: const LatLng(29.6857, 76.9905),
                              color: Colors.green.withValues(alpha: 0.12),
                              borderColor: AppTheme.primaryGreen.withValues(alpha: 0.7),
                              borderStrokeWidth: 1.5,
                              useRadiusInMeter: true,
                              radius: 7000,
                            ),
                            // FPO B 7km radius ring (Taraori)
                            CircleMarker(
                              point: const LatLng(29.8010, 76.9230),
                              color: Colors.green.withValues(alpha: 0.12),
                              borderColor: AppTheme.primaryGreen.withValues(alpha: 0.7),
                              borderStrokeWidth: 1.5,
                              useRadiusInMeter: true,
                              radius: 7000,
                            ),
                          ] else if (route.stops.isNotEmpty) ...[
                            // Single FPO Origin Geofence (3km radius)
                            CircleMarker(
                              point: LatLng(route.stops.first.latitude, route.stops.first.longitude),
                              color: Colors.green.withValues(alpha: 0.12),
                              borderColor: AppTheme.primaryGreen.withValues(alpha: 0.7),
                              borderStrokeWidth: 1.5,
                              useRadiusInMeter: true,
                              radius: 3000,
                            ),
                          ],
                          // Toll 1 Bastara Geofence (800m)
                          CircleMarker(
                            point: const LatLng(29.6120, 76.9850),
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderColor: Colors.blue.withValues(alpha: 0.8),
                            borderStrokeWidth: 1.5,
                            useRadiusInMeter: true,
                            radius: 800,
                          ),
                          // Toll 2 Panipat Geofence (800m)
                          CircleMarker(
                            point: const LatLng(29.3909, 76.9635),
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderColor: Colors.blue.withValues(alpha: 0.8),
                            borderStrokeWidth: 1.5,
                            useRadiusInMeter: true,
                            radius: 800,
                          ),
                        ],
                      ),

                      // Google Maps Snapped Navigation Polyline
                      PolylineLayer(
                        polylines: [
                          // Road Border
                          Polyline(
                            points: routePoints,
                            color: const Color(0xFF0D47A1),
                            strokeWidth: 6.0,
                          ),
                          // Google Maps Route Centerline
                          Polyline(
                            points: routePoints,
                            color: const Color(0xFF1E88E5),
                            strokeWidth: 4.0,
                          ),
                        ],
                      ),

                      // Stops & Live Vehicle Markers
                      MarkerLayer(
                        markers: [
                          for (final stop in route.stops)
                            Marker(
                              point: LatLng(stop.latitude, stop.longitude),
                              width: 38,
                              height: 38,
                              child: Tooltip(
                                message: stop.name,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: stop.isCompleted
                                        ? (stop.type == 'toll' ? const Color(0xFF1E88E5) : const Color(0xFF2E7D32))
                                        : (stop.type == 'destination' ? Colors.deepOrange : Colors.amber.shade800),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                  ),
                                  child: Icon(
                                    stop.type == 'fpo'
                                        ? Icons.warehouse
                                        : (stop.type == 'toll' ? Icons.toll : Icons.factory),
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),

                          // Live Moving Vehicle Marker with Radar Pulse
                          Marker(
                            point: currentPos,
                            width: 52,
                            height: 52,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                                    border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
                                  ),
                                ),
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1565C0),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                                  ),
                                  child: const Icon(
                                    Icons.local_shipping,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Top-Left Real Road & Map Layer Tag
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.layers, size: 14, color: AppTheme.primaryGreen),
                          const SizedBox(width: 5),
                          Text(
                            layerName,
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Map Controls Overlay
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'map_layer_toggle',
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.darkGreen,
                          tooltip: 'Switch Map Layer',
                          onPressed: () {
                            setState(() {
                              _selectedMapTileIndex = (_selectedMapTileIndex + 1) % 3;
                            });
                          },
                          child: Icon(
                            _selectedMapTileIndex == 0
                                ? Icons.map
                                : (_selectedMapTileIndex == 1 ? Icons.satellite_alt : Icons.public),
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FloatingActionButton.small(
                          heroTag: 'map_recenter',
                          backgroundColor: Colors.white,
                          foregroundColor: _autoFollowVehicle ? AppTheme.primaryGreen : Colors.grey,
                          tooltip: 'Recenter on Vehicle',
                          onPressed: () {
                            setState(() {
                              _autoFollowVehicle = !_autoFollowVehicle;
                            });
                            if (_isMapReady) {
                              try {
                                _mapController.move(currentPos, 11.5);
                              } catch (_) {}
                            }
                          },
                          child: const Icon(Icons.my_location, size: 18),
                        ),
                        const SizedBox(height: 6),
                        FloatingActionButton.small(
                          heroTag: 'map_zoom_in',
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.darkGreen,
                          tooltip: 'Zoom In',
                          onPressed: () {
                            if (_isMapReady) {
                              try {
                                _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
                              } catch (_) {}
                            }
                          },
                          child: const Icon(Icons.add, size: 18),
                        ),
                        const SizedBox(height: 6),
                        FloatingActionButton.small(
                          heroTag: 'map_zoom_out',
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.darkGreen,
                          tooltip: 'Zoom Out',
                          onPressed: () {
                            if (_isMapReady) {
                              try {
                                _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
                              } catch (_) {}
                            }
                          },
                          child: const Icon(Icons.remove, size: 18),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Coordinates & Highway Badge
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'NH-44 Corridor • ${route.currentLatitude.toStringAsFixed(4)}° N, ${route.currentLongitude.toStringAsFixed(4)}° E',
                        style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.location_pin, color: Colors.redAccent, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Live Pos: ${route.currentLocationName}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'ETA: ${route.eta}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3.5 Real-Time Highway Telemetry & Dynamic ETA Card
  Widget _buildLiveEtaTelemetryCard(MultiFpoShipmentRoute route) {
    final progressPct = (1.0 - (route.remainingDistanceKm / (route.totalRouteDistanceKm > 0 ? route.totalRouteDistanceKm : 168.0))).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timer, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Trip Telemetry & Dynamic ETA',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                    ),
                    Text(
                      'Real-time traffic & FASTag toll queue calculated',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text(
                  '${(progressPct * 100).toStringAsFixed(0)}% Complete',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Linear Progress Bar of Corridor
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPct,
              minHeight: 7,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(height: 14),

          // Main 2 Big Stat Cards (Remaining Dist + Final ETA)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.straighten, size: 14, color: AppTheme.primaryGreen),
                          const SizedBox(width: 4),
                          Text('Remaining Dist', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${route.remainingDistanceKm.toStringAsFixed(1)} km',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                      ),
                      Text(
                        'of ${route.totalRouteDistanceKm.toStringAsFixed(0)} km total',
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled, size: 14, color: Colors.blueAccent),
                          const SizedBox(width: 4),
                          Text('Calculated ETA', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        route.eta,
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      ),
                      Text(
                        'in ${route.remainingDurationFormatted} travel time',
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Next Approaching Milestone Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag_outlined, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Stop: ${route.nextStopName}',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown.shade800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${route.nextStopDistanceKm.toStringAsFixed(1)} km away • Approaching in ~${route.nextStopEta}',
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.brown.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Live IoT Grain & Vehicle Health Matrix
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(Icons.water_drop_outlined, 'Moisture', '${route.cargoMoisturePct.toStringAsFixed(1)}%', 'Optimal'),
              _buildMiniMetric(Icons.thermostat, 'Cabin Temp', '${route.ambientTempC.toStringAsFixed(1)}°C', 'Stable'),
              _buildMiniMetric(Icons.local_gas_station, 'Fuel Used', '${route.fuelConsumedLiters.toStringAsFixed(1)} L', '4.2 km/L'),
              _buildMiniMetric(Icons.speed, 'Avg Speed', '${route.currentSpeedKmH.toStringAsFixed(0)} km/h', 'Cruise'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String title, String value, String sub) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryGreen),
        const SizedBox(height: 3),
        Text(title, style: GoogleFonts.inter(fontSize: 9, color: Colors.grey.shade600)),
        Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
        Text(sub, style: GoogleFonts.inter(fontSize: 9, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
      ],
    );
  }

  /// 4. Demo Spatial Playback Controls
  Widget _buildDemoPlaybackControls(MultiFpoShipmentRoute route) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_outline, color: AppTheme.primaryGreen, size: 18),
              const SizedBox(width: 6),
              Text(
                'Spatial Playback Simulation Controls',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                color: AppTheme.primaryGreen,
                iconSize: 28,
                onPressed: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                    _trackingEngine.simulationEngine.togglePlayback();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Speed:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              _buildSpeedButton(1.0, '1x'),
              const SizedBox(width: 6),
              _buildSpeedButton(5.0, '5x'),
              const SizedBox(width: 6),
              _buildSpeedButton(20.0, '20x'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Jump to Milestone:',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < route.stops.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _buildJumpChip(
                    _getStopChipTitle(route.stops[i]),
                    route.stops.length > 1 ? (i / (route.stops.length - 1)) : 0.0,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedButton(double speed, String label) {
    final isSelected = _speedMultiplier == speed;
    return InkWell(
      onTap: () {
        setState(() {
          _speedMultiplier = speed;
          _trackingEngine.simulationEngine.setPlaybackSpeed(speed);
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryGreen),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppTheme.primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildJumpChip(String title, double fraction) {
    return ActionChip(
      label: Text(title, style: const TextStyle(fontSize: 11)),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      onPressed: () {
        _trackingEngine.simulationEngine.seekToFraction(fraction);
      },
    );
  }

  String _getStopChipTitle(RouteStop stop) {
    if (stop.type == 'fpo') {
      final name = stop.name.replaceAll(RegExp(r'FPO [A-Z]:\s*'), '').trim();
      final shortName = name.length > 16 ? '${name.substring(0, 14)}..' : name;
      final qtl = (stop.plannedQuantityMT != null && stop.plannedQuantityMT! > 0)
          ? (stop.plannedQuantityMT! * 10)
          : null;
      return qtl != null ? '$shortName (${qtl.toStringAsFixed(0)} Qtl)' : shortName;
    } else if (stop.type == 'toll') {
      final clean = stop.name
          .replaceAll('Toll Plaza (NH-44)', '')
          .replaceAll('Toll Plaza', '')
          .replaceAll('(NH-44)', '')
          .trim();
      return clean.isNotEmpty ? clean : stop.name;
    } else {
      return 'Buyer Factory';
    }
  }

  /// 5. Normalized Event Timeline Card
  Widget _buildNormalizedTimelineCard(MultiFpoShipmentRoute route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Collection & FASTag Toll Timeline',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < route.stops.length; i++)
            _buildTimelineItem(route.stops[i], isLast: i == route.stops.length - 1),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(RouteStop stop, {bool isLast = false}) {
    final isDone = stop.isCompleted;
    Color nodeColor = isDone ? const Color(0xFF2E7D32) : Colors.grey.shade400;
    if (stop.type == 'toll' && isDone) nodeColor = const Color(0xFF1565C0);
    if (stop.type == 'destination') nodeColor = Colors.deepOrange;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: nodeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  stop.type == 'fpo'
                      ? Icons.warehouse
                      : (stop.type == 'toll' ? Icons.toll : Icons.factory),
                  size: 12,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? const Color(0xFF81C784) : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stop.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDone ? AppTheme.darkGrey : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (stop.arrivalTime != null)
                        Text(
                          stop.arrivalTime!,
                          style: GoogleFonts.inter(fontSize: 11, color: isDone ? AppTheme.primaryGreen : Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stop.locationName,
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  if (stop.notes != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      stop.notes!,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.blueGrey.shade700, fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (stop.slipNumber != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        'Slip: ${stop.slipNumber} • Verified',
                        style: GoogleFonts.robotoMono(fontSize: 10, color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 6. Driver & Fleet Telemetry Card
  Widget _buildFleetTelemetryCard(MultiFpoShipmentRoute route) {
    final rawAllocs = (_liveOrder?['fpoAllocations'] as List<dynamic>?) ??
        (_liveOrder?['contributions'] as List<dynamic>?);
    final isMulti = (_liveOrder?['isMultiFpo'] == true || _liveOrder?['isPooled'] == true) &&
        (rawAllocs != null && rawAllocs.length > 1);

    final totalAmt = (_liveOrder?['totalAmount'] as num?)?.toDouble() ??
        (isMulti ? 7350000.0 : 573300.0);
    final formattedAmt = totalAmt.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

    final escrowText = isMulti
        ? '₹$formattedAmt (Tripartite Smart Contract)'
        : '₹$formattedAmt (Single FPO Escrow)';

    final vehicle = (_liveOrder?['vehicleNumber'] ?? widget.vehicleNumber).toString();
    final driver = (_liveOrder?['driverName'] ?? widget.driverName).toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text('Fleet Telemetry & Escrow', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTelemetryRow('Lead Vehicle', vehicle, Icons.directions_car),
          _buildTelemetryRow('Driver', driver, Icons.person),
          _buildTelemetryRow('Moisture & QA', '11.8% Moisture • 78 kg/hL Hectoliter', Icons.check_circle_outline),
          _buildTelemetryRow('Escrow Locked', escrowText, Icons.account_balance_wallet_outlined),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkGrey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 7. Electronic Weighbridge Slips & Digital Escrow
  Widget _buildWeighbridgeCertificateCard(MultiFpoShipmentRoute route) {
    final rawAllocs = (_liveOrder?['fpoAllocations'] as List<dynamic>?) ??
        (_liveOrder?['contributions'] as List<dynamic>?);
    final isMulti = (_liveOrder?['isMultiFpo'] == true || _liveOrder?['isPooled'] == true) &&
        (rawAllocs != null && rawAllocs.length > 1);

    final qtyQtl = (_liveOrder?['quantityQtl'] as num?)?.toDouble() ??
        (_liveOrder?['totalQuantityQtl'] as num?)?.toDouble() ??
        ((_liveOrder?['quantityMT'] as num?)?.toDouble() != null ? (_liveOrder!['quantityMT'] as num).toDouble() * 10 : null) ??
        (isMulti ? 3000.0 : 234.0);

    final title = isMulti
        ? 'Digital Weighment Slips (${qtyQtl.toStringAsFixed(0)} Qtl Batch)'
        : 'Digital Weighment Slip & FASTag Pass';

    final fpoName = (_liveOrder?['fpoName'] ?? _liveOrder?['sellerName'] ?? 'Karnal Agro Producer Co.').toString();
    final orderSuffix = widget.orderId.length > 4 ? widget.orderId.substring(widget.orderId.length - 4) : '9912';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
            ],
          ),
          const SizedBox(height: 12),
          if (isMulti) ...[
            _buildDocItem('Karnal Agro Silo Gross: 1,200 Qtl', 'WB-9912', true),
            _buildDocItem('Taraori Kisan Silo Gross: 1,000 Qtl', 'WB-9913', true),
            _buildDocItem('Gharaunda Center Gross: 800 Qtl', 'WB-9914', true),
            _buildDocItem('NHAI Toll Plaza Electronic Pass', 'FASTag-778942', true),
          ] else ...[
            _buildDocItem('$fpoName Gross: ${qtyQtl.toStringAsFixed(0)} Qtl', 'WB-$orderSuffix', true),
            _buildDocItem('NHAI Toll Plaza Electronic Pass', 'FASTag-778942', true),
            _buildDocItem('Quality Compliance Certificate (Grade A)', 'QC-PASS-88', true),
          ],
        ],
      ),
    );
  }

  Widget _buildDocItem(String title, String code, bool verified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(verified ? Icons.check_circle : Icons.pending, color: verified ? Colors.green : Colors.grey, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Text(code, style: GoogleFonts.robotoMono(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
