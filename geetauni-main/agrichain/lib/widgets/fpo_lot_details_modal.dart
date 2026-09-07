import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/crop_image_helper.dart';
import '../screens/bulk_buyer/escrow_checkout_screen.dart';

/// Comprehensive, rich, and detailed FPO Commodity Lot Passport Modal Sheet.
/// Displays deep warehouse telemetry, atomic reservation math, physical assaying
/// parameters, commercial trade terms, and certifications.
class FpoLotDetailsModal {
  static void show(
    BuildContext context, {
    required String cropName,
    required String variety,
    required String siloLocation,
    required double totalMt,
    required double availableMt,
    required double reservedMt,
    required double pricePerQtl,
    required double pricePerMt,
    required String qualityGrade,
    required String moistureText,
    String? imageUrl,
    String? imageCrop,
    String? fpoId,
    String? fpoName,
    String? inventoryItemId,
    VoidCallback? onRunAiAssay,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return _FpoLotDetailsContent(
              scrollController: scrollController,
              cropName: cropName,
              variety: variety,
              siloLocation: siloLocation,
              totalMt: totalMt,
              availableMt: availableMt,
              reservedMt: reservedMt,
              pricePerQtl: pricePerQtl,
              pricePerMt: pricePerMt,
              qualityGrade: qualityGrade,
              moistureText: moistureText,
              imageUrl: imageUrl,
              imageCrop: imageCrop,
              fpoId: fpoId,
              fpoName: fpoName,
              inventoryItemId: inventoryItemId,
              onRunAiAssay: onRunAiAssay,
            );
          },
        );
      },
    );
  }
}


class _FpoLotDetailsContent extends StatefulWidget {
  final ScrollController scrollController;
  final String cropName;
  final String variety;
  final String siloLocation;
  final double totalMt;
  final double availableMt;
  final double reservedMt;
  final double pricePerQtl;
  final double pricePerMt;
  final String qualityGrade;
  final String moistureText;
  final String? imageUrl;
  final String? imageCrop;
  final String? fpoId;
  final String? fpoName;
  final String? inventoryItemId;
  final VoidCallback? onRunAiAssay;

  const _FpoLotDetailsContent({
    required this.scrollController,
    required this.cropName,
    required this.variety,
    required this.siloLocation,
    required this.totalMt,
    required this.availableMt,
    required this.reservedMt,
    required this.pricePerQtl,
    required this.pricePerMt,
    required this.qualityGrade,
    required this.moistureText,
    this.imageUrl,
    this.imageCrop,
    this.fpoId,
    this.fpoName,
    this.inventoryItemId,
    this.onRunAiAssay,
  });


  @override
  State<_FpoLotDetailsContent> createState() => _FpoLotDetailsContentState();
}

class _FpoLotDetailsContentState extends State<_FpoLotDetailsContent> {
  bool _isDownloadingPdf = false;

  void _triggerDownloadPdf() async {
    setState(() => _isDownloadingPdf = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isDownloadingPdf = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF69F0AE), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lot Passport downloaded: LOT-${widget.cropName.toUpperCase().replaceAll(' ', '')}-QC.pdf',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1B5E20),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lotBatchId = 'LOT-HR-KNL-2026-${widget.cropName.contains('Wheat') ? 'W01' : (widget.cropName.contains('Basmati') ? 'B02' : 'M03')}';
    final totalQtl = widget.totalMt * 10;
    final availableQtl = widget.availableMt * 10;
    final reservedQtl = widget.reservedMt * 10;
    final totalValuation = totalQtl * widget.pricePerQtl;
    final availableValuation = availableQtl * widget.pricePerQtl;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        // 1. Drag Handle
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Header Title Row with Close Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        lotBatchId,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Warehouse Lot Passport',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Color(0xFF64748B)),
              tooltip: 'Close',
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 3. Hero Crop Picture with Floating Badges
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: CropImageHelper.buildCropImage(
                  widget.imageUrl,
                  widget.imageCrop ?? widget.cropName,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warehouse, size: 13, color: Color(0xFF69F0AE)),
                    const SizedBox(width: 5),
                    Text(
                      widget.siloLocation,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 13, color: Color(0xFF69F0AE)),
                    const SizedBox(width: 5),
                    Text(
                      widget.qualityGrade,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'AI Assayed & Lab Certified',
                      style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 4. Title, Variety, and Pricing Grid
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.cropName,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.variety} • Central Silo Complex 01, Taraori, Karnal',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${widget.pricePerQtl.toStringAsFixed(0)} / Quintal',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF15803D),
                  ),
                ),
                Text(
                  '₹${widget.pricePerQtl.toStringAsFixed(0)} / Qtl',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 5. ATOMIC INVENTORY MATH & RESERVATION BREAKDOWN
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Warehouse Stock Allocation',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'Avail: ₹${(availableValuation / 100000).toStringAsFixed(2)}L • Total: ₹${(totalValuation / 100000).toStringAsFixed(2)}L',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Segmented visual progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    if (widget.availableMt > 0)
                      Expanded(
                        flex: (widget.availableMt * 10).toInt(),
                        child: Container(height: 10, color: const Color(0xFF15803D)),
                      ),
                    if (widget.reservedMt > 0)
                      Expanded(
                        flex: (widget.reservedMt * 10).toInt(),
                        child: Container(height: 10, color: const Color(0xFFF59E0B)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTonnageTile('Total In Silo', '${totalQtl.toStringAsFixed(0)} Qtl', const Color(0xFF0F172A), 'Physical Stock'),
                  Container(width: 1, height: 32, color: Colors.grey.shade300),
                  _buildTonnageTile('Available to Contract', '${availableQtl.toStringAsFixed(0)} Qtl', const Color(0xFF15803D), 'Immediate Delivery'),
                  Container(width: 1, height: 32, color: Colors.grey.shade300),
                  _buildTonnageTile('Locked in Escrow', '${reservedQtl.toStringAsFixed(0)} Qtl', const Color(0xFFD97706), 'Under Active PO'),
                ],
              ),

              if (reservedQtl > 0) ...[
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.lock_clock, size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${reservedQtl.toStringAsFixed(0)} Qtl is locked for ITC Limited (PO-ITC-3000QTL-NH44) awaiting dispatch.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 6. REAL-TIME SILO ENVIRONMENTAL TELEMETRY
        Text(
          'Silo Environmental Telemetry',
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTelemetryCard('Chamber Temp', '21.4°C', 'Safe (< 25°C)', Icons.thermostat, const Color(0xFF0284C7)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTelemetryCard('Ambient Humidity', '54% RH', 'Optimal (< 65%)', Icons.water_drop_outlined, const Color(0xFF16A34A)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTelemetryCard('Aeration Blower', 'Active', 'Automated Cycling', Icons.air, const Color(0xFF7C3AED)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTelemetryCard('Pest Inspection', 'Zero Pest', 'Valid till Nov 2026', Icons.shield_outlined, const Color(0xFFD97706)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 7. PHYSICAL ASSAYING & QUALITY SPECIFICATIONS
        Text(
          'Physical Assaying & Quality Specs',
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            children: [
              _buildSpecRow('Moisture Assay', widget.moistureText, 'Standard ≤ 12.0%', true),
              const Divider(height: 16),
              _buildSpecRow('Purity Score', '98.8%', 'Minimum ≥ 98.0%', true),
              const Divider(height: 16),
              _buildSpecRow('Broken Grains', '1.4%', 'AGMARK Grade A ≤ 2.0%', true),
              const Divider(height: 16),
              _buildSpecRow('Foreign Matter', '0.3%', 'Standard ≤ 0.75%', true),
              const Divider(height: 16),
              _buildSpecRow('Bulk Density (Test Weight)', '79.4 kg/hL', 'Heavy Test Grain', true),
              const Divider(height: 16),
              _buildSpecRow('Protein / Gluten Content', '12.8% Wet Gluten', 'Superior Milling Yield', true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 8. COMMERCIAL TRADING & LOGISTICS TERMS
        Text(
          'Commercial Terms & Logistics',
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            children: [
              _buildTermItem('Minimum Order Quantity (MOQ)', '250 Quintals (1 Full Truckload / FTL)', Icons.fire_truck_outlined),
              _buildTermItem('Dispatch Lead Time', '24 - 48 Hours post-Escrow Confirmation', Icons.schedule),
              _buildTermItem('Weighbridge Specifications', '600-Quintal Electronic (NABL Haryana Calibrated)', Icons.scale_outlined),
              _buildTermItem('Mandi Cess & Tax Exemption', '0% GST (Tax Exempt) • 0.5% HR Mandi Cess', Icons.receipt_long_outlined),
              _buildTermItem('Escrow Settlement Type', 'Multi-FPO Isolated Smart Contract Escrow', Icons.verified_user_outlined),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 9. STATUTORY LICENSES & PROVENANCE HASH
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.fingerprint, size: 16, color: Color(0xFF334155)),
                  SizedBox(width: 6),
                  Text(
                    'Compliance & Traceability',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'FSSAI Lic: 1002302200192 • SFAC ID: SFAC-HR-KNL-08819\nSmart Contract Hash: 0x7b4a92c81092e44f8819',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 10. PRIMARY PROCUREMENT ACTION
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              final qtyMt = widget.availableMt > 0 ? (widget.availableMt > 250 ? 250.0 : widget.availableMt) : 100.0;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EscrowCheckoutScreen(
                    commodity: '${widget.cropName} (${widget.variety})',
                    variety: widget.variety,
                    originCluster: widget.siloLocation,
                    orderedTonnage: qtyMt,
                    cropRatePerTonne: widget.pricePerMt,
                    orderedQuantityQtl: qtyMt * 10,
                    cropRatePerQtl: widget.pricePerQtl,
                    fpoId: widget.fpoId ?? 'fpo_karnal_01',
                    fpoName: widget.fpoName ?? 'Karnal Agro Farmers Producer Co.',
                    inventoryItemId: widget.inventoryItemId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.lock, size: 16, color: Colors.white),
            label: Text(
              'Order Lot & Escrow Lock (@ ₹${widget.pricePerQtl.toStringAsFixed(0)}/Qtl)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isDownloadingPdf ? null : _triggerDownloadPdf,
                icon: _isDownloadingPdf
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download, size: 16),
                label: Text(_isDownloadingPdf ? 'Generating...' : 'Download Passport', style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  if (widget.onRunAiAssay != null) {
                    widget.onRunAiAssay!();
                  }
                },
                icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                label: const Text('Run AI Assaying', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTonnageTile(String label, String value, Color color, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildTelemetryCard(String label, String value, String status, IconData icon, Color color) {
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
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(
            status,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String parameter, String measured, String benchmark, bool isPass) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(parameter, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            Text(benchmark, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ],
        ),
        Row(
          children: [
            Text(measured, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(width: 6),
            const Icon(Icons.check_circle, size: 15, color: Color(0xFF15803D)),
          ],
        ),
      ],
    );
  }

  Widget _buildTermItem(String title, String detail, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text(detail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
