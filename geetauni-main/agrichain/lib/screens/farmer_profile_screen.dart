import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/firestore_models.dart';
import '../theme/app_theme.dart';
import '../services/score_engine.dart';

class FarmerProfileScreen extends StatefulWidget {
  final FirestoreCrop crop;

  const FarmerProfileScreen({super.key, required this.crop});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scoreRevealController;
  late Animation<double> _scoreRevealAnimation;

  @override
  void initState() {
    super.initState();
    _scoreRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreRevealAnimation = CurvedAnimation(
      parent: _scoreRevealController,
      curve: Curves.easeOutCubic,
    );

    if (widget.crop.agriScore != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scoreRevealController.forward();
      });
    }
  }

  @override
  void dispose() {
    _scoreRevealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: Text(
          'Farmer Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFarmerInfoCard(),
            const SizedBox(height: 24),
            if (widget.crop.agriScore != null) ...[
              Text(
                'Land Analysis Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
              ),
              const SizedBox(height: 16),
              _buildScoreCard(),
              const SizedBox(height: 16),
              _buildEnvironmentCard(),
              const SizedBox(height: 16),
              if (widget.crop.mlPredictions != null) _buildMLPredictionsCard(),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.terrain, size: 64, color: AppTheme.textDisabled),
                      const SizedBox(height: 16),
                      Text(
                        'No Land Analysis Available',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
            child: Text(
              widget.crop.farmerName.isNotEmpty ? widget.crop.farmerName[0] : 'F',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.crop.farmerName,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 16, color: AppTheme.primaryGreen),
                const SizedBox(width: 6),
                Text(
                  'Verified Farmer',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.crop.location,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    final score = widget.crop.agriScore!;
    final tier = widget.crop.riskTier ?? 'Bronze';
    final tierColor = _getTierColor(tier);
    final loanLimit = ScoreEngine.getLoanLimit(tier);

    return AnimatedBuilder(
      animation: _scoreRevealAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _scoreRevealAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _scoreRevealAnimation.value)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tierColor.withOpacity(0.85),
                    tierColor.withOpacity(0.65),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: tierColor.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$tier Tier',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${score.toInt()}',
                    style: GoogleFonts.poppins(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Agri-Trust Score',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'out of 1000',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: score / 1000,
                      minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Loan Eligible: ₹${_formatAmount(loanLimit)}',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnvironmentCard() {
    final ndvi = widget.crop.ndviValue ?? 0.0;
    final soil = widget.crop.soilType ?? 'Unknown';

    return _buildCard(
      icon: Icons.eco,
      title: 'Environmental Data',
      child: Column(
        children: [
          _buildEnvRow(
            Icons.satellite_alt,
            'NDVI Index',
            ndvi.toStringAsFixed(3),
            ndvi >= 0.5 ? AppTheme.success : AppTheme.warning,
          ),
          _buildEnvRow(Icons.terrain, 'Soil Type', soil, AppTheme.earthBrown),
          _buildEnvRow(
            Icons.landscape,
            'Land Class',
            'Agricultural Land',
            AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildMLPredictionsCard() {
    final ml = widget.crop.mlPredictions!;

    return _buildCard(
      icon: Icons.smart_toy,
      title: 'AI Predictions',
      child: Column(
        children: [
          _buildMLRow('Crop Quality', ml['crop_quality']?.toString() ?? 'N/A', Icons.star),
          _buildMLRow(
            'Health Score',
            '${ml['crop_health_score'] ?? '--'}/100',
            Icons.favorite,
          ),
          _buildMLRow('Risk Level', ml['risk_level']?.toString() ?? 'N/A', Icons.shield),
          _buildMLRow(
            'NDVI Trend',
            ml['ndvi_trend']?.toString() ?? 'N/A',
            Icons.trending_up,
          ),
          if (ml['ndvi_trend_description'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ml['ndvi_trend_description'].toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.info,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: AppTheme.primaryGreen),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEnvRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMLRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Platinum': return const Color(0xFF6C63FF);
      case 'Gold': return const Color(0xFFE6A817);
      case 'Silver': return const Color(0xFF78909C);
      case 'Bronze': return const Color(0xFFBF6D3A);
      default: return AppTheme.primaryGreen;
    }
  }

  String _formatAmount(int amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(amount % 100000 == 0 ? 0 : 1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toString();
  }
}
