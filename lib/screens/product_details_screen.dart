// lib/screens/product_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/products.dart';
import '../models/product_rating.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/design_system.dart';
import '../widgets/riyal_icon.dart';
import '../widgets/star_rating.dart';
import '../core/services/cart_service.dart';
import '../core/services/rating_service.dart';
import '../core/services/customer_session.dart';
import 'product_reviews_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Products product;

  const ProductDetailsScreen({Key? key, required this.product})
      : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin {
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
  bool _showReviewInput = false;

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
    _scaleController.forward();

    // Initialize slide animation for bottom sheet effect - exactly like showModalBottomSheet
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _slideController.forward();

    // Load rating data
    _loadRatingData();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  // Load rating data for the product
  Future<void> _loadRatingData() async {
    if (!CustomerSession.instance.isLoggedIn) {
      setState(() {
        _isLoadingRating = false;
      });
      return;
    }

    try {
      final customerId = CustomerSession.instance.currentCustomerId!;

      // Test table access first
      final tableAccess = await RatingService.testTableAccess();
      if (!tableAccess) {
        print('RatingService - Table access failed, cannot load rating data');
        setState(() {
          _isLoadingRating = false;
        });
        return;
      }

      // Load rating summary and user rating in parallel
      final results = await Future.wait([
        RatingService.getProductRatingSummary(widget.product.id),
        RatingService.getUserRating(widget.product.id, customerId),
      ]);

      setState(() {
        _ratingSummary = results[0] as ProductRatingSummary?;
        _userRating = results[1] as ProductRating?;
        _isLoadingRating = false;

        // Set initial values for rating input
        if (_userRating != null) {
          _selectedRating = _userRating!.rating.toDouble();
          _reviewController.text = _userRating!.review ?? '';
          _showReviewInput =
              _userRating!.review != null && _userRating!.review!.isNotEmpty;
        }
      });
    } catch (e) {
      print('Error loading rating data: $e');
      setState(() {
        _isLoadingRating = false;
      });
    }
  }

  // Submit user rating
  Future<void> _submitRating() async {
    if (!CustomerSession.instance.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول لتقييم المنتج'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار تقييم'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingRating = true;
    });

    try {
      final customerId = CustomerSession.instance.currentCustomerId!;
      final success = await RatingService.submitRating(
        productId: widget.product.id,
        customerId: customerId,
        rating: _selectedRating.toInt(),
        review: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
      );

      if (success) {
        // Reload rating data
        await _loadRatingData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال تقييمك بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'فشل في إرسال التقييم - تحقق من الاتصال بالإنترنت أو حاول مرة أخرى'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error submitting rating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ في إرسال التقييم'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmittingRating = false;
      });
    }
  }

  // Build star rating display widget (for under title)
  Widget _buildStarRatingDisplay() {
    return Row(
      children: [
        if (_isLoadingRating)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          StarRating(
            rating: _ratingSummary?.averageRating ?? widget.product.rating,
            size: 20,
            readOnly: true,
          ),
        const SizedBox(width: 8),
        Text(
          '${(_ratingSummary?.averageRating ?? widget.product.rating).toStringAsFixed(1)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'Rubik',
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '(${_ratingSummary?.totalRatings ?? 0} تقييم)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontFamily: 'Rubik',
          ),
        ),
      ],
    );
  }

  // Build rating input section widget (for under description)
  Widget _buildRatingInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User rating input (only if logged in)
        if (CustomerSession.instance.isLoggedIn) ...[
          const Text(
            'تقييمك',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InteractiveStarRating(
                  initialRating: _selectedRating,
                  onRatingChanged: (rating) {
                    setState(() {
                      _selectedRating = rating;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: DesignSystem.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmittingRating ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmittingRating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _userRating != null ? 'تحديث' : 'إرسال',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Rubik',
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          if (_userRating != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: 100,
              child: OutlinedButton(
                onPressed: _isSubmittingRating ? null : _deleteRating,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'حذف',
                  style: TextStyle(fontFamily: 'Rubik', fontSize: 12),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Review input
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: DesignSystem.primaryGradient,
                  ),
                  padding: const EdgeInsets.all(2), // Gradient border thickness
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                          14), // Slightly smaller to show gradient border
                    ),
                    child: TextField(
                      controller: _reviewController,
                      decoration: InputDecoration(
                        hintText: 'أضف مراجعة (اختياري)',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontFamily: 'Rubik',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Not logged in message
          Container(
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
          ),
        ],
      ],
    );
  }

  // Delete user rating
  Future<void> _deleteRating() async {
    if (!CustomerSession.instance.isLoggedIn || _userRating == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التقييم'),
        content: const Text('هل أنت متأكد من حذف تقييمك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final customerId = CustomerSession.instance.currentCustomerId!;
      final success =
          await RatingService.deleteRating(widget.product.id, customerId);

      if (success) {
        await _loadRatingData();
        setState(() {
          _selectedRating = 0;
          _reviewController.clear();
          _showReviewInput = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف تقييمك'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting rating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ في حذف التقييم'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // dark status‐bar icons on white background
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );

    return Scaffold(
      backgroundColor: Colors.white,

      // ───── BODY ─────
      body: Column(children: [
        // Top image section
        Expanded(
          flex: 45,
          child: Container(
            color: Colors.white,
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (ctx, child) => Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Hero(
                          tag: 'product_${widget.product.id}',
                          child: Image.network(
                            widget.product.imageUrl ?? '',
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholderImage(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: _buildNavButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Product details section with bottom sheet transition
        Expanded(
          flex: 55,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -4), // shadow at top edge only
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quantity + Title
                    Row(
                      textDirection: TextDirection.ltr,
                      children: [
                        _buildQuantitySelector(),
                        const Spacer(),
                        Text(
                          widget.product.name,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Star Rating Display
                    _buildStarRatingDisplay(),
                    const SizedBox(height: 12),

                    // Description
                    Align(
                      alignment: Alignment.centerRight,
                      child: const Text(
                        'الوصف',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Rubik',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.description ?? 'لا يوجد وصف.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.6,
                        fontFamily: 'Rubik',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Rating Input Section
                    _buildRatingInputSection(),
                    const SizedBox(height: 12),

                    // View all reviews button
                    if (_ratingSummary != null &&
                        _ratingSummary!.totalRatings > 0)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductReviewsScreen(
                                product: widget.product,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.rate_review_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'عرض جميع التقييمات (${_ratingSummary!.totalRatings})',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontFamily: 'Rubik',
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Colors.grey[600],
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
        ),
      ]),

      // ───── Bottom Nav Bar ─────
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 56, // reduced height
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          DesignSystem.primaryGradient.createShader(bounds),
                      child: Text(
                        widget.product.price.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          DesignSystem.primaryGradient.createShader(bounds),
                      child: RiyalIcon(size: 20, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildAddToCartButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() => Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_selectedQuantity > 1) setState(() => _selectedQuantity--);
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: DesignSystem.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.remove_rounded, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$_selectedQuantity',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'Rubik',
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedQuantity++),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: DesignSystem.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),
        ],
      );

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.glassBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.glassBorder,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? AppColors.textInverse : AppColors.textPrimary,
            size: 20,
          ),
        ),
      );

  Widget _buildAddToCartButton() => Material(
        color: Colors.transparent,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: DesignSystem.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: DesignSystem.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              // Add haptic feedback immediately
              HapticFeedback.lightImpact();

              // Show notification immediately (optimistic UI)
              if (mounted) {
                _showCartNotification();
              }

              // Fire and forget cart addition (non-blocking)
              _addToCartAsync();
            },
            child: const Center(
              child: Text(
                'أضف إلى السلة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textInverse,
                  fontFamily: 'Rubik',
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildPlaceholderImage() => Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image_outlined,
              size: 80, color: AppColors.textInverse),
        ),
      );

  // Non-blocking cart addition
  void _addToCartAsync() async {
    try {
      await CartManager.instance.addProduct(
        widget.product.id,
        quantity: _selectedQuantity,
      );
      print('Product added to cart successfully');
    } catch (e) {
      print('Error adding product to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_rounded,
                  color: AppColors.textInverse,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'خطأ في إضافة المنتج إلى السلة',
                  style: const TextStyle(
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // Show cart notification immediately
  void _showCartNotification() {
    if (!mounted) return;

    print('Showing overlay notification for: ${widget.product.name}');

    final overlay = Overlay.of(context);
    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: DesignSystem.primaryGradient,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shopping_cart_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'تم إضافة المنتج للسلة',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.product.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontFamily: 'Rubik',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.product.price.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.attach_money,
                          size: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      print('View cart button tapped from product details');
                      overlayEntry.remove();
                      // Navigate to cart screen
                      Navigator.of(context).pushNamed('/cart');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'عرض السلة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Rubik',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-remove after 2.5 seconds (faster than before)
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
