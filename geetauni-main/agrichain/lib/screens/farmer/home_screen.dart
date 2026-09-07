import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/language_switcher.dart';
import '../../services/database_service.dart';
import '../../services/whatsapp_kisan_service.dart';
import 'add_crop_screen.dart';
import 'demand_forecasting_screen.dart';
import 'farmer_orders_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final farmerId = user?.id ?? '';
    final farmerName = (user != null && user.name.isNotEmpty) ? user.name : 'Farmer';
    final location = (user?.location != null && user!.location!.isNotEmpty) ? user.location! : 'Karnal, Haryana';

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          CustomAppBar(
            title: 'Farm Command Center',
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: Center(child: LanguageSwitcherPill(isDark: true)),
              ),
            ],
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            // Welcome & Location Header
            _buildFarmerGreetingCard(farmerName, location),
            const SizedBox(height: 14),

            // PRIMARY 64px CTA BUTTON: FASAL BECHEIN / SELL YOUR CROP
            _buildPrimarySellCtaButton(),
            const SizedBox(height: 14),

            // WHATSAPP KISAN ASSISTANT (कृषि-साथी) BANNER
            _buildWhatsAppKisanAssistantBanner(),
            const SizedBox(height: 14),

            // AI DEMAND & PRICE FORECASTING BANNER (KrishiDrishti AI)
            _buildAiDemandForecastingBanner(),
            const SizedBox(height: 18),

            // Stats Overview
            _buildLiveFarmerStats(farmerId),
            const SizedBox(height: 14),

            // Orders Received & Dual-Signed Smart Contracts Banner
            _buildOrdersAndContractsBanner(farmerId),
            const SizedBox(height: 18),

            // Live Mandi Rates & MSP Advisory Card
            _buildMandiRatesTicker(),
            const SizedBox(height: 20),

            // Active Harvest Preview Header & List
            _buildActiveHarvestSection(farmerId),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerGreetingCard(String name, String location) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.12),
            child: const Icon(Icons.person, color: Color(0xFF2E7D32), size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Namaste, $name',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, color: Color(0xFF2563EB), size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimarySellCtaButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCropScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add_a_photo, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🌾 फसल बेचें / Sell Your Crop',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          'AI Crop Quality Scan • Tap to List Harvest',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: Color(0xFF1B5E20), size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsAppKisanAssistantBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF075E54), Color(0xFF128C7E), Color(0xFF25D366)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25D366).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showWhatsAppKisanModal(),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.chat, color: Color(0xFF075E54), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'WhatsApp कृषि-साथी Bot',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AI ACTIVE',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'बोलकर या चैट में फसल बेचें • 10s Voice Notes',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWhatsAppKisanModal() {
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    final kisanService = WhatsAppKisanService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF075E54), size: 28),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AgriChain कृषि-साथी Bot',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF075E54),
                            ),
                          ),
                          Text(
                            'WhatsApp पर बोलकर या लिखकर फसल बेचें',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.grey),
                    tooltip: 'Configure Bot Phone Number',
                    onPressed: () => _showBotNumberConfigDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Farmer Account Badge
              if (user != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle, color: Color(0xFF2E7D32), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'किसान खाता: ${user.name} (#${user.id.substring(0, user.id.length > 8 ? 8 : user.id.length)})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'VERIFIED',
                          style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  children: [
                    _buildFeatureBullet(
                      '🔗 1-टैप खाता लिंक (Auto-Login)',
                      'WhatsApp संदेश भेजते ही आपका खाता लिंक होगा। फसलें सीधे आपके खाते में जुड़ेंगी।',
                    ),
                    const Divider(height: 18),
                    _buildFeatureBullet(
                      '🎙️ बोलकर बेचें (10s Voice Note)',
                      'वॉइस नोट भेजें: "करनाल में 50 क्विंटल शरबती गेहूं ₹2600 भाव"',
                    ),
                    const Divider(height: 18),
                    _buildFeatureBullet(
                      '🔒 एस्क्रो पेमेंट व ट्रक अलर्ट',
                      'खरीदार द्वारा बैंक में भुगतान लॉक होते ही WhatsApp पर पक्की रसीद पाएं',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // PRIMARY ACTION: 1-Tap Auto Connect WhatsApp
              if (user != null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final launched = await kisanService.launchConnectWhatsApp(user);
                      if (!launched && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Handshake code copied! Paste in WhatsApp chat to link.'),
                            backgroundColor: Color(0xFF075E54),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.link, color: Colors.white),
                    label: Text(
                      '📲 WhatsApp खाता लिंक करें (Auto Link)',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // SECONDARY ACTION: Copy / Test Message
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await kisanService.launchTradeChat(
                      prefillText: '50 क्विंटल शरबती गेहूं करनाल भाव 2600',
                    );
                  },
                  icon: const Icon(Icons.chat, color: Color(0xFF075E54)),
                  label: Text(
                    '💬 सीधे चैट में फसल बेचें (Open Chat)',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF075E54)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF075E54)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBotNumberConfigDialog() async {
    final kisanService = WhatsAppKisanService();
    final currentNumber = await kisanService.getBotNumber();
    final controller = TextEditingController(text: currentNumber);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Configure Bot Phone Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the phone number that scanned the QR code (with country code, e.g. 918307165924):',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp Bot Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await kisanService.setBotNumber(controller.text.trim());
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Bot phone number updated!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF075E54)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF14532D),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiDemandForecastingBanner() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DemandForecastingScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF047857)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF047857).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_graph, color: Color(0xFF69F0AE), size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'AI Demand & Price Forecast',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF69F0AE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '7–14d ML',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF064E3B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'P10/P50/P90 demand quantiles & mandi modal price realization',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    final str = val.toString().trim();
    final direct = double.tryParse(str);
    if (direct != null) return direct;
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(str);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    return 0.0;
  }

  Widget _buildLiveFarmerStats(String farmerId) {
    final appState = Provider.of<AppState>(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _dbService.streamFarmerCrops(farmerId),
      builder: (context, cropsSnapshot) {
        final streamedCrops = cropsSnapshot.data ?? [];
        // Merge with local AppState crops
        final localCrops = appState.crops.map((c) => c.toFirestore()).toList();
        final Set<String> seenIds = {};
        final List<Map<String, dynamic>> crops = [];

        for (final c in [...streamedCrops, ...localCrops]) {
          final id = c['id']?.toString() ?? c['name']?.toString() ?? '';
          if (id.isEmpty || seenIds.add(id)) {
            crops.add(c);
          }
        }

        double totalHarvestKg = 0.0;
        int activeListings = 0;

        for (final c in crops) {
          final q = _toDouble(c['quantity']);
          totalHarvestKg += q;
          if (q > 0) activeListings++;
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _dbService.streamFarmerOrders(farmerId),
          builder: (context, ordersSnapshot) {
            final orders = ordersSnapshot.data ?? [];
            double totalEarnings = 0.0;
            for (final o in orders) {
              totalEarnings += _toDouble(o['totalPrice']);
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Active Crops', '$activeListings', Icons.grass, const Color(0xFF2E7D32)),
                  _buildStatItem('Available Qty', '${totalHarvestKg.toStringAsFixed(0)} kg', Icons.inventory_2_outlined, const Color(0xFF2563EB)),
                  _buildStatItem('Total Payouts', '₹${totalEarnings.toStringAsFixed(0)}', Icons.currency_rupee, const Color(0xFFD97706)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersAndContractsBanner(String farmerId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _dbService.streamFarmerRetailOrders(farmerId),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        final activeCount = orders.where((o) => (o['status'] ?? '') == 'active' || (o['status'] ?? '') == 'in_transit').length;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FarmerOrdersScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Orders & Smart Contracts',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (activeCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$activeCount NEW',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Retail buyer orders • Dual-signed PDFs • Escrow release',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String val, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildMandiRatesTicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: Color(0xFF15803D), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Live Mandi Rates & MSP Advisory',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                  ),
                ],
              ),
              Text('Karnal Mandi', style: TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFDCFCE7)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMandiRateItem('Sharbati Wheat', '₹34.50', 'MSP: ₹22.75'),
              _buildMandiRateItem('Basmati 1121', '₹46.00', 'MSP: ₹21.83'),
              _buildMandiRateItem('Mustard Seed', '₹58.00', 'MSP: ₹56.50'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMandiRateItem(String crop, String rate, String msp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(crop, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        Text('$rate/kg', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
        Text(msp, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
      ],
    );
  }

  Widget _buildActiveHarvestSection(String farmerId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Active Harvest Listings',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(1); // Go to My Crops tab
                }
              },
              child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _dbService.streamFarmerCrops(farmerId),
          builder: (context, snapshot) {
            final appState = Provider.of<AppState>(context);
            final streamedCrops = snapshot.data ?? [];
            final localCrops = appState.crops.map((c) => c.toFirestore()).toList();
            final Set<String> seenIds = {};
            final List<Map<String, dynamic>> crops = [];

            for (final c in [...streamedCrops, ...localCrops]) {
              final id = c['id']?.toString() ?? c['name']?.toString() ?? '';
              if (id.isEmpty || seenIds.add(id)) {
                crops.add(c);
              }
            }

            final activeCrops = crops.where((c) => _toDouble(c['quantity']) > 0).take(3).toList();

            if (activeCrops.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Text(
                        'No crops listed yet',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap "+ Sell Crop" above to start selling to buyers and FPOs.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: activeCrops.map((crop) {
                final name = crop['name'] ?? 'Crop';
                final qty = _toDouble(crop['quantity']);
                final price = _toDouble(crop['price']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.softShadow,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('${qty.toStringAsFixed(0)} kg available', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '₹${price.toStringAsFixed(0)} / kg',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
