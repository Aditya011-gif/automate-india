import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/b2b_contract_model.dart';
import '../../services/database_service.dart';
import '../../services/smart_contract_pdf_service.dart';
import '../../theme/app_theme.dart';

/// Screen: Official B2B Tripartite Smart Contract Viewer & E-Sign Inspection Sheet
/// Conforms to legal trade standards for institutional procurement between
/// FPOs, Corporate Bulk Buyers, and the AgriChain Escrow Protocol.
class B2bContractScreen extends StatefulWidget {
  final B2bContractModel? contract;
  final String? orderId;

  const B2bContractScreen({
    super.key,
    this.contract,
    this.orderId,
  });

  @override
  State<B2bContractScreen> createState() => _B2bContractScreenState();
}

class _B2bContractScreenState extends State<B2bContractScreen> {
  final DatabaseService _dbService = DatabaseService();
  B2bContractModel? _loadedContract;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.contract != null) {
      _loadedContract = widget.contract;
    } else if (widget.orderId != null) {
      _fetchContract(widget.orderId!);
    }
  }

  Future<void> _fetchContract(String orderId) async {
    setState(() => _isLoading = true);
    final contract = await _dbService.getB2bContract(orderId);
    if (mounted) {
      setState(() {
        _loadedContract = contract ??
            B2bContractModel.generateDefault(
              orderId: orderId,
              buyerId: 'buyer_institutional',
              buyerName: 'ITC Agri Business Division',
              buyerCompany: 'ITC Limited (ABD)',
              buyerGstin: '06AABCI9821E1ZK',
              fpoId: 'fpo_karnal_01',
              fpoName: 'Karnal Agro Farmers Producer Co.',
              fpoGstin: '06AAACF1049K1ZZ',
              commodity: 'Sharbati Wheat',
              variety: 'Milling Grade 1',
              qualityGrade: 'Grade A (NABL Assayed)',
              quantityQtl: 3000.0,
              pricePerQtl: 2450.0,
              freightAmount: 32400.0,
              carrierName: 'BlackBuck FTL Logistics',
              originLocation: 'Karnal Silo Dock 01, Haryana',
              destinationFactory: 'Kundli Food Processing Terminal, Sonipat',
            );
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

    final contract = _loadedContract;
    if (contract == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('B2B Smart Contract')),
        body: const Center(child: Text('Contract not found.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF1B5E20),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tripartite Smart Contract',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B5E20),
              ),
            ),
            Text(
              'Polygon PoS L2 • Immutable Legal Agreement',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Download Official PDF Contract',
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF1B5E20)),
            onPressed: () {
              SmartContractPdfService.autoDownloadOrPreviewB2bContract(
                context: context,
                contract: contract,
                openDirectly: true,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                SmartContractPdfService.autoDownloadOrPreviewB2bContract(
                  context: context,
                  contract: contract,
                  openDirectly: true,
                );
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
              label: Text(
                'Download Official PDF Contract',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // 1. Legal Certificate Header Container
          _buildLegalHeaderContainer(contract),
          const SizedBox(height: 16),

          // 2. Cryptographic Blockchain Verification Strip
          _buildBlockchainAnchorStrip(contract),
          const SizedBox(height: 16),

          // 3. Contracting Parties (Tripartite: Buyer, FPO, Escrow Agent)
          _buildContractingPartiesSection(contract),
          const SizedBox(height: 16),

          // 4. Physical Commodity Specs & NABL Quality Matrix
          _buildCommoditySpecsCard(contract),
          const SizedBox(height: 16),

          // 5. Commercials & Escrow Lock Schedule
          _buildCommercialsEscrowCard(contract),
          const SizedBox(height: 16),

          // 6. Tripartite Legal Clauses
          _buildLegalClausesSection(contract),
          const SizedBox(height: 20),

          // 7. Digital Signature Seals & Verification Stamps
          _buildDigitalSignaturesCard(contract),
          const SizedBox(height: 30),

          // 8. Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B5E20),
                    side: const BorderSide(color: Color(0xFF1B5E20)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    SmartContractPdfService.autoDownloadOrPreviewB2bContract(
                      context: context,
                      contract: contract,
                      openDirectly: true,
                    );
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Save PDF Contract'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLegalHeaderContainer(B2bContractModel c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user, color: Color(0xFF1B5E20), size: 28),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AGRICHAIN SMART ESCROW PROTOCOL',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  Text(
                    'Institutional Tripartite Agricultural Supply Agreement',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contract ID', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  Text(
                    c.contractNumber,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock, size: 12, color: Color(0xFF15803D)),
                    const SizedBox(width: 4),
                    Text(
                      'EXECUTED & LOCKED',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Executed On: ${c.createdAt.split('T').first}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              Text(
                'Target Delivery: ${c.expectedDeliveryDate}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainAnchorStrip(B2bContractModel c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
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
                  const Icon(Icons.polyline, color: Color(0xFF818CF8), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    c.blockchainNetwork,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC7D2FE),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF312E81),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'IMMUTABLE HASH',
                  style: TextStyle(fontSize: 9, color: Color(0xFFA5B4FC), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Smart Escrow Address: ${c.polygonContractAddress}',
            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'SHA-256 Fingerprint: ${c.sha256Hash}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    color: const Color(0xFF38BDF8),
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.copy, size: 14, color: Color(0xFF38BDF8)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: c.sha256Hash));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hash copied!')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContractingPartiesSection(B2bContractModel c) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_outlined, color: Color(0xFF1B5E20), size: 18),
              const SizedBox(width: 8),
              Text(
                'Contracting Parties (Tripartite)',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20),

          // Party 1: Buyer
          _buildPartyItem(
            roleBadge: 'FIRST PARTY • BUYER',
            badgeColor: const Color(0xFF0284C7),
            name: c.buyerCompany,
            subName: 'Represented by: ${c.buyerSignatory}',
            gstin: c.buyerGstin,
            location: c.destinationFactory,
            icon: Icons.business,
          ),
          const SizedBox(height: 14),

          // Party 2: FPO
          _buildPartyItem(
            roleBadge: 'SECOND PARTY • PRODUCER ORGANIZATION (FPO)',
            badgeColor: const Color(0xFF15803D),
            name: c.fpoName,
            subName: 'Registration: ${c.fpoRegistrationNo} • Auth: ${c.fpoSignatory}',
            gstin: c.fpoGstin,
            location: c.originLocation,
            icon: Icons.storefront,
          ),

          // Multi-FPO Pooled Contributor Tags if applicable
          if (c.isMultiFpo && c.coFpos.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contributing Co-Signatory FPOs (7 km Corridor):',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  ...c.coFpos.map((co) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '• ${co['fpoName'] ?? 'Partner FPO'}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${co['quantityQtl'] ?? 0} Qtl',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Party 3: Platform Escrow
          _buildPartyItem(
            roleBadge: 'THIRD PARTY • ESCROW AGENT & TRUSTEE',
            badgeColor: const Color(0xFF7C3AED),
            name: 'AgriChain Smart Escrow Protocols Ltd',
            subName: 'Non-Custodial Polygon PoS Smart Escrow Hub',
            gstin: '06AACCA8819L1Z8',
            location: 'National Agricultural Technology Park, NCR',
            icon: Icons.shield,
          ),
        ],
      ),
    );
  }

  Widget _buildPartyItem({
    required String roleBadge,
    required Color badgeColor,
    required String name,
    required String subName,
    required String gstin,
    required String location,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  roleBadge,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
              Icon(icon, size: 16, color: badgeColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(subName, style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569))),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GSTIN: $gstin', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFF64748B))),
              Expanded(
                child: Text(
                  location,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommoditySpecsCard(B2bContractModel c) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                  const Icon(Icons.science_outlined, color: Color(0xFF1B5E20), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Commodity Specifications & NABL Assay Matrix',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  c.qualityGrade,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Commodity: ${c.commodity}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
              Text('Variety: ${c.variety}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 12),

          // Parameter Table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                  children: [
                    _buildTableCell('Assay Parameter', isHeader: true),
                    _buildTableCell('Agreed Spec', isHeader: true),
                    _buildTableCell('Action Limit', isHeader: true),
                  ],
                ),
                TableRow(
                  children: [
                    _buildTableCell('Moisture Content'),
                    _buildTableCell('≤ ${c.moistureTolerancePct}%'),
                    _buildTableCell('> 14.0% Rejection'),
                  ],
                ),
                TableRow(
                  children: [
                    _buildTableCell('Foreign Matter / Dockage'),
                    _buildTableCell('≤ ${c.foreignMatterTolerancePct}%'),
                    _buildTableCell('> 1.5% Penalty'),
                  ],
                ),
                TableRow(
                  children: [
                    _buildTableCell('Broken Grains / Shriveled'),
                    _buildTableCell('≤ ${c.brokenGrainsTolerancePct}%'),
                    _buildTableCell('> 3.0% Pro-rata'),
                  ],
                ),
                TableRow(
                  children: [
                    _buildTableCell('Live Weevil Infestation'),
                    _buildTableCell('NIL (Zero)'),
                    _buildTableCell('Immediate Reject'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? const Color(0xFF0F172A) : const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildCommercialsEscrowCard(B2bContractModel c) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_rupee, color: Color(0xFF1B5E20), size: 18),
              const SizedBox(width: 8),
              Text(
                'Commercial Valuation & Escrow Lock Schedule',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildRow('Contracted Volume', '${c.quantityQtl.toStringAsFixed(0)} Quintals (${c.quantityMT.toStringAsFixed(1)} MT)'),
          _buildRow('Base Wholesale Rate', '₹${c.pricePerQtl.toStringAsFixed(0)} / Qtl (₹${(c.pricePerQtl * 10).toStringAsFixed(0)} / MT)'),
          _buildRow('Gross Commodity Valuation', '₹${c.cropBaseAmount.toStringAsFixed(0)}'),
          _buildRow('Freight Rate (${c.carrierName})', '₹${c.freightAmount.toStringAsFixed(0)}'),
          _buildRow('Single-Trip Transit Insurance (0.2%)', '₹${c.transitInsuranceAmount.toStringAsFixed(0)}'),
          _buildRow('AgriChain Protocol Escrow Fee (1.5%)', '₹${c.protocolFeeAmount.toStringAsFixed(0)}'),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Capital in Smart Escrow:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Text(
                '₹${c.totalEscrowAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF1B5E20)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildLegalClausesSection(B2bContractModel c) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_outlined, color: Color(0xFF1B5E20), size: 18),
              const SizedBox(width: 8),
              Text(
                'Operational & Legal Tripartite Clauses',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20),
          ...c.clauses.map((clause) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clause['title'] ?? 'Clause',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clause['content'] ?? '',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569), height: 1.4),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDigitalSignaturesCard(B2bContractModel c) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.draw_outlined, color: Color(0xFF1B5E20), size: 18),
              const SizedBox(width: 8),
              Text(
                'Cryptographic Digital Signatures & Stamps',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              // Buyer Stamp
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Color(0xFF15803D)),
                          const SizedBox(width: 4),
                          Text(
                            'BUYER E-SIGNED',
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.buyerSignatory,
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      Text(
                        'Time: ${c.buyerSignedAt?.split('T').first ?? 'Recent'}',
                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.buyerSignatureDigest ?? 'E-SIGN:VERIFIED',
                        style: GoogleFonts.jetBrainsMono(fontSize: 8.5, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Seller Stamp
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified, size: 14, color: Color(0xFF1D4ED8)),
                          const SizedBox(width: 4),
                          Text(
                            'FPO SEAL APPLIED',
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.fpoSignatory,
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Reg: ${c.fpoRegistrationNo}',
                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF475569)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.sellerSignatureDigest ?? 'FPO-SEAL:APPLIED',
                        style: GoogleFonts.jetBrainsMono(fontSize: 8.5, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
