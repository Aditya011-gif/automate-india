import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

/// Screen 10: Farmer Passbook & Payouts (Direct UPI & Tax-Free Agri Income Slip)
class FarmerPayoutHistoryScreen extends StatefulWidget {
  const FarmerPayoutHistoryScreen({super.key});

  @override
  State<FarmerPayoutHistoryScreen> createState() => _FarmerPayoutHistoryScreenState();
}

class _FarmerPayoutHistoryScreenState extends State<FarmerPayoutHistoryScreen> {
  final List<Map<String, dynamic>> _mockPayouts = [
    {
      'id': 'TXN-90281-UPI',
      'crop': 'Basmati Paddy 1121',
      'lotSize': '45 Quintals (2.25 MT)',
      'buyer': 'AgroFoods Milling India Pvt Ltd',
      'date': '28 Aug 2026, 04:30 PM',
      'amount': 158500.0,
      'status': 'CREDITED',
      'bank': 'State Bank of India •••• 4821',
      'utr': 'UPI/428901829102/AGRI',
      'escrowTxHash': '0x8f7a29...4b91',
      'taxSection': 'Sec 10(1) IT Act (Tax Exempt)',
    },
    {
      'id': 'TXN-88190-UPI',
      'crop': 'Sharbati Wheat (Grade A)',
      'lotSize': '30 Quintals (1.5 MT)',
      'buyer': 'Karnal Farmers Producer Co.',
      'date': '19 Aug 2026, 11:15 AM',
      'amount': 84200.0,
      'status': 'CREDITED',
      'bank': 'State Bank of India •••• 4821',
      'utr': 'UPI/428190182736/AGRI',
      'escrowTxHash': '0x1c4d92...8e23',
      'taxSection': 'Sec 10(1) IT Act (Tax Exempt)',
    },
    {
      'id': 'TXN-84102-ESCROW',
      'crop': 'Hybrid Red Onion',
      'lotSize': '20 Quintals (1.0 MT)',
      'buyer': 'FreshMart Retail Hypermarket',
      'date': '12 Aug 2026, 06:45 PM',
      'amount': 54000.0,
      'status': 'CREDITED',
      'bank': 'State Bank of India •••• 4821',
      'utr': 'UPI/427901829441/AGRI',
      'escrowTxHash': '0x6e2b10...9f12',
      'taxSection': 'Sec 10(1) IT Act (Tax Exempt)',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final farmerName = user?.name.isNotEmpty == true ? user!.name : 'Ramesh Kumar (Kisaan)';
    final location = user?.location ?? 'Karnal, Haryana';

    double totalSeasonRevenue = 0;
    for (var p in _mockPayouts) {
      totalSeasonRevenue += (p['amount'] as double);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF1B5E20),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kisaan Passbook & Payouts',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B5E20),
              ),
            ),
            Text(
              'Direct UPI Bank Credits • Polygon Smart Escrow',
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
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF1B5E20)),
            tooltip: 'Download Tax-Free Income Slip',
            onPressed: () => _showIncomeSlipDialog(context, farmerName, location, totalSeasonRevenue),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Season Revenue Header Card
          _buildRevenueHeaderCard(totalSeasonRevenue),
          const SizedBox(height: 16),

          // 2. Verified Bank & DBT Account Card
          _buildVerifiedBankCard(farmerName),
          const SizedBox(height: 20),

          // 3. Section Title & Download Slip CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Direct Settlement Ledger',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              InkWell(
                onTap: () => _showIncomeSlipDialog(context, farmerName, location, totalSeasonRevenue),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.download, size: 14, color: Color(0xFF1B5E20)),
                      const SizedBox(width: 4),
                      Text(
                        'Tax Exemption Slip',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. Payout Transaction Tiles
          ..._mockPayouts.map((txn) => _buildPayoutCard(txn)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRevenueHeaderCard(double totalRevenue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Season Sales Revenue',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF69F0AE), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '100% Escrow Settled',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${totalRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricCol('Settled Lots', '3 Harvests (4.75 MT)'),
              _buildMetricCol('Avg Realization', '₹3,520 / Qtl'),
              _buildMetricCol('Tax Liability', '₹0 (Exempted)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 10, color: Colors.white60)),
        const SizedBox(height: 2),
        Text(
          val,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildVerifiedBankCard(String farmerName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance, color: Color(0xFF1565C0), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'State Bank of India (SBI)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Penny-Drop Verified',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'A/C: ••••••••4821 | IFSC: SBIN0001290 | Beneficiary: $farmerName',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutCard(Map<String, dynamic> txn) {
    final amount = txn['amount'] as double;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  const Icon(Icons.arrow_downward, color: Color(0xFF00C853), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    txn['crop'],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
              Text(
                '+₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lot: ${txn['lotSize']} • Buyer: ${txn['buyer']}',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UTR: ${txn['utr']}',
                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.grey.shade600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  txn['status'],
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showIncomeSlipDialog(BuildContext context, String name, String location, double total) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified_user, color: Color(0xFF1B5E20)),
            const SizedBox(width: 8),
            Text('Tax-Free Agri Income Slip', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GOVERNMENT OF INDIA • FORM 16-AGRI (PROVISIONAL)', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Farmer: $name', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            Text('Location: $location', style: GoogleFonts.inter(fontSize: 12)),
            const SizedBox(height: 8),
            Text('Total Direct Credit: ₹${total.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF1B5E20))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Statutory Exemption under Section 10(1) of the Income Tax Act, 1961. 100% Tax-Free Agricultural Proceeds.',
                style: GoogleFonts.inter(fontSize: 10, color: Colors.green.shade900),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tax-Free Agriculture Income Slip PDF downloaded to device.'),
                  backgroundColor: Color(0xFF1B5E20),
                ),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Download Official PDF'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
          ),
        ],
      ),
    );
  }
}
