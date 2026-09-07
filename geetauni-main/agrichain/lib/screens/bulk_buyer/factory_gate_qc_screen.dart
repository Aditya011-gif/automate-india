import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Screen 20: Factory Gate 24-Hour QC Inspection & 3-Way Settlement Gate
class FactoryGateQcScreen extends StatefulWidget {
  final String orderId;
  final String commodity;
  final double orderedTonnage;
  final String claimedMoisture;
  final String claimedGrade;

  const FactoryGateQcScreen({
    super.key,
    this.orderId = 'PO-MILL-88190',
    this.commodity = 'Basmati Paddy 1121',
    this.orderedTonnage = 250.0,
    this.claimedMoisture = '11.4%',
    this.claimedGrade = 'AGMARK Grade A',
  });

  @override
  State<FactoryGateQcScreen> createState() => _FactoryGateQcScreenState();
}

class _FactoryGateQcScreenState extends State<FactoryGateQcScreen> {
  final _labMoistureController = TextEditingController(text: '11.6');
  final _labBrokenController = TextEditingController(text: '2.5');
  final _labForeignMatterController = TextEditingController(text: '0.4');
  final _partialTonnageController = TextEditingController(text: '200.0');

  late Timer _timer;
  Duration _remainingTime = const Duration(hours: 19, minutes: 42, seconds: 15);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _labMoistureController.dispose();
    _labBrokenController.dispose();
    _labForeignMatterController.dispose();
    _partialTonnageController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF0D47A1),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Factory Gate QC Inspection',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D47A1),
              ),
            ),
            Text(
              'Sale of Goods Act, 1930 • 24-Hour Statutory Window',
              style: GoogleFonts.inter(
                fontSize: 10,
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
          // 1. 24-Hour Countdown Timer Card
          _buildCountdownTimerCard(),
          const SizedBox(height: 16),

          // 2. Claimed CropNFT Metadata vs Physical Lab Test Entry
          _buildLabComparisonCard(),
          const SizedBox(height: 16),

          // 3. Three-Way Action Gate (Approve / Partial / Dispute)
          _buildThreeWayActionGateSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCountdownTimerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2647), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.orderId,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Color(0xFF69F0AE), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Statutory Gate',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF69F0AE)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatDuration(_remainingTime),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Remaining to complete physical lab testing. If no action is taken, smart escrow auto-settles under Section 42 of Sale of Goods Act, 1930.',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildLabComparisonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.biotech, color: Color(0xFF0D47A1), size: 18),
              const SizedBox(width: 8),
              Text(
                'Quality Assaying (Claimed vs Actual Lab Test)',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Claimed CropNFT Metadata:', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700)),
                Text(
                  '${widget.claimedGrade} • Moisture: ${widget.claimedMoisture}',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00C853)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Enter Plant Gate Lab Assay Readings:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _labMoistureController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Lab Moisture %',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _labBrokenController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Broken Grain %',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _labForeignMatterController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Foreign Matter %',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThreeWayActionGateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statutory QC Decision Gate',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
        ),
        const SizedBox(height: 10),

        // Action 1: 100% Approve
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          child: ElevatedButton.icon(
            onPressed: () => _handleApproval(),
            icon: const Icon(Icons.check_circle, color: Colors.white),
            label: const Text('APPROVE 100% LOT & RELEASE ESCROW'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        // Action 2: Partial Accept
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          child: OutlinedButton.icon(
            onPressed: () => _showPartialAcceptDialog(),
            icon: const Icon(Icons.pie_chart, color: Color(0xFFF57F17)),
            label: const Text('PARTIAL ACCEPT (SPECIFY TONNAGE)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF57F17),
              side: const BorderSide(color: Color(0xFFF57F17), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        // Action 3: Full Dispute
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _handleFullDispute(),
            icon: const Icon(Icons.gavel, color: Colors.red),
            label: const Text('FULL DISPUTE & CLAIM TRANSIT INSURANCE'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  void _handleApproval() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified, color: Color(0xFF00C853)),
            const SizedBox(width: 8),
            Text('100% Approval Confirmed', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Smart Contract Escrow released ₹8,80,000 via multi-split UPI to member farmers and freight transporter. Official B2B GST Tax Invoice generated in Vault.',
          style: GoogleFonts.inter(fontSize: 12, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showPartialAcceptDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Specify Accepted Volume', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _partialTonnageController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Accepted Volume (Qtl)',
                suffixText: 'Qtl',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pro-rata funds will be disbursed for accepted volume. Rejected volume is covered under 0.2% transit insurance protocol.',
              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Partial acceptance of ${_partialTonnageController.text} Qtl processed.'),
                  backgroundColor: const Color(0xFFF57F17),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF57F17)),
            child: const Text('Release Pro-Rata Escrow'),
          ),
        ],
      ),
    );
  }

  void _handleFullDispute() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('Dispute Raised', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Escrow funds frozen. Dispute routed to FPO Governance Arbitration Panel (Ballot.sol). Transit Insurance claim ticket created.',
          style: GoogleFonts.inter(fontSize: 12, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('View Dispute Status'),
          ),
        ],
      ),
    );
  }
}
