import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class RetailBuyerSavedScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const RetailBuyerSavedScreen({super.key, this.onNavigateTab});

  @override
  State<RetailBuyerSavedScreen> createState() => _RetailBuyerSavedScreenState();
}

class _RetailBuyerSavedScreenState extends State<RetailBuyerSavedScreen> {
  final List<Map<String, dynamic>> _savedListings = [
    {
      'id': 'crop_01',
      'cropName': 'Sharbati Wheat',
      'variety': 'Sharbati 306',
      'grade': 'Grade A',
      'price': 3500.0,
      'quantity': 20.0,
      'unit': 'Qtl',
      'farmerName': 'Rajesh Kumar',
      'distance': '7 km away',
      'location': 'Karnal Village, Haryana',
      'image': 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=500',
    },
    {
      'id': 'crop_02',
      'cropName': 'Basmati 1121 Rice',
      'variety': 'Pusa 1121',
      'grade': 'Grade 1',
      'price': 4600.0,
      'quantity': 15.0,
      'unit': 'Qtl',
      'farmerName': 'Gurpreet Singh',
      'distance': '9.2 km away',
      'location': 'Taraori, Karnal',
      'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved Produce',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
              ),
            ),
            Text(
              'Your Favorite Crops & Local Farmers',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      body: _savedListings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'No saved produce yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap the heart icon on any crop card to save it here',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => widget.onNavigateTab?.call(1),
                    icon: const Icon(Icons.search),
                    label: const Text('Find Crops'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _savedListings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final crop = _savedListings[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          crop['image'] as String,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 70,
                            height: 70,
                            color: AppTheme.lightGreen,
                            child: const Icon(Icons.agriculture, color: AppTheme.primaryGreen),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              crop['cropName'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkGreen,
                              ),
                            ),
                            Text(
                              '₹${(crop['price'] as double).toStringAsFixed(0)} / ${crop['unit']} • ${crop['grade']}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            Text(
                              '${crop['farmerName']} • ${crop['distance']}',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _savedListings.removeAt(index);
                              });
                            },
                          ),
                          ElevatedButton(
                            onPressed: () => widget.onNavigateTab?.call(1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Buy',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
