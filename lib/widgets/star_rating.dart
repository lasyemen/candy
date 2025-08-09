import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int? maxRating;
  final double size;
  final Color? color;
  final Color? unratedColor;
  final bool allowHalfRating;
  final bool readOnly;
  final Function(double)? onRatingChanged;

  const StarRating({
    Key? key,
    required this.rating,
    this.maxRating = 5,
    this.size = 32.0,
    this.color,
    this.unratedColor,
    this.allowHalfRating = false,
    this.readOnly = false,
    this.onRatingChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating!, (index) {
        final starValue = index + 1.0;
        final isHalfStar =
            allowHalfRating && rating > index && rating < index + 1;
        final isFullStar = rating >= starValue;

        return GestureDetector(
          onTap: readOnly
              ? null
              : () {
                  onRatingChanged?.call(starValue);
                },
          child: Container(
            margin: const EdgeInsets.only(right: 2),
            child: Icon(
              isFullStar
                  ? Icons.star_rounded
                  : isHalfStar
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
              size: size,
              color: isFullStar || isHalfStar
                  ? (color ?? Colors.amber[600])
                  : (unratedColor ?? Colors.grey[400]),
            ),
          ),
        );
      }),
    );
  }
}

class InteractiveStarRating extends StatefulWidget {
  final double initialRating;
  final int maxRating;
  final double size;
  final Color? color;
  final Color? unratedColor;
  final Function(double) onRatingChanged;

  const InteractiveStarRating({
    Key? key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.size = 32.0,
    this.color,
    this.unratedColor,
    required this.onRatingChanged,
  }) : super(key: key);

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late double _currentRating;
  late double _hoverRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
    _hoverRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        final starValue = index + 1.0;
        final isSelected = _hoverRating >= starValue;

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = starValue;
              _hoverRating = starValue;
            });
            widget.onRatingChanged(starValue);
          },
          onPanUpdate: (details) {
            // Handle drag to rate
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localPosition = renderBox.globalToLocal(
              details.globalPosition,
            );
            final starWidth = widget.size;
            final starIndex = (localPosition.dx / starWidth).floor();
            final newRating = (starIndex + 1)
                .clamp(1, widget.maxRating)
                .toDouble();

            setState(() {
              _hoverRating = newRating;
            });
          },
          onPanEnd: (details) {
            setState(() {
              _currentRating = _hoverRating;
            });
            widget.onRatingChanged(_hoverRating);
          },
          child: MouseRegion(
            onEnter: (_) {
              setState(() {
                _hoverRating = starValue;
              });
            },
            onExit: (_) {
              setState(() {
                _hoverRating = _currentRating;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 2),
              child: Icon(
                isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                size: widget.size,
                color: isSelected
                    ? (widget.color ?? Colors.amber[600])
                    : (widget.unratedColor ?? Colors.grey[400]),
              ),
            ),
          ),
        );
      }),
    );
  }
}
