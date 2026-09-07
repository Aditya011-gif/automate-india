import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/land_nft.dart';
import '../models/crop_nft.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../screens/farmer/mint_land_nft_screen.dart';
import '../screens/farmer/mint_crop_nft_screen.dart';

class EnhancedLoanRequestDialog extends StatefulWidget {
  const EnhancedLoanRequestDialog({super.key});

  @override
  State<EnhancedLoanRequestDialog> createState() =>
      _EnhancedLoanRequestDialogState();
}

class _EnhancedLoanRequestDialogState extends State<EnhancedLoanRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Form Controllers
  final _amountController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _cropGradeController = TextEditingController(); // Added for crop grade
  final _descriptionController = TextEditingController();

  // Dropdown values
  String _selectedPurpose = 'Seeds & Fertilizers';
  String _selectedCropType = 'Rice';
  String _selectedRepaymentPeriod = '6 months';
  String _urgency = 'medium';

  // NFT Collateral
  String _collateralType = 'none'; // none, land, crop, both
  List<LandNFT> _availableLandNFTs = [];
  List<CropNFT> _availableCropNFTs = [];
  final List<String> _selectedLandNFTs = [];
  final List<String> _selectedCropNFTs = [];
  double _totalCollateralValue = 0.0;

  final List<String> _purposes = [
    'Seeds & Fertilizers',
    'Equipment Purchase',
    'Land Preparation',
    'Irrigation Setup',
    'Crop Protection',
    'Harvesting',
    'Storage & Processing',
    'Other',
  ];

  final List<String> _cropTypes = [
    'Rice',
    'Wheat',
    'Corn',
    'Sugarcane',
    'Cotton',
    'Soybean',
    'Tomato',
    'Potato',
    'Onion',
    'Banana',
    'Mango',
    'Other',
  ];

  final List<String> _repaymentPeriods = [
    '3 months',
    '6 months',
    '12 months',
    '18 months',
    '24 months',
    '36 months',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserNFTs();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _farmSizeController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserNFTs() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;

    if (user == null) {
      print('NFT Loading: No user found in app state');
      return;
    }

    // Check Firebase Auth state
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      print('NFT Loading: No Firebase user authenticated');
      return;
    }

    print(
      'NFT Loading: User ID: ${user.id}, Firebase UID: ${firebaseUser.uid}',
    );

    try {
      // Load Land NFTs
      print('NFT Loading: Querying land_nfts for ownerFirebaseUid: ${user.id}');
      final landSnapshot = await FirebaseFirestore.instance
          .collection('land_nfts')
          .where('ownerFirebaseUid', isEqualTo: user.id)
          .where('isCollateralized', isEqualTo: false)
          .get();

      print('NFT Loading: Found ${landSnapshot.docs.length} land NFTs');

      // Load Crop NFTs
      print('NFT Loading: Querying crop_nfts for ownerFirebaseUid: ${user.id}');
      final cropSnapshot = await FirebaseFirestore.instance
          .collection('crop_nfts')
          .where('ownerFirebaseUid', isEqualTo: user.id)
          .where('isCollateralized', isEqualTo: false)
          .get();

      print('NFT Loading: Found ${cropSnapshot.docs.length} crop NFTs');

      setState(() {
        _availableLandNFTs = landSnapshot.docs
            .map((doc) => LandNFT.fromFirestore(doc))
            .toList();
        _availableCropNFTs = cropSnapshot.docs
            .map((doc) => CropNFT.fromFirestore(doc))
            .toList();
      });

      print('NFT Loading: Successfully loaded NFTs');
    } catch (e) {
      print('Error loading NFTs: $e');
      print('NFT Loading: Firebase Auth User: ${firebaseUser.uid}');
      print('NFT Loading: App State User ID: ${user.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade50, Colors.white, Colors.green.shade50],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildLoanDetailsStep(),
                  _buildCollateralSelectionStep(),
                  _buildReviewStep(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade700],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.agriculture, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Create Loan Request',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? AppTheme.primaryGreen
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoanDetailsStep() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('💰 Loan Details'),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _amountController,
              label: 'Loan Amount (₹)',
              hint: 'Enter amount in rupees',
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Amount is required';
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0) return 'Enter valid amount';
                return null;
              },
            ),

            const SizedBox(height: 20),

            _buildSectionHeader('🎯 Purpose & Details'),
            const SizedBox(height: 12),

            _buildDropdown(
              value: _selectedPurpose,
              label: 'Purpose',
              icon: Icons.assignment,
              items: _purposes,
              onChanged: (value) => setState(() => _selectedPurpose = value!),
            ),

            const SizedBox(height: 16),

            _buildDropdown(
              value: _selectedCropType,
              label: 'Crop Type',
              icon: Icons.eco,
              items: _cropTypes,
              onChanged: (value) => setState(() => _selectedCropType = value!),
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _farmSizeController,
              label: 'Farm Size',
              hint: 'e.g., 5 acres',
              icon: Icons.landscape,
            ),

            const SizedBox(height: 20),

            _buildSectionHeader('📊 Financial Terms'),
            const SizedBox(height: 12),

            _buildDropdown(
              value: _selectedRepaymentPeriod,
              label: 'Repayment Period',
              icon: Icons.schedule,
              items: _repaymentPeriods,
              onChanged: (value) =>
                  setState(() => _selectedRepaymentPeriod = value!),
            ),

            const SizedBox(height: 20),

            _buildSectionHeader('⚡ Urgency Level'),
            const SizedBox(height: 12),

            _buildUrgencySelector(),

            const SizedBox(height: 20),

            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Additional details about your loan request',
              icon: Icons.description,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollateralSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('🔒 Collateral Selection'),
          const SizedBox(height: 12),

          const Text(
            'Select NFT collateral to secure your loan and get better interest rates:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          _buildCollateralTypeSelector(),
          const SizedBox(height: 20),

          if (_collateralType == 'land' || _collateralType == 'both') ...[
            _buildLandNFTSection(),
            const SizedBox(height: 20),
          ],

          if (_collateralType == 'crop' || _collateralType == 'both') ...[
            _buildCropNFTSection(),
            const SizedBox(height: 20),
          ],

          if (_collateralType != 'none') ...[
            _buildCollateralSummary(),
            const SizedBox(height: 20),
            _buildCollateralDocumentUpload(),
            const SizedBox(height: 20),
          ],

          _buildMintNFTOptions(),
        ],
      ),
    );
  }

  Widget _buildCollateralTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Collateral Type:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          children: [
            _buildCollateralTypeChip('none', 'No Collateral', Icons.block),
            _buildCollateralTypeChip('land', 'Land NFT', Icons.landscape),
            _buildCollateralTypeChip('crop', 'Crop NFT', Icons.agriculture),
            _buildCollateralTypeChip('both', 'Both', Icons.account_balance),
          ],
        ),
      ],
    );
  }

  Widget _buildCollateralTypeChip(String type, String label, IconData icon) {
    final isSelected = _collateralType == type;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _collateralType = type;
          if (type == 'none') {
            _selectedLandNFTs.clear();
            _selectedCropNFTs.clear();
            _totalCollateralValue = 0.0;
          }
        });
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
      checkmarkColor: AppTheme.primaryGreen,
    );
  }

  Widget _buildLandNFTSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.landscape, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            const Text(
              'Land NFTs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${_availableLandNFTs.length} available',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_availableLandNFTs.isEmpty)
          _buildEmptyNFTState(
            'No land NFTs available',
            'Mint your first land NFT to use as collateral',
          )
        else
          ...(_availableLandNFTs.map((nft) => _buildLandNFTCard(nft))),
      ],
    );
  }

  Widget _buildCropNFTSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.agriculture, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            const Text(
              'Crop NFTs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${_availableCropNFTs.length} available',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_availableCropNFTs.isEmpty)
          _buildEmptyNFTState(
            'No crop NFTs available',
            'Mint your first crop NFT to use as collateral',
          )
        else
          ...(_availableCropNFTs.map((nft) => _buildCropNFTCard(nft))),
      ],
    );
  }

  Widget _buildLandNFTCard(LandNFT nft) {
    final isSelected = _selectedLandNFTs.contains(nft.tokenId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (selected) {
          setState(() {
            if (selected == true) {
              _selectedLandNFTs.add(nft.tokenId);
              _totalCollateralValue += nft.valuation.currentValue;
            } else {
              _selectedLandNFTs.remove(nft.tokenId);
              _totalCollateralValue -= nft.valuation.currentValue;
            }
          });
        },
        title: Text(
          '${nft.landDetails.village}, ${nft.landDetails.district}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${nft.landDetails.areaInAcres} acres • ${nft.landDetails.landType}',
            ),
            Text(
              '₹${nft.valuation.currentValue.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        activeColor: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildCropNFTCard(CropNFT nft) {
    final isSelected = _selectedCropNFTs.contains(nft.tokenId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (selected) {
          setState(() {
            if (selected == true) {
              _selectedCropNFTs.add(nft.tokenId);
              _totalCollateralValue += nft.harvestData.estimatedValue;
            } else {
              _selectedCropNFTs.remove(nft.tokenId);
              _totalCollateralValue -= nft.harvestData.estimatedValue;
            }
          });
        },
        title: Text(
          '${nft.cropDetails.cropName} (${nft.cropDetails.variety})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${nft.harvestData.quantity} ${nft.harvestData.unit} • ${nft.qualityAssurance.qualityGrade} Grade',
            ),
            Text(
              '₹${nft.harvestData.estimatedValue.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        activeColor: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildCollateralSummary() {
    final loanAmount = double.tryParse(_amountController.text) ?? 0.0;
    final collateralRatio = loanAmount > 0
        ? (_totalCollateralValue / loanAmount) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collateral Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGreen,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Collateral Value:'),
              Text(
                '₹${_totalCollateralValue.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),

          if (loanAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Collateral Ratio:'),
                Text(
                  '${collateralRatio.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: collateralRatio >= 150
                        ? Colors.green
                        : collateralRatio >= 100
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
          Text(
            'Selected: ${_selectedLandNFTs.length} Land NFTs, ${_selectedCropNFTs.length} Crop NFTs',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMintNFTOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need More Collateral?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            'Mint new NFTs to increase your collateral value and get better loan terms.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MintLandNFTScreen(),
                      ),
                    ).then((_) => _loadUserNFTs());
                  },
                  icon: const Icon(Icons.landscape),
                  label: const Text('Mint Land NFT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MintCropNFTScreen(),
                      ),
                    ).then((_) => _loadUserNFTs());
                  },
                  icon: const Icon(Icons.agriculture),
                  label: const Text('Mint Crop NFT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNFTState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final loanAmount = double.tryParse(_amountController.text) ?? 0.0;
    final collateralRatio = loanAmount > 0
        ? (_totalCollateralValue / loanAmount) * 100
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('📋 Review Your Request'),
          const SizedBox(height: 16),

          _buildReviewSection('Loan Details', [
            'Amount: ₹${_amountController.text}',
            'Purpose: $_selectedPurpose',
            'Crop Type: $_selectedCropType',
            'Farm Size: ${_farmSizeController.text}',
            'Repayment Period: $_selectedRepaymentPeriod',
            'Urgency: ${_urgency.toUpperCase()}',
          ]),

          if (_collateralType != 'none') ...[
            _buildReviewSection('Collateral', [
              'Type: ${_getCollateralTypeLabel()}',
              'Total Value: ₹${_totalCollateralValue.toStringAsFixed(0)}',
              'Collateral Ratio: ${collateralRatio.toStringAsFixed(1)}%',
              'Land NFTs: ${_selectedLandNFTs.length}',
              'Crop NFTs: ${_selectedCropNFTs.length}',
            ]),
          ],

          if (_descriptionController.text.isNotEmpty)
            _buildReviewSection('Description', [_descriptionController.text]),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.security,
                  color: AppTheme.primaryGreen,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Blockchain Secured',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _collateralType != 'none'
                      ? 'Your NFT collateral will be locked in a smart contract until loan repayment.'
                      : 'Your loan request will be recorded on the blockchain for transparency.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.darkGreen,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...items
              .where((item) => item.isNotEmpty)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(item, style: const TextStyle(fontSize: 14)),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.darkGreen,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null
              ? Icon(icon, color: AppTheme.primaryGreen)
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppTheme.primaryGreen,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    IconData? icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? Icon(icon, color: AppTheme.primaryGreen)
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppTheme.primaryGreen,
              width: 2,
            ),
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
      ),
    );
  }

  Widget _buildUrgencySelector() {
    return Row(
      children: [
        _buildUrgencyChip('low', 'Low', Colors.green),
        const SizedBox(width: 8),
        _buildUrgencyChip('medium', 'Medium', Colors.orange),
        const SizedBox(width: 8),
        _buildUrgencyChip('high', 'High', Colors.red),
      ],
    );
  }

  Widget _buildUrgencyChip(String value, String label, Color color) {
    final isSelected = _urgency == value;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) => setState(() => _urgency = value),
      label: Text(label),
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: color,
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep == 2 ? _submitLoanRequest : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_currentStep == 2 ? 'Submit Request' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _formKey.currentState?.validate() ?? false;
      case 1:
        return true; // Collateral is optional
      default:
        return true;
    }
  }

  Widget _buildCollateralDocumentUpload() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Upload Collateral Documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text(
            'Upload supporting documents for your collateral (land records, crop certificates, etc.):',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_upload, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                const Text(
                  'Drag & drop files here or click to browse',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement file upload functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'File upload functionality will be implemented',
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Choose Files'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Text(
            'Supported formats: PDF, JPG, PNG (Max 10MB per file)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _getCollateralTypeLabel() {
    switch (_collateralType) {
      case 'land':
        return 'Land NFT';
      case 'crop':
        return 'Crop NFT';
      case 'both':
        return 'Land & Crop NFTs';
      default:
        return 'None';
    }
  }

  Future<void> _submitLoanRequest() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isSubmitting = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final user = appState.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Debug: Print user information
      print('DEBUG LOAN SUBMIT: User ID: ${user.id}');
      print('DEBUG LOAN SUBMIT: User Name: ${user.name}');
      print('DEBUG LOAN SUBMIT: User Type: ${user.userType}');

      final loanRequestId = FirebaseFirestore.instance
          .collection('loan_requests')
          .doc()
          .id;

      final loanRequestData = {
        'loanRequestId': loanRequestId,
        'farmerId': user.id,
        'farmerName': user.name,
        'farmerEmail': user.email,
        'location': user.location ?? 'Unknown',
        'loanAmount': double.parse(_amountController.text),
        'purpose': _selectedPurpose,
        'cropType': _selectedCropType,
        'cropGrade': _cropGradeController.text, // Added cropGrade
        'farmSize': _farmSizeController.text,
        'repaymentPeriod': _selectedRepaymentPeriod,
        'urgency': _urgency,
        'description': _descriptionController.text,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // NFT Collateral
        'hasCollateral': _collateralType != 'none',
        'collateralType': _collateralType,
        'collateralValue': _totalCollateralValue,
        'landNFTCollateral': _selectedLandNFTs,
        'cropNFTCollateral': _selectedCropNFTs,
        'collateralLocked': false, // Will be set to true when loan is approved
      };

      // Debug: Print loan request data
      print('DEBUG LOAN SUBMIT: Loan Request ID: $loanRequestId');
      print(
        'DEBUG LOAN SUBMIT: Farmer ID in data: ${loanRequestData['farmerId']}',
      );

      await FirebaseFirestore.instance
          .collection('loan_requests')
          .doc(loanRequestId)
          .set(loanRequestData);

      print('DEBUG LOAN SUBMIT: Successfully saved to Firestore');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan request submitted successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      print('DEBUG LOAN SUBMIT: Error - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
