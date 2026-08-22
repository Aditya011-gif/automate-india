import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/rating_widgets.dart';
import '../widgets/enhanced_app_bar.dart';
import '../models/firestore_models.dart'; // Screen for giving a rating

class GiveRatingScreen extends StatefulWidget {
  final String toUserId;
  final String toUserName;
  final RatingType ratingType;
  final String? transactionId;

  const GiveRatingScreen({
    super.key,
    required this.toUserId,
    required this.toUserName,
    required this.ratingType,
    this.transactionId,
  });

  @override
  State<GiveRatingScreen> createState() => _GiveRatingScreenState();
}

class _GiveRatingScreenState extends State<GiveRatingScreen> {
  double _rating = 0.0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: EnhancedAppBar(
        title: 'Rate ${widget.toUserName}',
        subtitle: 'Share your experience',
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: theme.primaryColor,
                          child: Text(
                            widget.toUserName.isNotEmpty
                                ? widget.toUserName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.toUserName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.ratingType == RatingType.buyer
                                      ? Colors.blue[100]
                                      : Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Rating as ${widget.ratingType == RatingType.buyer ? 'Buyer' : 'Seller'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: widget.ratingType == RatingType.buyer
                                        ? Colors.blue[700]
                                        : Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'How would you rate your experience?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: StarRatingInput(
                initialRating: _rating,
                size: 40,
                onRatingChanged: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
            ),
            if (_rating > 0) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _getRatingText(_rating),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Write a review (optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.primaryColor),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _rating > 0 && !_isSubmitting ? _submitRating : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Submit Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excellent!';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Poor';
    return 'Very Poor';
  }

  void _submitRating() async {
    if (_rating == 0) return;

    setState(() {
      _isSubmitting = true;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    final currentUser = appState.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    try {
      appState.addRating(
        fromUserId: currentUser.id,
        fromUserName: currentUser.name,
        toUserId: widget.toUserId,
        toUserName: widget.toUserName,
        ratingType: widget.ratingType,
        rating: _rating,
        review: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
        transactionId: widget.transactionId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

// Screen for viewing ratings
class ViewRatingsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final int initialTab;

  const ViewRatingsScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.initialTab = 0,
  });

  @override
  State<ViewRatingsScreen> createState() => _ViewRatingsScreenState();
}

class _ViewRatingsScreenState extends State<ViewRatingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadRatingData(AppState appState) async {
    final buyerRatings = await appState.getRatingsForUser(
      widget.userId,
      ratingType: RatingType.buyer,
    );
    final sellerRatings = await appState.getRatingsForUser(
      widget.userId,
      ratingType: RatingType.seller,
    );
    final stats = await appState.calculateRatingStats(widget.userId);

    return {
      'buyerRatings': buyerRatings,
      'sellerRatings': sellerRatings,
      'stats': stats,
    };
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: EnhancedAppBar(
        title: '${widget.userName}\'s Ratings',
        subtitle: 'View transaction history',
        centerTitle: false,
        height: 120,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadRatingData(appState),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading ratings: ${snapshot.error}'),
            );
          }

          final data = snapshot.data!;
          final buyerRatings = data['buyerRatings'] as List<Rating>;
          final sellerRatings = data['sellerRatings'] as List<Rating>;
          final stats = data['stats'] as UserRatingStats?;

          return Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryGreen,
                  unselectedLabelColor: AppTheme.grey,
                  indicatorColor: AppTheme.primaryGreen,
                  tabs: [
                    Tab(text: 'As Buyer (${buyerRatings.length})'),
                    Tab(text: 'As Seller (${sellerRatings.length})'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRatingTab(stats, buyerRatings, 'Buyer Ratings'),
                    _buildRatingTab(stats, sellerRatings, 'Seller Ratings'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRatingTab(
    UserRatingStats? stats,
    List<Rating> ratings,
    String title,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stats != null)
            RatingSummary(stats: stats, title: title)
          else
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No rating statistics available',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 16),
          if (ratings.isNotEmpty) ...[
            Text(
              'Reviews',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ratings.length,
              itemBuilder: (context, index) {
                return ReviewCard(rating: ratings[index], showUserInfo: true);
              },
            ),
          ] else ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews yet',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reviews will appear here after transactions',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Screen for viewing all ratings (admin/overview)
class AllRatingsScreen extends StatefulWidget {
  const AllRatingsScreen({super.key});

  @override
  State<AllRatingsScreen> createState() => _AllRatingsScreenState();
}

class _AllRatingsScreenState extends State<AllRatingsScreen> {
  RatingType? _filterType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);

    List<Rating> filteredRatings = appState.ratings;
    if (_filterType != null) {
      filteredRatings = appState.ratings
          .where((rating) => rating.ratingType == _filterType)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Ratings'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<RatingType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (type) {
              setState(() {
                _filterType = type;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Ratings')),
              const PopupMenuItem(
                value: RatingType.buyer,
                child: Text('Buyer Ratings'),
              ),
              const PopupMenuItem(
                value: RatingType.seller,
                child: Text('Seller Ratings'),
              ),
            ],
          ),
        ],
      ),
      body: filteredRatings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No ratings found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _filterType == null
                        ? 'Ratings will appear here after transactions'
                        : 'No ${_filterType == RatingType.buyer ? 'buyer' : 'seller'} ratings found',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredRatings.length,
              itemBuilder: (context, index) {
                final rating = filteredRatings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.primaryColor,
                      child: Text(
                        rating.fromUserName.isNotEmpty
                            ? rating.fromUserName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '${rating.fromUserName} → ${rating.toUserName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StarRatingDisplay(
                              rating: rating.rating,
                              size: 16,
                              showRating: true,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: rating.ratingType == RatingType.buyer
                                    ? Colors.blue[100]
                                    : Colors.green[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                rating.ratingType == RatingType.buyer
                                    ? 'Buyer'
                                    : 'Seller',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: rating.ratingType == RatingType.buyer
                                      ? Colors.blue[700]
                                      : Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (rating.review != null &&
                            rating.review!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            rating.review!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    trailing: Text(
                      _formatDate(rating.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewRatingsScreen(
                            userId: rating.toUserId,
                            userName: rating.toUserName,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }
}
