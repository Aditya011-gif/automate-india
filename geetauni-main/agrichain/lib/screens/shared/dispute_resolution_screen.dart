import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Screen S3: Dispute Resolution & 3-Member FPO DAO Governance Committee
class DisputeResolutionScreen extends StatefulWidget {
  final String disputeId;
  final String orderId;
  final String commodity;
  final String buyerName;
  final String sellerFpo;
  final double disputedAmount;

  const DisputeResolutionScreen({
    super.key,
    this.disputeId = 'DISPUTE-2026-081',
    this.orderId = 'PO-MILL-88190',
    this.commodity = 'Basmati Paddy 1121 (25 MT)',
    this.buyerName = 'AgroFoods Milling India Pvt Ltd',
    this.sellerFpo = 'Karnal Farmers Producer Co.',
    this.disputedAmount = 880000.0,
  });

  @override
  State<DisputeResolutionScreen> createState() => _DisputeResolutionScreenState();
}

class _DisputeResolutionScreenState extends State<DisputeResolutionScreen> {
  String? _myVote;
  int _votesCast = 2; // 2 of 3 committee members voted
  final int _totalCommitteeMembers = 3;

  final List<Map<String, dynamic>> _committeeVotes = [
    {
      'name': 'Dr. Satish Verma',
      'role': 'Agricultural Extension Officer (Govt Appointee)',
      'vote': 'PARTIAL_PRO_RATA',
      'timestamp': '30 Aug 2026, 02:15 PM',
      'txHash': '0x9a81c2...11b4',
    },
    {
      'name': 'Harinder Dhillon',
      'role': 'Elected FPO Board Member',
      'vote': 'DISMISS_DISPUTE',
      'timestamp': '30 Aug 2026, 03:40 PM',
      'txHash': '0x7e22f0...44d9',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF37474F),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dispute Arbitration & DAO Voting',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF37474F),
              ),
            ),
            Text(
              'Ballot.sol Smart Contract • 3-Member Governance Panel',
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
          // 1. Dispute Header Card
          _buildDisputeHeaderCard(),
          const SizedBox(height: 16),

          // 2. Evidence Comparison Card (Claimed vs Gate QC)
          _buildEvidenceReviewCard(),
          const SizedBox(height: 16),

          // 3. Quorum & On-Chain Voting Tracker
          _buildCommitteeVotesTracker(),
          const SizedBox(height: 16),

          // 4. Casting Ballot Action Card
          _buildCastBallotSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDisputeHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.04),
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
              Text(
                widget.disputeId,
                style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade900),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ESCROW FROZEN (PENDING DAO)',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.commodity,
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
          ),
          const SizedBox(height: 4),
          Text('Buyer: ${widget.buyerName}', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700)),
          Text('Seller: ${widget.sellerFpo}', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Disputed Value in Escrow:', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
              Text(
                '₹${widget.disputedAmount.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.red.shade900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceReviewCard() {
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
              const Icon(Icons.compare_arrows, color: Color(0xFF37474F), size: 18),
              const SizedBox(width: 8),
              Text(
                'Arbitration Evidence Review',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF37474F)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildEvidenceRow('Claimed Moisture (CropNFT):', '11.4% (Grade A)', Colors.green.shade800),
                _buildEvidenceRow('Factory Gate Lab Assay:', '13.1% (Exceeds Tolerance by 1.1%)', Colors.red.shade800),
                _buildEvidenceRow('Transit Cold-Chain Reefer:', 'Normal (+4.2°C, 0 Temp Spikes)', Colors.blue.shade800),
                _buildEvidenceRow('Weighbridge Gross Tare:', '25.0 MT (100% Volume Intact)', Colors.black87),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceRow(String label, String val, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600)),
          Text(val, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: valColor)),
        ],
      ),
    );
  }

  Widget _buildCommitteeVotesTracker() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'On-Chain Ballot Quorum ($_votesCast / $_totalCommitteeMembers Votes)',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF37474F)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Ballot.sol', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: Colors.blue.shade900)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._committeeVotes.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v['name'], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(v['role'], style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Text(
                    v['vote'],
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF37474F)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCastBallotSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cast Your Committee Ballot',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF263238)),
          ),
          const SizedBox(height: 10),
          _buildVoteOptionButton('PARTIAL_PRO_RATA', 'Split 80% to Farmer, 20% Rebate to Buyer', Icons.pie_chart),
          const SizedBox(height: 8),
          _buildVoteOptionButton('UPHOLD_BUYER_CLAIM', 'Claim 100% Transit Insurance for Buyer', Icons.shield),
          const SizedBox(height: 8),
          _buildVoteOptionButton('DISMISS_DISPUTE', 'Dismiss Dispute & Release 100% Escrow to Farmer', Icons.gavel),
        ],
      ),
    );
  }

  Widget _buildVoteOptionButton(String voteKey, String label, IconData icon) {
    final isSelected = _myVote == voteKey;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _myVote = voteKey;
            _votesCast = 3;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vote "$voteKey" signed with private key and recorded on Ballot.sol.'),
              backgroundColor: const Color(0xFF37474F),
            ),
          );
        },
        icon: Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF37474F)),
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF37474F))),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF37474F) : Colors.white,
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
