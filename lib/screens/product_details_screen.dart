// lib/screens/product_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/products.dart';
import '../core/constants/app_colors.dart';
import '../widgets/riyal_icon.dart';

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

  int _selectedQuantity = 1;
  bool _isFavorite = false;

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
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
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
      body: Column(
        children: [
          // Top image section
          Expanded(
            flex: 60,
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
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    right: 16,
                    child: _buildNavButton(
                      icon: _isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      isActive: _isFavorite,
                      onTap: () {
                        setState(() => _isFavorite = !_isFavorite);
                        _scaleController
                          ..reset()
                          ..forward();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Product details section
          Expanded(
            flex: 40,
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

                    // Rating
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: Colors.yellow[700], size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.product.rating}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${widget.product.totalSold} مراجعة)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ],
                    ),
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

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
                          AppColors.primaryGradient.createShader(bounds),
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
                          AppColors.primaryGradient.createShader(bounds),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
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
          child: Icon(icon,
              color: isActive ? AppColors.textInverse : AppColors.textPrimary,
              size: 20),
        ),
      );

  Widget _buildAddToCartButton() => Material(
        color: Colors.transparent,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.textInverse, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Added ${widget.product.name} to cart',
                        style: const TextStyle(
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.all(16),
                ),
              );
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
          child:
              Icon(Icons.image_outlined, size: 80, color: AppColors.textInverse),
        ),
      );
}
