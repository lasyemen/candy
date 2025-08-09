import '../../models/cart.dart';
import '../../models/cart_item.dart';
import 'supabase_service.dart';
import 'customer_session.dart';
import 'cart_session_manager.dart';
import 'cart_cache_manager.dart';
import 'dart:math';

class CartService {
  // Session management for guests
  static String? _guestSessionId;

  // Get or create guest session ID
  static String getGuestSessionId() {
    if (_guestSessionId == null) {
      _guestSessionId = _generateSessionId();
    }
    return _guestSessionId!;
  }

  // Generate unique session ID for guests
  static String _generateSessionId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return 'guest_${List.generate(16, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  // Clear guest session
  static void clearGuestSession() {
    _guestSessionId = null;
  }

  // Get current session identifier (user ID or guest session ID)
  static String? getCurrentSessionId() {
    if (CustomerSession.instance.isLoggedIn) {
      return CustomerSession.instance.currentCustomerId;
    } else {
      return getGuestSessionId();
    }
  }

  // Initialize cart session
  static Future<void> initializeCartSession() async {
    await CartSessionManager.instance.initializeSession();
  }

  // Get or create active cart for current session
  static Future<Cart> getOrCreateActiveCart() async {
    try {
      await CartSessionManager.instance.initializeSession();

      if (CustomerSession.instance.isLoggedIn) {
        return await _getOrCreateCustomerCart();
      } else {
        // For guests, we'll use a temporary approach since there's no session_id column
        // We'll create a cart with a temporary customer_id based on session
        return await _getOrCreateGuestCart();
      }
    } catch (e) {
      print('CartService - Error getting or creating active cart: $e');
      throw Exception('Error getting or creating active cart: $e');
    }
  }

  // Get or create cart for logged-in customer
  static Future<Cart> _getOrCreateCustomerCart() async {
    try {
      final customerId = CustomerSession.instance.currentCustomerId;
      if (customerId == null) {
        throw Exception('No customer logged in');
      }

      print('CartService - Getting or creating cart for customer: $customerId');

      // Try to get existing cart
      final existingCart = await SupabaseService.instance.client
          .from('carts')
          .select('*')
          .eq('customer_id', customerId)
          .maybeSingle();

      if (existingCart != null) {
        print('CartService - Found existing cart: ${existingCart['id']}');
        return Cart.fromJson(existingCart);
      }

      // Create new cart
      print('CartService - Creating new cart for customer: $customerId');
      final response = await SupabaseService.instance.client
          .from('carts')
          .insert({
            'customer_id': customerId,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      print('CartService - Created new cart: ${response['id']}');
      return Cart.fromJson(response);
    } catch (e) {
      print('CartService - Error in _getOrCreateCustomerCart: $e');
      throw Exception('Error creating customer cart: $e');
    }
  }

  // Get or create cart for guest session
  static Future<Cart> _getOrCreateGuestCart() async {
    try {
      final sessionId = getGuestSessionId();
      print(
        'CartService - Getting or creating cart for guest session: $sessionId',
      );

      // For guests, we'll use the session ID as a temporary customer_id
      // This is a workaround since there's no session_id column
      final tempCustomerId = 'temp_$sessionId';

      // Try to get existing cart for this temporary customer
      final existingCart = await SupabaseService.instance.client
          .from('carts')
          .select('*')
          .eq('customer_id', tempCustomerId)
          .maybeSingle();

      if (existingCart != null) {
        print('CartService - Found existing guest cart: ${existingCart['id']}');
        return Cart.fromJson(existingCart);
      }

      // Create new cart for guest
      print('CartService - Creating new cart for guest session: $sessionId');
      final response = await SupabaseService.instance.client
          .from('carts')
          .insert({
            'customer_id': tempCustomerId,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      print('CartService - Created new guest cart: ${response['id']}');
      return Cart.fromJson(response);
    } catch (e) {
      print('CartService - Error in _getOrCreateGuestCart: $e');
      throw Exception('Error creating guest cart: $e');
    }
  }

  // Create a basic guest user if none exists
  static Future<void> createBasicGuestUser() async {
    try {
      // Check if guest user already exists
      final existingGuest = await CustomerSession.instance.guestUser;
      if (existingGuest != null) {
        print('CartService - Guest user already exists');
        return;
      }

      // Create a basic guest user
      await CustomerSession.instance.setGuestUser(
        name: 'Guest User',
        phone: '', // Will be filled in later
        address: null,
      );

      print('CartService - Basic guest user created');
    } catch (e) {
      print('CartService - Error creating basic guest user: $e');
    }
  }

  // Merge guest cart into user cart when guest logs in
  static Future<void> mergeGuestCartIntoUserCart(String customerId) async {
    try {
      await CartSessionManager.instance.mergeGuestCartIntoUserCart();
      print('CartService - Successfully merged guest cart into user cart');
    } catch (e) {
      print('CartService - Error merging guest cart: $e');
      throw Exception('Error merging guest cart: $e');
    }
  }

  // Get cart for current customer
  static Future<Cart?> getCurrentCustomerCart() async {
    try {
      final customerPhone = CustomerSession.instance.currentCustomerPhone;
      if (customerPhone == null) {
        print('CartService - No customer logged in');
        return null;
      }

      print('CartService - Getting cart for customer phone: $customerPhone');

      // First, get the customer ID from phone number
      final customerResponse = await SupabaseService.instance.client
          .from('customers')
          .select('id')
          .eq('phone', customerPhone)
          .single();

      final customerId = customerResponse['id'];
      print('CartService - Customer ID: $customerId');

      final response = await SupabaseService.instance.client
          .from('carts')
          .select('*, cart_items(*)')
          .eq('customer_id', customerId)
          .single();

      print('CartService - Cart retrieved successfully: ${response}');
      return Cart.fromJson(response);
    } catch (e) {
      print('CartService - Error getting cart: $e');
      return null;
    }
  }

  // Get cart for a customer by phone
  static Future<Cart?> getCartByPhone(String customerPhone) async {
    try {
      print('CartService - Getting cart for customer phone: $customerPhone');

      // First, get the customer ID from phone number
      final customerResponse = await SupabaseService.instance.client
          .from('customers')
          .select('id')
          .eq('phone', customerPhone)
          .single();

      final customerId = customerResponse['id'];
      print('CartService - Customer ID: $customerId');

      final response = await SupabaseService.instance.client
          .from('carts')
          .select('*, cart_items(*)')
          .eq('customer_id', customerId)
          .eq('status', 'active')
          .single();

      print('CartService - Cart retrieved successfully: ${response}');
      return Cart.fromJson(response);
    } catch (e) {
      print('CartService - Error getting cart: $e');
      return null;
    }
  }

  // Create a new cart for current customer
  static Future<Cart> createCartForCurrentCustomer() async {
    try {
      final customerPhone = CustomerSession.instance.currentCustomerPhone;
      if (customerPhone == null) {
        throw Exception('No customer logged in');
      }

      print('CartService - Creating cart for customer phone: $customerPhone');

      // First, get the customer ID from phone number
      final customerResponse = await SupabaseService.instance.client
          .from('customers')
          .select('id')
          .eq('phone', customerPhone)
          .single();

      final customerId = customerResponse['id'];
      print('CartService - Customer ID: $customerId');

      final response = await SupabaseService.instance.client
          .from('carts')
          .insert({
            'customer_id': customerId,
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      print('CartService - Cart created successfully: ${response}');
      return Cart.fromJson(response);
    } catch (e) {
      print('CartService - Error creating cart: $e');
      throw Exception('Error creating cart: $e');
    }
  }

  // Create a new cart
  static Future<Cart> createCart(String customerId) async {
    try {
      print('CartService - Creating cart for customer: $customerId');

      final response = await SupabaseService.instance.client
          .from('carts')
          .insert({
            'customer_id': customerId,
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      print('CartService - Cart created successfully: ${response}');
      return Cart.fromJson(response);
    } catch (e) {
      print('CartService - Error creating cart: $e');
      throw Exception('Error creating cart: $e');
    }
  }

  // Add item to current session's cart
  static Future<CartItem> addToCurrentCart(
    String productId,
    int quantity,
  ) async {
    try {
      await CartSessionManager.instance.addItem(productId, quantity: quantity);

      // Get the cart item that was just added
      final cart = await getOrCreateActiveCart();
      final items = await getCartItemsWithProducts(cart.id);
      final addedItem = items.firstWhere(
        (item) => item['product_id'] == productId,
        orElse: () => throw Exception('Item not found after adding'),
      );

      return CartItem.fromJson(addedItem);
    } catch (e) {
      print('CartService - Error adding to current cart: $e');
      throw Exception('Error adding to current cart: $e');
    }
  }

  // Add item to cart
  static Future<CartItem> addToCart(
    String cartId,
    String productId,
    int quantity,
  ) async {
    try {
      print(
        'CartService - Adding item to cart: cartId=$cartId, productId=$productId, quantity=$quantity',
      );

      // First, check if the item already exists in the cart
      final existingItems = await SupabaseService.instance.client
          .from('cart_items')
          .select()
          .eq('cart_id', cartId)
          .eq('product_id', productId);

      if (existingItems.isNotEmpty) {
        print('CartService - Item already exists, updating quantity');
        final existingItem = existingItems.first;
        final newQuantity = (existingItem['quantity'] as int) + quantity;

        final response = await SupabaseService.instance.client
            .from('cart_items')
            .update({
              'quantity': newQuantity,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingItem['id'])
            .select()
            .single();

        print('CartService - Item quantity updated successfully: ${response}');
        return CartItem.fromJson(response);
      } else {
        print('CartService - Creating new cart item');
        final response = await SupabaseService.instance.client
            .from('cart_items')
            .insert({
              'cart_id': cartId,
              'product_id': productId,
              'quantity': quantity,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        print('CartService - Item added successfully: ${response}');
        return CartItem.fromJson(response);
      }
    } catch (e) {
      print('CartService - Error adding item to cart: $e');
      throw Exception('Error adding item to cart: $e');
    }
  }

  // Update cart item quantity
  static Future<CartItem> updateCartItem(String itemId, int quantity) async {
    try {
      await CartSessionManager.instance.updateItemQuantity(itemId, quantity);

      // Get the updated item
      final response = await SupabaseService.instance.client
          .from('cart_items')
          .select()
          .eq('id', itemId)
          .single();

      return CartItem.fromJson(response);
    } catch (e) {
      throw Exception('Error updating cart item: $e');
    }
  }

  // Remove item from cart
  static Future<void> removeFromCart(String itemId) async {
    try {
      await CartSessionManager.instance.removeItem(itemId);
    } catch (e) {
      throw Exception('Error removing item from cart: $e');
    }
  }

  // Clear cart
  static Future<void> clearCart(String cartId) async {
    try {
      await SupabaseService.instance.client
          .from('cart_items')
          .delete()
          .eq('cart_id', cartId);
    } catch (e) {
      throw Exception('Error clearing cart: $e');
    }
  }

  // Get cart items with product details
  static Future<List<Map<String, dynamic>>> getCartItemsWithProducts(
    String cartId,
  ) async {
    try {
      final response = await SupabaseService.instance.client
          .from('cart_items')
          .select('*, products(*)')
          .eq('cart_id', cartId);

      return response;
    } catch (e) {
      throw Exception('Error fetching cart items: $e');
    }
  }

  // Calculate cart total
  static Future<double> getCartTotal(String cartId) async {
    try {
      final items = await getCartItemsWithProducts(cartId);
      double total = 0;

      for (final item in items) {
        final quantity = item['quantity'] as int;
        final product = item['products'] as Map<String, dynamic>;
        final price = product['price'] as double;
        total += quantity * price;
      }

      return total;
    } catch (e) {
      throw Exception('Error calculating cart total: $e');
    }
  }

  // Convert cart to order (checkout)
  static Future<String> convertCartToOrder(String cartId) async {
    try {
      return await CartSessionManager.instance.checkout();
    } catch (e) {
      print('CartService - Error converting cart to order: $e');
      throw Exception('Error converting cart to order: $e');
    }
  }

  // Clean up old guest carts (call this periodically)
  static Future<void> cleanupOldGuestCarts({int daysOld = 7}) async {
    try {
      await CartSessionManager.instance.cleanupOldCarts(daysOld: daysOld);
    } catch (e) {
      print('CartService - Error cleaning up old guest carts: $e');
      throw Exception('Error cleaning up old guest carts: $e');
    }
  }

  // Get cart summary for current session
  static Future<Map<String, dynamic>> getCartSummary() async {
    try {
      return await CartSessionManager.instance.getCartSummary();
    } catch (e) {
      print('CartService - Error getting cart summary: $e');
      return {'cartId': null, 'itemCount': 0, 'total': 0.0, 'items': []};
    }
  }
}

// Cart Manager for easy access throughout the app
class CartManager {
  static CartManager? _instance;
  static CartManager get instance => _instance ??= CartManager._();

  CartManager._();

  // Add product to cart
  Future<void> addProduct(String productId, {int quantity = 1}) async {
    try {
      await CartSessionManager.instance.addItem(productId, quantity: quantity);
      print('CartManager - Added product $productId to cart');

      // Invalidate cart cache when items are added
      await _invalidateCartCache();
    } catch (e) {
      print('CartManager - Error adding product to cart: $e');
      throw Exception('Error adding product to cart: $e');
    }
  }

  // Invalidate cart cache to force refresh
  Future<void> _invalidateCartCache() async {
    try {
      await CartCacheManager.instance.invalidateCache();
      print('CartManager - Cart cache invalidated successfully');
    } catch (e) {
      print('CartManager - Error invalidating cache: $e');
    }
  }

  // Remove product from cart
  Future<void> removeProduct(String itemId) async {
    try {
      await CartSessionManager.instance.removeItem(itemId);
      print('CartManager - Removed item $itemId from cart');
    } catch (e) {
      print('CartManager - Error removing product from cart: $e');
      throw Exception('Error removing product from cart: $e');
    }
  }

  // Update product quantity
  Future<void> updateQuantity(String itemId, int quantity) async {
    try {
      await CartSessionManager.instance.updateItemQuantity(itemId, quantity);
      print('CartManager - Updated quantity for item $itemId to $quantity');
    } catch (e) {
      print('CartManager - Error updating quantity: $e');
      throw Exception('Error updating quantity: $e');
    }
  }

  // Get cart summary
  Future<Map<String, dynamic>> getCartSummary() async {
    return await CartSessionManager.instance.getCartSummary();
  }

  // Checkout cart
  Future<String> checkout() async {
    try {
      final orderId = await CartSessionManager.instance.checkout();
      print('CartManager - Checkout completed, order ID: $orderId');
      return orderId;
    } catch (e) {
      print('CartManager - Error during checkout: $e');
      throw Exception('Error during checkout: $e');
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      final cartSummary = await getCartSummary();
      final cartId = cartSummary['cartId'];
      if (cartId != null) {
        await CartService.clearCart(cartId);
      }
      print('CartManager - Cart cleared');
    } catch (e) {
      print('CartManager - Error clearing cart: $e');
      throw Exception('Error clearing cart: $e');
    }
  }
}
