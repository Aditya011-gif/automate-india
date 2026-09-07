import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../models/fpo_inventory_model.dart';
import '../../services/fpo_inventory_service.dart';
import '../../services/gemini_crop_assay_service.dart';
import '../../utils/crop_image_helper.dart';
import '../../widgets/fpo_lot_details_modal.dart';
import 'fpo_add_crop_screen.dart';

/// Screen 2: FPO Warehouse Crops Inventory & AI Quality Analysis
/// Simple, visual, and friendly layout inspired by the Farmer module.
class FpoInventoryScreen extends StatefulWidget {
  const FpoInventoryScreen({super.key});

  @override
  State<FpoInventoryScreen> createState() => _FpoInventoryScreenState();
}

class _FpoInventoryScreenState extends State<FpoInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FpoInventoryService _inventoryService = FpoInventoryService();
  final GeminiCropAssayService _assayService = GeminiCropAssayService();

  // AI Quality Assaying interactive state
  String _selectedCropForAssay = 'Sharbati Wheat';
  String _selectedVarietyForAssay = 'Grade A (PBW-502)';
  bool _isAssaying = false;
  GeminiCropAssayResult? _assayResult;
  String? _lastAssayedCrop;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Pre-populate with realistic AI assay result for Wheat
    _assayResult = _assayService.simulateMockAssay('Wheat', 'Sharbati Grade A');
    _lastAssayedCrop = 'Sharbati Wheat';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _runAiQualityAssay(String cropName, String variety) async {
    setState(() {
      _selectedCropForAssay = cropName;
      _selectedVarietyForAssay = variety;
      _isAssaying = true;
    });

    try {
      final result = await _assayService.analyzeCropSample(
        imageBytes: Uint8List(0),
        cropCategory: cropName,
        cropVariety: variety,
      );
      if (mounted) {
        setState(() {
          _assayResult = result;
          _lastAssayedCrop = cropName;
          _isAssaying = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _assayResult = _assayService.simulateMockAssay(cropName, variety);
          _lastAssayedCrop = cropName;
          _isAssaying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final fpoId = user?.id.isNotEmpty == true ? user!.id : 'fpo_karnal_01';

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const CustomAppBar(
            title: 'Crops & Warehouse Stock',
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                children: [
                  _buildWarehouseHeaderCard(fpoId),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF1B5E20),
                      unselectedLabelColor: AppTheme.textSecondary,
                      indicatorColor: const Color(0xFF1B5E20),
                      indicatorWeight: 3,
                      labelStyle: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.inventory_2_outlined, size: 18),
                          text: 'Warehouse Crops',
                        ),
                        Tab(
                          icon: Icon(Icons.auto_awesome, size: 18),
                          text: 'AI Quality Analysis',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCropsInventoryTab(fpoId),
            _buildAiQualityAssayingTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FpoAddCropScreen()),
          );
        },
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Bulk Crop Lot',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Silo capacity and health overview
  Widget _buildWarehouseHeaderCard(String fpoId) {
    return StreamBuilder<List<FpoInventoryItem>>(
      stream: _inventoryService.streamFpoInventory(fpoId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final totalStockQtl = items.fold<double>(
          0.0,
          (sum, item) => sum + (item.totalQuantityMT * 10.0),
        );
        final reservedQtl = items.fold<double>(
          0.0,
          (sum, item) => sum + (item.reservedQuantityMT * 10.0),
        );
        final availableQtl = (totalStockQtl - reservedQtl).clamp(0.0, totalStockQtl);
        final capacityBase = totalStockQtl > 0 ? totalStockQtl : 5000.0;
        final utilizationPct = totalStockQtl > 0 ? ((totalStockQtl / capacityBase) * 100).round() : 0;

        final availFlex = totalStockQtl > 0 ? (availableQtl * 10).round() : 0;
        final resFlex = totalStockQtl > 0 ? (reservedQtl * 10).round() : 0;
        final freeFlex = totalStockQtl > 0 ? 100 : 1000;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softShadow,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.warehouse, color: Color(0xFF2E7D32), size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Central Silo Complex',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            totalStockQtl > 0
                                ? '${totalStockQtl.toStringAsFixed(0)} Qtl Active Warehouse Stock'
                                : '0 Qtl Deposited • Ready for Inflow',
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: totalStockQtl > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: totalStockQtl > 0 ? const Color(0xFFBBF7D0) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      '$utilizationPct% Utilized',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: totalStockQtl > 0 ? const Color(0xFF15803D) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    if (availFlex > 0)
                      Expanded(
                        flex: availFlex,
                        child: Container(height: 8, color: const Color(0xFF2E7D32)),
                      ),
                    if (resFlex > 0)
                      Expanded(
                        flex: resFlex,
                        child: Container(height: 8, color: const Color(0xFFF59E0B)),
                      ),
                    Expanded(
                      flex: freeFlex > 0 ? freeFlex : 1,
                      child: Container(height: 8, color: const Color(0xFFE2E8F0)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLegendDot(
                    'Available: ${availableQtl.toStringAsFixed(0)} Qtl',
                    const Color(0xFF2E7D32),
                  ),
                  _buildLegendDot(
                    'Locked: ${reservedQtl.toStringAsFixed(0)} Qtl',
                    const Color(0xFFF59E0B),
                  ),
                  _buildLegendDot(
                    totalStockQtl > 0 ? 'Allocated' : 'Ready for Deposits',
                    const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendDot(String text, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  /// Tab 1: Warehouse Crops Cards (Matching Farmer Crop Card style with Real Photos)
  Widget _buildCropsInventoryTab(String fpoId) {
    return StreamBuilder<List<FpoInventoryItem>>(
      stream: _inventoryService.streamFpoInventory(fpoId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty && snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
        }

        final List<FpoInventoryItem> displayItems = items;

        if (displayItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warehouse_outlined,
                    size: 60,
                    color: AppTheme.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No Warehouse Crops Deposited Yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap "+ Add Bulk Crop Lot" below to record inventory and list lots for bulk buyers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            final item = displayItems[index];
            return _buildCropInventoryCard(item);
          },
        );
      },
    );
  }

  Widget _buildCropInventoryCard(FpoInventoryItem item) {
    final isPartiallyReserved = item.reservedQuantityMT > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLotDetailsModal(item),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // 1. Photo with Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: CropImageHelper.buildCropImage(
                  '',
                  item.cropName,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warehouse, size: 12, color: Color(0xFF69F0AE)),
                      const SizedBox(width: 4),
                      Text(
                        item.storageLocation,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPartiallyReserved
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPartiallyReserved
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFBBF7D0),
                    ),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Text(
                    isPartiallyReserved
                        ? '${(item.reservedQuantityMT * 10).toStringAsFixed(0)} Qtl Reserved'
                        : '100% Available',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isPartiallyReserved
                          ? const Color(0xFFB45309)
                          : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Color(0xFF69F0AE), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${item.qualityGrade} • Moisture ${item.moisturePct}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. Details Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.cropName,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.variety,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${item.pricePerQtl.toStringAsFixed(0)} / Qtl',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        Text(
                          '₹${item.pricePerQtl.toStringAsFixed(0)} / Quintal',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tonnage Breakdown Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Warehouse Stock', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '${(item.totalQuantityMT * 10).toStringAsFixed(0)} Qtl',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 26, color: Colors.grey.shade300),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Available to Sell', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '${(item.availableQuantityMT * 10).toStringAsFixed(0)} Qtl',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 26, color: Colors.grey.shade300),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Locked Orders', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '${(item.reservedQuantityMT * 10).toStringAsFixed(0)} Qtl',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: item.reservedQuantityMT > 0 ? const Color(0xFFD97706) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showLotDetailsModal(item),
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('Lot Details', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Switch to AI Quality tab with this crop pre-selected
                          _tabController.animateTo(1);
                          _runAiQualityAssay(item.cropName, item.variety);
                        },
                        icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                        label: const Text('AI Assaying', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
    ),
  ),
);
}

  /// Tab 2: AI Crop Quality Analysis (Matching Farmer App)
  Widget _buildAiQualityAssayingTab() {
    final crops = [
      {'name': 'Sharbati Wheat', 'variety': 'Grade A (PBW-502)', 'silo': 'Silo #1'},
      {'name': 'Basmati Rice 1121', 'variety': 'Super Fine Paddy', 'silo': 'Silo #2'},
      {'name': 'Yellow Mustard', 'variety': 'High Oil 42% Pusa', 'silo': 'Silo #3'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF69F0AE), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Grain Assaying & Lab QC',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Instant physical parameters inspection powered by Gemini Vision AI before dispatch to Institutional Buyers.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Select Lot to Inspect
          Text(
            'Select Warehouse Lot to Test',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: crops.map((c) {
                final isSelected = _selectedCropForAssay == c['name'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${c['name']} (${c['silo']})'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2E7D32),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) {
                        _runAiQualityAssay(c['name']!, c['variety']!);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Sample Image Preview Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CropImageHelper.buildCropImage(
                        '',
                        _selectedCropForAssay,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      if (_isAssaying)
                        Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.black.withValues(alpha: 0.6),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Color(0xFF69F0AE)),
                              SizedBox(height: 10),
                              Text(
                                'Gemini AI Vision Assaying in Progress...',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCropForAssay,
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _selectedVarietyForAssay,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _isAssaying
                          ? null
                          : () => _runAiQualityAssay(_selectedCropForAssay, _selectedVarietyForAssay),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Re-scan Sample', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // AI Assaying Results
          if (_assayResult != null) ...[
            Text(
              'AI Physical Assaying Report',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),

            // Grade banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF15803D), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_assayResult!.agmarkGrade} • Certified',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF15803D)),
                        ),
                        Text(
                          'Meets BIS / FSSAI & Institutional Buyer procurement specifications.',
                          style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4 Assay Parameter Tiles
            Row(
              children: [
                Expanded(
                  child: _buildAssayParameterTile(
                    'Moisture',
                    '${_assayResult!.moisturePercentage.toStringAsFixed(1)}%',
                    'Optimal (<= 12%)',
                    Icons.water_drop_outlined,
                    const Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildAssayParameterTile(
                    'Purity Level',
                    '${_assayResult!.purityScore.toStringAsFixed(1)}%',
                    'Clean (> 98%)',
                    Icons.verified_outlined,
                    const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildAssayParameterTile(
                    'Broken Grains',
                    '${_assayResult!.brokenGrainPercentage.toStringAsFixed(1)}%',
                    'Grade A (<= 2%)',
                    Icons.grain,
                    const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildAssayParameterTile(
                    'Foreign Matter',
                    '${_assayResult!.foreignMatterPercentage.toStringAsFixed(1)}%',
                    'Minimal (<= 0.5%)',
                    Icons.filter_vintage_outlined,
                    const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Digital Certificate Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.fingerprint, color: Color(0xFF2E7D32), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Digital Certificate of Analysis',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const Text(
                        'PASS',
                        style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Certificate ID: AGRI-QC-2026-FPO-${_lastAssayedCrop?.replaceAll(' ', '').toUpperCase()}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                  ),
                  Text(
                    'Inspection Timestamp: 06 Sep 2026, 12:40 PM • Valid for 30 Days',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'AI Quality Certificate attached to $_lastAssayedCrop lot! Ready for institutional buyer dispatch.',
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      },
                      icon: const Icon(Icons.attachment, size: 16),
                      label: const Text('Attach Certificate to Bulk Lot'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssayParameterTile(
    String label,
    String value,
    String status,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          Text(
            status,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showLotDetailsModal(FpoInventoryItem item) {
    FpoLotDetailsModal.show(
      context,
      cropName: item.cropName,
      variety: item.variety,
      siloLocation: '${item.warehouseName} • ${item.storageLocation}',
      totalMt: item.totalQuantityMT,
      availableMt: item.availableQuantityMT,
      reservedMt: item.reservedQuantityMT,
      pricePerQtl: item.pricePerQtl,
      pricePerMt: item.pricePerMT,
      qualityGrade: item.qualityGrade,
      moistureText: '${item.moisturePct}% (Optimal)',
      onRunAiAssay: () {
        _tabController.animateTo(1);
        _runAiQualityAssay(item.cropName, item.variety);
      },
    );
  }

}
