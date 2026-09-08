import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../models/farmer_cluster_model.dart';
import '../../services/farmer_clustering_service.dart';
import '../../services/road_routing_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/crop_image_helper.dart';
import 'retail_checkout_screen.dart';

/// Screen: Farmer Grouping & Hyperlocal Produce Pooling (<= 7 km)
/// - Spatial clustering model auto-finding distinct farmers strictly within <= 7 km.
/// - Analyzes crop compatibility, quality grading, tested moisture, and residue-free GAP.
/// - Performs nearest-neighbor pickup route optimization (TSP).
/// - Dynamic custom quantity selector fulfilling retail buyer demand.
/// - Inspect & Map bottom sheet displaying real asphalt road geometry from OSRM Driving API.
class FarmerGroupingScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const FarmerGroupingScreen({super.key, this.onNavigateTab});

  @override
  State<FarmerGroupingScreen> createState() => _FarmerGroupingScreenState();
}

/// Backward compatibility alias
typedef GroupBuyingScreen = FarmerGroupingScreen;

class _FarmerGroupingScreenState extends State<FarmerGroupingScreen> {
  final FarmerClusteringService _clusteringService = FarmerClusteringService();

  String _selectedTagFilter = 'All Clusters';
  final Map<String, double> _selectedQuantities = {};

  double _getQuantity(String clusterId, double fallback) {
    return _selectedQuantities[clusterId] ?? fallback;
  }

  void _setQuantity(String clusterId, double newQty) {
    setState(() {
      _selectedQuantities[clusterId] = newQty.clamp(1.0, 5000.0);
    });
  }

  List<FarmerCluster> _filterClusters(List<FarmerCluster> clusters) {
    if (_selectedTagFilter == '≤ 5 km Radius') {
      return clusters.where((c) => c.maxInterFarmDistance <= 5.0).toList();
    } else if (_selectedTagFilter == '≤ 7 km Radius') {
      return clusters.where((c) => c.maxInterFarmDistance <= 7.0).toList();
    } else if (_selectedTagFilter == 'Residue-Free GAP') {
      return clusters.where((c) {
        final cond = c.conditions['cultivationMethod']?.toString() ?? '';
        return cond.toLowerCase().contains('residue') || cond.toLowerCase().contains('gap') || cond.toLowerCase().contains('bio');
      }).toList();
    } else if (_selectedTagFilter == 'Moisture Certified') {
      return clusters.where((c) {
        final moist = c.conditions['moistureLevel']?.toString() ?? '';
        return moist.contains('%');
      }).toList();
    }
    return clusters;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF1B5E20),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hub, color: Color(0xFF2E7D32), size: 18),
                const SizedBox(width: 6),
                Text(
                  'Farmer Produce Pooling',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            Text(
              '≤ 7 km Proximity Clusters • TSP Route Optimized • Wholesale Rates',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.onNavigateTab != null)
            IconButton(
              icon: const Icon(Icons.storefront_outlined, color: AppTheme.darkGreen),
              tooltip: 'Browse Single Listings',
              onPressed: () => widget.onNavigateTab!(1),
            ),
        ],
      ),
      body: StreamBuilder<List<FarmerCluster>>(
        stream: _clusteringService.streamFarmerClusters(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
          }

          final allClusters = snapshot.data ?? [];
          final filteredClusters = _filterClusters(allClusters);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Hero Banner
              _buildCleanHeroBanner(allClusters.length),
              const SizedBox(height: 14),

              // 2. Filter Chips
              _buildFilterChips(),
              const SizedBox(height: 16),

              // 3. Section Title with Cluster Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active ≤ 7km Hyperlocal Clusters',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${filteredClusters.length} Clusters Ready',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Cluster Cards or Empty State
              if (filteredClusters.isEmpty)
                _buildEmptySourceState()
              else
                ...filteredClusters.map((c) => _buildDetailedClusterCard(c)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCleanHeroBanner(int totalClusters) {
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
            color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
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
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hub, color: Color(0xFF69F0AE), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hyperlocal Proximity Pooling (≤ 7 km)',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Neighboring farms auto-clustered for single-dispatch wholesale savings',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB9F6CA)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Summary Badges
          Row(
            children: [
              _buildBannerStat(Icons.scatter_plot, '$totalClusters Clusters', 'Agricultural Belt'),
              const SizedBox(width: 8),
              _buildBannerStat(Icons.route, '≤ 7 km Radius', 'Inter-Farm Span'),
              const SizedBox(width: 8),
              _buildBannerStat(Icons.trending_down, '15% OFF Pooled', 'Wholesale Rate'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStat(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF69F0AE), size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All Clusters', '≤ 5 km Radius', '≤ 7 km Radius', 'Residue-Free GAP', 'Moisture Certified'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedTagFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedTagFilter = f);
              },
              labelStyle: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF1B5E20),
              ),
              selectedColor: const Color(0xFF1B5E20),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptySourceState() {
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.hub_outlined, size: 48, color: Color(0xFF15803D)),
          const SizedBox(height: 12),
          Text(
            'No Matching Clusters Found',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Try selecting "All Clusters" or check back as more local farmers publish their harvests.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedTagFilter = 'All Clusters';
              });
            },
            child: const Text('Reset Filter to All Clusters'),
          ),
        ],
      ),
    );
  }

  /// High-Fidelity Cluster Card with dynamic custom quantity picker fulfilling buyer demand
  Widget _buildDetailedClusterCard(FarmerCluster cluster) {
    final savingsPercent = ((cluster.retailMarketPrice - cluster.wholesalePrice) / cluster.retailMarketPrice * 100).round();
    final savingsPerKg = cluster.retailMarketPrice - cluster.wholesalePrice;
    final currentQty = _getQuantity(cluster.id, cluster.defaultOrderKg);
    final calculatedTotal = currentQty * cluster.wholesalePrice;
    final calculatedSavings = currentQty * savingsPerKg;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF86EFAC),
          width: 1.2,
        ),
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
          // 1. Photo / Emoji Hero Banner
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                child: cluster.imageUrl.isNotEmpty
                    ? CropImageHelper.buildCropImage(
                        cluster.imageUrl,
                        cluster.crop,
                        height: 145,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 125,
                        color: const Color(0xFFF1F8E9),
                        alignment: Alignment.center,
                        child: Text(cluster.imageEmoji, style: const TextStyle(fontSize: 48)),
                      ),
              ),

              // Floating Radius Tag
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me, size: 12, color: Color(0xFF69F0AE)),
                      const SizedBox(width: 4),
                      Text(
                        cluster.clusterRadius,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // Savings / Discount Tag
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$savingsPercent% OFF WHOLESALE',
                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Verified Cluster Badge
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15803D),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Verified ≤ 7km Spatial Cluster',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. Crop Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Grade
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cluster.crop,
                        style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        cluster.grade,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Color(0xFF15803D)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        cluster.hubLocation,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Key Metrics Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Wholesale Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Wholesale Rate', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Row(
                            children: [
                              Text(
                                '₹${cluster.wholesalePrice.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                              ),
                              Text('/kg  ', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF15803D))),
                              Text(
                                '₹${cluster.retailMarketPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Pooled Stock
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Pooled Stock', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Text(
                            '${cluster.availableStockKg.toStringAsFixed(0)} kg',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                        ],
                      ),

                      // Neighbor Farms
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Neighbor Farms', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Text(
                            '${cluster.totalFarms} Farms',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Inter-Farm Distance Chain Preview along pickup path
                _buildInterFarmChainPreview(cluster),
                const SizedBox(height: 10),

                // Quality & Verification Tags Bar
                _buildQualityTagsBar(cluster),
                const SizedBox(height: 14),

                // Custom Quantity Option Section directly on Card
                _buildCardQuantitySelector(cluster, currentQty, calculatedTotal, calculatedSavings),
                const SizedBox(height: 14),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showClusterInspectionSheet(context, cluster),
                        icon: const Icon(Icons.alt_route, size: 16),
                        label: Text(
                          'Inspect & Map',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF15803D),
                          side: const BorderSide(color: Color(0xFF86EFAC)),
                          backgroundColor: const Color(0xFFF0FDF4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _proceedToCheckout(cluster, currentQty, calculatedTotal),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                        label: Text(
                          'Buy ${currentQty.toStringAsFixed(0)} kg (₹${calculatedTotal.toStringAsFixed(0)})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Inter-Farm Distance Chain Preview along pickup path
  Widget _buildInterFarmChainPreview(FarmerCluster cluster) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCEDC8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.alt_route, size: 15, color: Color(0xFF2E7D32)),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: cluster.farmers.map((f) {
                  final isLast = f == cluster.farmers.last;
                  return Row(
                    children: [
                      Text(
                        '🚜 ${f.name.split(" ").first} (${f.distance == 0 ? "Hub" : "${f.distance}km"})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      ),
                      if (!isLast) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 11, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 4),
                      ],
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '≤ ${cluster.maxInterFarmDistance} km span',
              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Quality & Verification Tags Bar
  Widget _buildQualityTagsBar(FarmerCluster cluster) {
    final moisture = cluster.conditions['moistureLevel']?.toString() ?? '11.2% Moisture';
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _buildTagPill('💧 $moisture'),
        _buildTagPill('🌿 Residue-Free GAP'),
        _buildTagPill('🌾 Single-Belt Pure'),
        _buildTagPill('🔐 DigiLocker e-Signed'),
      ],
    );
  }

  Widget _buildTagPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF334155), fontWeight: FontWeight.w600),
      ),
    );
  }

  // Card Quantity Selector fulfilling buyer demand
  Widget _buildCardQuantitySelector(
    FarmerCluster cluster,
    double currentQty,
    double calculatedTotal,
    double calculatedSavings,
  ) {
    final quickOptions = [10.0, 25.0, 50.0, 100.0, 250.0];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Required Quantity:',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20, color: Color(0xFF15803D)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _setQuantity(cluster.id, currentQty - 5.0),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      '${currentQty.toStringAsFixed(0)} kg',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF15803D)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _setQuantity(cluster.id, currentQty + 5.0),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Quick Preset Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...quickOptions.map((opt) {
                  final isSel = currentQty == opt;
                  return GestureDetector(
                    onTap: () => _setQuantity(cluster.id, opt),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF15803D) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSel ? const Color(0xFF15803D) : Colors.grey.shade300),
                      ),
                      child: Text(
                        '${opt.toStringAsFixed(0)} kg',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () => _showCustomQuantityDialog(cluster),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF15803D)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 11, color: Color(0xFF15803D)),
                        SizedBox(width: 4),
                        Text('Custom kg', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Subtotal & Savings Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ₹${calculatedTotal.toStringAsFixed(0)}',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
              ),
              Text(
                'Retail: ₹${(currentQty * cluster.retailMarketPrice).toStringAsFixed(0)} (Save ₹${calculatedSavings.toStringAsFixed(0)})',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCustomQuantityDialog(FarmerCluster cluster) {
    final controller = TextEditingController(text: _getQuantity(cluster.id, cluster.defaultOrderKg).toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enter Custom Quantity (kg)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantity in Kilograms',
            suffixText: 'kg',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? cluster.defaultOrderKg;
              _setQuantity(cluster.id, val);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D)),
            child: const Text('Apply', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Multi-Stop Real Road Route Inspection Sheet with FlutterMap (OSRM Road Snapped)
  void _showClusterInspectionSheet(BuildContext context, FarmerCluster cluster) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final hubPos = LatLng(cluster.hubLat, cluster.hubLng);
        int mapTypeIndex = 0;
        RoadRouteResult? roadRoute;
        bool isRouteLoading = true;
        bool hasFetched = false;

        return StatefulBuilder(
          builder: (context, setInspectionState) {
            // Fetch live OSRM road geometry once when modal builds
            if (!hasFetched) {
              hasFetched = true;
              final waypoints = [
                hubPos,
                ...cluster.farmers.map((f) => LatLng(f.lat, f.lng)),
                hubPos,
              ];
              RoadRoutingService().getMultiStopRoute(waypoints, optimizeStops: true).then((res) {
                setInspectionState(() {
                  roadRoute = res;
                  isRouteLoading = false;
                });
              });
            }

            String tileUrl;
            switch (mapTypeIndex) {
              case 1:
                tileUrl = 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}'; // Satellite
                break;
              case 2:
                tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'; // OSM
                break;
              case 0:
              default:
                tileUrl = 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}'; // Google Road
                break;
            }

            final fallbackPoints = [hubPos, ...cluster.farmers.map((f) => LatLng(f.lat, f.lng)), hubPos];
            final polylinePoints = roadRoute?.points ?? fallbackPoints;

            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
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

                  // Title Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(cluster.imageEmoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cluster.crop,
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                              ),
                              Text(
                                '${cluster.hubLocation} • ${cluster.clusterRadius}',
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Google Maps / OSM Map Container
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Multi-Stop Pickup Road Route',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                              ),
                              Row(
                                children: [
                                  _buildInspectionMapToggle(0, '🗺️ Road', mapTypeIndex, (idx) => setInspectionState(() => mapTypeIndex = idx)),
                                  const SizedBox(width: 4),
                                  _buildInspectionMapToggle(1, '🛰️ Sat', mapTypeIndex, (idx) => setInspectionState(() => mapTypeIndex = idx)),
                                  const SizedBox(width: 4),
                                  _buildInspectionMapToggle(2, '🌐 OSM', mapTypeIndex, (idx) => setInspectionState(() => mapTypeIndex = idx)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Optimized asphalt road routing across smallholder farms in this pooled belt.',
                            style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 10),

                          Container(
                            height: 240,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: hubPos,
                                  initialZoom: 12.0,
                                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: tileUrl,
                                    userAgentPackageName: 'com.agrichain.app',
                                  ),

                                  // Proximity radius circle (7 km)
                                  CircleLayer(
                                    circles: [
                                      CircleMarker(
                                        point: hubPos,
                                        radius: (cluster.maxInterFarmDistance * 1000).clamp(2500, 7000),
                                        useRadiusInMeter: true,
                                        color: const Color(0xFF15803D).withValues(alpha: 0.10),
                                        borderColor: const Color(0xFF15803D),
                                        borderStrokeWidth: 1.5,
                                      ),
                                    ],
                                  ),

                                  // Real Asphalt Road Polyline (OSRM Driving Route)
                                  PolylineLayer(
                                    polylines: [
                                      // Outer casing
                                      Polyline(
                                        points: polylinePoints,
                                        strokeWidth: 5.5,
                                        color: const Color(0xFF064E3B),
                                      ),
                                      // Highway centerline
                                      Polyline(
                                        points: polylinePoints,
                                        strokeWidth: 3.5,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ],
                                  ),

                                  // Numbered Pickup Markers along the road
                                  MarkerLayer(
                                    markers: [
                                      // Hub Pin
                                      Marker(
                                        point: hubPos,
                                        width: 44,
                                        height: 44,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF15803D),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2.5),
                                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.storefront, color: Colors.white, size: 20),
                                          ),
                                        ),
                                      ),

                                      // Sequentially Numbered Neighbor Farm Pins
                                      ...cluster.farmers.asMap().entries.map((entry) {
                                        final idx = entry.key + 1;
                                        final f = entry.value;
                                        return Marker(
                                          point: LatLng(f.lat, f.lng),
                                          width: 38,
                                          height: 38,
                                          child: Tooltip(
                                            message: 'Stop #$idx: ${f.name} (${f.distance} km)',
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: const Color(0xFF15803D), width: 2.5),
                                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$idx',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF15803D),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Live Road Route Metrics Card
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.alt_route, color: Color(0xFF15803D), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isRouteLoading
                                            ? 'Computing OSRM Road Route...'
                                            : '${roadRoute?.distanceKm.toStringAsFixed(1) ?? cluster.maxInterFarmDistance.toStringAsFixed(1)} km Total Road Pickup Route',
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                                      ),
                                      Text(
                                        isRouteLoading
                                            ? 'Connecting to road navigation network...'
                                            : '${roadRoute?.durationMinutes ?? 18} mins pickup ETA • ${cluster.farmers.length} farm stops consolidated',
                                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF15803D),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'OSRM Road Snapped',
                                    style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 2. Pooled Neighbor Farmers
                          Text(
                            'Pooled Neighbor Farmers (${cluster.farmers.length})',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 8),

                          ...cluster.farmers.asMap().entries.map((entry) {
                            final idx = entry.key + 1;
                            final f = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFDCFCE7),
                                    child: Text(
                                      '#$idx',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          f.name,
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${f.farmName} • ${f.village} (${f.distance == 0 ? "Hub Farm" : "${f.distance} km away"})',
                                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(
                                              f.isDigiLocker ? Icons.verified : Icons.gesture,
                                              size: 13,
                                              color: f.isDigiLocker ? const Color(0xFF15803D) : const Color(0xFF0284C7),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${f.signatureType} (${f.certId})',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: f.isDigiLocker ? const Color(0xFF15803D) : const Color(0xFF0284C7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${f.pooledKg.toStringAsFixed(0)} kg\nPooled',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 16),

                          // 3. Verified Agricultural Standards
                          Text(
                            'Verified Agricultural Standards',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Column(
                              children: cluster.conditions.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle, size: 15, color: Color(0xFF15803D)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade800),
                                            children: [
                                              TextSpan(text: '${_formatKey(entry.key)}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              TextSpan(text: entry.value.toString()),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Direct Buy CTA
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showClusterBuySheet(context, cluster);
                              },
                              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                              label: Text(
                                'Select Quantity & Buy from Cluster',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF15803D),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          },
        );
      },
    );
  }

  Widget _buildInspectionMapToggle(int index, String label, int current, Function(int) onSelect) {
    final isSel = index == current;
    return GestureDetector(
      onTap: () => onSelect(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF15803D) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSel ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  /// Clean, dedicated Quick-Buy Sheet with custom kg order selection fulfilling buyer demand
  void _showClusterBuySheet(BuildContext context, FarmerCluster cluster) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final clusterId = cluster.id;
            final currentQty = _getQuantity(clusterId, cluster.defaultOrderKg);
            final totalPayable = currentQty * cluster.wholesalePrice;
            final retailTotal = currentQty * cluster.retailMarketPrice;
            final savings = retailTotal - totalPayable;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Text(cluster.imageEmoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cluster.crop,
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                ),
                                Text(
                                  '₹${cluster.wholesalePrice.toStringAsFixed(0)}/kg wholesale rate (${cluster.totalFarms} pooled farms)',
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF15803D), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Stepper & Custom Quantity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Select Order Quantity', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Min: 5 kg • In Stock: ${cluster.availableStockKg.toStringAsFixed(0)} kg', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Color(0xFF15803D), size: 28),
                                onPressed: () {
                                  if (currentQty > 5) {
                                    setModalState(() => _setQuantity(clusterId, currentQty - 5));
                                  }
                                },
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${currentQty.toStringAsFixed(0)} kg',
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Color(0xFF15803D), size: 28),
                                onPressed: () {
                                  if (currentQty + 5 <= cluster.availableStockKg) {
                                    setModalState(() => _setQuantity(clusterId, currentQty + 5));
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Multi-Farmer Fulfillment Allocation Preview
                      _buildFulfillmentAllocation(cluster.farmers, currentQty),
                      const SizedBox(height: 14),

                      // Price Summary
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Escrow Payable', style: TextStyle(fontSize: 11, color: Color(0xFF15803D))),
                                Text(
                                  '₹${totalPayable.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF15803D),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'You Save ₹${savings.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Proceed to Checkout CTA
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _proceedToCheckout(cluster, currentQty, totalPayable);
                          },
                          icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                          label: Text(
                            'Proceed to Secure Checkout • ₹${totalPayable.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFulfillmentAllocation(List<FarmerClusterMember> farmers, double totalQty) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Multi-Farmer Allocation (${totalQty.toStringAsFixed(0)} kg order)',
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              Text(
                '${farmers.length} Farms Pooled',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF15803D), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Segmented progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: farmers.map((f) {
                  final totalClusterStock = farmers.fold(0.0, (acc, curr) => acc + curr.pooledKg);
                  final double fraction = (totalClusterStock > 0) ? (f.pooledKg / totalClusterStock) : (1.0 / farmers.length);

                  final colors = [
                    const Color(0xFF15803D),
                    const Color(0xFF0284C7),
                    const Color(0xFFEAB308),
                    const Color(0xFF8B5CF6),
                  ];
                  final idx = farmers.indexOf(f) % colors.length;

                  return Expanded(
                    flex: (fraction * 100).round().clamp(1, 100),
                    child: Container(color: colors[idx]),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 10,
            children: farmers.map((f) {
              final totalClusterStock = farmers.fold(0.0, (acc, curr) => acc + curr.pooledKg);
              final double fraction = (totalClusterStock > 0) ? (f.pooledKg / totalClusterStock) : (1.0 / farmers.length);
              final allocatedKg = (totalQty * fraction).roundToDouble();

              return Text(
                '• ${f.name.split(" ").first}: ${allocatedKg.toStringAsFixed(0)} kg',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout(FarmerCluster cluster, double qty, double amount) {
    final leadFarmer = cluster.farmers.first;

    final cropMap = {
      'id': cluster.id,
      'name': cluster.crop,
      'cropName': cluster.crop,
      'price': cluster.wholesalePrice,
      'pricePerUnit': cluster.wholesalePrice,
      'quantity': '${cluster.availableStockKg} kg',
      'availableQuantity': cluster.availableStockKg,
      'unit': 'kg',
      'farmerId': leadFarmer.farmerId,
      'farmerName': '${leadFarmer.name} (Cluster Representative)',
      'location': cluster.hubLocation,
      'village': leadFarmer.village,
      'imageUrl': cluster.imageUrl,
      'category': 'Grains',
      'variety': cluster.variety,
      'qualityGrade': cluster.grade,
      'isClusterOrder': true,
      'clusterFarmsCount': cluster.totalFarms,
      'maxInterFarmDistance': cluster.maxInterFarmDistance,
      'selectedQuantity': qty,
      'orderQuantity': qty,
      'totalAmount': amount,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RetailCheckoutScreen(
          crop: cropMap,
        ),
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
        .replaceFirstMapped(RegExp(r'^[a-z]'), (m) => m[0]!.toUpperCase())
        .trim();
  }
}
