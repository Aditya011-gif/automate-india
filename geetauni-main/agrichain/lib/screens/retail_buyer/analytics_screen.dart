import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrichain/l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/enhanced_app_bar.dart';
import '../../widgets/language_switcher.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: AppTheme.lightGrey,
          appBar: EnhancedAppBar(
            title: l10n?.navAnalytics ?? 'Analytics',
            subtitle: l10n?.navAnalytics != null && Localizations.localeOf(context).languageCode == 'hi' ? 'अपनी प्रगति और प्रदर्शन ट्रैक करें' : 'Track your performance',
            centerTitle: false,
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: Center(child: LanguageSwitcherPill(isDark: true)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: l10n?.totalBids ?? 'Total Bids',
                        value: '12',
                        icon: Icons.gavel,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: l10n?.wonAuctions ?? 'Won Auctions',
                        value: '8',
                        icon: Icons.emoji_events,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: l10n?.totalSpent ?? 'Total Spent',
                        value: '₹24,500',
                        icon: Icons.account_balance_wallet,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: Localizations.localeOf(context).languageCode == 'hi' ? 'औसत बोली' : 'Avg. Bid',
                        value: '₹2,850',
                        icon: Icons.trending_up,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Market Trends
                Text(
                  l10n?.marketTrends ?? 'Market Trends',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTrendChart(context),
                const SizedBox(height: 24),

                // Recent Bidding Activity
                Text(
                  l10n?.recentBidding ?? 'Recent Bidding Activity',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBiddingActivity(context),
                const SizedBox(height: 24),

                // Top Categories
                Text(
                  Localizations.localeOf(context).languageCode == 'hi' ? 'शीर्ष श्रेणियां' : 'Top Categories',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTopCategories(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.trending_up, color: color, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.grey)),
        ],
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.priceTrends7Days ?? 'Price Trends (Last 7 Days)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildChartBar(isHindi ? 'सोम' : 'Mon', 0.6, AppTheme.primaryGreen),
                _buildChartBar(isHindi ? 'मंगल' : 'Tue', 0.8, AppTheme.primaryGreen),
                _buildChartBar(isHindi ? 'बुध' : 'Wed', 0.4, AppTheme.primaryGreen),
                _buildChartBar(isHindi ? 'गुरु' : 'Thu', 0.9, AppTheme.primaryGreen),
                _buildChartBar(isHindi ? 'शुक्र' : 'Fri', 0.7, AppTheme.primaryGreen),
                _buildChartBar(isHindi ? 'शनि' : 'Sat', 0.5, AppTheme.primaryGreen),
                _buildChartBar(isHindi ? 'रवि' : 'Sun', 0.8, AppTheme.primaryGreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: height * 100,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.grey)),
      ],
    );
  }

  Widget _buildBiddingActivity(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    final activities = [
      {
        'crop': isHindi ? 'जैविक गेहूं' : 'Organic Wheat',
        'bid': '₹2,500',
        'status': isHindi ? 'जीत लिया' : 'Won',
        'time': isHindi ? '2 घंटे पहले' : '2 hours ago',
        'color': AppTheme.primaryGreen,
      },
      {
        'crop': isHindi ? 'प्रीमियम चावल' : 'Premium Rice',
        'bid': '₹3,200',
        'status': isHindi ? 'अधिक बोली' : 'Outbid',
        'time': isHindi ? '5 घंटे पहले' : '5 hours ago',
        'color': Colors.orange,
      },
      {
        'crop': isHindi ? 'ताज़ा टमाटर' : 'Fresh Tomatoes',
        'bid': '₹1,800',
        'status': isHindi ? 'सक्रिय' : 'Active',
        'time': isHindi ? '1 दिन पहले' : '1 day ago',
        'color': Colors.blue,
      },
      {
        'crop': isHindi ? 'जैविक मक्का' : 'Organic Corn',
        'bid': '₹2,100',
        'status': isHindi ? 'समाप्त' : 'Lost',
        'time': isHindi ? '2 दिन पहले' : '2 days ago',
        'color': Colors.red,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (activity['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.gavel,
                  color: activity['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['crop'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bid: ${activity['bid']}',
                      style: TextStyle(color: AppTheme.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (activity['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      activity['status'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: activity['color'] as Color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity['time'] as String,
                    style: TextStyle(color: AppTheme.grey, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopCategories() {
    final categories = [
      {'name': 'Grains', 'percentage': 45, 'color': AppTheme.primaryGreen},
      {'name': 'Vegetables', 'percentage': 30, 'color': Colors.orange},
      {'name': 'Fruits', 'percentage': 15, 'color': Colors.blue},
      {'name': 'Others', 'percentage': 10, 'color': Colors.purple},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pie chart representation (simplified)
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: categories
                          .map((c) => c['color'] as Color)
                          .toList(),
                      stops: const [0.0, 0.45, 0.75, 1.0],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: category['color'] as Color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category['name'] as String,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '${category['percentage']}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
}
