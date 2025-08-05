import '../../models/cart.dart';
import '../../models/cart_item.dart';
import 'supabase_service.dart';
import 'customer_session.dart';
import 'storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';

class CartSessionManager {
  static CartSessionManager? _instance;
  static CartSessionManager get instance =>
      _instance ??= CartSessionManager._();

  CartSessionManager._();

  String? _currentCartId;
  String? _guestSessionId;
  String? _guestCartId; // Store guest cart ID for merging

  // Generate unique session ID for guests
  String _generateSessionId() {
    final random = Random();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url
        .encode(bytes)
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .substring(0, 16);
  }

  // Generate UUID for guest customer IDs
  String _generateUUID() {
    final random = Random();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    // Set version (4) and variant bits
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  // Get or create guest session ID
  Future<String> getGuestSessionId() async {
    if (_guestSessionId == null) {
      try {
        // Try to load from storage first
        final prefs = await SharedPreferences.getInstance();
        final storedSessionId = prefs.getString('guest_session_id');

        if (storedSessionId != null) {
          _guestSessionId = storedSessionId;
        } else {
          _guestSessionId = _generateSessionId();
          // Save to storage
          await prefs.setString('guest_session_id', _guestSessionId!);
        }
      } catch (e) {
        print('CartSessionManager - Error loading session ID: $e');
        // Fallback: generate new session ID
        _guestSessionId = _generateSessionId();
      }
    }
    return _guestSessionId!;
  }

  // Initialize cart session
  Future<void> initializeSession() async {
    try {
      if (CustomerSession.instance.isLoggedIn) {
        await _initializeCustomerSession();
      } else {
        try {
          await _initializeGuestSession();
        } catch (guestError) {
          print('CartSessionManager - Guest session failed, trying alternative approach: $guestError');
          // Try alternative approach - create a simpler guest session
          await _initializeSimpleGuestSession();
        }
      }
    } catch (e) {
      print('CartSessionManager - Error initializing session: $e');
      throw Exception('Error initializing session: $e');
    }
  }

  // Initialize session for logged-in customer
  Future<void> _initializeCustomerSession() async {
    try {
      final customerId = CustomerSession.instance.currentCustomerId;
      if (customerId == null) {
        throw Exception('No customer logged in');
      }

      // Try to get existing cart
      final existingCart = await SupabaseService.instance.client
          .from('carts')
          .select('*')
          .eq('customer_id', customerId)
          .maybeSingle();

      if (existingCart != null) {
        _currentCartId = existingCart['id'];
      } else {
        // Create new cart
        final response = await SupabaseService.instance.client
            .from('carts')
            .insert({
              'customer_id': customerId,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        _currentCartId = response['id'];
      }
    } catch (e) {
      print('CartSessionManager - Error in _initializeCustomerSession: $e');
      throw Exception('Error initializing customer session: $e');
    }
  }

  // Initialize session for guest
  Future<void> _initializeGuestSession() async {
    try {
      final sessionId = await getGuestSessionId();
      // Generate a proper UUID for guest sessions
      final tempCustomerId = _generateUUID();

      print(
        'CartSessionManager - Initializing guest session with ID: $sessionId',
      );

      // First, create a guest customer record
      try {
        await SupabaseService.instance.client.from('customers').upsert({
          'id': tempCustomerId,
          'phone': 'guest_${sessionId.substring(0, 8)}',
          'name': 'Guest User',
          'address': 'Guest Address',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('CartSessionManager - Guest customer created successfully');
      } catch (e) {
        print('CartSessionManager - Error creating guest customer: $e');
        throw Exception('Failed to create guest customer: $e');
      }

      // Try to get existing cart for this temporary customer
      final existingCart = await SupabaseService.instance.client
          .from('carts')
          .select('*')
          .eq('customer_id', tempCustomerId)
          .maybeSingle();

      if (existingCart != null) {
        _currentCartId = existingCart['id'];
        _guestCartId = existingCart['id'];
        print('CartSessionManager - Found existing guest cart: ${existingCart['id']}');
      } else {
        // Create new cart for guest
        try {
          final response = await SupabaseService.instance.client
              .from('carts')
              .insert({
                'customer_id': tempCustomerId,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

          _currentCartId = response['id'];
          _guestCartId = response['id'];
          print('CartSessionManager - Created new guest cart: ${response['id']}');
        } catch (e) {
          print('CartSessionManager - Error creating guest cart: $e');
          throw Exception('Failed to create guest cart: $e');
        }
      }
    } catch (e) {
      print('CartSessionManager - Error in _initializeGuestSession: $e');
      throw Exception('Error initializing guest session: $e');
    }
  }

  // Add item to cart
  Future<void> addItem(String productId, {int quantity = 1}) async {
    try {
      if (_currentCartId == null) {
        await initializeSession();
      }

      if (_currentCartId == null) {
        throw Exception('Failed to initialize cart session');
      }

      // Check if item already exists
      final existingItems = await SupabaseService.instance.client
          .from('cart_items')
          .select()
          .eq('cart_id', _currentCartId!)
          .eq('product_id', productId);

      if (existingItems.isNotEmpty) {
        // Update quantity
        final existingItem = existingItems.first;
        final newQuantity = (existingItem['quantity'] as int) + quantity;

        await SupabaseService.instance.client
            .from('cart_items')
            .update({
              'quantity': newQuantity,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingItem['id']);
      } else {
        // Add new item
        await SupabaseService.instance.client.from('cart_items').insert({
          'cart_id': _currentCartId!,
          'product_id': productId,
          'quantity': quantity,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('CartSessionManager - Error adding item: $e');
      throw Exception('Error adding item: $e');
    }
  }

  // Update item quantity
  Future<void> updateItemQuantity(String itemId, int quantity) async {
    try {
      await SupabaseService.instance.client
          .from('cart_items')
          .update({
            'quantity': quantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', itemId);
    } catch (e) {
      print('CartSessionManager - Error updating item quantity: $e');
      throw Exception('Error updating item quantity: $e');
    }
  }

  // Remove item from cart
  Future<void> removeItem(String itemId) async {
    try {
      await SupabaseService.instance.client
          .from('cart_items')
          .delete()
          .eq('id', itemId);
    } catch (e) {
      print('CartSessionManager - Error removing item: $e');
      throw Exception('Error removing item: $e');
    }
  }

  // Merge guest cart into user cart
  Future<void> mergeGuestCartIntoUserCart() async {
    try {
      if (CustomerSession.instance.isLoggedIn) {
        final customerId = CustomerSession.instance.currentCustomerId;
        if (customerId == null) {
          throw Exception('No customer logged in');
        }

        final guestSessionId = await getGuestSessionId();
        // Get guest cart items using stored cart ID
        if (_guestCartId == null) {
          return; // No guest cart to merge
        }

        final guestCart = await SupabaseService.instance.client
            .from('carts')
            .select('*, cart_items(*)')
            .eq('id', _guestCartId!)
            .maybeSingle();

        if (guestCart != null && guestCart['cart_items'] != null) {
          // Get or create user cart
          final userCart = await SupabaseService.instance.client
              .from('carts')
              .select('*')
              .eq('customer_id', customerId)
              .maybeSingle();

          String userCartId;
          if (userCart != null) {
            userCartId = userCart['id'];
          } else {
            // Create new user cart
            final newCart = await SupabaseService.instance.client
                .from('carts')
                .insert({
                  'customer_id': customerId,
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .select()
                .single();
            userCartId = newCart['id'];
          }

          // Move items from guest cart to user cart
          for (final item in guestCart['cart_items']) {
            await addItem(item['product_id'], quantity: item['quantity']);
          }

          // Delete guest cart
          await SupabaseService.instance.client
              .from('carts')
              .delete()
              .eq('id', _guestCartId!);
        }
      }
    } catch (e) {
      print('CartSessionManager - Error merging guest cart: $e');
      throw Exception('Error merging guest cart: $e');
    }
  }

  // Checkout cart
  Future<String> checkout() async {
    try {
      if (_currentCartId == null) {
        throw Exception('No active cart');
      }

      // Create order from cart
      final cart = await SupabaseService.instance.client
          .from('carts')
          .select('*, cart_items(*)')
          .eq('id', _currentCartId!)
          .single();

      // Create order
      final order = await SupabaseService.instance.client
          .from('orders')
          .insert({
            'customer_id': cart['customer_id'],
            'status': 'pending',
            'total': await _calculateCartTotal(_currentCartId!),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Move cart items to order items
      for (final item in cart['cart_items']) {
        await SupabaseService.instance.client.from('order_items').insert({
          'order_id': order['id'],
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'price': await _getProductPrice(item['product_id']),
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Clear cart
      await SupabaseService.instance.client
          .from('cart_items')
          .delete()
          .eq('cart_id', _currentCartId!);

      // Update cart status
      await SupabaseService.instance.client
          .from('carts')
          .update({
            'status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentCartId!);

      _currentCartId = null;
      return order['id'];
    } catch (e) {
      print('CartSessionManager - Error during checkout: $e');
      throw Exception('Error during checkout: $e');
    }
  }

  // Calculate cart total
  Future<double> _calculateCartTotal(String cartId) async {
    try {
      final items = await SupabaseService.instance.client
          .from('cart_items')
          .select('*, products(*)')
          .eq('cart_id', cartId);

      double total = 0;
      for (final item in items) {
        final quantity = item['quantity'] as int;
        final product = item['products'] as Map<String, dynamic>;
        final price = product['price'] as double;
        total += quantity * price;
      }

      return total;
    } catch (e) {
      print('CartSessionManager - Error calculating cart total: $e');
      return 0.0;
    }
  }

  // Get product price
  Future<double> _getProductPrice(String productId) async {
    try {
      final product = await SupabaseService.instance.client
          .from('products')
          .select('price')
          .eq('id', productId)
          .single();

      return product['price'] as double;
    } catch (e) {
      print('CartSessionManager - Error getting product price: $e');
      return 0.0;
    }
  }

  // Cleanup old guest carts
  Future<void> cleanupOldCarts({int daysOld = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      await SupabaseService.instance.client
          .from('carts')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String())
          .like('customer_id', 'temp_%');
    } catch (e) {
      print('CartSessionManager - Error cleaning up old carts: $e');
      throw Exception('Error cleaning up old carts: $e');
    }
  }

  // Get cart summary
  Future<Map<String, dynamic>> getCartSummary() async {
    try {
      if (_currentCartId == null) {
        await initializeSession();
      }

      if (_currentCartId == null) {
        return {'cartId': null, 'itemCount': 0, 'total': 0.0, 'items': []};
      }

      final items = await SupabaseService.instance.client
          .from('cart_items')
          .select('*, products(*)')
          .eq('cart_id', _currentCartId!);

      int itemCount = 0;
      double total = 0.0;

      for (final item in items) {
        final quantity = item['quantity'] as int;
        final product = item['products'] as Map<String, dynamic>;
        final price = product['price'] as double;

        itemCount += quantity;
        total += quantity * price;
      }

      return {
        'cartId': _currentCartId,
        'itemCount': itemCount,
        'total': total,
        'items': items,
      };
    } catch (e) {
      print('CartSessionManager - Error getting cart summary: $e');
      return {'cartId': null, 'itemCount': 0, 'total': 0.0, 'items': []};
    }
  }
}
