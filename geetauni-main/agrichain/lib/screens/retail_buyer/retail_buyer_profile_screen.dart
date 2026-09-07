import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../widgets/custom_app_bar.dart';
import '../login_screen.dart';

class RetailBuyerProfileScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const RetailBuyerProfileScreen({super.key, this.onNavigateTab});

  @override
  State<RetailBuyerProfileScreen> createState() => _RetailBuyerProfileScreenState();
}

class _RetailBuyerProfileScreenState extends State<RetailBuyerProfileScreen> {
  bool _pushNotifications = true;
  String _selectedLanguage = 'English (EN)';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Profile',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
              ),
            ),
            Text(
              'Personal Details & Settings',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // 1. User Info Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    child: Text(
                      (user?.name.isNotEmpty ?? false)
                          ? user!.name[0].toUpperCase()
                          : 'R',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
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
                            Text(
                              user?.name ?? 'Retail Buyer',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkGreen,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 16),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'buyer@agrichain.com',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Verified Retail Customer',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Profile Options List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.person_outline,
                    title: 'My Details',
                    subtitle: 'Name, Phone number, Email address',
                    onTap: () => _showDetailsModal(context, user?.name, user?.email, user?.phone),
                  ),
                  _buildDivider(),
                  _buildProfileTile(
                    icon: Icons.location_on_outlined,
                    title: 'My Delivery Address',
                    subtitle: 'Flat 402, Green Avenue, Delhi NCR',
                    onTap: () => _showAddressModal(context),
                  ),
                  _buildDivider(),
                  _buildProfileTile(
                    icon: Icons.payment_outlined,
                    title: 'Payment & UPI',
                    subtitle: 'Google Pay, PhonePe, Cards, Net Banking',
                    onTap: () => _showPaymentModal(context),
                  ),
                  _buildDivider(),
                  _buildProfileTile(
                    icon: Icons.shopping_bag_outlined,
                    title: 'My Orders',
                    subtitle: 'View recent purchases and delivery status',
                    onTap: () => widget.onNavigateTab?.call(2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Settings & Preferences
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined, color: AppTheme.primaryGreen),
                    title: Text(
                      'Notifications',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Harvest alerts and order tracking updates',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    value: _pushNotifications,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  _buildDivider(),
                  _buildProfileTile(
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: _selectedLanguage,
                    onTap: () => _showLanguageModal(context),
                  ),
                  _buildDivider(),
                  _buildProfileTile(
                    icon: Icons.headset_mic_outlined,
                    title: 'Help & Customer Support',
                    subtitle: '24x7 Customer Helpline, FAQs, Dispute Resolution',
                    onTap: () => _showHelpModal(context),
                  ),
                  _buildDivider(),
                  _buildProfileTile(
                    icon: Icons.security_outlined,
                    title: 'Privacy & Terms',
                    subtitle: 'AgriChain Direct Buyer Guarantee',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('AgriChain Buyer Protection is 100% active.')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Provider.of<AppState>(context, listen: false).signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(
                  'Sign Out',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.darkGreen),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey.shade100, indent: 60);

  void _showDetailsModal(BuildContext context, String? name, String? email, String? phone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Details', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildDetailRow('Full Name', name ?? 'Retail Buyer'),
                _buildDetailRow('Email', email ?? 'buyer@agrichain.com'),
                _buildDetailRow('Phone', phone ?? '+91 98765 00000'),
                _buildDetailRow('Account Type', 'Direct Retail Customer'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showAddressModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Delivery Address', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home, color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Home (Primary)', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          Text(
                            'Flat 402, Green Avenue, Sector 18, Delhi NCR - 110085',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payment Methods', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: AppTheme.primaryGreen),
                title: const Text('UPI ID (Google Pay / PhonePe)'),
                subtitle: const Text('user@okhdfcbank'),
                trailing: const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
              ),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.grey),
                title: const Text('HDFC Bank Visa Card'),
                subtitle: const Text('•••• •••• •••• 4092'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageModal(BuildContext context) {
    final languages = ['English (EN)', 'हिंदी (Hindi)', 'ਪੰਜਾਬੀ (Punjabi)', 'मराठी (Marathi)', 'ગુજરાતી (Gujarati)'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Language', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...languages.map((lang) {
                return RadioListTile<String>(
                  title: Text(lang),
                  value: lang,
                  groupValue: _selectedLanguage,
                  activeColor: AppTheme.primaryGreen,
                  onChanged: (val) {
                    setState(() => _selectedLanguage = val!);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer Support', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.phone, color: AppTheme.primaryGreen),
                title: const Text('Toll Free Helpline'),
                subtitle: const Text('1800-200-FARM (9 AM - 8 PM)'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling toll-free helpline...')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: AppTheme.primaryGreen),
                title: const Text('Email Support'),
                subtitle: const Text('support@agrichain.in'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
