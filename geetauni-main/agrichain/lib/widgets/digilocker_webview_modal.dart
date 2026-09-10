import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/firestore_models.dart';
import '../providers/app_state.dart';
import '../services/digilocker_service.dart';

class DigilockerWebviewModal extends StatefulWidget {
  const DigilockerWebviewModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DigilockerWebviewModal(),
    );
  }

  @override
  State<DigilockerWebviewModal> createState() => _DigilockerWebviewModalState();
}

class _DigilockerWebviewModalState extends State<DigilockerWebviewModal> {
  bool _isLoading = true;
  String? _errorMessage;
  DigilockerSessionResponse? _session;
  DigilockerProfile? _verifiedProfile;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final session = await DigilockerService.initiateSession();
    if (mounted) {
      setState(() {
        _session = session;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchAuthUrl() async {
    if (_session == null) return;
    final uri = Uri.parse(_session!.authorizationUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch DigiLocker URL.')),
        );
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Future<void> _checkStatusOrComplete({bool forceMock = false}) async {
    if (_session == null) return;
    setState(() => _isCheckingStatus = true);

    try {
      if (forceMock) {
        // Fast-track demo verification
        await Future.delayed(const Duration(milliseconds: 900));
        final profile = await DigilockerService.fetchAadhaarDocument(_session!.sessionId);
        if (mounted) {
          setState(() {
            _verifiedProfile = profile;
            _isCheckingStatus = false;
          });
        }
        return;
      }

      // Check real status from Sandbox.co.in
      final status = await DigilockerService.checkSessionStatus(_session!.sessionId);
      if (status == 'succeeded' || status == 'completed') {
        final profile = await DigilockerService.fetchAadhaarDocument(_session!.sessionId);
        if (mounted) {
          setState(() {
            _verifiedProfile = profile;
            _isCheckingStatus = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isCheckingStatus = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status: $status. If you finished on the web portal, tap "Simulate Success".'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  void _completeLoginWithRole(UserType role) {
    if (_verifiedProfile == null) return;
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setDigilockerUserRole(role, _verifiedProfile!);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF15803D),
        content: Row(
          children: [
            const Icon(Icons.verified, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Signed in via DigiLocker: ${_verifiedProfile!.fullName}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🇮🇳', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'MeriPehchaan / DigiLocker',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF15803D).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Govt. of India',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'National Single Sign-On (NSSO) • Sandbox.co.in Gateway',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Body Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0284C7)),
                        SizedBox(height: 16),
                        Text('Initializing DigiLocker Session with Sandbox.co.in...'),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _startSession,
                                child: const Text('Retry Connection'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _verifiedProfile != null
                        ? _buildVerifiedProfileView()
                        : _buildSessionLaunchView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionLaunchView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informational Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: Color(0xFF15803D), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aadhaar Verified Citizen Login',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Directly authenticate through UIDAI & DigiLocker with OTP. Your legal name and verified credentials will be linked to your AgriChain trade ledger.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF14532D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Session Details Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live Gateway Session Active',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Session ID: ${_session?.sessionId ?? ""}',
                  style: GoogleFonts.robotoMono(fontSize: 11, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Endpoint: digilocker.meripehchaan.gov.in',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Primary Button: Launch MeriPehchaan
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _launchAuthUrl,
              icon: const Icon(Icons.open_in_browser, color: Colors.white),
              label: Text(
                'Open MeriPehchaan / DigiLocker Portal',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Check Status Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _isCheckingStatus ? null : () => _checkStatusOrComplete(forceMock: false),
              icon: _isCheckingStatus
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh, size: 18),
              label: Text(
                _isCheckingStatus ? 'Checking Government Status...' : 'I Approved Consent • Check Status',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Fast-track Demo Simulation Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Color(0xFFD97706), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Demo Sandbox Fast-Track',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Instantly complete verification with verified Aadhaar test citizen record.',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _isCheckingStatus ? null : () => _checkStatusOrComplete(forceMock: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Simulate OK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedProfileView() {
    final p = _verifiedProfile!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aadhaar Card Visual
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          'Mera Aadhaar, Meri Pehchaan',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'DIGILOCKER VERIFIED',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  p.fullName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'DOB: ${p.dob ?? "12/08/1982"} • Gender: ${p.gender ?? "Male"}',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  p.address ?? 'Vill. Taraori, Tehsil Nilokheri, Karnal, Haryana',
                  style: GoogleFonts.inter(color: Colors.white.withOpacity(0.85), fontSize: 10.5),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.maskedAadhaar,
                      style: GoogleFonts.robotoMono(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      p.certificateId,
                      style: GoogleFonts.robotoMono(color: Colors.white60, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Select Your AgriChain Role to Enter:',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          _buildRoleChoiceCard(
            title: '🌾 Farmer (Kisan Portal)',
            subtitle: 'List crops, access MSP forecasting & direct buyer pooling',
            role: UserType.farmer,
          ),
          _buildRoleChoiceCard(
            title: '🏢 FPO Cooperative Manager',
            subtitle: 'Manage warehouse inventory, silo lots & multi-farm contracts',
            role: UserType.fpo,
          ),
          _buildRoleChoiceCard(
            title: '🏭 Bulk Buyer / Processor',
            subtitle: 'Procure multi-ton lots, road-routing & escrow agreements',
            role: UserType.buyer,
          ),
          _buildRoleChoiceCard(
            title: '🛒 Retail Consumer',
            subtitle: 'Direct farm produce purchase, cluster pooling & escrow',
            role: UserType.retailBuyer,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChoiceCard({
    required String title,
    required String subtitle,
    required UserType role,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B))),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF0284C7)),
        onTap: () => _completeLoginWithRole(role),
      ),
    );
  }
}
