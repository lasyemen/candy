import 'package:flutter/material.dart';
import '../../core/constants/design_system.dart';
import '../star_rating.dart';

class StarRatingDisplay extends StatelessWidget {
  final bool isLoading;
  final double rating;
  final int totalRatings;

  const StarRatingDisplay({
    super.key,
    required this.isLoading,
    required this.rating,
    required this.totalRatings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          StarRating(
            rating: rating,
            size: 22,
            readOnly: true,
          ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            fontFamily: 'Rubik',
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($totalRatings تقييم)',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
            fontFamily: 'Rubik',
          ),
        ),
      ],
    );
  }
}








