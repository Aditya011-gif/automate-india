import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
  DigilockerSessionResponse? _session;
  DigilockerProfile? _verifiedProfile;

  // Authentication Flow Steps:
  // 0 = Enter Mobile/Aadhaar
  // 1 = Enter 6-digit OTP
  // 2 = Verified Citizen eKYC Profile & Role Choice
  int _currentStep = 0;
  int _selectedTab = 0; // 0: Aadhaar/Mobile, 1: Username, 2: Others

  final TextEditingController _identifierController =
      TextEditingController(text: '98765 43210');
  final TextEditingController _otpController =
      TextEditingController(text: '782190');

  bool _consentChecked = true;
  bool _isProcessingOtp = false;
  int _resendCountdown = 45;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _identifierController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() => _isLoading = true);
    final session = await DigilockerService.initiateSession();
    if (mounted) {
      setState(() {
        _session = session;
        _isLoading = false;
      });
    }
  }

  void _sendOtp() {
    if (_identifierController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Mobile or Aadhaar number')),
      );
      return;
    }

    setState(() {
      _currentStep = 1;
      _resendCountdown = 45;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0284C7),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.sms, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'MeriPehchaan OTP sent! Test OTP: 782190 (auto-filled)',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOtpAndGrantConsent() async {
    if (_otpController.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP received')),
      );
      return;
    }

    setState(() => _isProcessingOtp = true);
    await Future.delayed(const Duration(milliseconds: 950));

    final profile = await DigilockerService.fetchAadhaarDocument(
      _session?.sessionId ?? 'sandbox_dl_active',
    );

    if (mounted) {
      setState(() {
        _verifiedProfile = profile;
        _currentStep = 2;
        _isProcessingOtp = false;
      });
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
      height: MediaQuery.of(context).size.height * 0.90,
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

          // Official Government MeriPehchaan Header
          _buildOfficialHeader(),

          // Body Content based on Step
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0284C7)),
                        SizedBox(height: 16),
                        Text('Connecting to MeriPehchaan National Gateway...'),
                      ],
                    ),
                  )
                : _currentStep == 2 && _verifiedProfile != null
                    ? _buildVerifiedProfileView()
                    : _currentStep == 1
                        ? _buildOtpVerificationStep()
                        : _buildCredentialsInputStep(),
          ),
        ],
      ),
    );
  }

  /// Header with National Emblem, MeriPehchaan branding & Government logos
  Widget _buildOfficialHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Government National Emblem icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              border: Border.all(color: const Color(0xFFFDE68A)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('🇮🇳', style: TextStyle(fontSize: 24)),
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
                      'Meri',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    Text(
                      'Pehchaan',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NSSO SSO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'SINGLE SIGN-ON SERVICE • DigiLocker • e-Pramaan',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.2,
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
    );
  }

  /// Step 0: Mobile / Aadhaar Number Entry
  Widget _buildCredentialsInputStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Government Auth Method Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildTabItem(0, '📱 Mobile / Aadhaar'),
                _buildTabItem(1, '👤 Username'),
                _buildTabItem(2, '🆔 Others'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Sign In to your account via MeriPehchaan',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Authenticate directly using your linked Mobile number or 12-digit Aadhaar.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Identifier Input
          Text(
            'Mobile Number / Aadhaar Number',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _identifierController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Text(
                  '+91',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              hintText: 'Enter 10-digit mobile or 12-digit Aadhaar',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Consent Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _consentChecked,
                  activeColor: const Color(0xFF15803D),
                  onChanged: (val) => setState(() => _consentChecked = val ?? true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'I consent to MeriPehchaan / DigiLocker terms and authorize sharing my verified Aadhaar KYC details with AgriChain for digital trade contracts.',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Primary Button: Generate OTP
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _consentChecked ? _sendOtp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Generate OTP',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Fast-Track Sandbox Callout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Color(0xFF15803D), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Government Sandbox Environment Active',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF166534),
                        ),
                      ),
                      Text(
                        'Pre-configured test citizen (Ramesh Singh Sandhu, Karnal, Haryana).',
                        style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF14532D)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Step 1: OTP Entry & Verification
  Widget _buildOtpVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF334155)),
                onPressed: () => setState(() => _currentStep = 0),
              ),
              const SizedBox(width: 4),
              Text(
                'Enter OTP Verification Code',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'A 6-digit OTP has been dispatched to your mobile linked to Aadhaar (ending in ...6743).',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
            ),
          ),
          const SizedBox(height: 24),

          // OTP Field
          Center(
            child: SizedBox(
              width: 260,
              child: TextField(
                controller: _otpController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: GoogleFonts.robotoMono(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 10,
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF15803D), width: 2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Center(
            child: Text(
              _resendCountdown > 0
                  ? 'Resend OTP in 00:${_resendCountdown.toString().padLeft(2, '0')}'
                  : 'Didn\'t receive OTP? Tap below to resend',
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
            ),
          ),
          if (_resendCountdown == 0)
            Center(
              child: TextButton(
                onPressed: _sendOtp,
                child: const Text('Resend OTP via SMS'),
              ),
            ),
          const SizedBox(height: 24),

          // Verify Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isProcessingOtp ? null : _verifyOtpAndGrantConsent,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessingOtp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_user, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Verify & Grant Consent',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Security note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield, color: Color(0xFF15803D), size: 14),
              const SizedBox(width: 6),
              Text(
                'Protected by UIDAI 2048-bit RSA Encryption & MeitY Standards',
                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Step 2: Verified Aadhaar Card & Role Selection
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
                  color: const Color(0xFF0F766E).withValues(alpha: 0.3),
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'DIGILOCKER VERIFIED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
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
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 10.5,
                  ),
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
            color: Colors.black.withValues(alpha: 0.02),
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
