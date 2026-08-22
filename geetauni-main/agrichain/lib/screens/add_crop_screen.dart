import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/blockchain_service.dart';
import '../widgets/enhanced_app_bar.dart';
import '../models/crop.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

enum CropAction { sell }

class AddCropScreen extends StatefulWidget {
  const AddCropScreen({super.key});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedImagePath;
  XFile? _cropImageFile;
  XFile? _signatureImage;
  bool _isUploading = false;
  DateTime _harvestDate = DateTime.now();

  // New fields for enhanced crop listing
  CropType? _selectedCropType;
  CropCategory? _selectedCategory;
  QualityGrade _selectedQualityGrade = QualityGrade.standard;
  final List<CertificationType> _selectedCertifications = [];
  CropPricing? _currentPricing;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _locationController.dispose();

    super.dispose();
  }

  Future<void> _selectImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (image != null) {
        setState(() {
          _cropImageFile = image;
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking crop image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick crop image: $e')),
        );
      }
    }
  }

  Future<void> _pickSignatureImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (image != null) {
        setState(() {
          _signatureImage = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking signature image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _selectHarvestDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _harvestDate) {
      setState(() {
        _harvestDate = picked;
      });
    }
  }

  void _onCropTypeChanged(CropType? cropType) {
    setState(() {
      _selectedCropType = cropType;
      if (cropType != null) {
        _selectedCategory = CropDataHelper.getCategoryForCropType(cropType);
        _currentPricing = CropDataHelper.getPricingForCropType(cropType);
        // Auto-fill crop name if it's empty
        if (_nameController.text.isEmpty) {
          _nameController.text = CropDataHelper.getCropDisplayName(cropType);
        }
      } else {
        _selectedCategory = null;
        _currentPricing = null;
      }
    });
  }

  void _toggleCertification(CertificationType certification) {
    setState(() {
      if (_selectedCertifications.contains(certification)) {
        _selectedCertifications.remove(certification);
      } else {
        _selectedCertifications.add(certification);
      }
    });
  }

  Widget _buildPricingInfo() {
    if (_currentPricing == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Market Pricing Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          if (_currentPricing!.msp > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MSP:', style: TextStyle(color: AppTheme.grey)),
                Text(
                  '₹${_currentPricing!.msp.toStringAsFixed(0)}/${_currentPricing!.unit}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Market Price:',
                style: TextStyle(color: AppTheme.grey),
              ),
              Text(
                '₹${_currentPricing!.marketPrice.toStringAsFixed(0)}/${_currentPricing!.unit}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Season:', style: TextStyle(color: AppTheme.grey)),
              Text(
                _currentPricing!.season,
                style: const TextStyle(fontSize: 12, color: AppTheme.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _uploadCrop() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image for your crop'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final blockchainService = BlockchainService();

      // Step 1: Upload image to IPFS
      final ipfsHash = await blockchainService.uploadImageToIPFS(
        _selectedImagePath!,
      );

      // Step 2: Mint NFT for the crop
      final nftTokenId = await blockchainService.mintNFT(
        appState.currentUser!.name,
        _nameController.text,
        _descriptionController.text,
        ipfsHash,
      );

      String? cropSignatureUrl;
      if (_signatureImage != null) {
        try {
          final bytes = await _signatureImage!.readAsBytes();
          final base64String = base64Encode(bytes);
          cropSignatureUrl = 'data:image/jpeg;base64,$base64String';
          debugPrint(
            '✅ Crop signature converted to Base64 (${bytes.length} bytes)',
          );
        } catch (e) {
          debugPrint('Error converting crop signature: $e');
        }
      }

      String cropImageUrl = _selectedImagePath!;
      if (_cropImageFile != null) {
        try {
          final bytes = await _cropImageFile!.readAsBytes();
          final base64String = base64Encode(bytes);
          cropImageUrl = 'data:image/jpeg;base64,$base64String';
        } catch (e) {
          debugPrint('Error converting crop image: $e');
        }
      }

      // Step 3: Create crop using AppState (handles both local and Firebase sync)
      final success = await appState.createCrop(
        name: _nameController.text,
        location: _locationController.text.isEmpty
            ? appState.currentUser!.location ?? ''
            : _locationController.text,
        price: double.parse(_priceController.text),
        quantity: _quantityController.text,
        harvestDate: _harvestDate,
        imageUrl: cropImageUrl,
        description: _descriptionController.text,
        cropType: _selectedCropType ?? CropType.wheat,
        category: _selectedCategory ?? CropCategory.grains,
        qualityGrade: _selectedQualityGrade,
        isNFT: true,
        biddingType: BiddingType.fixedPrice,
        signatureUrl: cropSignatureUrl,
      );

      if (success) {
        debugPrint('✅ Crop created successfully');

        // Step 4: Create smart contract for selling
        final cropId = DateTime.now().millisecondsSinceEpoch.toString();
        await blockchainService.createSellOrder(
          cropId,
          double.parse(_priceController.text),
          _quantityController.text,
          nftTokenId,
        );
      } else {
        debugPrint('❌ Failed to create crop');
        throw Exception('Failed to create crop');
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Crop listed for sale with NFT!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EnhancedAppBar(
        title: 'Add New Crop',
        subtitle: 'List your crop for sale or loan',
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sell Type Selection
              const Text(
                'How would you like to sell?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGreen,
                ),
              ),
              const SizedBox(height: 16),
              _buildSellTypeCard(
                title: 'Fixed Price',
                subtitle: 'Set a fixed price for your crop',
                icon: Icons.local_offer,
              ),
              const SizedBox(height: 24),

              // Image Upload
              const Text(
                'Crop Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGreen,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedImagePath == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: AppTheme.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to select image',
                              style: TextStyle(
                                color: AppTheme.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppTheme.primaryGreen.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _cropImageFile != null
                                    ? (kIsWeb
                                        ? Image.network(
                                            _cropImageFile!.path,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(_cropImageFile!.path),
                                            fit: BoxFit.cover,
                                          ))
                                    : const Icon(
                                        Icons.image,
                                        size: 64,
                                        color: AppTheme.primaryGreen,
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Crop Details
              const Text(
                'Crop Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGreen,
                ),
              ),
              const SizedBox(height: 16),

              // Crop Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Crop Name',
                  hintText: 'e.g., Organic Wheat',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter crop name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Crop Type Dropdown
              DropdownButtonFormField<CropType>(
                initialValue: _selectedCropType,
                decoration: InputDecoration(
                  labelText: 'Crop Type',
                  hintText: 'Select crop type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
                items: CropDataHelper.cropCategories.entries
                    .expand(
                      (categoryEntry) => [
                        // Category header
                        DropdownMenuItem<CropType>(
                          enabled: false,
                          value: null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              CropDataHelper.getCategoryDisplayName(
                                categoryEntry.key,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkGreen,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        // Crop items
                        ...categoryEntry.value.map(
                          (cropType) => DropdownMenuItem<CropType>(
                            value: cropType,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Text(
                                CropDataHelper.getCropDisplayName(cropType),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                    .toList(),
                onChanged: _onCropTypeChanged,
                validator: (value) {
                  if (value == null) {
                    return 'Please select a crop type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Show pricing info if crop type is selected
              _buildPricingInfo(),

              // Quality Grade Dropdown
              DropdownButtonFormField<QualityGrade>(
                initialValue: _selectedQualityGrade,
                decoration: InputDecoration(
                  labelText: 'Quality Grade',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
                items: QualityGrade.values
                    .map(
                      (grade) => DropdownMenuItem<QualityGrade>(
                        value: grade,
                        child: Text(
                          CropDataHelper.getQualityGradeDisplayName(grade),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedQualityGrade = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Certifications
              const Text(
                'Certifications',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGreen,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CertificationType.values.map((certification) {
                  final isSelected = _selectedCertifications.contains(
                    certification,
                  );
                  return FilterChip(
                    label: Text(
                      CropDataHelper.getCertificationDisplayName(certification),
                    ),
                    selected: isSelected,
                    onSelected: (_) => _toggleCertification(certification),
                    selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryGreen,
                    backgroundColor: Colors.grey[100],
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.grey,
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your crop quality, farming methods, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'e.g., 100 kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price Field
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price (₹)',
                  hintText: '2500',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location (Optional)',
                  hintText: 'Farm location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Harvest Date
              GestureDetector(
                onTap: _selectHarvestDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.grey),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Harvest Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.grey,
                            ),
                          ),
                          Text(
                            '${_harvestDate.day}/${_harvestDate.month}/${_harvestDate.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.darkGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Signature Upload Section
              const Text(
                'Contract Document Signature',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGreen,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (_signatureImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                _signatureImage!.path,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              )
                            : Image.file(
                                File(_signatureImage!.path),
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _pickSignatureImage,
                        icon: const Icon(
                          Icons.edit,
                          color: AppTheme.primaryGreen,
                        ),
                        label: const Text('Change Signature'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: const BorderSide(color: AppTheme.primaryGreen),
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.draw, size: 48, color: AppTheme.grey),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload your signature for contracts associated with this crop',
                        style: TextStyle(color: AppTheme.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _pickSignatureImage,
                        icon: const Icon(
                          Icons.upload,
                          color: AppTheme.primaryGreen,
                        ),
                        label: const Text('Upload Signature'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: const BorderSide(color: AppTheme.primaryGreen),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadCrop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Creating NFT & Processing...'),
                          ],
                        )
                      : const Text(
                          'List Crop for Sale',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // NFT Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security, color: AppTheme.primaryGreen),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your crop will be automatically converted to an NFT for blockchain verification and ownership proof.',
                        style: TextStyle(
                          color: AppTheme.darkGreen,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSellTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      height: 120, // Fixed height to prevent overflow
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.primaryGreen, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: AppTheme.primaryGreen),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.primaryGreen,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
