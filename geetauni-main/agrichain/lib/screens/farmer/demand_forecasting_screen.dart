import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/demand_forecast_models.dart';
import '../../services/demand_forecasting_service.dart';
import '../../theme/app_theme.dart';

class DemandForecastingScreen extends StatefulWidget {
  final String? initialCrop;
  final String? initialDistrict;

  const DemandForecastingScreen({
    super.key,
    this.initialCrop,
    this.initialDistrict,
  });

  @override
  State<DemandForecastingScreen> createState() => _DemandForecastingScreenState();
}

class _DemandForecastingScreenState extends State<DemandForecastingScreen> {
  final DemandForecastingService _forecastingService = DemandForecastingService();

  late String _selectedCrop;
  late String _selectedDistrict;
  late DateTime _targetDate;
  int _selectedDaysAhead = 7;
  double _farmerLotSizeKg = 4000;

  bool _isLoading = false;
  DemandForecastResponse? _forecastData;

  final List<String> _supportedCrops = [
    'Tomato',
    'Onion',
    'Wheat',
    'Rice',
    'Potato',
    'Cotton',
  ];

  final List<Map<String, String>> _supportedDistricts = [
    {'name': 'Karnal', 'state': 'Haryana', 'badge': 'NH-44 Hub'},
    {'name': 'Nashik', 'state': 'Maharashtra', 'badge': 'Lasalgaon Mandi'},
    {'name': 'Kolar', 'state': 'Karnataka', 'badge': 'South Mandi'},
    {'name': 'Azadpur', 'state': 'Delhi', 'badge': 'Mega APMC'},
    {'name': 'Pune', 'state': 'Maharashtra', 'badge': 'Western APMC'},
    {'name': 'Agra', 'state': 'Uttar Pradesh', 'badge': 'Central Silo'},
    {'name': 'Rajkot', 'state': 'Gujarat', 'badge': 'Saurashtra Hub'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCrop = widget.initialCrop ?? 'Tomato';
    _selectedDistrict = widget.initialDistrict ?? 'Karnal';
    _targetDate = DateTime.now().add(Duration(days: _selectedDaysAhead));
    _fetchForecast();
  }

  Future<void> _fetchForecast() async {
    setState(() => _isLoading = true);
    try {
      final selectedDistrictMeta = _supportedDistricts.firstWhere(
        (d) => d['name'] == _selectedDistrict,
        orElse: () => {'name': _selectedDistrict, 'state': 'Haryana'},
      );

      final result = await _forecastingService.getForecast(
        commodity: _selectedCrop,
        district: _selectedDistrict,
        targetDate: _targetDate,
        state: selectedDistrictMeta['state'],
      );

      if (mounted) {
        setState(() {
          _forecastData = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onDaysAheadChanged(int days) {
    setState(() {
      _selectedDaysAhead = days;
      _targetDate = DateTime.now().add(Duration(days: days));
    });
    _fetchForecast();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppTheme.darkGreen,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KrishiDrishti AI Forecasting',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C853),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Probabilistic Quantile & Mandi Price Engine',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
            tooltip: 'Recalculate Forecast',
            onPressed: _isLoading ? null : _fetchForecast,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Interactive Parameter Selector Card
          _buildSelectorControlsCard(),
          const SizedBox(height: 16),

          // 2. Loading or Forecast Results
          if (_isLoading)
            _buildLoadingIndicator()
          else if (_forecastData != null) ...[
            // 3. Price Forecast & Revenue Estimator
            _buildPriceRealizationCard(_forecastData!),
            const SizedBox(height: 16),

            // 4. Probabilistic Demand Quantiles (P10 / P50 / P90)
            _buildDemandQuantilesCard(_forecastData!),
            const SizedBox(height: 16),

            // 5. Actionable Farm-Gate Advisory Card
            _buildActionableAdvisoryCard(_forecastData!),
            const SizedBox(height: 16),

            // 6. Agrometeorological & Disruption Radar
            _buildAgroWeatherDisruptionCard(_forecastData!),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  /// 1. Interactive Selector Controls Card
  Widget _buildSelectorControlsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppTheme.primaryGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                'Forecast Parameters',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '7–14 Day Forward ML',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Crop Selector Chips
          Text(
            'Select Commodity:',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _supportedCrops.map((crop) {
                final isSelected = _selectedCrop == crop;
                String emoji = '🌾';
                if (crop == 'Tomato') emoji = '🍅';
                if (crop == 'Onion') emoji = '🧅';
                if (crop == 'Rice') emoji = '🍚';
                if (crop == 'Potato') emoji = '🥔';
                if (crop == 'Cotton') emoji = '🌿';

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('$emoji $crop'),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCrop = crop);
                        _fetchForecast();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // District / Mandi Hub Selector
          Text(
            'Target Mandi Corridor:',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _supportedDistricts.map((d) {
                final isSelected = _selectedDistrict == d['name'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('${d['name']} (${d['state']})'),
                    selected: isSelected,
                    selectedColor: AppTheme.darkGreen,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedDistrict = d['name']!);
                        _fetchForecast();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Target Horizon Day Buttons (+7d, +10d, +14d)
          Row(
            children: [
              Text(
                'Horizon:',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 8),
              _buildHorizonChip(7, '+7 Days'),
              const SizedBox(width: 6),
              _buildHorizonChip(10, '+10 Days'),
              const SizedBox(width: 6),
              _buildHorizonChip(14, '+14 Days'),
              const Spacer(),
              Text(
                '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizonChip(int days, String label) {
    final isSelected = _selectedDaysAhead == days;
    return InkWell(
      onTap: () => _onDaysAheadChanged(days),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppTheme.darkGreen,
          ),
        ),
      ),
    );
  }

  /// 2. Price Forecast & Revenue Estimator Card
  Widget _buildPriceRealizationCard(DemandForecastResponse data) {
    final price = data.priceForecastInrPerKg;
    final grossEstimatedRevenue = price.expectedModalPrice * _farmerLotSizeKg;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                child: const Icon(Icons.currency_rupee, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expected Modal Price Realization',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${price.expectedModalPrice.toStringAsFixed(2)} / kg',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Mandi Expected',
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
          const SizedBox(height: 16),

          // Price Spread Range Bar (Min -> Modal -> Max)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Min: ₹${price.minPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Modal: ₹${price.expectedModalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Max: ₹${price.maxPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.60,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF69F0AE)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Lot Size Gross Revenue Calculator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated Value (${_farmerLotSizeKg.toStringAsFixed(0)} kg lot):',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
              ),
              Text(
                '₹${grossEstimatedRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF69F0AE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Probabilistic Demand Quantiles (P10 / P50 / P90)
  Widget _buildDemandQuantilesCard(DemandForecastResponse data) {
    final demand = data.demandForecastKg;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Probabilistic Demand Quantiles (KG)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                    Text(
                      'Pinball Loss Quantile Risk Distribution (80% Confidence)',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Quantile Risk Cards (P10, P50, P90)
          Row(
            children: [
              Expanded(
                child: _buildQuantileBox(
                  title: 'P10 (Pessimistic)',
                  subtitle: 'Downside Floor',
                  value: demand.p10Pessimistic,
                  color: Colors.orange.shade700,
                  bgColor: Colors.orange.shade50,
                  borderColor: Colors.orange.shade200,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuantileBox(
                  title: 'P50 (Expected)',
                  subtitle: 'Baseline Target',
                  value: demand.p50Expected,
                  color: AppTheme.primaryGreen,
                  bgColor: Colors.green.shade50,
                  borderColor: Colors.green.shade300,
                  isHighlighted: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuantileBox(
                  title: 'P90 (Surge)',
                  subtitle: 'Festival / Peak',
                  value: demand.p90Optimistic,
                  color: Colors.purple.shade700,
                  bgColor: Colors.purple.shade50,
                  borderColor: Colors.purple.shade200,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantileBox({
    required String title,
    required String subtitle,
    required int value,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isHighlighted ? 1.5 : 1.0),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} kg',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 4. Actionable Farm-Gate Advisory Card
  Widget _buildActionableAdvisoryCard(DemandForecastResponse data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Farm-Gate Advisory Strategy',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.recommendation,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: Colors.brown.shade900,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 10),
          Text(
            data.actionableInsight,
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Agrometeorological & Disruption Radar
  Widget _buildAgroWeatherDisruptionCard(DemandForecastResponse data) {
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
              const Icon(Icons.cloud_outlined, color: Colors.blueAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Agrometeorological & Supply Disruption Index',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeatherMetric('Transit Delay', 'Low (0.0 mm rain)', Icons.check_circle, Colors.green),
              _buildWeatherMetric('Mandi Arrivals', 'Active Flow', Icons.local_shipping, Colors.blue),
              _buildWeatherMetric('Heat Risk', 'Normal Range', Icons.thermostat, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMetric(String title, String val, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 3),
        Text(title, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600)),
        Text(
          val,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            SizedBox(height: 14),
            Text(
              'Running LightGBM Quantile & Weather Inference...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
