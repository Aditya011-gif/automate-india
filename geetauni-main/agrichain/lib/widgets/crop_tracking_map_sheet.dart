import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../services/smart_contract_pdf_service.dart';
import '../services/road_routing_service.dart';

/// Modal Bottom Sheet providing live Google Maps & OpenStreetMap tracking for crop orders.
/// Displays farm origin, courier in transit along real asphalt roads (OSRM geometry),
/// live vehicle marker with pulsing radar waves, and buyer delivery destination.
class CropTrackingMapSheet extends StatefulWidget {
  final Map<String, dynamic> order;

  const CropTrackingMapSheet({super.key, required this.order});

  static void show(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CropTrackingMapSheet(order: order),
    );
  }

  @override
  State<CropTrackingMapSheet> createState() => _CropTrackingMapSheetState();
}

class _CropTrackingMapSheetState extends State<CropTrackingMapSheet> with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;

  // Map Tile API selection: 0 = Google Maps Roadmap, 1 = Google Satellite Hybrid, 2 = OpenStreetMap
  int _selectedMapType = 0;

  // Origin (Farmer cluster hub) & Destination (Buyer address) coordinates
  late final LatLng _originPos;
  late final LatLng _destinationPos;
  late LatLng _courierPos;
  late List<LatLng> _routePoints;

  double _roadDistanceKm = 0.0;
  int _roadEtaMins = 0;
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Origin coordinate (Farm) & Destination (Buyer)
    final double originLat = (widget.order['farmerLat'] as num?)?.toDouble() ?? 29.7420;
    final double originLng = (widget.order['farmerLng'] as num?)?.toDouble() ?? 76.9550;
    _originPos = LatLng(originLat, originLng);

    final double destLat = (widget.order['buyerLat'] as num?)?.toDouble() ?? 29.6857;
    final double destLng = (widget.order['buyerLng'] as num?)?.toDouble() ?? 76.9905;
    _destinationPos = LatLng(destLat, destLng);

    // Initial fallback route
    _setupInitialFallbackRoute();

    // Fetch exact asphalt road geometry via OSRM Driving Route API
    _fetchRealRoadRoute(originLat, originLng, destLat, destLng);
  }

  void _setupInitialFallbackRoute() {
    final status = (widget.order['status'] ?? 'active').toString().toLowerCase();
    final double progress = status == 'delivered' ? 1.0 : (status == 'in_transit' ? 0.65 : 0.15);

    final midLat = (_originPos.latitude + _destinationPos.latitude) / 2 + 0.006;
    final midLng = (_originPos.longitude + _destinationPos.longitude) / 2 - 0.005;

    _routePoints = [
      _originPos,
      LatLng((_originPos.latitude + midLat) / 2, (_originPos.longitude + midLng) / 2),
      LatLng(midLat, midLng),
      LatLng((midLat + _destinationPos.latitude) / 2, (midLng + _destinationPos.longitude) / 2),
      _destinationPos,
    ];

    _courierPos = LatLng(
      _originPos.latitude + (_destinationPos.latitude - _originPos.latitude) * progress,
      _originPos.longitude + (_destinationPos.longitude - _originPos.longitude) * progress,
    );

    _roadDistanceKm = 8.4;
    _roadEtaMins = 25;
  }

  /// Live Real Road Snapped Route from OSRM Driving API via RoadRoutingService
  Future<void> _fetchRealRoadRoute(double startLat, double startLng, double endLat, double endLng) async {
    try {
      final result = await RoadRoutingService().getMultiStopRoute([
        LatLng(startLat, startLng),
        LatLng(endLat, endLng),
      ]);

      if (mounted && result.points.isNotEmpty) {
        setState(() {
          _routePoints = result.points;
          _roadDistanceKm = result.distanceKm;
          _roadEtaMins = result.durationMinutes;
          _isLoadingRoute = false;
          _updateCourierPositionOnRoad();
        });
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Routing service notice (using fallback): $e');
    }

    if (mounted) {
      setState(() => _isLoadingRoute = false);
    }
  }

  void _updateCourierPositionOnRoad() {
    if (_routePoints.isEmpty) return;
    final status = (widget.order['status'] ?? 'active').toString().toLowerCase();

    if (status == 'delivered') {
      _courierPos = _routePoints.last;
    } else if (status == 'in_transit') {
      // Pick index along the 60-70% mark of the road vertices
      final targetIdx = (_routePoints.length * 0.65).floor().clamp(0, _routePoints.length - 1);
      _courierPos = _routePoints[targetIdx];
    } else {
      // Dispatched / at farm
      _courierPos = _routePoints.first;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  String get _tileUrl {
    switch (_selectedMapType) {
      case 0:
        return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}'; // Google Maps Road
      case 1:
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}'; // Google Satellite Hybrid
      case 2:
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'; // OpenStreetMap
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final orderId = order['orderId']?.toString() ?? order['id']?.toString() ?? 'ORD-001';
    final cropName = order['cropName']?.toString() ?? 'Farm Produce';
    final farmerName = order['farmerName']?.toString() ?? 'Local Verified Kisaan';
    final buyerAddress = order['deliveryAddress']?.toString() ?? 'Buyer Delivery Address, Karnal';
    final status = (order['status'] ?? 'active').toString().toLowerCase();
    final isDelivered = status == 'delivered';
    final isInTransit = status == 'in_transit';
    final deliveryOtp = order['deliveryOtp']?.toString() ?? '482915';

    final centerPoint = LatLng(
      (_originPos.latitude + _destinationPos.latitude) / 2,
      (_originPos.longitude + _destinationPos.longitude) / 2,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDelivered
                                  ? const Color(0xFFDCFCE7)
                                  : (isInTransit ? const Color(0xFFDBEAFE) : const Color(0xFFFEF3C7)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isDelivered
                                      ? Icons.check_circle
                                      : (isInTransit ? Icons.local_shipping : Icons.schedule),
                                  size: 12,
                                  color: isDelivered
                                      ? const Color(0xFF15803D)
                                      : (isInTransit ? const Color(0xFF1D4ED8) : const Color(0xFFB45309)),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isDelivered ? 'Delivered' : (isInTransit ? 'In Transit' : 'Dispatched'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDelivered
                                        ? const Color(0xFF15803D)
                                        : (isInTransit ? const Color(0xFF1D4ED8) : const Color(0xFFB45309)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Order #$orderId',
                            style: GoogleFonts.spaceMono(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cropName,
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Live Map Area (Interactive Google Maps / OSM)
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: centerPoint,
                    initialZoom: 12.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                  ),
                  children: [
                    // Real Map Tile Layer (Google Maps / Satellite / OSM)
                    TileLayer(
                      urlTemplate: _tileUrl,
                      userAgentPackageName: 'com.agrichain.app',
                    ),

                    // Delivery Route Polyline (Snapped to real roads)
                    PolylineLayer(
                      polylines: [
                        // Background shadow
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 6.5,
                          color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                        ),
                        // Foreground solid route
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 4.0,
                          color: const Color(0xFF2563EB),
                        ),
                      ],
                    ),

                    // Markers Layer
                    MarkerLayer(
                      markers: [
                        // 1. Origin: Farmer Farm Pin
                        Marker(
                          point: _originPos,
                          width: 48,
                          height: 48,
                          child: Tooltip(
                            message: 'Pickup: $farmerName',
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B5E20),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                              ),
                              child: const Icon(Icons.agriculture, color: Colors.white, size: 24),
                            ),
                          ),
                        ),

                        // 2. Destination: Buyer Delivery Pin
                        Marker(
                          point: _destinationPos,
                          width: 48,
                          height: 48,
                          child: Tooltip(
                            message: 'Deliver To: $buyerAddress',
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                              ),
                              child: const Icon(Icons.location_on, color: Colors.white, size: 24),
                            ),
                          ),
                        ),

                        // 3. Live Animated Courier Marker with Radar Pulse
                        if (!isDelivered)
                          Marker(
                            point: _courierPos,
                            width: 64,
                            height: 64,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Concentric pulsing radar waves
                                    Container(
                                      width: 44 + (_pulseController.value * 20),
                                      height: 44 + (_pulseController.value * 20),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF3B82F6).withValues(alpha: (1.0 - _pulseController.value) * 0.4),
                                      ),
                                    ),
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2.5),
                                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                                      ),
                                      child: const Icon(Icons.local_shipping, color: Colors.white, size: 22),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Floating Map Layer Switcher (Top-Right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMapTypeBtn(0, '🗺️ Google'),
                        const SizedBox(width: 4),
                        _buildMapTypeBtn(1, '🛰️ Satellite'),
                        const SizedBox(width: 4),
                        _buildMapTypeBtn(2, '🌐 OSM'),
                      ],
                    ),
                  ),
                ),

                // Floating ETA Pill (Top-Left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.speed, color: Color(0xFF60A5FA), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          isDelivered
                              ? 'Delivered • Handshake Verified'
                              : 'Real Road: ~$_roadEtaMins mins • ${_roadDistanceKm.toStringAsFixed(1)} km',
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (_isLoadingRoute) ...[
                          const SizedBox(width: 6),
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Recenter Button (Bottom-Right)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter_map',
                    onPressed: () {
                      _mapController.move(centerPoint, 12.0);
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 3,
                    child: const Icon(Icons.my_location, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Details & Handshake Section
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Delivery OTP Handshake Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.pin, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Doorstep Delivery OTP',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isDelivered ? 'VERIFIED • ESCROW RELEASED' : deliveryOtp,
                                style: GoogleFonts.spaceMono(
                                  fontSize: isDelivered ? 13 : 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: isDelivered ? 1.0 : 3.0,
                                  color: isDelivered ? const Color(0xFF166534) : const Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isDelivered
                                    ? 'Escrow released upon physical receipt'
                                    : 'Share with delivery driver upon physical inspection',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        if (!isDelivered)
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18, color: Color(0xFF2563EB)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: deliveryOtp));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('📋 Delivery OTP copied to clipboard!'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Color(0xFF2563EB),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Journey Milestones
                  _buildMilestone(
                    title: 'Farm Aggregated & Packed',
                    subtitle: 'Picked up from $farmerName farm hub',
                    isDone: true,
                  ),
                  _buildMilestone(
                    title: 'Road Transit (Google Maps Snapped)',
                    subtitle: 'Live transit along Haryana logistics corridor',
                    isDone: isInTransit || isDelivered,
                  ),
                  _buildMilestone(
                    title: 'Doorstep Delivery Handshake',
                    subtitle: 'Destination: $buyerAddress',
                    isDone: isDelivered,
                    isLast: true,
                  ),
                  const SizedBox(height: 14),

                  // 3. Dual-Signed Smart Contract PDF CTA
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        SmartContractPdfService.autoDownloadOrPreviewContract(
                          context: context,
                          order: order,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF1B5E20), size: 18),
                      label: const Text(
                        '📄 View Dual-Signed Smart Contract (PDF)',
                        style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: const Color(0xFFF0FDF4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTypeBtn(int type, String label) {
    final isSelected = _selectedMapType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMapType = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B5E20) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildMilestone({
    required String title,
    required String subtitle,
    required bool isDone,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFF15803D) : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: isDone ? const Color(0xFF15803D) : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDone ? const Color(0xFF0F172A) : Colors.grey.shade500,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
              ),
              if (!isLast) const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }
}
