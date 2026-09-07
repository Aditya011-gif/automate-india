import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/buyer_plant_model.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../login_screen.dart';

class BulkBuyerProfileScreen extends StatefulWidget {
  const BulkBuyerProfileScreen({super.key});

  @override
  State<BulkBuyerProfileScreen> createState() => _BulkBuyerProfileScreenState();
}

class _BulkBuyerProfileScreenState extends State<BulkBuyerProfileScreen> {
  List<BuyerDeliveryPlant> _plants = [];
  bool _isLoadingPlants = true;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final plants = await BuyerDeliveryPlant.loadSavedPlants();
    if (mounted) {
      setState(() {
        _plants = plants;
        _isLoadingPlants = false;
      });
    }
  }

  Future<void> _setPrimaryPlant(String id) async {
    final updated = await BuyerDeliveryPlant.setPrimary(id);
    if (mounted) {
      setState(() => _plants = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primary delivery plant updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final companyName = user?.name.isNotEmpty == true
        ? user!.name
        : 'AgroFoods Milling India Pvt Ltd';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const CustomAppBar(
            title: 'Company & KYC Profile',
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Company Header Badge Card
            _buildCompanyCard(companyName, user?.location ?? 'Pune, Maharashtra'),

            const SizedBox(height: 16),

            // Statutory GSTIN & Corporate KYC
            _buildSectionHeader('Statutory & Corporate KYC'),
            _buildInfoCard([
              _buildInfoRow('GSTIN', '06AAACA0000A1Z5', isVerified: true),
              _buildInfoRow('PAN', 'AAACA0000A', isVerified: true),
              _buildInfoRow('CIN', 'U01100MH2018PTC304912', isVerified: true),
              _buildInfoRow('Enterprise Type', 'Large Corporate / Agro Processor'),
            ]),

            const SizedBox(height: 16),

            // Statutory Licenses & Certifications
            _buildSectionHeader('Mandatory Licenses & Documents'),
            _buildInfoCard([
              _buildDocRow('FSSAI Central License', 'Lic #10019022009182', 'Valid till Dec 2028', true),
              _buildDocRow('APEDA Export Registration', 'Reg #APEDA/RCMC/7781', 'Active', true),
              _buildDocRow('State Mandi Trading License', 'Lic #MND/PUN/8821', 'Active', true),
            ]),

            const SizedBox(height: 16),

            // Corporate Escrow & Virtual Payment Account
            _buildSectionHeader('Corporate Escrow & Payments'),
            _buildEscrowAccountCard(),

            const SizedBox(height: 16),

            // Saved Delivery Locations / Processing Plants
            _buildSectionHeader('Saved Delivery Plants & Silos'),
            _buildSavedPlantsCard(),

            const SizedBox(height: 16),

            // Team & User Roles
            _buildSectionHeader('Procurement Team & Authorizations'),
            _buildTeamCard(),

            const SizedBox(height: 24),

            // Account Settings & Sign Out
            _buildSettingsAndLogout(context, appState),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyCard(String companyName, String location) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.corporate_fare, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        companyName,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 18),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Milling Capacity: 12,000 Qtl / Day',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isVerified = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              if (isVerified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check_circle, size: 14, color: Color(0xFF2E7D32)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocRow(String name, String id, String status, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 18, color: Color(0xFF1565C0)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(id, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowAccountCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, color: Color(0xFF1565C0), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Dedicated Institutional Escrow Account',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildInfoRow('Virtual Account No (VAN)', 'AGRI990184920'),
          _buildInfoRow('IFSC Code', 'UTIB0000001 (Axis Bank)'),
          _buildInfoRow('Available Escrow Credit', '₹2.50 Crore'),
          _buildInfoRow('Settlement Mode', 'Instant RTGS on Weighbridge Pass'),
        ],
      ),
    );
  }

  Widget _buildSavedPlantsCard() {
    if (_isLoadingPlants) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32), strokeWidth: 2)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (int i = 0; i < _plants.length; i++) ...[
            if (i > 0) const Divider(height: 18),
            _buildPlantItem(_plants[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildPlantItem(BuyerDeliveryPlant plant) {
    return InkWell(
      onTap: () => _setPrimaryPlant(plant.id),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: plant.isPrimary ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.factory_outlined,
                color: plant.isPrimary ? const Color(0xFF2E7D32) : const Color(0xFF64748B),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plant.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      if (plant.isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Primary Delivery Hub',
                            style: TextStyle(fontSize: 9.5, color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        TextButton(
                          onPressed: () => _setPrimaryPlant(plant.id),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Set Primary', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(plant.address, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.gps_fixed, size: 10, color: Color(0xFF64748B)),
                            const SizedBox(width: 3),
                            Text(
                              '${plant.latitude.toStringAsFixed(4)}° N, ${plant.longitude.toStringAsFixed(4)}° E',
                              style: const TextStyle(fontSize: 9.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        plant.corridorName,
                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTeamMemberRow('Vikram Mehta', 'VP — Global Procurement', 'Full Access (PO & Escrow)'),
          const Divider(height: 16),
          _buildTeamMemberRow('Sunil Rao', 'Chief Quality Inspector', 'Lab Clearance & Inspection'),
          const Divider(height: 16),
          _buildTeamMemberRow('Pooja Nair', 'Senior Accounts Manager', 'Tax Invoices & Reconciliation'),
        ],
      ),
    );
  }

  Widget _buildTeamMemberRow(String name, String role, String access) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFE8F5E9),
          child: Text(
            name.substring(0, 1),
            style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(role, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        Text(access, style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSettingsAndLogout(BuildContext context, AppState appState) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.support_agent, color: Color(0xFF2E7D32)),
                title: const Text('24x7 Institutional Key Account Manager', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('+91 8000 442 990 • support@agrichain.in', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.security, color: Color(0xFF1565C0)),
                title: const Text('Enterprise Security & 2FA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () async {
              await appState.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text('Sign Out of Corporate Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
