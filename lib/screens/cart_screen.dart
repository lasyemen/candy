import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../blocs/app_bloc.dart';
import '../core/constants/design_system.dart';
import '../core/services/cart_service.dart';
import '../core/services/cart_cache_manager.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';

import '../widgets/riyal_icon.dart';
import 'delivery_location_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late AnimationController _listAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<Offset>> _itemAnimations = [];
  late List<Animation<double>> _itemFadeAnimations = [];
  late List<Animation<double>> _itemScaleAnimations = [];
  bool _showSummaryCard = false;
  List<Map<String, dynamic>> _cartItemsWithProducts = [];
  bool _animationsInitialized = false;
  bool _isFirstLoad = true;
  bool _isLoading = false;
  bool _hasLoadedOnce = false;

  // State preservation is now handled by CartCacheManager

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutQuart),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.1, 0.6, curve: Curves.easeOutQuart),
          ),
        );

    _animationController.forward();

    // Load cart data on init - use cached data if available and valid
    _loadCartData();

    _animationsInitialized = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _animationsInitialized) {
      // Don't reload cart data when app resumes - preserve state
    }
  }

  // Method to manually refresh cart data
  Future<void> _refreshCartData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _loadCartData(forceRefresh: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _triggerItemAnimations() {
    if (_cartItemsWithProducts.isNotEmpty) {
      _initializeItemAnimations(_cartItemsWithProducts.length);
    }
  }

  void _initializeItemAnimations(int itemCount) {
    _itemAnimations.clear();
    _itemFadeAnimations.clear();
    _itemScaleAnimations.clear();

    for (int i = 0; i < itemCount; i++) {
      // Slide animation
      _itemAnimations.add(
        Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _listAnimationController,
            curve: Interval(
              i * 0.12,
              0.4 + (i * 0.12),
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
      );

      // Fade animation
      _itemFadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _listAnimationController,
            curve: Interval(
              i * 0.12,
              0.4 + (i * 0.12),
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
      );

      // Scale animation
      _itemScaleAnimations.add(
        Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: _listAnimationController,
            curve: Interval(
              i * 0.12,
              0.4 + (i * 0.12),
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
      );
    }

    if (_isFirstLoad || _cartItemsWithProducts.length != itemCount) {
      _listAnimationController.reset();
      _listAnimationController.forward();
      _isFirstLoad = false;
    }
  }

  void _updateQuantity(String itemId, int newQuantity) async {
    final appBloc = context.read<AppBloc>();
    HapticFeedback.lightImpact();

    print('=== UPDATE QUANTITY DEBUG ===');
    print(
      '_updateQuantity called with itemId: $itemId, newQuantity: $newQuantity',
    );
    print('Current cart items count: ${_cartItemsWithProducts.length}');

    if (itemId.isEmpty || itemId == 'null') {
      print('Error: Invalid item ID provided');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ: معرف المنتج غير صحيح'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      if (itemId.startsWith('temp_')) {
        print('Handling temporary item ID: $itemId');
        final itemIndex = _cartItemsWithProducts.indexWhere(
          (item) =>
              item['product_id']?.toString() == itemId.split('_')[1] ||
              item['id']?.toString() == itemId,
        );

        print('Found item at index: $itemIndex');

        if (itemIndex != -1) {
          final actualItem = _cartItemsWithProducts[itemIndex];
          final actualItemId =
              actualItem['id']?.toString() ??
              actualItem['product_id']?.toString() ??
              itemId;
          final productId = actualItem['product_id']?.toString() ?? itemId;

          print('Actual item ID: $actualItemId');
          print('Product ID: $productId');

          if (newQuantity <= 0) {
            print('Removing item with quantity <= 0');
            await CartManager.instance.removeProduct(actualItemId);
            appBloc.add(RemoveFromCartEvent(productId));
          } else {
            print('Updating quantity to: $newQuantity');
            await CartManager.instance.updateQuantity(
              actualItemId,
              newQuantity,
            );
            appBloc.add(UpdateCartItemQuantityEvent(productId, newQuantity));
          }
        } else {
          throw Exception('Item not found in cart');
        }
      } else {
        print('Handling regular item ID: $itemId');

        final itemIndex = _cartItemsWithProducts.indexWhere(
          (item) => item['id']?.toString() == itemId,
        );

        print('Found item at index: $itemIndex');

        String productId = itemId;
        if (itemIndex != -1) {
          productId =
              _cartItemsWithProducts[itemIndex]['product_id']?.toString() ??
              itemId;
          print('Product ID found: $productId');
        } else {
          print('Item not found in cart items, using itemId as productId');
        }

        await CartManager.instance.updateQuantity(itemId, newQuantity);
        print('CartManager updateQuantity completed successfully');

        if (newQuantity <= 0) {
          print('Removing item from app bloc');
          appBloc.add(RemoveFromCartEvent(productId));
        } else {
          print('Updating item quantity in app bloc');
          appBloc.add(UpdateCartItemQuantityEvent(productId, newQuantity));
        }
      }

      // Update local state immediately for better UX
      _updateLocalCartState(itemId, newQuantity);

      // Reload cart data to reflect changes
      await _loadCartData();
      print('=== UPDATE QUANTITY SUCCESS ===');
    } catch (e) {
      print('=== UPDATE QUANTITY ERROR ===');
      print('Error updating quantity: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الكمية: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Update local cart state immediately for better UX
  void _updateLocalCartState(String itemId, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        // Remove item
        _cartItemsWithProducts.removeWhere(
          (item) =>
              item['id']?.toString() == itemId ||
              item['product_id']?.toString() == itemId,
        );
      } else {
        // Update quantity
        final itemIndex = _cartItemsWithProducts.indexWhere(
          (item) =>
              item['id']?.toString() == itemId ||
              item['product_id']?.toString() == itemId,
        );
        if (itemIndex != -1) {
          _cartItemsWithProducts[itemIndex]['quantity'] = newQuantity;
        }
      }
    });

    // Update cache asynchronously
    _updateCartCache();
  }

  // Update cart cache with current state
  Future<void> _updateCartCache() async {
    await CartCacheManager.instance.updateCache(_cartItemsWithProducts);
  }

  // Check if cached data is still valid
  Future<bool> _isCacheValid() async {
    return await CartCacheManager.instance.isCacheValid();
  }

  // Invalidate cache when items are added from other screens
  static Future<void> invalidateCache() async {
    await CartCacheManager.instance.invalidateCache();
  }

  // Clear cache completely
  static Future<void> clearCache() async {
    await CartCacheManager.instance.clearCache();
  }

  Future<void> _loadCartData({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    // Use cached data if available and valid, unless force refresh is requested
    if (!forceRefresh) {
      final isCacheValid = await _isCacheValid();
      final cachedItems = await CartCacheManager.instance.getCachedCartItems();

      if (isCacheValid && cachedItems.isNotEmpty) {
        setState(() {
          _cartItemsWithProducts = cachedItems;
          _hasLoadedOnce = true;
          _isLoading = false;
        });

        if (_cartItemsWithProducts.isNotEmpty) {
          _triggerItemAnimations();
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('CartScreen - Loading cart data...');

      await CartService.initializeCartSession();

      final cartSummary = await CartManager.instance.getCartSummary();
      print('CartScreen - Cart summary: $cartSummary');
      print(
        'CartScreen - Items in summary: ${cartSummary['items']?.length ?? 0}',
      );

      if (mounted) {
        final newCartItems = List<Map<String, dynamic>>.from(
          cartSummary['items'] ?? [],
        );

        if (_cartItemsWithProducts.length != newCartItems.length ||
            !_areCartItemsEqual(_cartItemsWithProducts, newCartItems)) {
          setState(() {
            _cartItemsWithProducts = newCartItems;
            _hasLoadedOnce = true;
            print(
              'CartScreen - Updated cart items: ${_cartItemsWithProducts.length} items',
            );

            if (_cartItemsWithProducts.isNotEmpty) {
              _triggerItemAnimations();
            }

            for (int i = 0; i < _cartItemsWithProducts.length; i++) {
              final item = _cartItemsWithProducts[i];
              print(
                'CartScreen - Item $i: ${item['product_id']} x${item['quantity']}',
              );
              print('CartScreen - Item $i structure: ${item.keys.toList()}');
              print('CartScreen - Item $i ID: ${item['id']}');
              print('CartScreen - Item $i product_id: ${item['product_id']}');
            }
          });

          // Update cache with new data
          await _updateCartCache();
        }
      }
    } catch (e) {
      print('CartScreen - Error loading cart data: $e');

      if (!_hasLoadedOnce) {
        try {
          await CartService.initializeCartSession();
          final cartSummary = await CartManager.instance.getCartSummary();
          if (mounted) {
            setState(() {
              _cartItemsWithProducts = List<Map<String, dynamic>>.from(
                cartSummary['items'] ?? [],
              );
              _hasLoadedOnce = true;
            });

            // Update cache with fallback data
            await _updateCartCache();
          }
        } catch (retryError) {
          print('CartScreen - Error retrying cart data load: $retryError');
          if (mounted) {
            setState(() {
              _hasLoadedOnce = true;
            });
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'لا يمكن تحميل السلة حالياً. تحقق من اتصالك بالإنترنت.',
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.all(20),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _areCartItemsEqual(
    List<Map<String, dynamic>> oldItems,
    List<Map<String, dynamic>> newItems,
  ) {
    if (oldItems.length != newItems.length) return false;

    for (int i = 0; i < oldItems.length; i++) {
      final oldItem = oldItems[i];
      final newItem = newItems[i];

      if (oldItem['id'] != newItem['id'] ||
          oldItem['quantity'] != newItem['quantity'] ||
          oldItem['product_id'] != newItem['product_id']) {
        return false;
      }
    }
    return true;
  }

  void _resetCartState() {
    setState(() {
      _cartItemsWithProducts = [];
      _hasLoadedOnce = false;
      _isLoading = false;
    });
    _loadCartData();
  }

  void _debugCartState() {
    print('=== CART STATE DEBUG ===');
    print('Cart items count: ${_cartItemsWithProducts.length}');
    print('Has loaded once: $_hasLoadedOnce');
    print('Is loading: $_isLoading');
    print('Is first load: $_isFirstLoad');
    print('Animations initialized: $_animationsInitialized');
    print('Show summary card: $_showSummaryCard');

    for (int i = 0; i < _cartItemsWithProducts.length; i++) {
      final item = _cartItemsWithProducts[i];
      print(
        'Item $i: ID=${item['id']}, ProductID=${item['product_id']}, Quantity=${item['quantity']}',
      );
    }
    print('=== END CART STATE DEBUG ===');
  }

  void _debugCartItemStructure() {
    print('CartScreen - Debugging cart item structure:');
    for (int i = 0; i < _cartItemsWithProducts.length; i++) {
      final item = _cartItemsWithProducts[i];
      print('Item $i:');
      print('  Keys: ${item.keys.toList()}');
      print('  ID: ${item['id']} (type: ${item['id']?.runtimeType})');
      print(
        '  Product ID: ${item['product_id']} (type: ${item['product_id']?.runtimeType})',
      );
      print(
        '  Quantity: ${item['quantity']} (type: ${item['quantity']?.runtimeType})',
      );
      if (item['products'] != null) {
        print('  Product: ${item['products']}');
      }
      print('  ---');
    }
  }

  void _showCartSummaryFromItems() {
    setState(() {
      _showSummaryCard = !_showSummaryCard;
    });
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

  void _removeItem(String itemId) async {
    final appBloc = context.read<AppBloc>();
    HapticFeedback.mediumImpact();

    print('_removeItem called with itemId: $itemId');

    if (itemId.isEmpty || itemId == 'null') {
      print('Error: Invalid item ID provided for removal');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ: معرف المنتج غير صحيح'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Update local state immediately for better UX
      _updateLocalCartState(itemId, 0); // 0 quantity means remove

      if (itemId.startsWith('temp_')) {
        print('Handling temporary item ID for removal: $itemId');
        final itemIndex = _cartItemsWithProducts.indexWhere(
          (item) =>
              item['product_id']?.toString() == itemId.split('_')[1] ||
              item['id']?.toString() == itemId,
        );

        if (itemIndex != -1) {
          final actualItem = _cartItemsWithProducts[itemIndex];
          final actualItemId =
              actualItem['id']?.toString() ??
              actualItem['product_id']?.toString() ??
              itemId;
          final productId = actualItem['product_id']?.toString() ?? itemId;

          await CartManager.instance.removeProduct(actualItemId);
          appBloc.add(RemoveFromCartEvent(productId));
        } else {
          throw Exception('Item not found in cart for removal');
        }
      } else {
        await CartManager.instance.removeProduct(itemId);
        appBloc.add(RemoveFromCartEvent(itemId));
      }

      // Reload cart data to reflect changes
      await _loadCartData();

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(20),
          elevation: 8,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error removing item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إزالة المنتج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Load cart items with product details
  Future<void> _loadCartItemsWithProducts(String cartId) async {
    try {
      final cartItemsWithProducts = await CartService.getCartItemsWithProducts(
        cartId,
      );
      // Store the cart items with products for display
      setState(() {
        _cartItemsWithProducts = cartItemsWithProducts;
      });
    } catch (e) {
      print('Error loading cart items with products: $e');
    }
  }

  // Helper method to get product name
  String _getProductName(String productId) {
    final item = _cartItemsWithProducts.firstWhere(
      (item) => item['product_id'] == productId,
      orElse: () => {
        'products': {'name': 'مياه كاندي'},
      },
    );
    return item['products']?['name'] ?? 'مياه كاندي';
  }

  // Helper method to get product price
  double _getProductPrice(String productId) {
    final item = _cartItemsWithProducts.firstWhere(
      (item) => item['product_id'] == productId,
      orElse: () => {
        'products': {'price': 5.0},
      },
    );
    return (item['products']?['price'] ?? 5.0).toDouble();
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
    // Debug cart state when screen is built
    _debugCartState();

    // Debug cart item structure when screen is built
    if (_cartItemsWithProducts.isNotEmpty) {
      _debugCartItemStructure();
    }

    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: DesignSystem.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        if (_cartItemsWithProducts.isNotEmpty)
                          Text(
                            '${_cartItemsWithProducts.length} منتج',
                            style: DesignSystem.bodySmall.copyWith(
                              color: DesignSystem.textSecondary,
                              fontFamily: 'Rubik',
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_cartItemsWithProducts.isNotEmpty)
                    IconButton(
                      onPressed: () => _showCartSummaryFromItems(),
                      icon: ShaderMask(
                        shaderCallback: (bounds) =>
                            DesignSystem.primaryGradient.createShader(bounds),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshCartData();
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _isLoading && !_hasLoadedOnce
                ? _buildLoadingState()
                : _cartItemsWithProducts.isEmpty
                ? _buildEmptyCart()
                : _buildCartContentFromItems(),
          ),
        ),
      ),
    );
  }

  Widget _buildCartContentFromItems() {
    // Calculate total
    double cartTotal = 0;
    for (final item in _cartItemsWithProducts) {
      final quantity = item['quantity'] as int;
      final product = item['products'] as Map<String, dynamic>?;
      if (product != null) {
        final price = product['price'] as double? ?? 0.0;
        cartTotal += quantity * price;
      }
    }

    return Stack(
      children: [
        ListView.builder(
          // Changed from ListView.separated for better performance
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: _cartItemsWithProducts.length,
          itemBuilder: (context, index) {
            final cartItem = _cartItemsWithProducts[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _cartItemsWithProducts.length - 1 ? 16 : 0,
              ),
              child: SlideTransition(
                position:
                    _itemAnimations.isNotEmpty && index < _itemAnimations.length
                    ? _itemAnimations[index]
                    : AlwaysStoppedAnimation(Offset.zero),
                child: FadeTransition(
                  opacity:
                      _itemFadeAnimations.isNotEmpty &&
                          index < _itemFadeAnimations.length
                      ? _itemFadeAnimations[index]
                      : AlwaysStoppedAnimation(1.0),
                  child: ScaleTransition(
                    scale:
                        _itemScaleAnimations.isNotEmpty &&
                            index < _itemScaleAnimations.length
                        ? _itemScaleAnimations[index]
                        : AlwaysStoppedAnimation(1.0),
                    child: _buildCartItemFromMap(cartItem, index),
                  ),
                ),
              ),
            );
          },
        ),
        // Floating total card with slide-up animation
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200), // Faster animation
          curve: Curves.easeOutQuart, // More responsive curve
          bottom: _showSummaryCard ? 100 : -200, // Slide up from bottom
          left: 10,
          right: 10,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200), // Faster opacity
            opacity: _showSummaryCard ? 1.0 : 0.0,
            child: _buildSummaryCardContentFromItems(cartTotal),
          ),
        ),
      ],
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

  Widget _buildLoadingState() {
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
              child: SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DesignSystem.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'جاري تحميل السلة...',
              style: DesignSystem.headlineMedium.copyWith(
                color: DesignSystem.textPrimary,
                fontWeight: FontWeight.bold,
                fontFamily: 'Rubik',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'يرجى الانتظار بينما نقوم بتحميل محتويات سلة التسوق',
              style: DesignSystem.bodyLarge.copyWith(
                color: DesignSystem.textSecondary,
                fontFamily: 'Rubik',
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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

  Widget _buildCartItemFromMap(Map<String, dynamic> cartItem, int index) {
    final product = cartItem['products'] as Map<String, dynamic>?;
    final productName = product?['name'] ?? 'Product';
    final productPrice = product?['price'] as double? ?? 0.0;
    final productImage = product?['image_url'] as String?;
    final quantity = cartItem['quantity'] as int;

    // Improved item ID extraction with fallback
    String itemId = '';
    if (cartItem['id'] != null && cartItem['id'].toString().isNotEmpty) {
      itemId = cartItem['id'].toString();
    } else if (cartItem['product_id'] != null) {
      // Use product_id as fallback for local items
      itemId = cartItem['product_id'].toString();
    } else {
      // Generate a temporary ID if neither exists
      itemId = 'temp_${index}_${DateTime.now().millisecondsSinceEpoch}';
    }

    print(
      'Building cart item: itemId=$itemId, quantity=$quantity, productName=$productName',
    );
    print('Cart item structure: ${cartItem.keys.toList()}');

    return AnimatedContainer(
      // Added AnimatedContainer for smooth transitions
      duration: const Duration(
        milliseconds: 300,
      ), // Slightly longer for smoother feel
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Dismissible(
        key: Key(itemId),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white, size: 30),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  'حذف المنتج',
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  'هل أنت متأكد من حذف هذا المنتج من السلة؟',
                  style: TextStyle(fontFamily: 'Rubik'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(fontFamily: 'Rubik', color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'حذف',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) {
          _removeItem(itemId);
        },
        child: Row(
          children: [
            // Product Image (kept in original place)
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: productImage != null && productImage.isNotEmpty
                    ? Image.network(
                        productImage,
                        width: 85,
                        height: 85,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: DesignSystem.getBrandGradient(
                                'primary',
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Icon(
                                FontAwesomeIcons.droplet,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: DesignSystem.getBrandGradient('primary'),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Icon(
                            FontAwesomeIcons.droplet,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
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
                    productName,
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
                        productPrice.toStringAsFixed(2),
                        style: DesignSystem.bodyLarge.copyWith(
                          color: DesignSystem.primary,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Rubik',
                        ),
                      ),
                      const SizedBox(width: 4),
                      const RiyalIcon(size: 14, color: DesignSystem.primary),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Quantity Controls on the right (which appears as left in RTL)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuantityButton(
                  icon: Icons.remove,
                  onPressed: () {
                    print(
                      'Decrease button pressed for item: $itemId, current quantity: $quantity',
                    );
                    print(
                      'Item ID type: ${itemId.runtimeType}, value: "$itemId"',
                    );
                    _updateQuantity(itemId, quantity - 1);
                  },
                  isDecrease: true,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    quantity.toString(),
                    style: DesignSystem.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
                _buildQuantityButton(
                  icon: Icons.add,
                  onPressed: () {
                    print(
                      'Increase button pressed for item: $itemId, current quantity: $quantity',
                    );
                    print(
                      'Item ID type: ${itemId.runtimeType}, value: "$itemId"',
                    );
                    _updateQuantity(itemId, quantity + 1);
                  },
                  isDecrease: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCardContentFromItems(double cartTotal) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المجموع الكلي',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Rubik',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_cartItemsWithProducts.length} منتج',
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
                  fontSize: 24,
                ),
              ),
              const SizedBox(width: 8),
              const RiyalIcon(size: 24, color: Colors.white),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 160, // Further reduced width
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
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Rubik',
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: DesignSystem.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem cartItem, int index) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Container(
                decoration: BoxDecoration(
                  gradient: DesignSystem.getBrandGradient('primary'),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Icon(
                    FontAwesomeIcons.droplet,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getProductName(cartItem.productId),
                  style: DesignSystem.titleMedium.copyWith(
                    color: DesignSystem.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Rubik',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _getProductPrice(cartItem.productId).toStringAsFixed(2),
                      style: DesignSystem.bodyLarge.copyWith(
                        color: DesignSystem.primary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Rubik',
                      ),
                    ),
                    const SizedBox(width: 4),
                    const RiyalIcon(size: 14, color: DesignSystem.primary),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 12),

                // Quantity Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                        horizontal: 12,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
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

          const SizedBox(width: 8),

          // Total Price & Info
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showProductInfo(cartItem),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: DesignSystem.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: DesignSystem.primary,
                    size: 14,
                  ),
                ),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignSystem.primary.withOpacity(0.15),
                      DesignSystem.primary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(cartItem.quantity * 5.0).toStringAsFixed(2)}',
                      style: DesignSystem.labelLarge.copyWith(
                        color: DesignSystem.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Rubik',
                      ),
                    ),
                    const SizedBox(width: 2),
                    const RiyalIcon(size: 10, color: DesignSystem.primary),
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
    return AnimatedContainer(
      // Added AnimatedContainer for smooth button transitions
      duration: const Duration(
        milliseconds: 200,
      ), // Slightly longer for smoother feel
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTap: () {
          print('Button tapped: ${isDecrease ? "decrease" : "increase"}');
          onPressed();
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: DesignSystem.getBrandGradient('primary'),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: DesignSystem.primary.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 16, color: Colors.white),
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
