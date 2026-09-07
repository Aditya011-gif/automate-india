import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/signature_pad_dialog.dart';
import '../../services/database_service.dart';
import '../../services/whatsapp_kisan_service.dart';
import '../login_screen.dart';
import 'mint_land_nft_screen.dart';
import 'land_analysis_screen.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final DatabaseService _dbService = DatabaseService();
  bool _notificationsEnabled = true;

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  // Editable Bank/UPI details
  final _bankAccController = TextEditingController(text: '918273645012');
  final _ifscController = TextEditingController(text: 'HDFC0001824');
  final _upiController = TextEditingController(text: 'ramesh.farmer@oksbi');
  final _khasraController = TextEditingController(text: 'Khasra #42/18, Acreage: 6.5 Acres');

  @override
  void dispose() {
    _bankAccController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    _khasraController.dispose();
    super.dispose();
  }

  void _showBankUpiModal() {
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
              const Text(
                'Direct Settlement Bank & UPI Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Used for instant IMPS and UPI payouts from retail buyers and FPO procurement.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bankAccController,
                decoration: const InputDecoration(
                  labelText: 'Bank Account Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
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
                controller: _upiController,
                decoration: const InputDecoration(
                  labelText: 'UPI ID (VPA)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bank and UPI payout details updated successfully!'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save Payout Details', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final farmerId = user?.id ?? '';
    final farmerName = (user != null && user.name.isNotEmpty) ? user.name : 'Member Farmer';
    final email = user?.email ?? 'farmer@agrichain.in';
    final location = (user?.location != null && user!.location!.isNotEmpty) ? user.location! : 'Karnal, Haryana';

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          CustomAppBar(
            title: 'Farmer Profile',
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
            // Farmer Header Card
            _buildProfileHeaderCard(farmerName, email, location),
            const SizedBox(height: 18),

            // WhatsApp Kisan Assistant (Auto-Connect & Status)
            _buildWhatsAppKisanAssistantCard(appState),
            const SizedBox(height: 18),

            // Land & GIS Verification Card
            _buildLandAndGisCard(),
            const SizedBox(height: 18),

            // Digital Signature & DigiLocker Card
            _buildDigitalSignatureAndDigiLockerCard(appState),
            const SizedBox(height: 18),

            // Bank & UPI Details Card
            _buildBankAndUpiCard(),
            const SizedBox(height: 18),

            // Payout History Card
            _buildPayoutHistoryCard(farmerId),
            const SizedBox(height: 18),

            // Farmer Documents & Certifications
            _buildDocumentsCard(),
            const SizedBox(height: 18),

            // Preferences & Settings
            _buildSettingsCard(appState),
          ],
        ),
      ),
    );
  }

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
            radius: 30,
            backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'F',
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
                fontSize: 24,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.verified, color: Color(0xFF2563EB), size: 18),
                  ],
                ),
                Text(email, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 13, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 4),
                    Text(location, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppKisanAssistantCard(AppState appState) {
    final user = appState.currentUser;
    final kisanService = WhatsAppKisanService();
    final userId = user?.id ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: const Color(0xFFBBF7D0)),
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
                      color: const Color(0xFF25D366).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat, color: Color(0xFF075E54), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'WhatsApp कृषि-साथी AI',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF075E54),
                    ),
                  ),
                ],
              ),
              StreamBuilder<bool>(
                stream: kisanService.isWhatsAppLinkedStream(userId),
                builder: (context, snapshot) {
                  final isLinked = snapshot.data ?? false;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLinked ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLinked ? Icons.check_circle : Icons.link_off,
                          size: 13,
                          color: isLinked ? const Color(0xFF15803D) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isLinked ? 'Linked' : 'Not Linked',
                          style: TextStyle(
                            color: isLinked ? const Color(0xFF15803D) : const Color(0xFFD97706),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Connect WhatsApp for 1-Tap Auto Login. Any crops you send via voice note or text to WhatsApp will automatically be saved to your AgriChain account under "My Crops".',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please log in first to link your account')),
                      );
                      return;
                    }
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
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Connect WhatsApp (Auto Link)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Color(0xFF075E54)),
                tooltip: 'Configure Bot Phone Number',
                onPressed: () => _showBotNumberConfigDialog(),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildLandAndGisCard() {
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
              const Row(
                children: [
                  Icon(Icons.satellite_alt, color: Color(0xFF2563EB), size: 22),
                  SizedBox(width: 8),
                  Text('Land Records & GIS Soil Health', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('NFT Bound', style: TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _khasraController.text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Soil: Alluvial Sandy Loam • Moisture Index: Optimal (11.8%) • Nitrogen: High',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LandAnalysisScreen()),
                    );
                  },
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Land Scan', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MintLandNFTScreen()),
                    );
                  },
                  icon: const Icon(Icons.token, size: 16),
                  label: const Text('Mint Land NFT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalSignatureAndDigiLockerCard(AppState appState) {
    final signatureUrl = appState.currentUser?.signatureUrl;
    final hasSignature = signatureUrl != null && signatureUrl.isNotEmpty;

    Uint8List? sigBytes;
    if (hasSignature && signatureUrl.startsWith('data:image')) {
      try {
        final base64Part = signatureUrl.split(',').last;
        sigBytes = base64Decode(base64Part);
      } catch (_) {}
    }

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
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.draw, color: Color(0xFF15803D), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Digital Signature & DigiLocker',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Text(
                        'Embedded onto dual-signed smart contracts',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasSignature ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasSignature ? Icons.verified : Icons.warning_amber_rounded,
                      size: 13,
                      color: hasSignature ? const Color(0xFF15803D) : const Color(0xFFB45309),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasSignature ? 'ACTIVE' : 'ACTION REQUIRED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: hasSignature ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (hasSignature) ...[
            Container(
              width: double.infinity,
              height: 110,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
              ),
              child: sigBytes != null
                  ? Image.memory(sigBytes, fit: BoxFit.contain)
                  : Image.network(
                      signatureUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.verified, color: Color(0xFF15803D), size: 40),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle, size: 14, color: Color(0xFF15803D)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Official signature linked to your Aadhaar & e-Kisan profile.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final res = await SignaturePadDialog.show(
                      context,
                      signerName: appState.currentUser?.name ?? 'Farmer',
                      currentSignatureUrl: signatureUrl,
                      isFarmer: true,
                    );
                    if (res != null && res['signatureUrl'] != null) {
                      await appState.updateUserSignature(res['signatureUrl']);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Signature updated for smart contracts!'),
                            backgroundColor: Color(0xFF15803D),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Update / Re-sign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No digital signature on file!',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Upload your signature, draw it directly, or verify via DigiLocker so the dual-signed smart contracts include your real signature.',
                    style: TextStyle(fontSize: 11, color: Color(0xFFB45309), height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final res = await SignaturePadDialog.show(
                          context,
                          signerName: appState.currentUser?.name ?? 'Farmer',
                          isFarmer: true,
                        );
                        if (res != null && res['signatureUrl'] != null) {
                          await appState.updateUserSignature(res['signatureUrl']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Digital signature saved to profile!'),
                                backgroundColor: Color(0xFF15803D),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.draw, size: 16),
                      label: const Text('Upload or Draw Signature / DigiLocker e-Sign', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
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

  Widget _buildBankAndUpiCard() {
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
              const Row(
                children: [
                  Icon(Icons.account_balance, color: Color(0xFF2E7D32), size: 22),
                  SizedBox(width: 8),
                  Text('Direct Payout Bank & UPI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Color(0xFF2E7D32)),
                onPressed: _showBankUpiModal,
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildInfoRow('Account Number', _bankAccController.text),
          _buildInfoRow('IFSC Code', _ifscController.text),
          _buildInfoRow('UPI ID (VPA)', _upiController.text),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildPayoutHistoryCard(String farmerId) {
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
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Color(0xFFD97706), size: 22),
              SizedBox(width: 8),
              Text('Recent Payout Settlements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _dbService.streamFarmerOrders(farmerId),
            builder: (context, snapshot) {
              final orders = snapshot.data ?? [];
              if (orders.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No payout settlements yet.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                );
              }

              return Column(
                children: orders.take(3).map((o) {
                  final total = _toDouble(o['totalPrice']);
                  final date = o['createdAt'] != null ? o['createdAt'].toString().split('T').first : 'Recent';
                  final type = o['orderType'] == 'fpo_procurement' ? 'FPO Settlement' : 'Retail Sale';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$type ($date)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        Text('+₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D))),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsCard() {
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
          const Row(
            children: [
              Icon(Icons.folder_shared, color: Color(0xFF475569), size: 22),
              SizedBox(width: 8),
              Text('Documents & Certifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          _buildDocItem('Aadhaar / Farmer Identity Card', 'Verified', const Color(0xFF15803D)),
          _buildDocItem('Land Registry Deed (7/12 Extract)', 'Verified', const Color(0xFF15803D)),
          _buildDocItem('NPOP Organic Certification', 'Active', const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _buildDocItem(String name, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

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
          const Text('App Settings & Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('SMS & Push Notifications', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Order updates, FPO collection routes, MSP alerts', style: TextStyle(fontSize: 11)),
            value: _notificationsEnabled,
            activeThumbColor: const Color(0xFF2E7D32),
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
          ),
          const Divider(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.help_outline, color: Color(0xFF475569)),
            title: const Text('Kisan Helpdesk & Agri Advisory', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kisan Toll-Free Helpdesk: 1800-180-1551 (Available 24x7)')),
              );
            },
          ),
          const Divider(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text('Sign Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.error)),
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
