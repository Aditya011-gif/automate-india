import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/enhanced_app_bar.dart';

/// Screen 09: CropNFT Digital Passport Card Screen (Polygon ERC-721 & AGMARK Grade A)
class CropNftCardScreen extends StatelessWidget {
  final String tokenId;
  final String cropName;
  final String variety;
  final double quantityKg;
  final double pricePerKg;
  final String agmarkGrade;
  final double moisturePercentage;
  final double brokenGrainPercentage;
  final double foreignMatterPercentage;
  final double purityScore;
  final String farmerName;
  final String location;
  final String ipfsHash;
  final String contractAddress;
  final String txHash;

  const CropNftCardScreen({
    super.key,
    this.tokenId = '88019',
    this.cropName = 'Basmati Paddy 1121',
    this.variety = 'PB-1121 (Export Grade)',
    this.quantityKg = 500.0,
    this.pricePerKg = 35.20,
    this.agmarkGrade = 'AGMARK Grade A',
    this.moisturePercentage = 11.2,
    this.brokenGrainPercentage = 2.1,
    this.foreignMatterPercentage = 0.3,
    this.purityScore = 99.1,
    this.farmerName = 'Ramesh Kumar (Kisaan)',
    this.location = 'Karnal Cluster, Haryana',
    this.ipfsHash = 'ipfs://bafybeid7k9201948ba2981048bca8819024',
    this.contractAddress = '0x3B887fC3171802998634B033A18378A527A37d71',
    this.txHash = '0x8f7a294b01982b19283748291048bca9028190248bca9012',
  });

  @override
  Widget build(BuildContext context) {
    final totalValuation = quantityKg * pricePerKg;
    final totalBags = (quantityKg / 50).round(); // 50kg bags
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: EnhancedAppBar(
        title: 'CropNFT Digital Passport',
        subtitle: 'Polygon PoS L2 • ERC-721 Token',
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF1B5E20)),
            tooltip: 'Share Passport',
            onPressed: () => _shareOnWhatsApp(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 1. Digital Passport Card
          _buildPassportCard(totalValuation, totalBags),
          const SizedBox(height: 20),

          // 2. Action Buttons: PolygonScan & WhatsApp
          _buildActionButtons(context, canPop),
        ],
      ),
    );
  }

  Widget _buildPassportCard(double totalValuation, int totalBags) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D381E),
            Color(0xFF1B5E20),
            Color(0xFF092813),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF69F0AE).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Passport Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF69F0AE).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.token, color: Color(0xFF69F0AE), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Polygon PoS L2 • ERC-721',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF69F0AE),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Token ID: #$tokenId',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, size: 13, color: Colors.black),
                      const SizedBox(width: 4),
                      Text(
                        'AGMARK Grade A',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crop Name & Variety
                Text(
                  cropName,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Variety: $variety • Farmer: $farmerName',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 14),

                // Valuation & Bag Volume Container
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Harvest Volume:', style: GoogleFonts.inter(fontSize: 10, color: Colors.white60)),
                          const SizedBox(height: 2),
                          Text(
                            '${quantityKg.toStringAsFixed(0)} kg ($totalBags Bags)',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Smart Escrow Value:', style: GoogleFonts.inter(fontSize: 10, color: Colors.white60)),
                          const SizedBox(height: 2),
                          Text(
                            '₹${totalValuation.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF69F0AE),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // AI Physical Assaying Metrics Grid
                Text(
                  'AI Physical Quality Assaying:',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF69F0AE)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildQualityMetricTile('Moisture %', '$moisturePercentage%', 'Max 12.0%', Icons.water_drop_outlined),
                    const SizedBox(width: 8),
                    _buildQualityMetricTile('Broken %', '$brokenGrainPercentage%', 'Max 3.0%', Icons.grain),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildQualityMetricTile('Foreign Matter', '$foreignMatterPercentage%', 'Max 0.5%', Icons.clean_hands_outlined),
                    const SizedBox(width: 8),
                    _buildQualityMetricTile('Purity Score', '$purityScore%', 'Min 95.0%', Icons.check_circle_outline),
                  ],
                ),
                const SizedBox(height: 16),

                // QR Code & Verification Proof
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1B5E20), width: 1.5),
                        ),
                        child: const Icon(Icons.qr_code_2, size: 60, color: Color(0xFF0F381E)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'On-Chain Verification QR',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Scan to verify AGMARK lab parameters, seed lineage & IPFS metadata proof on Polygon blockchain.',
                              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade700, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Cryptographic Proof hashes
                Text('IPFS: $ipfsHash', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: Colors.white54), overflow: TextOverflow.ellipsis),
                Text('Contract: $contractAddress', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: Colors.white54), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityMetricTile(String label, String value, String standard, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF69F0AE), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 9, color: Colors.white60)),
                  Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(standard, style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF69F0AE))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool canPop) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _openPolygonScan(context),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('View on PolygonScan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B3FE4), // Polygon Purple
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _shareOnWhatsApp(context),
            icon: const Icon(Icons.share, color: Color(0xFF1B5E20)),
            label: const Text('Share Digital Passport via WhatsApp'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1B5E20),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (canPop) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Farm Dashboard'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1B5E20),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openPolygonScan(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.token, color: Color(0xFF7B3FE4)),
            const SizedBox(width: 8),
            Text('Polygon L2 Explorer', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Network: Polygon Mainnet PoS (Chain ID 137)', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text('ERC-721 Contract: $contractAddress', style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Token ID: #$tokenId', style: GoogleFonts.jetBrainsMono(fontSize: 10)),
            const SizedBox(height: 4),
            Text('Tx Hash: $txHash', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Text('Status: 100% Confirmed (Block #58,910,291)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7B3FE4))),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B3FE4)),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareOnWhatsApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CropNFT Digital Passport link copied! Share via WhatsApp to buyers and FPOs.'),
        backgroundColor: Color(0xFF1B5E20),
      ),
    );
  }
}
