import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/multi_fpo_clustering_service.dart';
import '../../models/shared_bulk_order_model.dart';
import 'fpo_order_shipment_screen.dart';

/// Screen: Multi-FPO Shared Bulk Order & Cluster Aggregator (7 km Radius)
/// Implements B2B collaborative pooling where neighboring FPOs satisfy large institutional demands.
/// Demonstrates the official scenario:
/// Buyer demands 300 MT wheat -> FPO A (120 MT) + FPO B (100 MT) + FPO C (80 MT) = 300 MT.
class FpoBatchPoolingScreen extends StatefulWidget {
  const FpoBatchPoolingScreen({super.key});

  @override
  State<FpoBatchPoolingScreen> createState() => _FpoBatchPoolingScreenState();
}

class _FpoBatchPoolingScreenState extends State<FpoBatchPoolingScreen> {
  final MultiFpoClusteringService _clusteringService = MultiFpoClusteringService();
  final MapController _mapController = MapController();

  final LatLng _clusterHubCenter = const LatLng(29.6857, 76.9905); // Karnal Central Hub

  late SharedBulkOrder _activeSharedOrder;

  @override
  void initState() {
    super.initState();
    _activeSharedOrder = _clusteringService.buildSharedBulkOrder(
      buyerId: 'BUYER-AGRO-NCR',
      buyerName: 'AgroFoods Milling India Pvt Ltd',
      commodity: 'Sharbati Wheat',
      variety: 'Sharbati 306 (Milling Quality)',
      requiredTonnageMT: 300.0,
      primaryFpoId: 'fpo_karnal_01',
      destinationPlantName: 'AgroFoods Milling Terminal, Kundli (NCR)',
      destinationLat: 28.5355,
      destinationLng: 77.3910,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fulfilledPct = (_activeSharedOrder.totalFulfilledMT / _activeSharedOrder.totalRequiredMT).clamp(0.0, 1.0);
    final myContribution = _activeSharedOrder.getContributionForFpo('fpo_karnal_01');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF00796B),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Multi-FPO Cluster Engine (7 km)',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00796B),
              ),
            ),
            Text(
              'Collaborative B2B Fulfillment • Shared Bulk Orders',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Demand & Fulfillment Status Card
          _buildRequirementSummaryCard(fulfilledPct),
          const SizedBox(height: 14),

          // 2. Capacity Shortage & Cluster Aggregation Explainer
          _buildClusterExplainer(),
          const SizedBox(height: 14),

          // 3. Cluster GPS Map (7 km Geofence Radius + Participating FPOs)
          _buildClusterMapCard(),
          const SizedBox(height: 14),

          // 4. Isolated Contribution Breakdown (No Merged Ownership)
          _buildContributionsBreakdown(),
          const SizedBox(height: 14),

          // 5. My FPO's Direct Operational Summary
          if (myContribution != null) _buildMyFpoCommitmentCard(myContribution),
          const SizedBox(height: 20),

          // 6. Action Button: Inspect Fleet & Track Shipment
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FpoOrderShipmentScreen(
                      orderId: 'BPO-84920',
                      buyerName: 'AgroFoods Milling India Pvt Ltd',
                      commodity: '3,000 Qtl Sharbati Wheat (Karnal Cluster)',
                      destination: 'Industrial Processing Plant, NCR Hub',
                      vehicleNumber: 'HR-05-AB-9842 (Lead) + 2 Fleet Trucks',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.alt_route),
              label: const Text('Track Multi-FPO Shipment & Toll Route'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRequirementSummaryCard(double fulfilledPct) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00796B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('ACTIVE INSTITUTIONAL DEMAND', style: TextStyle(color: Color(0xFF00796B), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Text('Contract ID: BPO-84920', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${(_activeSharedOrder.totalRequiredMT * 10).toStringAsFixed(0)} Qtl ${_activeSharedOrder.cropName}',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(
            'Buyer: ${_activeSharedOrder.buyerName} • Destination: ${_activeSharedOrder.destinationPlantName}',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // Fulfillment Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cluster Fulfillment: ${(_activeSharedOrder.totalFulfilledMT * 10).toStringAsFixed(0)} / ${(_activeSharedOrder.totalRequiredMT * 10).toStringAsFixed(0)} Qtl',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
              ),
              Text('${(fulfilledPct * 100).toInt()}% Assembled', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00796B))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fulfilledPct,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00796B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterExplainer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF80CBC4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.hub, color: Color(0xFF00796B), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your FPO has 1,200 Qtl available. Because demand is 3,000 Qtl, the Multi-FPO Cluster Engine pooled Taraori FPO (1,000 Qtl) & Gharaunda FPO (800 Qtl) within a 7 km radius to fulfill 100% of volume.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF004D40), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterMapCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.radar, color: Color(0xFF00796B), size: 18),
                    const SizedBox(width: 8),
                    Text('7 km Geospatial Cluster Geofence', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Radius ≤ 6.8 km', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _clusterHubCenter,
                  initialZoom: 11.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                    userAgentPackageName: 'com.agrichain.app',
                  ),

                  // 7 km Proximity Radius Circle
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _clusterHubCenter,
                        radius: 6800,
                        useRadiusInMeter: true,
                        color: const Color(0xFF00796B).withValues(alpha: 0.12),
                        borderColor: const Color(0xFF00796B),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),

                  // Polyline connecting the 3 FPO Godowns
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _activeSharedOrder.contributions.map((c) => LatLng(c.warehouseLat, c.warehouseLng)).toList(),
                        strokeWidth: 3.0,
                        color: const Color(0xFF00796B),
                      ),
                    ],
                  ),

                  // Markers for each FPO
                  MarkerLayer(
                    markers: _activeSharedOrder.contributions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final c = entry.value;
                      final isMe = c.fpoId == 'fpo_karnal_01';

                      return Marker(
                        point: LatLng(c.warehouseLat, c.warehouseLng),
                        width: 42,
                        height: 42,
                        child: Tooltip(
                          message: '${c.fpoName} (${(c.contributedQuantityMT * 10).toStringAsFixed(0)} Qtl)',
                          child: Container(
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFF00796B) : const Color(0xFF1E293B),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionsBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Separate Contribution Records', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
              const Text('3 FPOs Combined', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00796B))),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Ownership and payout accounts remain strictly independent.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const Divider(height: 20),

          ..._activeSharedOrder.contributions.map((c) {
            final isMe = c.fpoId == 'fpo_karnal_01';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFE0F2F1).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isMe ? const Color(0xFF80CBC4) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF00796B) : const Color(0xFF64748B),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        isMe ? 'YOU' : 'FPO',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.fpoName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: isMe ? const Color(0xFF0F172A) : const Color(0xFF0F172A)),
                        ),
                        Text('Silo: ${c.warehouseName}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${(c.contributedQuantityMT * 10).toStringAsFixed(0)} Qtl',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF00796B))),
                      Text('₹${c.ratePerQtl.toStringAsFixed(0)}/Qtl', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMyFpoCommitmentCard(FpoContributionRecord my) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified, color: Color(0xFF15803D), size: 18),
                  SizedBox(width: 6),
                  Text('Your FPO Contribution Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF15803D), borderRadius: BorderRadius.circular(4)),
                child: const Text('RESERVED & LOCKED', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Committed Volume:', style: TextStyle(fontSize: 12)),
              Text('${(my.contributedQuantityMT * 10).toStringAsFixed(0)} Qtl (of 1,200 Qtl Total Available)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Expected Gross Payout:', style: TextStyle(fontSize: 12)),
              Text('₹${my.grossPayableAmount.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF15803D))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Freight & Logistics Share:', style: TextStyle(fontSize: 12)),
              Text('- ₹${my.freightShare.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Net Escrow Settlement Payable:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text('₹${my.netPayableAmount.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF15803D))),
            ],
          ),
        ],
      ),
    );
  }
}
