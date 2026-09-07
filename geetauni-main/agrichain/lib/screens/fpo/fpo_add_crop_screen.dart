import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/fpo_inventory_model.dart';
import '../../services/fpo_inventory_service.dart';
import '../../services/gemini_crop_assay_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/crop_image_helper.dart';
import '../../widgets/custom_app_bar.dart';

/// Screen: Publish Commercial Bulk Crop Listing
/// Designed like the beloved Farmer Add Crop experience with photo upload,
/// automated Gemini AI Quality Assaying, and market pricing intelligence,
/// tailored specifically for FPO B2B wholesale warehouse inventory.
class FpoAddCropScreen extends StatefulWidget {
  const FpoAddCropScreen({super.key});

  @override
  State<FpoAddCropScreen> createState() => _FpoAddCropScreenState();
}

class _FpoAddCropScreenState extends State<FpoAddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final FpoInventoryService _inventoryService = FpoInventoryService();
  final GeminiCropAssayService _assayService = GeminiCropAssayService();

  // Form Controllers
  final _commodityController = TextEditingController(text: 'Sharbati Wheat');
  final _varietyController = TextEditingController(text: 'Sharbati 306 (Milling Grade)');
  final _quantityController = TextEditingController(text: '1200'); // 1,200 Qtl
  final _moqController = TextEditingController(text: '250'); // 250 Qtl (1 FTL standard)
  final _pricePerQtlController = TextEditingController(text: '3560'); // ₹3,560 / Qtl
  final _moistureController = TextEditingController(text: '11.2');
  final _storageLocationController = TextEditingController(text: 'Silo Bay 04 (Aerated)');

  // Selected crop preset for quick fill
  String _selectedPreset = 'Wheat';

  // Sample photo & AI assay state
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _isAnalyzingWithAi = false;
  GeminiCropAssayResult? _aiAssayResult;

  String _selectedGrade = 'Grade A (Milling Grade)';
  String _selectedWarehouse = 'Central Silo Depot 01, Karnal Hub';
  int _dispatchLeadTimeDays = 2;
  bool _isMultiFpoEligible = true;
  bool _isSubmitting = false;

  final List<String> _gradeOptions = [
    'Grade A (Milling Grade)',
    'Super Fine Export Grade',
    'Industrial Grade 1',
    'FAQ Standard Grade',
  ];

  final List<String> _warehouseOptions = [
    'Central Silo Depot 01, Karnal Hub',
    'Grain Warehouse Unit 02, Panipat',
    'Cold Storage Facility Bay A, Sonipat',
    'Depot Silo Complex, Kurukshetra',
  ];

  // Crop presets with typical MSP, market rate, and variety
  final Map<String, Map<String, dynamic>> _cropPresets = {
    'Wheat': {
      'name': 'Sharbati Wheat',
      'variety': 'Sharbati 306 (Milling Grade)',
      'grade': 'Grade A (Milling Grade)',
      'moisture': '11.2',
      'priceQtl': '3560',
      'mspQtl': 2275,
      'mandiQtl': 3560,
      'silo': 'Silo Bay 04 (Aerated)',
      'imageCrop': 'wheat',
    },
    'Basmati Rice': {
      'name': 'Basmati 1121 Paddy',
      'variety': 'Pusa 1121 (Aromatic Export)',
      'grade': 'Super Fine Export Grade',
      'moisture': '11.0',
      'priceQtl': '4620',
      'mspQtl': 2320,
      'mandiQtl': 4620,
      'silo': 'Covered Concrete Dock B',
      'imageCrop': 'basmati rice',
    },
    'Mustard': {
      'name': 'Black Mustard (RH-749)',
      'variety': 'RH 749 (High Oil Content)',
      'grade': 'Grade A (Milling Grade)',
      'moisture': '8.8',
      'priceQtl': '5850',
      'mspQtl': 5650,
      'mandiQtl': 5850,
      'silo': 'Ventilated Bagged Bay C',
      'imageCrop': 'mustard',
    },
    'Maize': {
      'name': 'Yellow Maize (Corn)',
      'variety': 'DKC 9108 (Starch Rich)',
      'grade': 'Industrial Grade 1',
      'moisture': '12.5',
      'priceQtl': '2480',
      'mspQtl': 2090,
      'mandiQtl': 2480,
      'silo': 'Dry Storage Bay 01',
      'imageCrop': 'corn',
    },
    'Soybean': {
      'name': 'Yellow Soybean',
      'variety': 'JS 335 (High Protein)',
      'grade': 'Grade A (Milling Grade)',
      'moisture': '10.5',
      'priceQtl': '4700',
      'mspQtl': 4892,
      'mandiQtl': 4700,
      'silo': 'Aerated Bin 03',
      'imageCrop': 'soybean',
    },
  };

  @override
  void dispose() {
    _commodityController.dispose();
    _varietyController.dispose();
    _quantityController.dispose();
    _moqController.dispose();
    _pricePerQtlController.dispose();
    _moistureController.dispose();
    _storageLocationController.dispose();
    super.dispose();
  }

  void _applyPreset(String key) {
    final preset = _cropPresets[key];
    if (preset == null) return;
    setState(() {
      _selectedPreset = key;
      _commodityController.text = preset['name'] as String;
      _varietyController.text = preset['variety'] as String;
      _selectedGrade = preset['grade'] as String;
      _moistureController.text = preset['moisture'] as String;
      _pricePerQtlController.text = preset['priceQtl'] as String;
      _storageLocationController.text = preset['silo'] as String;
      _aiAssayResult = null;
    });
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload Grain Lot Sample Photo',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Photograph the physical grain sample or select from gallery for automated AI assaying & AGMARK grading.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx, ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, color: Color(0xFF1B5E20)),
                      label: const Text('Camera', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFF1B5E20)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, color: Colors.white),
                      label: const Text('Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageFile = image;
          _imageBytes = bytes;
          _aiAssayResult = null;
        });

        // Trigger AI Assaying automatically
        _runAiAssaying();
      }
    } catch (e) {
      debugPrint('Error picking crop sample: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick crop image: $e')),
        );
      }
    }
  }

  Future<void> _runAiAssaying() async {
    setState(() => _isAnalyzingWithAi = true);

    try {
      // If no photo picked, use a simulated 1x1 dummy or sample bytes
      final bytes = _imageBytes ?? Uint8List.fromList(utf8.encode('grain_sample_assay'));
      final result = await _assayService.analyzeCropSample(
        imageBytes: bytes,
        cropCategory: _commodityController.text.trim(),
        cropVariety: _varietyController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _aiAssayResult = result;
          _isAnalyzingWithAi = false;
          _moistureController.text = result.moisturePercentage.toStringAsFixed(1);
          if (result.agmarkGrade.contains('Grade A')) {
            _selectedGrade = 'Grade A (Milling Grade)';
          } else if (result.agmarkGrade.contains('Premium') || result.agmarkGrade.contains('Export')) {
            _selectedGrade = 'Super Fine Export Grade';
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFF69F0AE), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Assaying Complete: ${result.agmarkGrade} (${result.moisturePercentage}% Moisture)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzingWithAi = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Assaying error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final user = appState.currentUser;
      final fpoId = user?.id.isNotEmpty == true ? user!.id : 'fpo_karnal_01';
      final fpoName = user?.name.isNotEmpty == true ? user!.name : 'Karnal Agro Producer Co. Ltd.';

      final qtyQtl = double.tryParse(_quantityController.text.trim()) ?? 1000.0;
      final moqQtl = double.tryParse(_moqController.text.trim()) ?? 250.0;
      final priceQtl = double.tryParse(_pricePerQtlController.text.trim()) ?? 3560.0;
      final qtyMT = qtyQtl / 10.0;
      final moqMT = moqQtl / 10.0;
      final priceMT = priceQtl * 10.0;
      final moisture = double.tryParse(_moistureController.text.trim()) ?? 11.2;

      final now = DateTime.now();
      final itemId = 'INV-${now.millisecondsSinceEpoch.toString().substring(7)}';
      final listingId = 'LIST-${now.millisecondsSinceEpoch.toString().substring(7)}';

      final imgPath = _imageFile?.path;

      // 1. Create warehouse inventory record
      final inventoryItem = FpoInventoryItem(
        id: itemId,
        fpoId: fpoId,
        fpoName: fpoName,
        cropName: _commodityController.text.trim(),
        variety: _varietyController.text.trim(),
        totalQuantityMT: qtyMT,
        reservedQuantityMT: 0.0,
        soldQuantityMT: 0.0,
        unit: 'Qtl',
        qualityGrade: _selectedGrade,
        moisturePct: moisture,
        warehouseId: 'WH-01',
        warehouseName: _selectedWarehouse,
        storageLocation: _storageLocationController.text.trim(),
        pricePerMT: priceMT,
        pricePerQtl: priceQtl,
        inventoryStatus: InventoryStatus.available,
        listingStatus: ListingStatus.published,
        activeListingId: listingId,
        imageUrl: imgPath,
        createdAt: now,
        updatedAt: now,
      );

      // 2. Create B2B commercial listing
      final listing = BulkCropListing(
        id: listingId,
        inventoryItemId: itemId,
        fpoId: fpoId,
        fpoName: fpoName,
        cropName: _commodityController.text.trim(),
        variety: _varietyController.text.trim(),
        listedQuantityMT: qtyMT,
        minimumOrderQuantityMT: moqMT,
        pricePerMT: priceMT,
        pricePerQtl: priceQtl,
        qualityGrade: _selectedGrade,
        moisturePct: moisture,
        warehouseName: _selectedWarehouse,
        warehouseLat: 29.6857,
        warehouseLng: 76.9905,
        dispatchLeadTimeDays: _dispatchLeadTimeDays,
        isMultiFpoEligible: _isMultiFpoEligible,
        status: ListingStatus.published,
        imageUrl: imgPath,
        publishedAt: now,
        updatedAt: now,
      );

      await _inventoryService.createInventoryItem(inventoryItem);
      final success = await _inventoryService.publishBulkListing(listing);

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF69F0AE), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Published ${qtyQtl.toStringAsFixed(0)} Qtl of ${_commodityController.text} to B2B Institutional Market!',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1B5E20),
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error publishing listing.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qtyQtl = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final priceQtl = double.tryParse(_pricePerQtlController.text.trim()) ?? 0.0;
    final totalValuation = qtyQtl * priceQtl;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const CustomAppBar(
            title: 'Publish Bulk Listing',
          ),
        ],
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              // 1. Direct B2B Commercial Explainer Banner
              _buildExplainerBanner(),
              const SizedBox(height: 14),

              // 2. Crop Type Quick Selectors (Preset Pills)
              _buildQuickPresetsRow(),
              const SizedBox(height: 14),

              // 3. Grain Sample Image & AI Assaying Card (Farmer-Style!)
              _buildSampleImageAndAiCard(),
              const SizedBox(height: 14),

              // 4. Market Pricing Intelligence & MSP Benchmark
              _buildMarketPricingCard(totalValuation),
              const SizedBox(height: 14),

              // 5. Commodity Specifications Card
              _buildCommoditySpecsCard(),
              const SizedBox(height: 14),

              // 6. Volume & Wholesale Pricing Card (FPO Tonnage & MOQ)
              _buildVolumeAndPricingCard(totalValuation),
              const SizedBox(height: 14),

              // 7. Warehouse & Fulfillment Terms Card
              _buildWarehouseAndLogisticsCard(),
              const SizedBox(height: 24),

              // 8. Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplainerBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.storefront, color: Color(0xFF15803D), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Direct B2B Commercial Listing: Published lots are accessible by verified institutional bulk buyers across India with escrow protection.',
              style: TextStyle(fontSize: 12, color: Color(0xFF14532D), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPresetsRow() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _cropPresets.keys.map((key) {
          final isSelected = _selectedPreset == key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(key),
              selected: isSelected,
              onSelected: (_) => _applyPreset(key),
              selectedColor: const Color(0xFF1B5E20),
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFCBD5E1)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSampleImageAndAiCard() {
    final preset = _cropPresets[_selectedPreset];
    final defaultCropImg = preset?['imageCrop'] as String? ?? 'wheat';

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
                  const Icon(Icons.camera_alt, color: Color(0xFF2E7D32), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Crop Sample & AI Assaying',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              if (_imageFile != null || _aiAssayResult != null)
                TextButton.icon(
                  onPressed: _selectImage,
                  icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF2E7D32)),
                  label: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Image Upload Area / Preview
          GestureDetector(
            onTap: _selectImage,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
              ),
              child: _imageFile != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: kIsWeb
                              ? Image.network(_imageFile!.path, width: double.infinity, height: 180, fit: BoxFit.cover)
                              : Image.file(File(_imageFile!.path), width: double.infinity, height: 180, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B5E20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, color: Color(0xFF69F0AE), size: 14),
                                SizedBox(width: 4),
                                Text('Sample Attached', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 180,
                            child: CropImageHelper.buildCropImage(null, defaultCropImg, fit: BoxFit.cover),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.black.withValues(alpha: 0.35),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_a_photo, size: 28, color: Color(0xFF1B5E20)),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap to Photograph or Pick Grain Sample',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Enables automated AI moisture & AGMARK analysis',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Run AI Assaying Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isAnalyzingWithAi ? null : _runAiAssaying,
              icon: _isAnalyzingWithAi
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B5E20)))
                  : const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF1B5E20)),
              label: Text(
                _isAnalyzingWithAi ? 'Analyzing Sample with Gemini AI...' : 'Run Automated AI Quality Assay',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF1B5E20)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2E7D32)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // AI Quality Assaying Output Card (Matching Farmer Screen!)
          if (_aiAssayResult != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F381E), Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
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
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF69F0AE), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'AI Quality Assaying Results',
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF69F0AE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _aiAssayResult!.agmarkGrade,
                          style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w900, color: const Color(0xFF0F381E)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildAssayMetricCol('Moisture', '${_aiAssayResult!.moisturePercentage}%', 'Optimal <12%'),
                      _buildAssayMetricCol('Broken Grain', '${_aiAssayResult!.brokenGrainPercentage}%', 'Grade A <2%'),
                      _buildAssayMetricCol('Foreign Matter', '${_aiAssayResult!.foreignMatterPercentage}%', 'Clean <0.5%'),
                      _buildAssayMetricCol('AI Purity', '${_aiAssayResult!.purityScore}%', 'High Purity'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Assessment: ${_aiAssayResult!.assessmentSummary}',
                    style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssayMetricCol(String label, String value, String sub) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFF69F0AE))),
        ],
      ),
    );
  }

  Widget _buildMarketPricingCard(double totalValuation) {
    final preset = _cropPresets[_selectedPreset];
    final msp = preset?['mspQtl'] ?? 2275;
    final mandi = preset?['mandiQtl'] ?? 3560;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up, color: Color(0xFF2563EB), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Wholesale Pricing Benchmark (Haryana)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Live Mandi', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Govt MSP Benchmark', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  Text('₹$msp / qtl', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Mandi Wholesale Spot', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  Text('₹$mandi / qtl', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total Lot Valuation', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  Text(
                    '₹${(totalValuation / 100000).toStringAsFixed(2)} L',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommoditySpecsCard() {
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
            children: [
              const Icon(Icons.grain, color: Color(0xFF2E7D32), size: 18),
              const SizedBox(width: 8),
              Text(
                'Commodity Specifications',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20),
          TextFormField(
            controller: _commodityController,
            decoration: InputDecoration(
              labelText: 'Commodity Name *',
              hintText: 'e.g. Sharbati Wheat, Basmati Paddy',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _varietyController,
            decoration: InputDecoration(
              labelText: 'Variety / Specification *',
              hintText: 'e.g. Sharbati 306, Pusa 1121',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedGrade,
            decoration: InputDecoration(
              labelText: 'Quality Grade Standard *',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            items: _gradeOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) => setState(() => _selectedGrade = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _moistureController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Certified Moisture Level (%) *',
              suffixText: '%',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeAndPricingCard(double totalValuation) {
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
                  const Icon(Icons.scale, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Volume & Wholesale Pricing',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${(totalValuation / 100000).toStringAsFixed(2)} L Lot Value',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Total Quantity (Qtl) *',
                    suffixText: 'Qtl',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _moqController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Min Order Qty (MOQ) *',
                    suffixText: 'Qtl',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pricePerQtlController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Wholesale Rate per Quintal (₹/Qtl) *',
              prefixText: '₹ ',
              helperText: 'Standard mandi wholesale rate (1 Quintal = 100 kg)',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseAndLogisticsCard() {
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
            children: [
              const Icon(Icons.warehouse, color: Color(0xFF2E7D32), size: 18),
              const SizedBox(width: 8),
              Text(
                'Warehouse & Fulfillment Terms',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _selectedWarehouse,
            decoration: InputDecoration(
              labelText: 'Origin Warehouse Silo *',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            items: _warehouseOptions.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _selectedWarehouse = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _storageLocationController,
            decoration: InputDecoration(
              labelText: 'Storage Location / Bay *',
              hintText: 'e.g. Silo Bay 04 (Aerated)',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dispatch Lead Time:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              DropdownButton<int>(
                value: _dispatchLeadTimeDays,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 Day (Immediate)')),
                  DropdownMenuItem(value: 2, child: Text('2 Days (Standard)')),
                  DropdownMenuItem(value: 4, child: Text('4 Days (Custom Call)')),
                ],
                onChanged: (v) => setState(() => _dispatchLeadTimeDays = v!),
              ),
            ],
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('7 km Multi-FPO Pooling Eligible', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: const Text('Permit neighboring FPOs to aggregate inventory with this lot for large institutional demand', style: TextStyle(fontSize: 11)),
            activeThumbColor: const Color(0xFF2E7D32),
            value: _isMultiFpoEligible,
            onChanged: (v) => setState(() => _isMultiFpoEligible = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : _submitListing,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isSubmitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Publish Bulk Listing to B2B Market',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
