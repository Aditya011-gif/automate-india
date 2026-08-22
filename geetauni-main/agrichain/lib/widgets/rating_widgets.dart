import 'package:flutter/material.dart';
import '../models/firestore_models.dart';

// Star Rating Display Widget (Read-only)
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showRating;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 20.0,
    this.activeColor,
    this.inactiveColor,
    this.showRating = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeStarColor = activeColor ?? Colors.amber;
    final inactiveStarColor = inactiveColor ?? Colors.grey[300]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(starCount, (index) {
            final starValue = index + 1;
            IconData iconData;
            Color color;

            if (rating >= starValue) {
              iconData = Icons.star;
              color = activeStarColor;
            } else if (rating >= starValue - 0.5) {
              iconData = Icons.star_half;
              color = activeStarColor;
            } else {
              iconData = Icons.star_border;
              color = inactiveStarColor;
            }

            return Icon(iconData, size: size, color: color);
          }),
        ),
        if (showRating) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// Interactive Star Rating Widget (for giving ratings)
class StarRatingInput extends StatefulWidget {
  final double initialRating;
  final int starCount;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final ValueChanged<double>? onRatingChanged;

  const StarRatingInput({
    super.key,
    this.initialRating = 0.0,
    this.starCount = 5,
    this.size = 30.0,
    this.activeColor,
    this.inactiveColor,
    this.onRatingChanged,
  });

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final activeStarColor = widget.activeColor ?? Colors.amber;
    final inactiveStarColor = widget.inactiveColor ?? Colors.grey[300]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.starCount, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = starValue.toDouble();
            });
            widget.onRatingChanged?.call(_currentRating);
          },
          child: Icon(
            _currentRating >= starValue ? Icons.star : Icons.star_border,
            size: widget.size,
            color: _currentRating >= starValue
                ? activeStarColor
                : inactiveStarColor,
          ),
        );
      }),
    );
  }
}

// Review Card Widget
class ReviewCard extends StatelessWidget {
  final Rating rating;
  final bool showUserInfo;

  const ReviewCard({super.key, required this.rating, this.showUserInfo = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (showUserInfo) ...[
                  CircleAvatar(
                    radius: 20,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rating.fromUserName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDate(rating.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                StarRatingDisplay(
                  rating: rating.rating,
                  size: 18,
                  showRating: true,
                ),
              ],
            ),
            if (rating.review != null && rating.review!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(rating.review!, style: theme.textTheme.bodyMedium),
            ],
            if (rating.ratingType != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rating.ratingType == RatingType.buyer
                      ? Colors.blue[100]
                      : Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  rating.ratingType == RatingType.buyer
                      ? 'As Buyer'
                      : 'As Seller',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: rating.ratingType == RatingType.buyer
                        ? Colors.blue[700]
                        : Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

// Rating Summary Widget
class RatingSummary extends StatelessWidget {
  final UserRatingStats stats;
  final String title;

  const RatingSummary({super.key, required this.stats, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (stats.totalRatings == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No ratings yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Column(
                  children: [
                    Text(
                      stats.averageRating.toStringAsFixed(1),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    StarRatingDisplay(rating: stats.averageRating, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.totalRatings} rating${stats.totalRatings == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildRatingBar(
                        context,
                        5,
                        stats.fiveStarCount,
                        stats.totalRatings,
                      ),
                      _buildRatingBar(
                        context,
                        4,
                        stats.fourStarCount,
                        stats.totalRatings,
                      ),
                      _buildRatingBar(
                        context,
                        3,
                        stats.threeStarCount,
                        stats.totalRatings,
                      ),
                      _buildRatingBar(
                        context,
                        2,
                        stats.twoStarCount,
                        stats.totalRatings,
                      ),
                      _buildRatingBar(
                        context,
                        1,
                        stats.oneStarCount,
                        stats.totalRatings,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(
    BuildContext context,
    int stars,
    int count,
    int total,
  ) {
    final theme = Theme.of(context);
    final percentage = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars', style: theme.textTheme.bodySmall),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// Compact Rating Display for lists
class CompactRatingDisplay extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double size;

  const CompactRatingDisplay({
    super.key,
    required this.rating,
    required this.totalRatings,
    this.size = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (totalRatings == 0) {
      return Text(
        'No ratings',
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: size, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          '${rating.toStringAsFixed(1)} ($totalRatings)',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
