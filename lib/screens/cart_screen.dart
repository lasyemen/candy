import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../blocs/app_bloc.dart';
import '../core/constants/design_system.dart';
import '../models/cart.dart';

import '../widgets/riyal_icon.dart';
import 'delivery_location_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _listAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<Offset>> _itemAnimations = [];
  bool _showSummaryCard = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  void _initializeItemAnimations(int itemCount) {
    _itemAnimations.clear();
    for (int i = 0; i < itemCount; i++) {
      _itemAnimations.add(
        Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _listAnimationController,
            curve: Interval(
              i * 0.1,
              0.5 + (i * 0.1),
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
      );
    }
    _listAnimationController.forward();
  }

  void _updateQuantity(String productId, int newQuantity) {
    final appBloc = context.read<AppBloc>();
    HapticFeedback.lightImpact();

    if (newQuantity <= 0) {
      appBloc.add(RemoveFromCartEvent(productId));
    } else {
      appBloc.add(UpdateCartItemQuantityEvent(productId, newQuantity));
    }
  }

  void _showCartDetails(List<CartItem> cartItems, double cartTotal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignSystem.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: DesignSystem.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'تفاصيل السلة',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Items breakdown
              ...cartItems
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'مياه ${item.productId}',
                              style: TextStyle(
                                fontFamily: 'Rubik',
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${item.quantity} × 5.00',
                                style: TextStyle(
                                  fontFamily: 'Rubik',
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 4),
                              const RiyalIcon(size: 12, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              const Divider(height: 20),
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المجموع الكلي',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        cartTotal.toStringAsFixed(2),
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DesignSystem.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const RiyalIcon(size: 16, color: Colors.orange),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إغلاق',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _removeItem(String productId) {
    final appBloc = context.read<AppBloc>();
    HapticFeedback.mediumImpact();
    appBloc.add(RemoveFromCartEvent(productId));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(FontAwesomeIcons.check, color: Colors.white, size: 16),
            const SizedBox(width: 12),
            Text(
              'تم حذف المنتج من السلة',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignSystem.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                FontAwesomeIcons.exclamationTriangle,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'مسح جميع المنتجات',
              style: DesignSystem.headlineSmall.copyWith(
                fontFamily: 'Rubik',
                fontWeight: FontWeight.bold,
                color: DesignSystem.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'هل أنت متأكد من رغبتك في حذف جميع المنتجات من السلة؟ لا يمكن التراجع عن هذا الإجراء.',
              style: DesignSystem.bodyMedium.copyWith(
                fontFamily: 'Rubik',
                color: DesignSystem.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: DesignSystem.textSecondary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.w600,
                        color: DesignSystem.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final appBloc = context.read<AppBloc>();
                      appBloc.add(ClearCartEvent());
                      Navigator.pop(context);
                      HapticFeedback.mediumImpact();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'حذف الكل',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppBloc>(
      builder: (context, appBloc, child) {
        final cartItems = appBloc.cart?.items ?? [];
        final cartTotal = appBloc.cartTotal;

        if (cartItems.isNotEmpty &&
            _itemAnimations.length != cartItems.length) {
          _initializeItemAnimations(cartItems.length);
        }

        return Scaffold(
          backgroundColor: DesignSystem.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'سلة التسوق',
                              style: DesignSystem.headlineSmall.copyWith(
                                color: DesignSystem.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Rubik',
                              ),
                            ),
                            if (cartItems.isNotEmpty)
                              Text(
                                '${cartItems.length} منتج',
                                style: DesignSystem.bodySmall.copyWith(
                                  color: DesignSystem.textSecondary,
                                  fontFamily: 'Rubik',
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (cartItems.isNotEmpty)
                        IconButton(
                          onPressed: () =>
                              _showCartSummary(cartItems, cartTotal),
                          icon: ShaderMask(
                            shaderCallback: (bounds) => DesignSystem
                                .primaryGradient
                                .createShader(bounds),
                            child: Icon(
                              Icons.receipt_long,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: cartItems.isEmpty
                  ? _buildEmptyCart()
                  : _buildCartContent(cartItems, cartTotal),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartContent(List<CartItem> cartItems, double cartTotal) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: cartItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final cartItem = cartItems[index];
        return SlideTransition(
          position: _itemAnimations.isNotEmpty && index < _itemAnimations.length
              ? _itemAnimations[index]
              : AlwaysStoppedAnimation(Offset.zero),
          child: _buildCartItem(cartItem, index),
        );
      },
    );
  }

  Widget _buildSummaryCardContent(List<CartItem> cartItems, double cartTotal) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  DesignSystem.primaryGradient.createShader(bounds),
              child: Text(
                'المجموع الكلي',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Rubik',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${cartItems.length} منتج',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Rubik',
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              cartTotal.toStringAsFixed(2),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Rubik',
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            const RiyalIcon(size: 24, color: Colors.white),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeliveryLocationScreen(),
                ),
              );
            },
            icon: Icon(FontAwesomeIcons.creditCard, size: 18),
            label: ShaderMask(
              shaderCallback: (bounds) =>
                  DesignSystem.primaryGradient.createShader(bounds),
              child: Text(
                'المتابعة للدفع',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Rubik',
                  color: Colors.white,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: DesignSystem.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              shadowColor: DesignSystem.secondary.withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }

  void _showCartSummary(List<CartItem> cartItems, double cartTotal) {
    if (_showSummaryCard) {
      setState(() {
        _showSummaryCard = false;
      });
    } else {
      _showSummaryOverlay(cartItems, cartTotal);
    }
  }

  void _showSummaryOverlay(List<CartItem> cartItems, double cartTotal) {
    final overlay = Overlay.of(context);
    late final OverlayEntry overlayEntry;
    bool isVisible = false;

    overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          // Dismiss when tapping anywhere
          isVisible = false;
          overlayEntry.markNeedsBuild();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (overlayEntry.mounted) {
              overlayEntry.remove();
            }
          });
        },
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                bottom: 120, // Position above the navigation bar
                left: 20,
                right: 20,
                child: Material(
                  color: Colors.transparent,
                  elevation: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    transform: Matrix4.translationValues(
                      0,
                      isVisible ? 0 : 200, // Slide up from bottom
                      0,
                    ),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: isVisible ? 1.0 : 0.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        decoration: BoxDecoration(
                          gradient: DesignSystem.getBrandGradient('primary'),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: _buildSummaryCardContent(cartItems, cartTotal),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Start appearing animation
    Future.delayed(const Duration(milliseconds: 50), () {
      if (overlayEntry.mounted) {
        isVisible = true;
        overlayEntry.markNeedsBuild();
      }
    });

    // Auto remove after 5 seconds with disappearing animation
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        isVisible = false;
        overlayEntry.markNeedsBuild();

        // Remove after animation completes
        Future.delayed(const Duration(milliseconds: 300), () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        });
      }
    });
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DesignSystem.surface,
                    DesignSystem.surface.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: DesignSystem.primary.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                FontAwesomeIcons.cartShopping,
                size: 80,
                color: DesignSystem.textSecondary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'السلة فارغة',
              style: DesignSystem.headlineMedium.copyWith(
                color: DesignSystem.textPrimary,
                fontWeight: FontWeight.bold,
                fontFamily: 'Rubik',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'ابدأ بإضافة منتجات المياه المفضلة لديك\nإلى سلة التسوق',
              style: DesignSystem.bodyLarge.copyWith(
                color: DesignSystem.textSecondary,
                fontFamily: 'Rubik',
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                gradient: DesignSystem.getBrandGradient('primary'),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: DesignSystem.primary.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final appBloc = context.read<AppBloc>();
                  appBloc.add(SetCurrentIndexEvent(2)); // Home is index 2
                },
                icon: Icon(FontAwesomeIcons.magnifyingGlass, size: 18),
                label: Text(
                  'تصفح المنتجات',
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem cartItem, int index) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: DesignSystem.getBrandGradient('primary'),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: DesignSystem.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                FontAwesomeIcons.droplet,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مياه ${cartItem.productId}', // Using productId since we don't have product details
                  style: DesignSystem.titleMedium.copyWith(
                    color: DesignSystem.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Rubik',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '5.00', // Mock price since we don't have product details
                      style: DesignSystem.bodyLarge.copyWith(
                        color: DesignSystem.primary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Rubik',
                      ),
                    ),
                    const SizedBox(width: 4),
                    const RiyalIcon(size: 14, color: DesignSystem.primary),
                    const SizedBox(width: 8),
                    Text(
                      '/ الوحدة',
                      style: DesignSystem.bodySmall.copyWith(
                        color: DesignSystem.textSecondary,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quantity Controls
                Row(
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onPressed: () => _updateQuantity(
                        cartItem.productId,
                        cartItem.quantity - 1,
                      ),
                      isDecrease: true,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DesignSystem.primary.withOpacity(0.1),
                            DesignSystem.primary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${cartItem.quantity}',
                        style: DesignSystem.titleMedium.copyWith(
                          color: DesignSystem.primary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Rubik',
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add,
                      onPressed: () => _updateQuantity(
                        cartItem.productId,
                        cartItem.quantity + 1,
                      ),
                      isDecrease: false,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total Price & Info
          Column(
            children: [
              IconButton(
                onPressed: () => _showProductInfo(cartItem),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DesignSystem.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: DesignSystem.primary,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignSystem.primary.withOpacity(0.15),
                      DesignSystem.primary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(cartItem.quantity * 5.0).toStringAsFixed(2)}', // Calculate total price
                      style: DesignSystem.labelLarge.copyWith(
                        color: DesignSystem.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Rubik',
                      ),
                    ),
                    const SizedBox(width: 4),
                    const RiyalIcon(size: 12, color: DesignSystem.primary),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDecrease,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: isDecrease
              ? LinearGradient(
                  colors: [
                    DesignSystem.background,
                    DesignSystem.background.withOpacity(0.8),
                  ],
                )
              : DesignSystem.getBrandGradient('primary'),
          borderRadius: BorderRadius.circular(12),
          border: isDecrease
              ? Border.all(
                  color: DesignSystem.textSecondary.withOpacity(0.2),
                  width: 1,
                )
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDecrease ? DesignSystem.textSecondary : Colors.white,
        ),
      ),
    );
  }

  void _showProductInfo(CartItem cartItem) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignSystem.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: DesignSystem.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'تفاصيل المنتج',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: DesignSystem.getBrandGradient('primary'),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: DesignSystem.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      FontAwesomeIcons.droplet,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Product Name
              Text(
                'مياه ${cartItem.productId}', // Using productId since we don't have product details
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'السعر:',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '5.00', // Mock price since we don't have product details
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DesignSystem.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const RiyalIcon(size: 16, color: Colors.orange),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Quantity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الكمية المطلوبة:',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '${cartItem.quantity}',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DesignSystem.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Total for this item
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المجموع:',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${(cartItem.quantity * 5.0).toStringAsFixed(2)}', // Calculate total price
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DesignSystem.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const RiyalIcon(size: 16, color: Colors.orange),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'إغلاق',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
