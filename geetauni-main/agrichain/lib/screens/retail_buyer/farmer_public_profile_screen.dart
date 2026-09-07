import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/firestore_models.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class FarmerPublicProfileScreen extends StatefulWidget {
  final FirestoreCrop crop;

  const FarmerPublicProfileScreen({
    super.key,
    required this.crop,
  });

  @override
  State<FarmerPublicProfileScreen> createState() => _FarmerPublicProfileScreenState();
}

class _FarmerPublicProfileScreenState extends State<FarmerPublicProfileScreen> {
  final DatabaseService _dbService = DatabaseService();

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final crop = widget.crop;
    final farmerName = crop.farmerName.isNotEmpty ? crop.farmerName : 'Verified Farmer';
    final location = crop.location.isNotEmpty ? crop.location : 'Karnal, Haryana';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          CustomAppBar(
            title: 'Farmer Showcase',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            // Farmer Identity & Trust Banner
            _buildFarmerHeaderCard(farmerName, location),
            const SizedBox(height: 16),

            // Current Crop & Farm Traceability Passport
            _buildCropTraceabilityCard(crop),
            const SizedBox(height: 16),

            // Producer Credentials & Quality Badges
            _buildProducerBadgesCard(),
            const SizedBox(height: 18),

            // All Available Produce from this Farmer
            _buildFarmerAvailableCropsSection(crop.farmerId),
            const SizedBox(height: 18),

            // Buyer Protection & Escrow Guarantee
            _buildBuyerGuaranteeCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerHeaderCard(String name, String location) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFE8F5E9),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'F',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Color(0xFF2563EB), size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Text(
                        'Direct Farmgate Producer',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrustMetric('4.9 ★', 'Buyer Rating', const Color(0xFFD97706)),
              _buildTrustMetric('100%', 'KYC Verified', const Color(0xFF2E7D32)),
              _buildTrustMetric('Fast', 'Farm Dispatch', const Color(0xFF2563EB)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustMetric(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCropTraceabilityCard(FirestoreCrop crop) {
    final grade = crop.qualityGrade.name.toUpperCase();
    final isNft = crop.isNFT;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    child: const Icon(Icons.qr_code_2, color: Color(0xFF2E7D32), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Harvest Traceability & Passport',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (isNft)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.token, size: 12, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Text(
                        'NFT Bound',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTraceabilityRow('Selected Commodity', crop.name),
          _buildTraceabilityRow('Category / Type', crop.category?.name ?? crop.cropType?.name ?? 'Agricultural Produce'),
          _buildTraceabilityRow('Quality Grade', grade),
          _buildTraceabilityRow('Available Stock', crop.quantity),
          _buildTraceabilityRow('Listed Rate', '₹${crop.price.toStringAsFixed(0)}'),
          if (crop.agriScore != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.satellite_alt, color: Color(0xFF15803D), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AgriScore Satellite Land Index: ${crop.agriScore!.toStringAsFixed(0)}/100',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Optimal soil nitrogen, vegetation health, and irrigation indices confirmed via Sentinel GIS.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTraceabilityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildProducerBadgesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verified Producer Credentials',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildBadgeItem(Icons.badge_outlined, 'Aadhaar / Government KYC', 'Identity verified through DigiLocker UIDAI', const Color(0xFF15803D)),
          const SizedBox(height: 10),
          _buildBadgeItem(Icons.eco_outlined, 'Good Agricultural Practices', 'Natural cultivation and minimal chemical pesticide usage', const Color(0xFF2E7D32)),
          const SizedBox(height: 10),
          _buildBadgeItem(Icons.local_shipping_outlined, 'Farmgate Pickup Ready', 'Pre-sorted harvest ready for transport loading', const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(IconData icon, String title, String subtitle, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFarmerAvailableCropsSection(String farmerId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More Harvests from this Farmer',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _dbService.streamFarmerCrops(farmerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final crops = snapshot.data ?? [];
            final availableCrops = crops.where((c) => _toDouble(c['quantity']) > 0).toList();

            if (availableCrops.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Text(
                    'No other harvest listings active currently.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              );
            }

            return Column(
              children: availableCrops.map((cropMap) {
                final name = cropMap['name'] ?? 'Crop';
                final variety = cropMap['variety'] ?? 'Grade 1';
                final qty = _toDouble(cropMap['quantity']);
                final unit = cropMap['unit'] ?? 'kg';
                final price = _toDouble(cropMap['price']);
                final image = cropMap['imageUrl'] ?? cropMap['image'] ?? '';

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
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          image: image.isNotEmpty
                              ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover)
                              : null,
                        ),
                        child: image.isEmpty
                            ? const Icon(Icons.grass, color: Color(0xFF2E7D32), size: 24)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                            ),
                            Text(
                              '$variety • Stock: $qty $unit',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹$price/$unit',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D)),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Available',
                            style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                          ),
                        ],
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

  Widget _buildBuyerGuaranteeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: Color(0xFF15803D), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AgriChain 100% Buyer Protection',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                ),
                SizedBox(height: 2),
                Text(
                  'Payments are held safely in escrow and only released to the farmer after successful weighbridge verification.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
