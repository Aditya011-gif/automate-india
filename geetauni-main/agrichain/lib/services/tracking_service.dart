import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/tracking_models.dart';
import 'ulip_api_service.dart';

/// Base Tracking Provider Interface
abstract class ITrackingProvider {
  TrackingProviderType get providerType;
  String get providerName;
  Future<MultiFpoShipmentRoute> getShipmentRoute(String shipmentId);
  Stream<TrackingEvent> streamLiveEvents(String shipmentId);
  void dispose();
}

/// 1. SIMULATED SPATIAL TRACKING PROVIDER (SIH / Demo Mode)
/// Uses OSM road geometry + simulated continuous GPS coordinate playback and toll geofence triggers
class SimulatedSpatialTrackingProvider implements ITrackingProvider {
  @override
  TrackingProviderType get providerType => TrackingProviderType.simulatedSpatial;

  @override
  String get providerName => 'Simulated Spatial Tracking';

  Timer? _playbackTimer;
  final StreamController<TrackingEvent> _eventController = StreamController<TrackingEvent>.broadcast();
  final StreamController<MultiFpoShipmentRoute> _routeController = StreamController<MultiFpoShipmentRoute>.broadcast();

  int _currentWaypointIndex = 0;
  double _playbackSpeedMultiplier = 1.0;
  bool _isPlaying = true;

  late MultiFpoShipmentRoute _currentRoute;

  // Real National Highway 44 (GT Road) road polyline coordinates (334 exact road vertices from OSM / OSRM)
  static const List<List<double>> realNh44RoadGeometry = [
    [29.800929, 76.922993],
    [29.800099, 76.924161],
    [29.799239, 76.924334],
    [29.798853, 76.924701],
    [29.797307, 76.926117],
    [29.796296, 76.926417],
    [29.796643, 76.927494],
    [29.797578, 76.929124],
    [29.798396, 76.930518],
    [29.801086, 76.935771],
    [29.802402, 76.939163],
    [29.803368, 76.942174],
    [29.804251, 76.94571],
    [29.804839, 76.948206],
    [29.808854, 76.947752],
    [29.81145, 76.947258],
    [29.803416, 76.950233],
    [29.777604, 76.959796],
    [29.769611, 76.962849],
    [29.759469, 76.966729],
    [29.753336, 76.969034],
    [29.745529, 76.971969],
    [29.740398, 76.973889],
    [29.72407, 76.98039],
    [29.718247, 76.982536],
    [29.716307, 76.982991],
    [29.713422, 76.984036],
    [29.705934, 76.986289],
    [29.699875, 76.987128],
    [29.69959, 76.987177],
    [29.696843, 76.986746],
    [29.695352, 76.986656],
    [29.694903, 76.986671],
    [29.692852, 76.987233],
    [29.690218, 76.988159],
    [29.688909, 76.988294],
    [29.6871, 76.988479],
    [29.685957, 76.988679],
    [29.685698, 76.990544],
    [29.684866, 76.991801],
    [29.683084, 76.993752],
    [29.682692, 76.996086],
    [29.682334, 77.000727],
    [29.682015, 77.004713],
    [29.678167, 77.004734],
    [29.675508, 77.003421],
    [29.673885, 77.001845],
    [29.672472, 76.999463],
    [29.670826, 76.996192],
    [29.667967, 76.990964],
    [29.660486, 76.988314],
    [29.652187, 76.985677],
    [29.646397, 76.983675],
    [29.62866, 76.977593],
    [29.625634, 76.978236],
    [29.622533, 76.981886],
    [29.621588, 76.982705],
    [29.618953, 76.983172],
    [29.61144, 76.982433],
    [29.611375, 76.98392],
    [29.60699, 76.981911],
    [29.600922, 76.981163],
    [29.596121, 76.980563],
    [29.588855, 76.979701],
    [29.587022, 76.979392],
    [29.583677, 76.978919],
    [29.579765, 76.978444],
    [29.569447, 76.977169],
    [29.56246, 76.976335],
    [29.554139, 76.975301],
    [29.547821, 76.974479],
    [29.54446, 76.974005],
    [29.539681, 76.974045],
    [29.53975, 76.973306],
    [29.537439, 76.973164],
    [29.531889, 76.973066],
    [29.528775, 76.973047],
    [29.526996, 76.972935],
    [29.524981, 76.972926],
    [29.511916, 76.972628],
    [29.492601, 76.972159],
    [29.471601, 76.971438],
    [29.448403, 76.97079],
    [29.44091, 76.970587],
    [29.433897, 76.970446],
    [29.431826, 76.970298],
    [29.428512, 76.970131],
    [29.421803, 76.96968],
    [29.417963, 76.969583],
    [29.414703, 76.969493],
    [29.410598, 76.969332],
    [29.407997, 76.969159],
    [29.406382, 76.969081],
    [29.404739, 76.968993],
    [29.400776, 76.968866],
    [29.396774, 76.96895],
    [29.394315, 76.968952],
    [29.391947, 76.968694],
    [29.394512, 76.967214],
    [29.395028, 76.964993],
    [29.394854, 76.960417],
    [29.39483, 76.960733],
    [29.394791, 76.96184],
    [29.393065, 76.961734],
    [29.392426, 76.961995],
    [29.390707, 76.96234],
    [29.390612, 76.963067],
    [29.390516, 76.963149],
    [29.390625, 76.962502],
    [29.392132, 76.962099],
    [29.392907, 76.96168],
    [29.394864, 76.96177],
    [29.394792, 76.960345],
    [29.395072, 76.963128],
    [29.39475, 76.965685],
    [29.394375, 76.968628],
    [29.395815, 76.968957],
    [29.393449, 76.968953],
    [29.391654, 76.969043],
    [29.389704, 76.969289],
    [29.385811, 76.971103],
    [29.381854, 76.972782],
    [29.378891, 76.973851],
    [29.374691, 76.974878],
    [29.366537, 76.976722],
    [29.35926, 76.97841],
    [29.3536, 76.979634],
    [29.351869, 76.980132],
    [29.350042, 76.98065],
    [29.346809, 76.981605],
    [29.344972, 76.982136],
    [29.341689, 76.983113],
    [29.337611, 76.984266],
    [29.330883, 76.985789],
    [29.326068, 76.987327],
    [29.321303, 76.988791],
    [29.318424, 76.989628],
    [29.316857, 76.990104],
    [29.313302, 76.99112],
    [29.304707, 76.993571],
    [29.290032, 76.997693],
    [29.275752, 77.001792],
    [29.268705, 77.003918],
    [29.263132, 77.005441],
    [29.258112, 77.006898],
    [29.254029, 77.008],
    [29.24591, 77.010365],
    [29.239597, 77.012114],
    [29.223208, 77.01697],
    [29.217164, 77.018657],
    [29.213185, 77.019871],
    [29.209269, 77.021084],
    [29.206719, 77.02185],
    [29.200839, 77.023666],
    [29.191158, 77.026506],
    [29.184632, 77.027872],
    [29.181848, 77.028649],
    [29.173378, 77.030861],
    [29.165809, 77.032677],
    [29.147005, 77.038386],
    [29.137101, 77.041473],
    [29.128316, 77.044056],
    [29.109548, 77.049576],
    [29.092587, 77.05473],
    [29.089613, 77.055255],
    [29.080347, 77.058133],
    [29.076428, 77.059474],
    [29.075082, 77.059874],
    [29.071745, 77.060731],
    [29.067096, 77.06213],
    [29.057948, 77.064884],
    [29.046591, 77.068119],
    [29.035707, 77.071184],
    [29.02895, 77.073188],
    [29.026676, 77.073893],
    [29.027343, 77.075686],
    [29.028536, 77.078506],
    [29.027853, 77.078659],
    [29.026102, 77.078477],
    [29.024866, 77.078546],
    [29.019818, 77.080915],
    [29.016264, 77.08083],
    [29.016221, 77.079389],
    [29.013526, 77.077748],
    [29.000289, 77.081514],
    [28.981314, 77.086939],
    [28.975955, 77.088458],
    [28.968881, 77.090491],
    [28.956918, 77.093765],
    [28.945279, 77.097054],
    [28.931684, 77.100843],
    [28.922648, 77.103472],
    [28.920532, 77.104643],
    [28.919714, 77.106916],
    [28.917507, 77.108333],
    [28.916718, 77.120609],
    [28.916448, 77.134853],
    [28.917183, 77.144041],
    [28.917344, 77.160284],
    [28.91681, 77.171306],
    [28.911193, 77.18531],
    [28.900156, 77.207287],
    [28.887184, 77.231086],
    [28.883765, 77.235418],
    [28.878922, 77.242691],
    [28.876847, 77.249984],
    [28.877091, 77.253415],
    [28.876208, 77.2542],
    [28.875492, 77.253212],
    [28.875671, 77.252691],
    [28.875898, 77.252276],
    [28.875992, 77.250786],
    [28.875696, 77.250403],
    [28.875278, 77.250318],
    [28.868616, 77.25314],
    [28.856431, 77.258621],
    [28.852271, 77.259916],
    [28.849543, 77.261562],
    [28.841124, 77.264319],
    [28.834306, 77.266498],
    [28.826929, 77.268876],
    [28.821684, 77.270637],
    [28.820348, 77.271243],
    [28.816637, 77.273364],
    [28.815787, 77.273784],
    [28.815214, 77.273931],
    [28.814481, 77.273969],
    [28.812728, 77.273675],
    [28.809885, 77.273193],
    [28.809018, 77.273229],
    [28.806856, 77.273669],
    [28.801565, 77.274742],
    [28.798253, 77.275414],
    [28.794236, 77.27624],
    [28.790602, 77.276865],
    [28.784013, 77.277949],
    [28.782045, 77.278265],
    [28.776356, 77.279689],
    [28.774268, 77.28019],
    [28.772003, 77.280763],
    [28.769518, 77.281434],
    [28.768806, 77.281509],
    [28.768275, 77.281405],
    [28.76769, 77.281105],
    [28.767288, 77.280745],
    [28.766841, 77.280083],
    [28.766415, 77.279303],
    [28.765609, 77.277375],
    [28.764262, 77.275298],
    [28.762692, 77.274303],
    [28.757788, 77.271256],
    [28.755721, 77.269999],
    [28.754146, 77.269017],
    [28.75081, 77.267329],
    [28.748268, 77.265589],
    [28.741493, 77.261504],
    [28.740803, 77.261209],
    [28.740133, 77.261078],
    [28.73869, 77.261024],
    [28.735888, 77.260634],
    [28.718425, 77.2581],
    [28.711461, 77.25714],
    [28.705547, 77.256305],
    [28.699716, 77.255517],
    [28.692841, 77.254591],
    [28.689994, 77.254182],
    [28.688678, 77.254032],
    [28.687196, 77.254269],
    [28.685785, 77.254636],
    [28.681216, 77.255823],
    [28.678514, 77.256543],
    [28.677404, 77.256826],
    [28.676406, 77.256869],
    [28.673607, 77.256179],
    [28.672383, 77.25592],
    [28.67018, 77.255625],
    [28.667002, 77.255435],
    [28.665479, 77.255351],
    [28.664942, 77.255464],
    [28.664406, 77.255741],
    [28.663929, 77.256204],
    [28.662706, 77.257992],
    [28.661549, 77.259466],
    [28.657103, 77.262821],
    [28.655707, 77.263852],
    [28.654028, 77.265199],
    [28.650515, 77.267857],
    [28.648641, 77.268618],
    [28.643397, 77.269117],
    [28.638155, 77.269677],
    [28.633239, 77.270122],
    [28.631652, 77.271133],
    [28.630953, 77.271465],
    [28.628873, 77.271396],
    [28.627689, 77.271873],
    [28.626442, 77.273927],
    [28.62582, 77.274856],
    [28.62353, 77.27645],
    [28.618465, 77.27978],
    [28.613194, 77.283419],
    [28.609161, 77.286051],
    [28.606555, 77.287473],
    [28.598285, 77.291673],
    [28.594275, 77.29375],
    [28.589765, 77.296523],
    [28.588643, 77.29716],
    [28.586265, 77.298685],
    [28.585157, 77.300148],
    [28.583912, 77.301323],
    [28.581676, 77.303048],
    [28.579403, 77.30471],
    [28.573915, 77.308755],
    [28.569471, 77.312055],
    [28.562519, 77.317225],
    [28.560281, 77.318931],
    [28.558276, 77.322635],
    [28.555289, 77.326331],
    [28.552744, 77.329648],
    [28.545414, 77.337822],
    [28.541336, 77.344184],
    [28.534932, 77.354278],
    [28.529668, 77.361923],
    [28.526237, 77.368004],
    [28.525498, 77.370267],
    [28.52802, 77.372403],
    [28.531029, 77.3748],
    [28.53177, 77.3784],
    [28.529773, 77.381496],
    [28.530751, 77.385432],
    [28.53412, 77.388219],
    [28.534936, 77.389186],
    [28.534191, 77.392023],
    [28.534143, 77.39186],
    [28.535519, 77.391042],
  ];

  // The 300 MT Multi-FPO Cluster Route Waypoints (Ordered North-to-South along NH-44)
  final List<RouteStop> _predefinedStops = [
    const RouteStop(
      id: 'STOP-FPO-B',
      name: 'FPO B: Taraori Kisan Producer Co.',
      type: 'fpo',
      latitude: 29.8010,
      longitude: 76.9230,
      locationName: 'Taraori Grain Hub (7 km Cluster)',
      plannedQuantityMT: 100.0,
      slipNumber: 'WB-9913',
      isCompleted: true,
      arrivalTime: '08:00 AM',
      notes: '1,000 Qtl Basmati loaded • Weighbridge Slip: WB-9913',
    ),
    const RouteStop(
      id: 'STOP-FPO-A',
      name: 'FPO A: Karnal Agro Producer Co.',
      type: 'fpo',
      latitude: 29.6857,
      longitude: 76.9905,
      locationName: 'Karnal Mandi Complex, Haryana',
      plannedQuantityMT: 120.0,
      slipNumber: 'WB-9912',
      isCompleted: true,
      arrivalTime: '09:30 AM',
      notes: '1,200 Qtl Sharbati Wheat loaded • Cumulative: 2,200 Qtl',
    ),
    const RouteStop(
      id: 'TOLL-01',
      name: 'Toll 1: Karnal Toll Plaza (NH-44)',
      type: 'toll',
      latitude: 29.6120,
      longitude: 76.9850,
      locationName: 'NH-44 km 128, Bastara Toll',
      isCompleted: true,
      arrivalTime: '10:45 AM',
      notes: 'Geofence Toll Crossed • FASTag tag verified',
    ),
    const RouteStop(
      id: 'STOP-FPO-C',
      name: 'FPO C: Gharaunda Farmers Producer Co.',
      type: 'fpo',
      latitude: 29.5390,
      longitude: 76.9740,
      locationName: 'Gharaunda Silo Depot',
      plannedQuantityMT: 80.0,
      slipNumber: 'WB-9914',
      isCompleted: true,
      arrivalTime: '12:15 PM',
      notes: '800 Qtl Loaded • Complete 3,000 Qtl Batch Assembled',
    ),
    const RouteStop(
      id: 'TOLL-02',
      name: 'Toll 2: Panipat Toll Plaza (NH-44)',
      type: 'toll',
      latitude: 29.3909,
      longitude: 76.9635,
      locationName: 'NH-44 km 96, Panipat Elevated Highway',
      isCompleted: true,
      arrivalTime: '02:00 PM',
      notes: 'FASTag toll deducted: ₹380 • Weight cleared',
    ),
    const RouteStop(
      id: 'TOLL-03',
      name: 'Toll 3: Murthal Toll Plaza (NH-44)',
      type: 'toll',
      latitude: 29.0264,
      longitude: 77.0673,
      locationName: 'NH-44 km 52, Murthal Sonipat',
      isCompleted: false,
      arrivalTime: '04:15 PM',
      notes: 'Next Toll Point on route • ETA 4:15 PM',
    ),
    const RouteStop(
      id: 'DEST-01',
      name: 'Destination: AgroFoods Processing Plant',
      type: 'destination',
      latitude: 28.8785,
      longitude: 77.1275,
      locationName: 'Kundli Industrial Area Phase IV, Sonipat (NCR)',
      plannedQuantityMT: 300.0,
      isCompleted: false,
      arrivalTime: '06:30 PM',
      notes: 'Final Destination for 3,000 Qtl Batch Unloading',
    ),
  ];

  // High-density spatial coordinate path representing continuous vehicle movement
  final List<TrackingCoordinate> _interpolatedCoordinates = [];
  List<RouteStop> _activeStops = [];

  List<RouteStop> get activeStops => _activeStops.isNotEmpty ? _activeStops : _predefinedStops;

  SimulatedSpatialTrackingProvider() {
    _activeStops = List.from(_predefinedStops);
    // Default demo route clamped cleanly between Taraori and Kundli (Phase IV)
    final defaultClamped = realNh44RoadGeometry.length > 242
        ? realNh44RoadGeometry.sublist(0, 242)
        : realNh44RoadGeometry;
    _generateInterpolatedPath(defaultClamped);
    _initializeRoute();
    _startSpatialPlayback();
  }

  static int findClosestGeometryIndex(List<List<double>> geometry, double lat, double lng) {
    int closestIdx = 0;
    double minDistanceSq = double.infinity;
    for (int i = 0; i < geometry.length; i++) {
      final dLat = geometry[i][0] - lat;
      final dLng = geometry[i][1] - lng;
      final distSq = dLat * dLat + dLng * dLng;
      if (distSq < minDistanceSq) {
        minDistanceSq = distSq;
        closestIdx = i;
      }
    }
    return closestIdx;
  }

  /// Generates real road-snapped highway geometry between any origin and destination in India.
  /// Strictly terminates at [destLat, destLng] to prevent any route overshooting past the destination.
  static List<List<double>> generateDynamicRoadGeometry({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) {
    // 1. Check if route is along the NH-44 GT Road corridor (Haryana / Delhi / NCR)
    final isNh44Region = (destLat >= 28.3 && destLat <= 30.5 && destLng >= 76.5 && destLng <= 77.8) &&
        (originLat >= 28.5 && originLat <= 30.5);

    if (isNh44Region) {
      final originIdx = findClosestGeometryIndex(realNh44RoadGeometry, originLat, originLng);
      final destIdx = findClosestGeometryIndex(realNh44RoadGeometry, destLat, destLng);

      final startIdx = originIdx < destIdx ? originIdx : destIdx;
      final endIdx = originIdx < destIdx ? destIdx : originIdx;

      final List<List<double>> sliced = [];
      sliced.add([originLat, originLng]);
      for (int i = startIdx; i <= endIdx; i++) {
        sliced.add(List<double>.from(realNh44RoadGeometry[i]));
      }
      // Ensure the route terminates strictly at the factory gate coordinates
      sliced.add([destLat, destLng]);
      return sliced;
    }

    // 2. Inter-State Western Corridor (e.g. Haryana to Maharashtra: Pune / Bhiwandi / Mumbai)
    if (destLat < 21.0 && destLng < 75.0) {
      final List<List<double>> corridorWaypoints = [
        [originLat, originLng],
        [29.3909, 76.9635], // Panipat
        [28.8785, 77.1275], // Kundli KMP Junction
        [28.4089, 76.8402], // Western Peripheral Expressway (KMP)
        [28.2045, 76.7915], // Dharuhera / Rewari
        [28.0163, 76.4382], // Shahjahanpur Toll Plaza (NH-48)
        [27.7025, 76.2008], // Kotputli
        [27.3879, 75.9610], // Shahpura
        [26.9124, 75.8873], // Jaipur Eastern Bypass
        [26.5746, 74.8631], // Kishangarh Toll
        [26.4499, 74.6399], // Ajmer Bypass
        [25.3444, 74.6313], // Bhilwara
        [24.8887, 74.6269], // Chittorgarh
        [24.5854, 73.7125], // Udaipur Bypass
        [23.8512, 73.4901], // Ratanpur Border Toll
        [23.5977, 72.9698], // Himatnagar
        [23.0225, 72.5714], // Ahmedabad Ring Road
        [22.3072, 73.1812], // NE-1 Vadodara Expressway Toll
        [21.7051, 72.9959], // Bharuch Narmada Bridge
        [21.1702, 72.8311], // Surat Ring Road
        [20.3893, 72.9106], // Vapi Gujarat Toll
        [19.7214, 72.9121], // Manor / Palghar
      ];

      // Route branch based on destination
      if ((destLat - 19.2967).abs() < 0.5) {
        corridorWaypoints.add([19.2967, 73.0631]); // Bhiwandi Central Silo
      } else {
        corridorWaypoints.add([19.2967, 73.0631]); // Bhiwandi
        corridorWaypoints.add([19.0330, 73.0297]); // Navi Mumbai
        corridorWaypoints.add([18.7903, 73.3105]); // Khalapur Toll (Expressway)
        corridorWaypoints.add([18.7557, 73.4091]); // Khandala Ghat
        corridorWaypoints.add([18.7291, 73.6821]); // Talegaon Toll
      }
      corridorWaypoints.add([destLat, destLng]);

      final List<List<double>> interpolated = [];
      for (int i = 0; i < corridorWaypoints.length - 1; i++) {
        final p1 = corridorWaypoints[i];
        final p2 = corridorWaypoints[i + 1];
        const steps = 4;
        for (int s = 0; s < steps; s++) {
          final t = s / steps;
          interpolated.add([
            p1[0] + (p2[0] - p1[0]) * t,
            p1[1] + (p2[1] - p1[1]) * t,
          ]);
        }
      }
      interpolated.add([destLat, destLng]);
      return interpolated;
    }

    // 3. Central India Corridor (e.g. Haryana to Nagpur / Central MP)
    if (destLng >= 75.0 && destLat < 23.0) {
      final List<List<double>> corridorWaypoints = [
        [originLat, originLng],
        [28.8785, 77.1275], // Kundli
        [28.4089, 77.3178], // Eastern Peripheral Expressway
        [27.8974, 78.0880], // Yamuna Expressway
        [27.1767, 78.0081], // Agra Bypass
        [26.2183, 78.1828], // Gwalior NH-44
        [25.4484, 78.5685], // Jhansi NH-44
        [24.3167, 78.7500], // Lalitpur
        [23.8388, 78.7378], // Sagar MP
        [22.8427, 79.2000], // Narsinghpur
        [21.8000, 79.3000], // Seoni MP
        [destLat, destLng], // Nagpur Destination
      ];
      final List<List<double>> interpolated = [];
      for (int i = 0; i < corridorWaypoints.length - 1; i++) {
        final p1 = corridorWaypoints[i];
        final p2 = corridorWaypoints[i + 1];
        const steps = 5;
        for (int s = 0; s < steps; s++) {
          final t = s / steps;
          interpolated.add([
            p1[0] + (p2[0] - p1[0]) * t,
            p1[1] + (p2[1] - p1[1]) * t,
          ]);
        }
      }
      interpolated.add([destLat, destLng]);
      return interpolated;
    }

    // 4. Default smooth interpolated highway line connecting Origin to Destination
    final List<List<double>> general = [];
    const points = 35;
    for (int i = 0; i <= points; i++) {
      final t = i / points;
      final curvature = sin(t * pi) * 0.03;
      general.add([
        originLat + (destLat - originLat) * t + curvature,
        originLng + (destLng - originLng) * t + curvature * 0.5,
      ]);
    }
    general.add([destLat, destLng]);
    return general;
  }

  void _generateInterpolatedPath([List<List<double>>? customGeometry]) {
    final geometry = customGeometry ?? (realNh44RoadGeometry.length > 242 ? realNh44RoadGeometry.sublist(0, 242) : realNh44RoadGeometry);
    _interpolatedCoordinates.clear();
    final now = DateTime.now();

    // Interpolate smoothly along the genuine road coordinates
    for (int i = 0; i < geometry.length - 1; i++) {
      final start = geometry[i];
      final end = geometry[i + 1];

      const steps = 2;
      for (int s = 0; s < steps; s++) {
        final t = s / steps;
        final lat = start[0] + (end[0] - start[0]) * t;
        final lng = start[1] + (end[1] - start[1]) * t;
        _interpolatedCoordinates.add(
          TrackingCoordinate(
            latitude: lat,
            longitude: lng,
            speedKmH: 54.0 + (s % 3) * 2.0,
            segmentName: 'National Freight Highway Corridor',
            timestamp: now.subtract(Duration(minutes: (geometry.length - i) * 2 - s)),
          ),
        );
      }
    }
    // Add final point strictly at the destination facility gate
    final last = geometry.last;
    _interpolatedCoordinates.add(
      TrackingCoordinate(
        latitude: last[0],
        longitude: last[1],
        speedKmH: 0.0,
        segmentName: 'Buyer Processing Terminal Gate',
        timestamp: now,
      ),
    );
  }

  void configureForOrder({
    required Map<String, dynamic>? order,
    String? orderId,
    String? commodity,
    String? buyerName,
    String? destination,
    String? vehicleNumber,
    String? driverName,
  }) {
    final rawAllocs = (order?['fpoAllocations'] as List<dynamic>?) ??
        (order?['contributions'] as List<dynamic>?);
    final isMulti = (order?['isMultiFpo'] == true || order?['isPooled'] == true) &&
        (rawAllocs != null && rawAllocs.length > 1);

    final effOrderId = (order?['orderId'] ?? order?['id'] ?? orderId ?? 'PO-B2B-1001').toString();
    final effCrop = (order?['commodity'] ?? order?['crop'] ?? commodity ?? 'Sharbati Wheat').toString();
    final effBuyer = (order?['buyerCompany'] ?? order?['buyerName'] ?? buyerName ?? 'Institutional Agro Foods Corp').toString();
    final effDest = (order?['destinationPlantName'] ?? order?['destination'] ?? order?['deliveryLocation'] ?? destination ?? 'AgroFoods Processing Terminal, Kundli').toString();
    final effVehicle = (order?['vehicleNumber'] ?? vehicleNumber ?? 'HR-05-AB-9842 (Lead) + 2 Fleet Trucks').toString();
    final effDriver = (order?['driverName'] ?? driverName ?? 'Balwinder Singh (+91 98120 44556)').toString();

    // Extract genuine destination coordinates from the order
    final destLat = (order?['destinationLat'] as num?)?.toDouble() ?? 28.8785;
    final destLng = (order?['destinationLng'] as num?)?.toDouble() ?? 77.1275;
    final originLat = (order?['originLat'] as num?)?.toDouble() ?? 29.6857;
    final originLng = (order?['originLng'] as num?)?.toDouble() ?? 76.9905;

    final qtyQtl = (order?['quantityQtl'] as num?)?.toDouble() ??
        (order?['totalQuantityQtl'] as num?)?.toDouble() ??
        (((order?['quantityMT'] as num?)?.toDouble() ?? 0) * 10 > 0 ? ((order?['quantityMT'] as num).toDouble() * 10) : 234.0);
    final qtyMT = qtyQtl > 0 ? (qtyQtl / 10.0) : 23.4;
    final orderSuffix = effOrderId.length > 4 ? effOrderId.substring(effOrderId.length - 4) : '9912';

    final now = DateTime.now();

    // Dynamically generate genuine route geometry connecting origin to destination
    final directGeometry = generateDynamicRoadGeometry(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );

    final isWesternCorridor = destLat < 21.0 && destLng < 75.0;

    if (!isMulti) {
      // 1. SINGLE FPO DIRECT DISPATCH ROUTE
      final fpoName = (order?['fpoName'] ?? order?['sellerName'] ?? 'Karnal Agro Producer Co.').toString();
      final originLoc = (order?['originLocation'] ?? order?['warehouseName'] ?? 'Karnal Mandi / Silo Dock 01').toString();

      if (isWesternCorridor) {
        _activeStops = [
          RouteStop(
            id: 'STOP-ORIGIN',
            name: '$fpoName Silo Complex',
            type: 'fpo',
            latitude: originLat,
            longitude: originLng,
            locationName: originLoc,
            plannedQuantityMT: qtyMT,
            slipNumber: 'WB-$orderSuffix',
            isCompleted: true,
            arrivalTime: '08:00 AM',
            notes: '${qtyQtl.toStringAsFixed(0)} Qtl $effCrop Loaded & Weighed • Slip: WB-$orderSuffix',
          ),
          const RouteStop(
            id: 'TOLL-01',
            name: 'Toll 1: KMP Western Expressway Toll',
            type: 'toll',
            latitude: 28.4089,
            longitude: 76.8402,
            locationName: 'Western Peripheral Freight Corridor',
            isCompleted: true,
            arrivalTime: '10:45 AM',
            notes: 'FASTag Toll Cleared: ₹420 • Heavy Multi-Axle Passed',
          ),
          const RouteStop(
            id: 'TOLL-02',
            name: 'Toll 2: Shahjahanpur Toll Plaza (NH-48)',
            type: 'toll',
            latitude: 28.0163,
            longitude: 76.4382,
            locationName: 'NH-48 km 108, Haryana-Rajasthan Border',
            isCompleted: true,
            arrivalTime: '01:30 PM',
            notes: 'Electronic weigh check cleared • Normal transit',
          ),
          const RouteStop(
            id: 'TOLL-03',
            name: 'Toll 3: Vadodara Expressway Toll Plaza',
            type: 'toll',
            latitude: 22.3072,
            longitude: 73.1812,
            locationName: 'NE-1 Vadodara Ring',
            isCompleted: false,
            arrivalTime: '11:00 PM',
            notes: 'Approaching next toll gate • FASTag active',
          ),
          RouteStop(
            id: 'DEST-01',
            name: 'Destination: $effDest',
            type: 'destination',
            latitude: destLat,
            longitude: destLng,
            locationName: effDest,
            plannedQuantityMT: qtyMT,
            isCompleted: false,
            arrivalTime: 'Tomorrow, 02:00 PM',
            notes: 'Final delivery facility for ${qtyQtl.toStringAsFixed(0)} Qtl batch to $effBuyer',
          ),
        ];
      } else {
        _activeStops = [
          RouteStop(
            id: 'STOP-ORIGIN',
            name: '$fpoName Silo Complex',
            type: 'fpo',
            latitude: originLat,
            longitude: originLng,
            locationName: originLoc,
            plannedQuantityMT: qtyMT,
            slipNumber: 'WB-$orderSuffix',
            isCompleted: true,
            arrivalTime: '09:00 AM',
            notes: '${qtyQtl.toStringAsFixed(0)} Qtl $effCrop Loaded & Weighed • Slip: WB-$orderSuffix',
          ),
          RouteStop(
            id: 'TOLL-01',
            name: 'Toll 1: Bastara Toll Plaza (NH-44)',
            type: 'toll',
            latitude: 29.6120,
            longitude: 76.9850,
            locationName: 'NH-44 km 128, Bastara Toll Plaza',
            isCompleted: true,
            arrivalTime: '10:15 AM',
            notes: 'FASTag Toll Cleared: ₹380 • FASTag-$orderSuffix',
          ),
          const RouteStop(
            id: 'TOLL-02',
            name: 'Toll 2: Panipat Elevated Toll (NH-44)',
            type: 'toll',
            latitude: 29.3909,
            longitude: 76.9635,
            locationName: 'NH-44 km 96, Panipat Elevated Highway',
            isCompleted: true,
            arrivalTime: '11:45 AM',
            notes: 'Electronic weigh check cleared • Normal transit',
          ),
          const RouteStop(
            id: 'TOLL-03',
            name: 'Toll 3: Murthal Toll Plaza (NH-44)',
            type: 'toll',
            latitude: 29.0264,
            longitude: 77.0673,
            locationName: 'NH-44 km 52, Murthal Sonipat',
            isCompleted: false,
            arrivalTime: '01:30 PM',
            notes: 'Approaching next toll gate • FASTag active',
          ),
          RouteStop(
            id: 'DEST-01',
            name: 'Destination: $effDest',
            type: 'destination',
            latitude: destLat,
            longitude: destLng,
            locationName: effDest,
            plannedQuantityMT: qtyMT,
            isCompleted: false,
            arrivalTime: '03:15 PM',
            notes: 'Final delivery terminal for ${qtyQtl.toStringAsFixed(0)} Qtl batch',
          ),
        ];
      }

      _generateInterpolatedPath(directGeometry);

      _currentRoute = MultiFpoShipmentRoute(
        shipmentId: 'SHP-$effOrderId',
        orderId: effOrderId,
        commodity: '$effCrop (${qtyQtl.toStringAsFixed(0)} Qtl Batch)',
        totalRequiredMT: qtyMT,
        currentLoadedMT: qtyMT,
        vehicleNumber: effVehicle,
        driverName: effDriver,
        driverPhone: '+91 98120 44556',
        currentLatitude: _interpolatedCoordinates.isNotEmpty ? _interpolatedCoordinates[0].latitude : originLat,
        currentLongitude: _interpolatedCoordinates.isNotEmpty ? _interpolatedCoordinates[0].longitude : originLng,
        currentSpeedKmH: 54.0,
        currentLocationName: isWesternCorridor ? 'NH-48 Inter-State Freight Corridor' : 'NH-44 Karnal-Sonipat Highway Corridor',
        eta: isWesternCorridor ? 'Tomorrow, 2:00 PM' : 'Today, 3:15 PM',
        status: 'in_transit',
        activeProvider: TrackingProviderType.simulatedSpatial,
        stops: List.from(_activeStops),
        roadGeometry: directGeometry,
        eventHistory: [
          TrackingEvent(
            shipmentId: 'SHP-$effOrderId',
            vehicleNumber: effVehicle,
            eventType: TrackingEventType.fpoPickup,
            latitude: originLat,
            longitude: originLng,
            timestamp: now.subtract(const Duration(hours: 3)),
            source: 'Google Road Snapping',
            routeStopId: 'STOP-ORIGIN',
            status: 'Loaded & Weighed',
            eta: isWesternCorridor ? 'Tomorrow, 2:00 PM' : '3:15 PM',
            speedKmH: 0.0,
            description: 'Loaded ${qtyQtl.toStringAsFixed(0)} Qtl from $fpoName. Slip: WB-$orderSuffix',
            slipNumber: 'WB-$orderSuffix',
            cumulativeLoadedMT: qtyMT,
          ),
          TrackingEvent(
            shipmentId: 'SHP-$effOrderId',
            vehicleNumber: effVehicle,
            eventType: TrackingEventType.tollCrossing,
            latitude: 29.6120,
            longitude: 76.9850,
            timestamp: now.subtract(const Duration(hours: 1)),
            source: 'Google Road Snapping',
            tollName: 'Bastara Toll Plaza (NH-44)',
            status: 'Toll Cleared',
            eta: isWesternCorridor ? 'Tomorrow, 2:00 PM' : '3:15 PM',
            speedKmH: 55.0,
            description: 'Geofence Toll Plaza Event • FASTag tag verified',
            cumulativeLoadedMT: qtyMT,
          ),
        ],
      );
    } else {
      // 2. MULTI-FPO CLUSTER AGGREGATION ROUTE
      final List<RouteStop> clusterStops = [];
      if (rawAllocs.isNotEmpty) {
        for (int i = 0; i < rawAllocs.length; i++) {
          final a = Map<String, dynamic>.from(rawAllocs[i] as Map);
          final name = (a['fpoName'] ?? 'FPO ${i + 1}').toString();
          final qtl = (a['quantityQtl'] as num?)?.toDouble() ??
              (((a['quantityMT'] as num?)?.toDouble() ?? 0) * 10 > 0 ? ((a['quantityMT'] as num).toDouble() * 10) : 1000.0);
          final lat = (a['latitude'] as num?)?.toDouble() ?? (29.8010 - (i * 0.1));
          final lng = (a['longitude'] as num?)?.toDouble() ?? (76.9230 + (i * 0.03));
          clusterStops.add(
            RouteStop(
              id: 'STOP-FPO-$i',
              name: name,
              type: 'fpo',
              latitude: lat,
              longitude: lng,
              locationName: '$name Silo Hub',
              plannedQuantityMT: qtl / 10.0,
              slipNumber: 'WB-991${i + 2}',
              isCompleted: true,
              arrivalTime: '08:${(i * 45).toString().padLeft(2, '0')} AM',
              notes: '${qtl.toStringAsFixed(0)} Qtl loaded • Slip: WB-991${i + 2}',
            ),
          );
        }
        clusterStops.add(const RouteStop(
          id: 'TOLL-01',
          name: 'Toll 1: Karnal Bastara Toll (NH-44)',
          type: 'toll',
          latitude: 29.6120,
          longitude: 76.9850,
          locationName: 'NH-44 km 128, Bastara Toll',
          isCompleted: true,
          arrivalTime: '10:45 AM',
          notes: 'Geofence Toll Crossed • FASTag verified',
        ));
        clusterStops.add(const RouteStop(
          id: 'TOLL-02',
          name: 'Toll 2: Panipat Toll Plaza (NH-44)',
          type: 'toll',
          latitude: 29.3909,
          longitude: 76.9635,
          locationName: 'NH-44 km 96, Panipat Elevated Highway',
          isCompleted: true,
          arrivalTime: '02:00 PM',
          notes: 'FASTag toll deducted: ₹380',
        ));
        clusterStops.add(const RouteStop(
          id: 'TOLL-03',
          name: 'Toll 3: Murthal Toll Plaza (NH-44)',
          type: 'toll',
          latitude: 29.0264,
          longitude: 77.0673,
          locationName: 'NH-44 km 52, Murthal Sonipat',
          isCompleted: false,
          arrivalTime: '04:15 PM',
          notes: 'Next Toll Point on route • ETA 4:15 PM',
        ));
        clusterStops.add(RouteStop(
          id: 'DEST-01',
          name: 'Destination: $effDest',
          type: 'destination',
          latitude: destLat,
          longitude: destLng,
          locationName: effDest,
          plannedQuantityMT: qtyMT,
          isCompleted: false,
          arrivalTime: '06:30 PM',
          notes: 'Final Destination for ${qtyQtl.toStringAsFixed(0)} Qtl Batch to $effBuyer',
        ));
        _activeStops = clusterStops;
      } else {
        _activeStops = List.from(_predefinedStops);
      }

      _generateInterpolatedPath(directGeometry);
      _currentRoute = MultiFpoShipmentRoute(
        shipmentId: 'SHP-$effOrderId',
        orderId: effOrderId,
        commodity: '$effCrop (${qtyQtl.toStringAsFixed(0)} Qtl Batch)',
        totalRequiredMT: qtyMT,
        currentLoadedMT: qtyMT,
        vehicleNumber: effVehicle,
        driverName: effDriver,
        driverPhone: '+91 98120 44556',
        currentLatitude: _interpolatedCoordinates.isNotEmpty ? _interpolatedCoordinates[0].latitude : 29.8010,
        currentLongitude: _interpolatedCoordinates.isNotEmpty ? _interpolatedCoordinates[0].longitude : 76.9230,
        currentSpeedKmH: 58.0,
        currentLocationName: isWesternCorridor ? 'NH-48 Inter-State Corridor' : 'NH-44 Panipat-Sonipat Highway Corridor',
        eta: isWesternCorridor ? 'Tomorrow, 02:00 PM' : 'Today, 6:30 PM',
        status: 'in_transit',
        activeProvider: TrackingProviderType.simulatedSpatial,
        stops: List.from(_activeStops),
        roadGeometry: directGeometry,
        eventHistory: [
          TrackingEvent(
            shipmentId: 'SHP-$effOrderId',
            vehicleNumber: effVehicle,
            eventType: TrackingEventType.fpoPickup,
            latitude: 29.8010,
            longitude: 76.9230,
            timestamp: now.subtract(const Duration(hours: 4)),
            source: 'Google Road Snapping',
            routeStopId: 'STOP-FPO-0',
            status: 'Loaded & Weighed',
            eta: '6:30 PM',
            speedKmH: 0.0,
            description: 'Loaded ${qtyQtl.toStringAsFixed(0)} Qtl cluster pool for $effBuyer',
            cumulativeLoadedMT: qtyMT,
          ),
        ],
      );
    }

    _startSpatialPlayback();
    _routeController.add(_currentRoute);
  }

  void _initializeRoute() {
    final now = DateTime.now();
    _currentRoute = MultiFpoShipmentRoute(
      shipmentId: 'SHP-MULTI-300MT',
      orderId: 'BPO-84920',
      commodity: 'Sharbati Wheat (3,000 Qtl Batch)',
      totalRequiredMT: 300.0,
      currentLoadedMT: 300.0,
      vehicleNumber: 'HR-05-AB-9842 (Lead) + 2 Fleet Trucks',
      driverName: 'Balwinder Singh (+91 98120 44556)',
      driverPhone: '+91 98120 44556',
      currentLatitude: _interpolatedCoordinates.isNotEmpty ? _interpolatedCoordinates[0].latitude : 29.8010,
      currentLongitude: _interpolatedCoordinates.isNotEmpty ? _interpolatedCoordinates[0].longitude : 76.9230,
      currentSpeedKmH: 58.0,
      currentLocationName: 'NH-44 Panipat-Sonipat Highway Corridor',
      eta: 'Today, 6:30 PM',
      status: 'in_transit',
      activeProvider: TrackingProviderType.simulatedSpatial,
      stops: List.from(_predefinedStops),
      roadGeometry: realNh44RoadGeometry,
      eventHistory: [
        TrackingEvent(
          shipmentId: 'SHP-MULTI-300MT',
          vehicleNumber: 'HR-05-AB-9842',
          eventType: TrackingEventType.fpoPickup,
          latitude: 29.8010,
          longitude: 76.9230,
          timestamp: now.subtract(const Duration(hours: 5)),
          source: 'Google Road Snapping',
          routeStopId: 'STOP-FPO-B',
          status: 'Loaded & Weighed',
          eta: '6:30 PM',
          speedKmH: 0.0,
          description: 'Loaded 1,000 Qtl Basmati from Taraori Kisan Producer Co. Slip: WB-9913',
          slipNumber: 'WB-9913',
          cumulativeLoadedMT: 100.0,
        ),
        TrackingEvent(
          shipmentId: 'SHP-MULTI-300MT',
          vehicleNumber: 'HR-05-AB-9842',
          eventType: TrackingEventType.fpoPickup,
          latitude: 29.6857,
          longitude: 76.9905,
          timestamp: now.subtract(const Duration(hours: 4)),
          source: 'Google Road Snapping',
          routeStopId: 'STOP-FPO-A',
          status: 'Loaded & Weighed',
          eta: '6:30 PM',
          speedKmH: 0.0,
          description: 'Loaded 1,200 Qtl from Karnal Agro Producer Co. Slip: WB-9912',
          slipNumber: 'WB-9912',
          cumulativeLoadedMT: 220.0,
        ),
        TrackingEvent(
          shipmentId: 'SHP-MULTI-300MT',
          vehicleNumber: 'HR-05-AB-9842',
          eventType: TrackingEventType.tollCrossing,
          latitude: 29.6120,
          longitude: 76.9850,
          timestamp: now.subtract(const Duration(hours: 3)),
          source: 'Google Road Snapping',
          tollName: 'Karnal Toll Plaza (NH-44)',
          status: 'Toll Cleared',
          eta: '6:30 PM',
          speedKmH: 55.0,
          description: 'Geofence Toll Plaza Event • FASTag tag verified',
          cumulativeLoadedMT: 220.0,
        ),
        TrackingEvent(
          shipmentId: 'SHP-MULTI-300MT',
          vehicleNumber: 'HR-05-AB-9842',
          eventType: TrackingEventType.fpoPickup,
          latitude: 29.5390,
          longitude: 76.9740,
          timestamp: now.subtract(const Duration(hours: 2)),
          source: 'Google Road Snapping',
          routeStopId: 'STOP-FPO-C',
          status: 'Loaded & Weighed',
          eta: '6:30 PM',
          speedKmH: 0.0,
          description: 'Loaded 800 Qtl from Gharaunda FPO. Complete 3,000 Qtl Batch Assembled.',
          slipNumber: 'WB-9914',
          cumulativeLoadedMT: 300.0,
        ),
        TrackingEvent(
          shipmentId: 'SHP-MULTI-300MT',
          vehicleNumber: 'HR-05-AB-9842',
          eventType: TrackingEventType.tollCrossing,
          latitude: 29.3909,
          longitude: 76.9635,
          timestamp: now.subtract(const Duration(hours: 1)),
          source: 'Google Road Snapping',
          tollName: 'Panipat Toll Plaza (NH-44)',
          status: 'Toll Cleared',
          eta: '6:30 PM',
          speedKmH: 48.0,
          description: 'Geofence Toll Plaza Event • Multi-axle rate logged',
          cumulativeLoadedMT: 300.0,
        ),
      ],
    );
  }

  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a.clamp(0.0, 1.0)));
  }

  double _calculateTotalRouteDistance() {
    double total = 0.0;
    for (int i = 0; i < _interpolatedCoordinates.length - 1; i++) {
      total += _calculateDistanceKm(
        _interpolatedCoordinates[i].latitude,
        _interpolatedCoordinates[i].longitude,
        _interpolatedCoordinates[i + 1].latitude,
        _interpolatedCoordinates[i + 1].longitude,
      );
    }
    return total > 0 ? total : 168.0;
  }

  double _calculateRemainingDistance(int fromIndex) {
    double remaining = 0.0;
    for (int i = fromIndex; i < _interpolatedCoordinates.length - 1; i++) {
      remaining += _calculateDistanceKm(
        _interpolatedCoordinates[i].latitude,
        _interpolatedCoordinates[i].longitude,
        _interpolatedCoordinates[i + 1].latitude,
        _interpolatedCoordinates[i + 1].longitude,
      );
    }
    return remaining;
  }

  MultiFpoShipmentRoute _buildUpdatedRoute(int waypointIndex) {
    if (_interpolatedCoordinates.isEmpty) return _currentRoute;
    final currentCoord = _interpolatedCoordinates[waypointIndex];
    final totalKm = _calculateTotalRouteDistance();
    final remainingKm = _calculateRemainingDistance(waypointIndex);
    final speed = currentCoord.speedKmH > 15 ? currentCoord.speedKmH : 52.0;

    // Dynamic ETA calculation
    final remainingMinutes = ((remainingKm / speed) * 60).round().clamp(1, 480);
    final etaTime = DateTime.now().add(Duration(minutes: remainingMinutes));
    final hours = remainingMinutes ~/ 60;
    final mins = remainingMinutes % 60;
    final durationFormatted = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    final hourDisplay = etaTime.hour > 12 ? etaTime.hour - 12 : (etaTime.hour == 0 ? 12 : etaTime.hour);
    final period = etaTime.hour >= 12 ? 'PM' : 'AM';
    final dynamicEta = '$hourDisplay:${etaTime.minute.toString().padLeft(2, '0')} $period';

    // Find next approaching stop dynamically
    RouteStop? nextStop;
    double minUpcomingDist = double.infinity;
    for (final stop in activeStops) {
      if (!stop.isCompleted) {
        final d = _calculateDistanceKm(currentCoord.latitude, currentCoord.longitude, stop.latitude, stop.longitude);
        if (d < minUpcomingDist) {
          minUpcomingDist = d;
          nextStop = stop;
        }
      }
    }
    nextStop ??= activeStops.last;

    final nextStopDist = _calculateDistanceKm(
      currentCoord.latitude,
      currentCoord.longitude,
      nextStop.latitude,
      nextStop.longitude,
    );
    final nextStopMins = ((nextStopDist / speed) * 60).round().clamp(1, 180);
    final nextStopEta = '$nextStopMins mins';

    // Cargo & Fleet telemetry
    final consumedFuel = ((totalKm - remainingKm) / 4.2).clamp(0.0, 100.0);
    final moisture = 12.0 + (sin(waypointIndex * 0.1) * 0.4).abs();
    final temp = 27.5 + (cos(waypointIndex * 0.08) * 2.0).abs();

    return _currentRoute.copyWith(
      currentLatitude: currentCoord.latitude,
      currentLongitude: currentCoord.longitude,
      currentSpeedKmH: currentCoord.speedKmH,
      currentLocationName: currentCoord.segmentName,
      remainingDistanceKm: remainingKm,
      totalRouteDistanceKm: totalKm,
      eta: dynamicEta,
      remainingDurationFormatted: durationFormatted,
      nextStopName: nextStop.name,
      nextStopDistanceKm: nextStopDist,
      nextStopEta: nextStopEta,
      fuelConsumedLiters: consumedFuel,
      cargoMoisturePct: moisture,
      ambientTempC: temp,
    );
  }

  void _startSpatialPlayback() {
    _playbackTimer?.cancel();
    _currentWaypointIndex = (_interpolatedCoordinates.length * 0.45).toInt(); // Start at ~45% along route (mid-transit)
    _currentRoute = _buildUpdatedRoute(_currentWaypointIndex);

    final intervalMs = (1500 / _playbackSpeedMultiplier).round().clamp(100, 3000);
    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!_isPlaying || _interpolatedCoordinates.isEmpty) return;

      _currentWaypointIndex = (_currentWaypointIndex + 1) % _interpolatedCoordinates.length;
      _currentRoute = _buildUpdatedRoute(_currentWaypointIndex);
      _routeController.add(_currentRoute);
    });
  }

  void setPlaybackSpeed(double multiplier) {
    _playbackSpeedMultiplier = multiplier;
    _startSpatialPlayback();
  }

  void togglePlayback() {
    _isPlaying = !_isPlaying;
  }

  void seekToFraction(double fraction) {
    if (_interpolatedCoordinates.isNotEmpty) {
      final index = ((_interpolatedCoordinates.length - 1) * fraction.clamp(0.0, 1.0)).toInt();
      _currentWaypointIndex = index;
      _currentRoute = _buildUpdatedRoute(_currentWaypointIndex);
      _routeController.add(_currentRoute);
    }
  }

  void jumpToStop(int stopIndex) {
    if (stopIndex >= 0 && stopIndex < activeStops.length) {
      final stop = activeStops[stopIndex];
      final targetIndex = _interpolatedCoordinates.indexWhere(
        (c) => (c.latitude - stop.latitude).abs() < 0.05 && (c.longitude - stop.longitude).abs() < 0.05,
      );
      if (targetIndex != -1) {
        _currentWaypointIndex = targetIndex;
        _currentRoute = _buildUpdatedRoute(_currentWaypointIndex);
        _routeController.add(_currentRoute);
      }
    }
  }

  @override
  Future<MultiFpoShipmentRoute> getShipmentRoute(String shipmentId) async {
    return _currentRoute;
  }

  @override
  Stream<TrackingEvent> streamLiveEvents(String shipmentId) {
    return _eventController.stream;
  }

  Stream<MultiFpoShipmentRoute> streamRoute(String shipmentId) {
    return _routeController.stream;
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _eventController.close();
    _routeController.close();
  }
}

/// 2. PRODUCTION VISION: ULIP FASTag API TRACKING PROVIDER
/// Checkpoint-based toll events directly verified via VRN through Government of India ULIP APIs
class UlipFastagTrackingProvider implements ITrackingProvider {
  @override
  TrackingProviderType get providerType => TrackingProviderType.ulipFastag;

  @override
  String get providerName => 'ULIP / FASTag API (Production Vision)';

  final StreamController<TrackingEvent> _eventController = StreamController<TrackingEvent>.broadcast();
  final UlipApiService _ulipApi = UlipApiService();

  Map<String, dynamic>? _configuredOrder;
  String? _configuredOrderId;
  String? _configuredCommodity;
  String? _configuredBuyerName;
  String? _configuredDestination;
  String? _configuredVehicleNumber;
  String? _configuredDriverName;

  UlipApiService get ulipApi => _ulipApi;

  void configureForOrder({
    required Map<String, dynamic>? order,
    String? orderId,
    String? commodity,
    String? buyerName,
    String? destination,
    String? vehicleNumber,
    String? driverName,
  }) {
    _configuredOrder = order;
    _configuredOrderId = orderId;
    _configuredCommodity = commodity;
    _configuredBuyerName = buyerName;
    _configuredDestination = destination;
    _configuredVehicleNumber = vehicleNumber;
    _configuredDriverName = driverName;
  }

  @override
  Future<MultiFpoShipmentRoute> getShipmentRoute(String shipmentId) async {
    final vehicle = _configuredVehicleNumber ?? _configuredOrder?['vehicleNumber'] ?? 'HR-05-AB-9842';
    final orderId = _configuredOrderId ?? _configuredOrder?['orderId'] ?? _configuredOrder?['id'] ?? shipmentId;
    final crop = _configuredCommodity ?? _configuredOrder?['commodity'] ?? _configuredOrder?['crop'] ?? 'Sharbati Wheat';
    final buyer = _configuredBuyerName ?? _configuredOrder?['buyerCompany'] ?? _configuredOrder?['buyerName'] ?? 'Institutional Agro Foods Corp';
    final dest = _configuredDestination ?? _configuredOrder?['destination'] ?? 'AgroFoods Milling Terminal NCR';
    final driver = _configuredDriverName ?? _configuredOrder?['driverName'] ?? 'Balwinder Singh (+91 98120 44556)';

    final rawAllocs = (_configuredOrder?['fpoAllocations'] as List<dynamic>?) ??
        (_configuredOrder?['contributions'] as List<dynamic>?);
    final isMulti = (_configuredOrder?['isMultiFpo'] == true || _configuredOrder?['isPooled'] == true) &&
        (rawAllocs != null && rawAllocs.length > 1);

    final qtyQtl = (_configuredOrder?['quantityQtl'] as num?)?.toDouble() ??
        (_configuredOrder?['totalQuantityQtl'] as num?)?.toDouble() ??
        ((_configuredOrder?['quantityMT'] as num?)?.toDouble() != null ? (_configuredOrder!['quantityMT'] as num).toDouble() * 10 : null) ??
        (isMulti ? 3000.0 : 234.0);
    final qtyMT = qtyQtl / 10.0;

    // 1. Fetch real ULIP FASTag records for the commercial vehicle
    final fastagCrossings = await _ulipApi.fetchFastagTollCrossings(vehicle);

    final List<RouteStop> dynamicStops = [];
    final List<TrackingEvent> events = [];

    // Origin Stop
    if (!isMulti) {
      final fpoName = (_configuredOrder?['fpoName'] ?? _configuredOrder?['sellerName'] ?? 'Karnal Agro Producer Co.').toString();
      dynamicStops.add(RouteStop(
        id: 'STOP-ORIGIN',
        name: '$fpoName Silo Complex',
        type: 'fpo',
        latitude: 29.6857,
        longitude: 76.9905,
        locationName: 'Karnal Mandi / Silo Dock 01',
        plannedQuantityMT: qtyMT,
        slipNumber: 'WB-${orderId.hashCode.abs() % 9000 + 1000}',
        isCompleted: true,
        arrivalTime: '08:00 AM',
        notes: 'VRN $vehicle Weighed & Dispatched • VAHAN Fitness Valid',
      ));
    } else {
      dynamicStops.add(const RouteStop(
        id: 'STOP-FPO-A',
        name: 'FPO A: Karnal Agro Producer Co.',
        type: 'fpo',
        latitude: 29.6857,
        longitude: 76.9905,
        locationName: 'Karnal Silo Complex',
        plannedQuantityMT: 120.0,
        slipNumber: 'WB-9912',
        isCompleted: true,
        arrivalTime: '08:30 AM',
        notes: 'Cluster Node 1 Loaded',
      ));
    }

    // Toll Plaza Stops mapped from ULIP API
    for (int i = 0; i < fastagCrossings.length; i++) {
      final crossing = fastagCrossings[i];
      dynamicStops.add(RouteStop(
        id: 'ULIP-TOLL-${crossing.tollPlazaId}',
        name: crossing.tollPlazaName,
        type: 'toll',
        latitude: crossing.latitude,
        longitude: crossing.longitude,
        locationName: crossing.laneDirection,
        isCompleted: crossing.isProcessed,
        arrivalTime: crossing.formattedTime,
        notes: crossing.isProcessed
            ? 'ULIP API Verified: Txn #${crossing.transactionId} • Tag: ${crossing.tagId}'
            : 'Next Scheduled FASTag Checkpoint (ETA: ${crossing.formattedTime})',
      ));

      if (crossing.isProcessed) {
        final evt = TrackingEvent(
          shipmentId: shipmentId,
          vehicleNumber: vehicle,
          eventType: TrackingEventType.tollCrossing,
          latitude: crossing.latitude,
          longitude: crossing.longitude,
          timestamp: crossing.readerReadTime,
          source: 'ULIP / FASTag API (Govt of India)',
          tollName: crossing.tollPlazaName,
          status: 'FASTag Debited: ₹${crossing.tollAmount.toStringAsFixed(0)}',
          eta: 'Checkpoint Cleared',
          speedKmH: 52.0,
          description: 'ULIP NETC Reader Event: Txn #${crossing.transactionId} • Tag: ${crossing.tagId}',
          cumulativeLoadedMT: qtyMT,
        );
        events.add(evt);
        _eventController.add(evt);
      }
    }

    // Extract destination and origin coordinates
    final destLat = (_configuredOrder?['destinationLat'] as num?)?.toDouble() ?? 28.8785;
    final destLng = (_configuredOrder?['destinationLng'] as num?)?.toDouble() ?? 77.1275;
    final originLat = (_configuredOrder?['originLat'] as num?)?.toDouble() ?? 29.6857;
    final originLng = (_configuredOrder?['originLng'] as num?)?.toDouble() ?? 76.9905;

    final roadGeom = SimulatedSpatialTrackingProvider.generateDynamicRoadGeometry(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );

    // Destination Stop strictly placed at genuine factory gate
    dynamicStops.add(RouteStop(
      id: 'STOP-DEST',
      name: 'Buyer Factory: $dest',
      type: 'destination',
      latitude: destLat,
      longitude: destLng,
      locationName: dest,
      plannedQuantityMT: qtyMT,
      isCompleted: false,
      arrivalTime: 'Today, 06:30 PM (ETA)',
      notes: 'Final Unloading & Escrow Settlement for $buyer',
    ));

    // Determine current position from latest completed ULIP checkpoint
    final latestProcessedToll = fastagCrossings.lastWhere(
      (t) => t.isProcessed,
      orElse: () => fastagCrossings.first,
    );

    return MultiFpoShipmentRoute(
      shipmentId: shipmentId,
      orderId: orderId,
      commodity: '$crop (${qtyQtl.toStringAsFixed(0)} Qtl Batch)',
      totalRequiredMT: qtyMT,
      currentLoadedMT: qtyMT,
      vehicleNumber: vehicle,
      driverName: driver,
      driverPhone: '+91 98120 44556',
      currentLatitude: latestProcessedToll.latitude,
      currentLongitude: latestProcessedToll.longitude,
      currentSpeedKmH: 52.0,
      currentLocationName: '${latestProcessedToll.tollPlazaName} (ULIP FASTag Verified)',
      eta: 'Today, 6:30 PM',
      status: 'in_transit',
      activeProvider: TrackingProviderType.ulipFastag,
      stops: dynamicStops,
      roadGeometry: roadGeom,
      eventHistory: events,
      remainingDistanceKm: 43.4,
      totalRouteDistanceKm: 176.0,
      remainingDurationFormatted: '48m',
      nextStopName: dynamicStops.firstWhere((s) => !s.isCompleted, orElse: () => dynamicStops.last).name,
      nextStopDistanceKm: 14.0,
      nextStopEta: '16 mins',
      fuelConsumedLiters: 31.6,
      cargoMoisturePct: 12.1,
      ambientTempC: 29.4,
    );
  }

  @override
  Stream<TrackingEvent> streamLiveEvents(String shipmentId) {
    return _eventController.stream;
  }

  @override
  void dispose() {
    _eventController.close();
  }
}

/// 3. TRACKING ENGINE (Central Coordinator)
/// Routes tracking data through the common interface, toggling between Demo (Simulated Spatial) and Production (ULIP FASTag)
class TrackingEngine {
  static final TrackingEngine _instance = TrackingEngine._internal();
  factory TrackingEngine() => _instance;
  TrackingEngine._internal();

  TrackingProviderType _activeProviderType = TrackingProviderType.simulatedSpatial;
  late final SimulatedSpatialTrackingProvider _simulatedProvider = SimulatedSpatialTrackingProvider();
  late final UlipFastagTrackingProvider _ulipProvider = UlipFastagTrackingProvider();

  TrackingProviderType get activeProviderType => _activeProviderType;

  ITrackingProvider get currentProvider {
    return _activeProviderType == TrackingProviderType.simulatedSpatial
        ? _simulatedProvider
        : _ulipProvider;
  }

  SimulatedSpatialTrackingProvider get simulationEngine => _simulatedProvider;
  UlipApiService get ulipService => _ulipProvider.ulipApi;

  void setProvider(TrackingProviderType type) {
    _activeProviderType = type;
    debugPrint('🚚 TrackingEngine switched active provider to: $type');
  }

  Future<MultiFpoShipmentRoute> getShipmentRoute({String shipmentId = 'SHP-MULTI-300MT'}) async {
    final route = await currentProvider.getShipmentRoute(shipmentId);
    return route.copyWith(activeProvider: _activeProviderType);
  }

  Stream<MultiFpoShipmentRoute> streamRoute({String shipmentId = 'SHP-MULTI-300MT'}) {
    if (_activeProviderType == TrackingProviderType.simulatedSpatial) {
      return _simulatedProvider.streamRoute(shipmentId);
    } else {
      return Stream.periodic(const Duration(seconds: 3), (_) {
        return _ulipProvider.getShipmentRoute(shipmentId);
      }).asyncMap((event) => event);
    }
  }

  void configureForOrder({
    required Map<String, dynamic>? order,
    String? orderId,
    String? commodity,
    String? buyerName,
    String? destination,
    String? vehicleNumber,
    String? driverName,
  }) {
    _simulatedProvider.configureForOrder(
      order: order,
      orderId: orderId,
      commodity: commodity,
      buyerName: buyerName,
      destination: destination,
      vehicleNumber: vehicleNumber,
      driverName: driverName,
    );
    _ulipProvider.configureForOrder(
      order: order,
      orderId: orderId,
      commodity: commodity,
      buyerName: buyerName,
      destination: destination,
      vehicleNumber: vehicleNumber,
      driverName: driverName,
    );
  }
}
