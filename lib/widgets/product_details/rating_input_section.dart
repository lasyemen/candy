import 'package:flutter/material.dart';
import '../../core/constants/design_system.dart';
import '../star_rating.dart';

class RatingInputSection extends StatelessWidget {
  final bool isLoggedIn;
  final double selectedRating;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback? onDelete;
  final ValueChanged<double> onRatingChanged;

  const RatingInputSection({
    super.key,
    required this.isLoggedIn,
    required this.selectedRating,
    required this.isSubmitting,
    required this.onSubmit,
    this.onDelete,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'سجل دخولك لتقييم هذا المنتج',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontFamily: 'Rubik',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تقييمك',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            fontFamily: 'Rubik',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InteractiveStarRating(
                initialRating: selectedRating,
                onRatingChanged: onRatingChanged,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 60,
              height: 32,
              child: Container(
                decoration: BoxDecoration(
                  gradient: DesignSystem.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'إرسال',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Rubik',
                            fontSize: 10,
                          ),
                        ),
                ),
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                height: 32,
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'حذف',
                    style: TextStyle(fontFamily: 'Rubik', fontSize: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
