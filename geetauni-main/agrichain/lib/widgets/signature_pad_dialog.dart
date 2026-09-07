import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

/// Modal dialog that allows farmers and buyers to:
/// 1. Draw their digital signature on screen
/// 2. Upload a signature photo from Gallery/Camera
/// 3. Authenticate with Government of India DigiLocker / Aadhaar e-Sign
class SignaturePadDialog extends StatefulWidget {
  final String signerName;
  final String? currentSignatureUrl;
  final bool isFarmer;

  const SignaturePadDialog({
    super.key,
    required this.signerName,
    this.currentSignatureUrl,
    this.isFarmer = true,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String signerName,
    String? currentSignatureUrl,
    bool isFarmer = true,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SignaturePadDialog(
        signerName: signerName,
        currentSignatureUrl: currentSignatureUrl,
        isFarmer: isFarmer,
      ),
    );
  }

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Drawing state
  final List<Offset?> _points = [];

  // Image upload state
  Uint8List? _uploadedImageBytes;

  // DigiLocker state
  bool _isDigiLockerAuthenticating = false;
  bool _isDigiLockerVerified = false;
  final _aadhaarController = TextEditingController(text: 'XXXX-XXXX-8921');
  final _otpController = TextEditingController(text: '892104');
  String? _digiLockerCertId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aadhaarController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Convert drawn strokes to PNG Base64 Data URI
  Future<String?> _captureDrawnSignature() async {
    if (_points.where((p) => p != null).length < 5) return null;

    try {
      const double width = 360;
      const double height = 180;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromPoints(const Offset(0, 0), const Offset(width, height)),
      );

      // White background
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), bgPaint);

      // Signature line guideline
      final guidePaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        const Offset(20, height - 35),
        const Offset(width - 20, height - 35),
        guidePaint,
      );

      // Stroke paint
      final paint = Paint()
        ..color = const Color(0xFF0F3D1F)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 3.5;

      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != null && _points[i + 1] != null) {
          canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes == null) return null;

      final base64String = base64Encode(pngBytes.buffer.asUint8List());
      return 'data:image/png;base64,$base64String';
    } catch (e) {
      debugPrint('Error capturing drawn signature: $e');
      return null;
    }
  }

  // Pick signature image from Gallery or Camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _uploadedImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking signature: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e')),
        );
      }
    }
  }

  // Simulate official DigiLocker / Aadhaar e-Sign authentication
  Future<void> _simulateDigiLockerAuth() async {
    setState(() {
      _isDigiLockerAuthenticating = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    final certId = 'DL-ESIGN-AADHAAR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // Generate a stylized official DigiLocker signature badge
    final recorder = ui.PictureRecorder();
    const double width = 380;
    const double height = 180;
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

    // Green tinted background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()..color = const Color(0xFFF0FDF4),
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(2, 2, width - 4, height - 4), const Radius.circular(10)),
      Paint()
        ..color = const Color(0xFF15803D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Text details
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontSize: 12,
    ))
      ..pushStyle(ui.TextStyle(color: const Color(0xFF14532D), fontWeight: FontWeight.bold, fontSize: 13))
      ..addText('✔ DIGILOCKER AADHAAR e-SIGN VERIFIED\n')
      ..pushStyle(ui.TextStyle(color: const Color(0xFF166534), fontWeight: FontWeight.normal, fontSize: 11))
      ..addText('Signer: ${widget.signerName}\n')
      ..addText('Authority: Controller of Certifying Authorities (CCA, MeitY)\n')
      ..addText('Certificate ID: $certId\n')
      ..addText('Timestamp: ${DateTime.now().toIso8601String().split('.').first}\n')
      ..pushStyle(ui.TextStyle(color: const Color(0xFF0F766E), fontStyle: FontStyle.italic, fontSize: 11))
      ..addText('Digitally signed pursuant to Section 3A of IT Act 2000');

    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: width - 30));
    canvas.drawParagraph(paragraph, const Offset(15, 20));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    setState(() {
      _isDigiLockerAuthenticating = false;
      _isDigiLockerVerified = true;
      _digiLockerCertId = certId;
      _uploadedImageBytes = pngBytes!.buffer.asUint8List();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ DigiLocker Aadhaar e-Sign Verified ($certId)'),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.draw, color: Color(0xFF15803D), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isFarmer ? 'Farmer Digital Signature' : 'Buyer Digital Signature',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Upload, Draw or verify with DigiLocker for smart contracts',
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF1B5E20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF475569),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: const [
                    Tab(icon: Icon(Icons.gesture, size: 16), text: 'Draw'),
                    Tab(icon: Icon(Icons.upload_file, size: 16), text: 'Upload'),
                    Tab(icon: Icon(Icons.verified, size: 16), text: 'DigiLocker'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDrawTab(),
                    _buildUploadTab(),
                    _buildDigiLockerTab(),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Footer actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: _saveAndReturnSignature,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Save & Use Signature',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 1: Draw Signature on Touch Canvas
  Widget _buildDrawTab() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // Signature line guide
                  Positioned(
                    bottom: 35,
                    left: 20,
                    right: 20,
                    child: Container(height: 1, color: const Color(0xFFE2E8F0)),
                  ),
                  const Positioned(
                    bottom: 12,
                    right: 20,
                    child: Text(
                      'Sign above the line',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ),
                  // Drawing canvas
                  GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _points.add(details.localPosition);
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _points.add(details.localPosition);
                      });
                    },
                    onPanEnd: (details) {
                      setState(() {
                        _points.add(null);
                      });
                    },
                    child: CustomPaint(
                      painter: _SignaturePainter(points: _points),
                      size: Size.infinite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Draw with your finger or stylus',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _points.clear();
                });
              },
              icon: const Icon(Icons.clear, size: 14, color: Colors.red),
              label: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  // TAB 2: Upload Signature photo from Camera or Gallery
  Widget _buildUploadTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_uploadedImageBytes != null) ...[
          Container(
            height: 140,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
            ),
            child: Image.memory(
              _uploadedImageBytes!,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Color(0xFF15803D), size: 16),
              SizedBox(width: 6),
              Text(
                'Signature Ready for Contracts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF15803D)),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ] else ...[
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined, size: 42, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                const Text(
                  'Upload paper signature photo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                ),
                Text(
                  'White paper with dark pen works best',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // TAB 3: DigiLocker & Aadhaar e-Sign Verification
  Widget _buildDigiLockerTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance, color: Color(0xFF15803D), size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Government of India DigiLocker e-Sign',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF14532D)),
                      ),
                      Text(
                        'Direct legally certified Aadhaar e-Sign under IT Act 2000',
                        style: TextStyle(fontSize: 10, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_isDigiLockerVerified) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified, color: Color(0xFF15803D), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'DigiLocker e-Sign Active & Certified',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Certificate ID: ${_digiLockerCertId ?? 'DL-ESIGN-8921'}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                  Text('Signer: ${widget.signerName}', style: const TextStyle(fontSize: 11)),
                  const Text('Issuer: e-Mudhra CA / National e-Gov Division', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            TextField(
              controller: _aadhaarController,
              decoration: const InputDecoration(
                labelText: 'Linked Aadhaar Number',
                prefixIcon: Icon(Icons.fingerprint),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Aadhaar OTP (Demo: 892104)',
                prefixIcon: Icon(Icons.lock_clock),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDigiLockerAuthenticating ? null : _simulateDigiLockerAuth,
                icon: _isDigiLockerAuthenticating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.verified, size: 18),
                label: Text(
                  _isDigiLockerAuthenticating ? 'Authenticating with DigiLocker...' : 'Verify & Import DigiLocker e-Sign',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Final submission logic
  Future<void> _saveAndReturnSignature() async {
    String? signatureDataUri;
    bool isDigiLocker = false;
    String? certId;

    if (_tabController.index == 0) {
      // Drawn
      signatureDataUri = await _captureDrawnSignature();
      if (signatureDataUri == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please draw your signature before saving.')),
        );
        return;
      }
    } else if (_tabController.index == 1) {
      // Uploaded image
      if (_uploadedImageBytes != null) {
        final base64String = base64Encode(_uploadedImageBytes!);
        signatureDataUri = 'data:image/jpeg;base64,$base64String';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please take a photo or select an image.')),
        );
        return;
      }
    } else if (_tabController.index == 2) {
      // DigiLocker
      if (!_isDigiLockerVerified) {
        await _simulateDigiLockerAuth();
      }
      isDigiLocker = true;
      certId = _digiLockerCertId ?? 'DL-ESIGN-IND-8921';
      if (_uploadedImageBytes != null) {
        final base64String = base64Encode(_uploadedImageBytes!);
        signatureDataUri = 'data:image/png;base64,$base64String';
      }
    }

    if (!mounted) return;

    Navigator.pop(context, {
      'signatureUrl': signatureDataUri,
      'isDigiLockerVerified': isDigiLocker,
      'digiLockerCertId': certId,
      'method': _tabController.index == 0 ? 'draw' : (_tabController.index == 1 ? 'upload' : 'digilocker'),
    });
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F3D1F)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
