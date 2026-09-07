import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/language_switcher.dart';
import '../login_screen.dart';

/// Screen 5: FPO Profile
/// Styled exactly like the Farmer profile: clean, friendly, warm green tones,
/// with editable settlement bank details, warehouse infrastructure, accreditations, and settings.
class FpoProfileScreen extends StatefulWidget {
  const FpoProfileScreen({super.key});

  @override
  State<FpoProfileScreen> createState() => _FpoProfileScreenState();
}

class _FpoProfileScreenState extends State<FpoProfileScreen> {
  bool _notificationsEnabled = true;

  // Editable settlement bank details
  final _bankAccController = TextEditingController(text: '918273645012');
  final _ifscController = TextEditingController(text: 'SBIN0001824');
  final _bankNameController = TextEditingController(text: 'State Bank of India');
  final _branchController = TextEditingController(text: 'Commercial Branch, GT Road, Karnal');

  @override
  void dispose() {
    _bankAccController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  void _showEditBankModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Institutional Escrow Bank Details',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Used for automated RTGS escrow releases and direct buyer disbursements.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bankAccController,
                decoration: const InputDecoration(
                  labelText: 'Current Account Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ifscController,
                decoration: const InputDecoration(
                  labelText: 'Bank IFSC Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _branchController,
                decoration: const InputDecoration(
                  labelText: 'Branch Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settlement bank account details updated successfully!'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save Bank Details', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final fpoName = (user?.name.isNotEmpty == true && user?.name != 'Demo User')
        ? user!.name
        : 'Karnal Agri Producer Company Limited';
    final email = user?.email ?? 'operations@karnalagrifpo.org';
    final location = user?.location ?? 'Taraori, Karnal, Haryana';

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: CustomScrollView(
        slivers: [
          CustomAppBar(
            title: 'FPO Organization Profile',
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: Center(child: LanguageSwitcherPill(isDark: true)),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                children: [
                  // 1. Profile Header Card (Matching Farmer Profile Card)
                  _buildProfileHeaderCard(fpoName, email, location),
                  const SizedBox(height: 16),

                  // 2. Organization Stats Row
                  _buildStatsRow(),
                  const SizedBox(height: 16),

                  // 3. Bank Account Card (Matching Farmer Bank Card)
                  _buildBankAndSettlementCard(),
                  const SizedBox(height: 16),

                  // 4. Warehouse Infrastructure Card
                  _buildWarehouseInfrastructureCard(),
                  const SizedBox(height: 16),

                  // 5. Verification & Accreditations Card
                  _buildAccreditationsCard(),
                  const SizedBox(height: 16),

                  // 6. Settings & Preferences Card
                  _buildSettingsCard(appState),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Profile Header Card (avatar, verified check, organization name)
  Widget _buildProfileHeaderCard(String name, String email, String location) {
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
            radius: 32,
            backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'K',
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
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
                        name,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.verified, color: Color(0xFF2563EB), size: 18),
                  ],
                ),
                Text(
                  'CIN: U01111HR2023PTC109284 • Sec 378A Co.',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 13, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
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

  /// 3-Stat row: Warehouses, Capacity, Members
  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSingleStat('Silo Capacity', '5,000 Qtl', Icons.warehouse),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          _buildSingleStat('Current Stock', '4,300 Qtl', Icons.inventory_2),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          _buildSingleStat('Co-op Status', 'Verified', Icons.verified_user),
        ],
      ),
    );
  }

  Widget _buildSingleStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
      ],
    );
  }

  /// Bank & Settlement Card with Edit button
  Widget _buildBankAndSettlementCard() {
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
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance, color: Color(0xFF2E7D32), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Direct Settlement Bank Account',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _showEditBankModal,
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2E7D32)),
                tooltip: 'Edit Bank Details',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBankField('Bank Name', _bankNameController.text),
          _buildBankField('Current Account', '•••• •••• •••• ${_bankAccController.text.substring((_bankAccController.text.length - 4).clamp(0, _bankAccController.text.length))}'),
          _buildBankField('IFSC Code', _ifscController.text),
          _buildBankField('Branch', _branchController.text),
          _buildBankField('Payout Method', 'Direct RTGS / Escrow Auto-Release'),
        ],
      ),
    );
  }

  Widget _buildBankField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  /// Warehouse Infrastructure Card
  Widget _buildWarehouseInfrastructureCard() {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.domain, color: Color(0xFF0284C7), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Warehouse & Silos Infrastructure',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfrastructureTile('Central Silo Complex 01', '3 Steel Silos (5,000 Qtl) • NH-44 GT Road, Taraori', true),
          const SizedBox(height: 8),
          _buildInfrastructureTile('60-Tonne Electronic Weighbridge', 'Calibrated by Legal Metrology Haryana • Fastag linked', true),
          const SizedBox(height: 8),
          _buildInfrastructureTile('On-Site Quality Lab & Assaying', 'NABL Certified Moisture Meters & Purity Analyzers', true),
        ],
      ),
    );
  }

  Widget _buildInfrastructureTile(String title, String subtitle, bool isVerified) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF15803D)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Accreditations & Tax IDs
  Widget _buildAccreditationsCard() {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_outlined, color: Color(0xFF7C3AED), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Statutory Accreditations & Licenses',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBadge('SFAC / NABARD', 'Status: Active', const Color(0xFF15803D)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBadge('GSTIN', '06AABCK9928P1Z8', const Color(0xFF0284C7)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildBadge('FSSAI Central Lic.', '1002302200192', const Color(0xFFD97706)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBadge('Corporate PAN', 'AABCK9928P', const Color(0xFF7C3AED)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: color)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  /// Settings & Logout
  Widget _buildSettingsCard(AppState appState) {
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
          Text(
            'Settings & Preferences',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Order & Dispatch Alerts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Get instant notifications on buyer RFQs and payments', style: TextStyle(fontSize: 11)),
            value: _notificationsEnabled,
            activeThumbColor: const Color(0xFF2E7D32),
            onChanged: (val) => setState(() => _notificationsEnabled = val),
          ),
          const Divider(height: 16),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.help_outline, color: Color(0xFF2E7D32), size: 20),
            title: const Text('Help & FPO Co-op Support', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connecting to AgriChain 24/7 FPO Desk: 1800-AGRI-FPO')),
              );
            },
          ),
          const Divider(height: 16),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout, color: Colors.red, size: 20),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              appState.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
