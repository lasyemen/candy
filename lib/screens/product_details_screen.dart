// lib/screens/product_details_screen.dart
library product_details_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/app_settings.dart';
import '../core/i18n/product_dictionary.dart';
import 'package:flutter/services.dart';
import '../models/products.dart';
import '../models/product_rating.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/design_system.dart';
import '../widgets/riyal_icon.dart';
import '../core/services/cart_service.dart';
import '../core/services/rating_service.dart';
import '../core/services/customer_session.dart';
import '../widgets/product_details/star_rating_display.dart';
import '../widgets/product_details/rating_input_section.dart';
import '../widgets/product_details/quantity_selector.dart';
import '../core/constants/translations.dart';
import '../blocs/app_bloc.dart';
// duplicate imports removed
part 'functions/product_details_screen.functions.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Products product;

  const ProductDetailsScreen({Key? key, required this.product})
    : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin, ProductDetailsScreenFunctions {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  int _selectedQuantity = 1;

  // Rating state
  ProductRatingSummary? _ratingSummary;
  ProductRating? _userRating;
  bool _isLoadingRating = true;
  bool _isSubmittingRating = false;
  double _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Initialize slide animation for bottom sheet effect - exactly like showModalBottomSheet
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start image animation immediately
    _scaleController.forward();

    // Start bottom sheet animation after a delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _slideController.forward();
          }
        });
      }
    });

    // Load rating data
    _loadRatingData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scaleController.dispose();
    _slideController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  // Functions moved to ProductDetailsScreenFunctions mixin (see part file)

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<AppSettings>(context).currentLanguage;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Full screen background image
          Positioned.fill(
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              padding: const EdgeInsets.only(bottom: 320),
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Image.network(
                    widget.product.imageUrl ?? '',
                    fit: BoxFit.contain,
                    height: 50,
                    errorBuilder: (_, __, ___) => Container(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF121212)
                          : Colors.grey[300],
                      child: Icon(
                        Icons.image,
                        size: 80,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Transparent overlay to preserve layout without darkening the image
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Close button removed per request but keep Positioned to preserve layout
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: const SizedBox.shrink(),
          ),

          // Bottom sheet content
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF121212)
                      : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white24
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quantity + Title
                            Row(
                              textDirection: TextDirection.ltr,
                              children: [
                                QuantitySelector(
                                  quantity: _selectedQuantity,
                                  onIncrease: () =>
                                      setState(() => _selectedQuantity++),
                                  onDecrease: () {
                                    if (_selectedQuantity > 1) {
                                      setState(() => _selectedQuantity--);
                                    }
                                  },
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    ProductDictionary.translateName(
                                      widget.product.name,
                                      language,
                                    ),
                                    textAlign: TextAlign.right,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontFamily: language == 'en'
                                          ? 'SFProDisplay'
                                          : 'Rubik',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Star Rating Display
                            StarRatingDisplay(
                              isLoading: _isLoadingRating,
                              rating:
                                  _ratingSummary?.averageRating ??
                                  widget.product.rating,
                              totalRatings: _ratingSummary?.totalRatings ?? 0,
                            ),
                            const SizedBox(height: 12),

                            // Description
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                AppTranslations.getText(
                                  'description',
                                  Provider.of<AppSettings>(
                                    context,
                                    listen: false,
                                  ).currentLanguage,
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                                  fontFamily: 'Rubik',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.product.description ??
                                  AppTranslations.getText(
                                    'no_description',
                                    Provider.of<AppSettings>(
                                      context,
                                      listen: false,
                                    ).currentLanguage,
                                  ),
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                height: 1.6,
                                fontFamily: 'Rubik',
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Rating Input Section
                            RatingInputSection(
                              isLoggedIn: CustomerSession.instance.isLoggedIn,
                              selectedRating: _selectedRating,
                              isSubmitting: _isSubmittingRating,
                              onSubmit: _submitRating,
                              onDelete: _userRating != null
                                  ? _deleteRating
                                  : null,
                              onRatingChanged: (rating) {
                                setState(() {
                                  _selectedRating = rating;
                                });
                              },
                            ),
                            const SizedBox(height: 20),

                            // Price and Add to Cart
                            Row(
                              children: [
                                // Price
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ShaderMask(
                                        shaderCallback: (bounds) => DesignSystem
                                            .primaryGradient
                                            .createShader(bounds),
                                        child: Text(
                                          widget.product.price.toStringAsFixed(
                                            0,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      ShaderMask(
                                        shaderCallback: (bounds) => DesignSystem
                                            .primaryGradient
                                            .createShader(bounds),
                                        blendMode: BlendMode.srcIn,
                                        child: const RiyalIcon(
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Add to Cart Button
                                Expanded(
                                  flex: 2,
                                  child: _buildAddToCartButton(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI helpers moved to ProductDetailsScreenFunctions mixin

  // UI helpers moved to ProductDetailsScreenFunctions mixin

  // UI helpers moved to ProductDetailsScreenFunctions mixin

  // Logic moved to ProductDetailsScreenFunctions mixin

  // UI helpers moved to ProductDetailsScreenFunctions mixin
}
