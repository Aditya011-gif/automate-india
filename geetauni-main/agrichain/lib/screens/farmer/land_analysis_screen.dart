import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/firestore_models.dart';
import '../../providers/app_state.dart';
import '../../services/agri_score_service.dart';
import '../../services/score_engine.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:agrichain/l10n/app_localizations.dart';
import '../../utils/translation_helper.dart';
import '../../widgets/language_switcher.dart';
import 'demand_forecasting_screen.dart';

class LandAnalysisScreen extends StatefulWidget {
  final FirestoreCrop? crop;

  const LandAnalysisScreen({super.key, this.crop});

  @override
  State<LandAnalysisScreen> createState() => _LandAnalysisScreenState();
}

class _LandAnalysisScreenState extends State<LandAnalysisScreen>
    with TickerProviderStateMixin {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final AgriScoreService _agriScoreService = AgriScoreService();
  final MapController _mapController = MapController();

  void _updateMapLocation() {
    final latStr = _latController.text;
    final lngStr = _lngController.text;
    if (latStr.isNotEmpty && lngStr.isNotEmpty) {
      final lat = double.tryParse(latStr);
      final lng = double.tryParse(lngStr);
      if (lat != null && lng != null) {
        try {
          _mapController.move(LatLng(lat, lng), 16.0);
        } catch (e) {
          // Ignore if map is not ready
        }
      }
    }
  }

  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  String? _error;

  late AnimationController _pulseController;
  late AnimationController _scoreRevealController;
  late Animation<double> _scoreRevealAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scoreRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreRevealAnimation = CurvedAnimation(
      parent: _scoreRevealController,
      curve: Curves.easeOutCubic,
    );

    // Pre-fill with default Indian coordinates
    _latController.text = '28.6139';
    _lngController.text = '77.2090';

    // If crop is passed and already has an analysis, show it
    if (widget.crop != null && widget.crop!.agriScore != null) {
      _analysisResult = {
        'agri_score': widget.crop!.agriScore,
        'risk_category': widget.crop!.riskTier,
        'ndvi_value': widget.crop!.ndviValue,
        'soil_type': widget.crop!.soilType,
        'ml_predictions': widget.crop!.mlPredictions,
      };
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scoreRevealController.forward();
      });
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _pulseController.dispose();
    _scoreRevealController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    if (lat == null || lng == null) {
      setState(() => _error = 'Please enter valid coordinates');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _analysisResult = null;
    });

    _scoreRevealController.reset();

    try {
      final result = await _agriScoreService.analyzeLand(
        latitude: lat,
        longitude: lng,
      );

      // Save to Firestore via AppState if crop exists
      if (mounted && widget.crop != null) {
        await context.read<AppState>().updateCropAgriScore(
          widget.crop!.id,
          result,
        );
      }

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      _scoreRevealController.forward();
    } catch (e) {
      setState(() {
        _error = 'Analysis failed: ${e.toString()}';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: Text(
          l10n?.landAnalysisTitle ?? 'Land Analysis',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.backgroundGreen,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: LanguageSwitcherPill()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crop Info Header
            _buildCropInfoHeader(),
            const SizedBox(height: 24),

            // Map Visualization
            _buildMapVisualization(),
            const SizedBox(height: 24),

            // Coordinate Input
            _buildCoordinateInput(),
            const SizedBox(height: 20),

            // Analyze Button
            _buildAnalyzeButton(),
            const SizedBox(height: 24),

            // Error Message
            if (_error != null) _buildErrorBanner(),

            // Loading Animation
            if (_isAnalyzing) _buildAnalyzingAnimation(),

            // Results
            if (_analysisResult != null && !_isAnalyzing) ...[
              _buildScoreCard(),
              const SizedBox(height: 16),
              _buildBreakdownCard(),
              const SizedBox(height: 16),
              _buildEnvironmentCard(),
              const SizedBox(height: 16),
              if (_analysisResult!['ml_predictions'] != null)
                _buildMLPredictionsCard(),
              const SizedBox(height: 16),
              // KrishiDrishti AI Demand & Price Forecasting Card
              _buildDemandForecastPromptCard(),
              const SizedBox(height: 24),
              _buildDataSourceInfo(),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCropInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.satellite_alt,
              color: AppTheme.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.crop?.name ?? 'Independent Land Scan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  widget.crop != null
                      ? '📍 ${widget.crop!.location}'
                      : '📍 Unlinked Analysis',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (widget.crop?.agriScore != null)
            _buildMiniScoreBadge(
              widget.crop!.agriScore!,
              widget.crop!.riskTier ?? 'Bronze',
            ),
        ],
      ),
    );
  }

  Widget _buildMiniScoreBadge(double score, String tier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getTierColor(tier).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getTierColor(tier).withValues(alpha: 0.4)),
      ),
      child: Text(
        '${score.toInt()}',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _getTierColor(tier),
        ),
      ),
    );
  }

  bool _isGettingLocation = false;

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permissions are denied';
            _isGettingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permissions are permanently denied.';
          _isGettingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      
      setState(() {
        _latController.text = position.latitude.toStringAsFixed(4);
        _lngController.text = position.longitude.toStringAsFixed(4);
        _isGettingLocation = false;
      });
      _updateMapLocation();
    } catch (e) {
      setState(() {
        _error = 'Failed to get location: $e';
        _isGettingLocation = false;
      });
    }
  }

  Widget _buildCoordinateInput() {
    return Container(
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
              const Icon(Icons.location_on, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Land Coordinates',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                icon: _isGettingLocation 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, size: 16),
                label: Text('Use Current', style: GoogleFonts.poppins(fontSize: 13)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Latitude',
                    hintText: 'e.g. 28.61',
                    prefixIcon: const Icon(Icons.north, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (_) {
                    setState(() {});
                    _updateMapLocation();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _lngController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Longitude',
                    hintText: 'e.g. 77.20',
                    prefixIcon: const Icon(Icons.east, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (_) {
                    setState(() {});
                    _updateMapLocation();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isAnalyzing ? null : _runAnalysis,
        icon: _isAnalyzing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.radar, size: 24),
        label: Text(
          _isAnalyzing
              ? (l10n?.analyzingLand ?? 'Scanning Land...')
              : (l10n?.runAnalysis ?? 'Analyze Land Quality'),
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_error!, style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingAnimation() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 120 + (_pulseController.value * 20),
                  height: 120 + (_pulseController.value * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryGreen.withValues(
                      alpha: 0.1 + _pulseController.value * 0.1,
                    ),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(
                        alpha: 0.3 + _pulseController.value * 0.3,
                      ),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.satellite_alt,
                    size: 48,
                    color: AppTheme.primaryGreen,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Scanning satellite data...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fetching NDVI, soil & weather data',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final score = (_analysisResult!['agri_score'] as num).toDouble();
    final tier = _analysisResult!['risk_category'] as String;
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
                    tierColor.withValues(alpha: 0.85),
                    tierColor.withValues(alpha: 0.65),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: tierColor.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Tier Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      TranslationHelper.getRiskTier(context, tier),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Score
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
                    AppLocalizations.of(context)?.agriTrustScore ?? 'Agri-Trust Score',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'out of 1000',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Score bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: score / 1000,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Agronomic Quality & Yield Potential
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Yield Potential: ${score >= 700 ? "Optimal High Output (Tier A)" : "Moderate Resilient (Tier B)"}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
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

  Widget _buildBreakdownCard() {
    final breakdown =
        _analysisResult!['score_breakdown'] as Map<String, dynamic>?;
    if (breakdown == null) return const SizedBox.shrink();

    return _buildCard(
      icon: Icons.analytics,
      title: 'Score Breakdown',
      child: Column(
        children: [
          _buildBreakdownRow(
            'NDVI (Vegetation)',
            breakdown['ndvi_score'] ?? 0,
            350,
            Icons.grass,
          ),
          _buildBreakdownRow(
            'Soil Quality',
            breakdown['soil_score'] ?? 0,
            250,
            Icons.terrain,
          ),
          _buildBreakdownRow(
            'Land Class',
            breakdown['land_class_score'] ?? 0,
            150,
            Icons.landscape,
          ),
          _buildBreakdownRow(
            'Weather',
            breakdown['weather_score'] ?? 0,
            150,
            Icons.cloud,
          ),
          _buildBreakdownRow(
            'Market',
            breakdown['market_score'] ?? 0,
            100,
            Icons.store,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    num score,
    int maxScore,
    IconData icon,
  ) {
    final ratio = maxScore > 0
        ? (score.toDouble() / maxScore).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: AppTheme.neutral200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ratio > 0.7
                      ? AppTheme.success
                      : (ratio > 0.4 ? AppTheme.warning : AppTheme.error),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 50,
            child: Text(
              '${score.toInt()}/$maxScore',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentCard() {
    final ndvi = (_analysisResult!['ndvi_value'] as num).toDouble();
    final soil = _analysisResult!['soil_type'] as String? ?? 'Unknown';
    final landClass =
        _analysisResult!['score_breakdown']?['land_class'] as String? ??
        'Agricultural Land';
    final weatherDetails =
        _analysisResult!['weather_details'] as Map<String, dynamic>?;

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
            landClass,
            AppTheme.primaryGreen,
          ),
          if (weatherDetails != null) ...[
            _buildEnvRow(
              Icons.thermostat,
              'Temperature',
              '${(weatherDetails['temp'] as num?)?.toStringAsFixed(1) ?? '--'}°C',
              AppTheme.info,
            ),
            _buildEnvRow(
              Icons.water_drop,
              'Rainfall',
              '${(weatherDetails['rainfall'] as num?)?.toStringAsFixed(0) ?? '--'} mm',
              AppTheme.skyBlue,
            ),
          ],
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
              color: color.withValues(alpha: 0.1),
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

  Widget _buildMLPredictionsCard() {
    final ml = _analysisResult!['ml_predictions'] as Map<String, dynamic>;
    final l10n = AppLocalizations.of(context);

    return _buildCard(
      icon: Icons.smart_toy,
      title: l10n?.mlPredictionsTitle ?? 'AI Predictions',
      child: Column(
        children: [
          _buildMLRow(
            l10n?.cropQualityPrediction ?? 'Crop Quality',
            TranslationHelper.getCropQuality(context, ml['crop_quality']),
            Icons.star,
          ),
          _buildMLRow(
            l10n?.cropHealthScore ?? 'Health Score',
            '${ml['crop_health_score'] ?? '--'}/100',
            Icons.favorite,
          ),
          _buildMLRow(
            l10n?.riskLevelPrediction ?? 'Risk Level',
            TranslationHelper.getRiskTier(context, ml['risk_level']),
            Icons.shield,
          ),
          _buildMLRow(
            l10n?.ndviTrendPrediction ?? 'NDVI Trend',
            TranslationHelper.getNdviTrend(context, ml['ndvi_trend']),
            Icons.trending_up,
          ),
          if (ml['ndvi_trend_description'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ml['ndvi_trend_description'],
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
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
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

  Widget _buildDemandForecastPromptCard() {
    final cropName = widget.crop?.name ?? 'Crop';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
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
                child: const Icon(Icons.auto_graph, color: Color(0xFF69F0AE), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Demand & Price Forecast',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '7–14 Day Quantile & Mandi Realization',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Predict forward mandi prices and P10/P50/P90 demand volume for $cropName to time optimal harvesting and auction delivery.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.85), height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DemandForecastingScreen(
                      initialCrop: widget.crop?.name.contains('Tomato') == true
                          ? 'Tomato'
                          : (widget.crop?.name.contains('Onion') == true ? 'Onion' : 'Wheat'),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.insights, size: 16, color: Color(0xFF064E3B)),
              label: const Text(
                'View Price & Demand Projections',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF064E3B)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF69F0AE),
                foregroundColor: const Color(0xFF064E3B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanEligibilityCard() {
    final l10n = AppLocalizations.of(context);
    final tier = _analysisResult!['risk_category'] as String;
    final loanLimit = ScoreEngine.getLoanLimit(tier);
    final tierColor = _getTierColor(tier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: tierColor, size: 22),
              const SizedBox(width: 10),
              Text(
                l10n?.navLoans ?? 'Loan Eligibility',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLoanDetail(
                l10n?.loanAmount ?? 'Max Loan',
                '₹${_formatAmount(loanLimit)}',
                tierColor,
              ),
              const SizedBox(width: 16),
              _buildLoanDetail('Risk Tier', tier, tierColor),
              const SizedBox(width: 16),
              _buildLoanDetail('Interest', _getInterestRate(tier), tierColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoanDetail(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
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

  Widget _buildMapVisualization() {
    final latStr = _latController.text;
    final lngStr = _lngController.text;
    double lat = 28.6139;
    double lng = 77.2090;

    if (latStr.isNotEmpty && lngStr.isNotEmpty) {
      lat = double.tryParse(latStr) ?? lat;
      lng = double.tryParse(lngStr) ?? lng;
    }

    final centerLocation = LatLng(lat, lng);

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.backgroundGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // FlutterMap instead of Mock Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerLocation,
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.example.agrichain',
              ),
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: [
                      LatLng(lat + 0.001, lng - 0.001),
                      LatLng(lat + 0.001, lng + 0.001),
                      LatLng(lat - 0.001, lng + 0.001),
                      LatLng(lat - 0.001, lng - 0.001),
                    ],
                    color: AppTheme.primaryGreen.withValues(alpha: _isAnalyzing ? 0.1 + (_pulseController.value * 0.2) : 0.3),
                    borderColor: AppTheme.primaryGreen.withValues(alpha: _isAnalyzing ? 0.5 + (_pulseController.value * 0.5) : 1.0),
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: centerLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isAnalyzing)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: RadarSweepPainter(
                      animationValue: _pulseController.value,
                      color: AppTheme.primaryGreen,
                    ),
                  );
                },
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.satellite_alt, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Live Map Data',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDataSourceInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 10),
              Text(
                'How is this calculated?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.satellite_alt, 'AgroMonitoring API', 'Live satellite imagery for NDVI (Normalized Difference Vegetation Index) & Soil properties.'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.cloud, 'OpenWeather API', 'Real-time localized climate metrics (temp, rainfall, humidity).'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.psychology, 'AI / ML Engine', 'Custom predictive model analyzing environment data to assess risk & health.'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
              children: [
                TextSpan(text: '$title: ', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

Color _getTierColor(String tier) {
  switch (tier) {
    case 'Platinum':
      return const Color(0xFF6C63FF);
    case 'Gold':
      return const Color(0xFFE6A817);
    case 'Silver':
      return const Color(0xFF78909C);
    case 'Bronze':
      return const Color(0xFFBF6D3A);
    default:
      return AppTheme.primaryGreen;
  }
}

String _getInterestRate(String tier) {
  switch (tier) {
    case 'Platinum':
      return '4%';
    case 'Gold':
      return '6%';
    case 'Silver':
      return '9%';
    case 'Bronze':
      return '12%';
    default:
      return '10%';
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

class RadarSweepPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  RadarSweepPainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sweepPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 3.0;
    
    final sweepY = size.height * animationValue;
    canvas.drawLine(Offset(0, sweepY), Offset(size.width, sweepY), sweepPaint);
    
    // Gradient trail
    final rect = Rect.fromLTRB(0, sweepY - 40, size.width, sweepY);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.3),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant RadarSweepPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
