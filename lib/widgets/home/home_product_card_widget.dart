import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../models/products.dart';
import '../../models/product_rating.dart';
import '../../core/constants/design_system.dart';
import '../../core/routes/app_routes.dart';
import '../riyal_icon.dart';
import '../../core/services/rating_service.dart';
import '../../core/i18n/product_dictionary.dart';
import '../../core/services/app_settings.dart';
import 'package:provider/provider.dart';

class HomeProductCardWidget extends StatefulWidget {
  final Products product;
  final VoidCallback onAddToCart;

  const HomeProductCardWidget({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<HomeProductCardWidget> createState() => _HomeProductCardWidgetState();
}

class _HomeProductCardWidgetState extends State<HomeProductCardWidget> {
  ProductRatingSummary? _ratingSummary;
  bool _isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    _loadRatingData();
  }

  Future<void> _loadRatingData() async {
    try {
      final ratingSummary = await RatingService.getProductRatingSummary(
        widget.product.id,
      );
      if (mounted) {
        setState(() {
          _ratingSummary = ratingSummary;
          _isLoadingRating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final language = context.watch<AppSettings>().currentLanguage;
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child:
          ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        AppRoutes.showProductDetails(context, widget.product);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image with Organic Shape
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF333333)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: widget.product.imageUrl != null
                                      ? Image.network(
                                          widget.product.imageUrl!,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  color: isDark
                                                      ? const Color(0xFF222222)
                                                      : Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.image,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              },
                                        )
                                      : Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          color: isDark
                                              ? const Color(0xFF222222)
                                              : Colors.grey[300],
                                          child: const Icon(
                                            Icons.image,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            // Product Info Section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Name with Modern Typography
                                Text(
                                  ProductDictionary.translateName(
                                    widget.product.name,
                                    language,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                                    height: 1.3,
                                    fontFamily: language == 'en'
                                        ? 'SFProDisplay'
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Product Rating
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isLoadingRating
                                          ? '...'
                                          : '${(_ratingSummary?.averageRating ?? widget.product.rating).toStringAsFixed(1)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isLoadingRating
                                          ? '(0)'
                                          : '(${_ratingSummary?.totalRatings ?? 0})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Price and Add to Cart Section
                                Row(
                                  children: [
                                    // Price with Gradient Text
                                    Expanded(
                                      child: Row(
                                        children: [
                                          ShaderMask(
                                            shaderCallback: (Rect bounds) {
                                              return const LinearGradient(
                                                colors: [
                                                  Color(0xFF6B46C1),
                                                  Color(0xFF3B82F6),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ).createShader(bounds);
                                            },
                                            blendMode: BlendMode.srcIn,
                                            child: isDark
                                                ? Text(
                                                    widget.product.price
                                                        .toStringAsFixed(2),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 15,
                                                      letterSpacing: -0.3,
                                                    ),
                                                  )
                                                : Text(
                                                    widget.product.price
                                                        .toStringAsFixed(2),
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 15,
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(width: 4),
                                          const RiyalIcon(
                                            size: 16,
                                            color: Color(0xFF6B46C1),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Modern Add to Cart Button
                                    Container(
                                      width: 48,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        gradient: DesignSystem.getBrandGradient(
                                          'primary',
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: DesignSystem.getBrandShadow(
                                          'medium',
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(14),
                                        elevation: 0,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            widget.onAddToCart();
                                          },
                                          child: const Center(
                                            child: FaIcon(
                                              FontAwesomeIcons.shoppingCart,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms, curve: Curves.easeOutCubic)
              .slideY(
                begin: 0.3,
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutCubic,
              ),
    );
  }
}
