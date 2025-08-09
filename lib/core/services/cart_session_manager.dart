import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'supabase_service.dart';
import 'customer_session.dart';

class CartSessionManager {
  static CartSessionManager? _instance;
  static CartSessionManager get instance =>
      _instance ??= CartSessionManager._();

  CartSessionManager._();

  String? _currentCartId;
  String? _guestSessionId;
  String? _guestCartId; // Store guest cart ID for merging

  // Check network connectivity
  Future<bool> _isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

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

  // Initialize cart session with retry logic
  Future<void> initializeSession() async {
    int retryCount = 0;
    const maxRetries = 2;

    while (retryCount < maxRetries) {
      try {
        if (CustomerSession.instance.isLoggedIn) {
          await _initializeCustomerSession();
        } else {
          try {
            await _initializeGuestSession();
          } catch (guestError) {
            print(
              'CartSessionManager - Guest session failed, trying alternative approach: $guestError',
            );
            // Try alternative approach - create a simpler guest session
            await _initializeSimpleGuestSession();
          }
        }

        // If we get here, initialization was successful
        print('CartSessionManager - Session initialized successfully');
        return;
      } catch (e) {
        retryCount++;
        print(
          'CartSessionManager - Error initializing session (attempt $retryCount): $e',
        );

        if (retryCount >= maxRetries) {
          print(
            'CartSessionManager - Max retries reached for session initialization',
          );
          throw Exception(
            'Error initializing session after $maxRetries attempts: $e',
          );
        }

        // Wait before retrying
        final delay = Duration(milliseconds: 2000 * retryCount);
        print(
          'CartSessionManager - Retrying session initialization in ${delay.inMilliseconds}ms...',
        );
        await Future.delayed(delay);
      }
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

      // For guest sessions, we'll use a local approach that doesn't require network
      // Store the guest session data locally
      await _saveGuestSessionData(tempCustomerId, sessionId);
      print('CartSessionManager - Guest session data saved locally');

      // Try to get existing cart for this temporary customer
      try {
        final existingCart = await SupabaseService.instance.client
            .from('carts')
            .select('*')
            .eq('customer_id', tempCustomerId)
            .maybeSingle();

        if (existingCart != null) {
          _currentCartId = existingCart['id'];
          _guestCartId = existingCart['id'];
          print(
            'CartSessionManager - Found existing guest cart: ${existingCart['id']}',
          );
        } else {
          // Create new cart for guest (only if network is available)
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
            print(
              'CartSessionManager - Created new guest cart: $_currentCartId',
            );
          } catch (networkError) {
            print(
              'CartSessionManager - Network error creating guest cart: $networkError',
            );
            // Use a proper UUID for local cart ID instead of string concatenation
            _currentCartId = tempCustomerId;
            _guestCartId = tempCustomerId;
            print(
              'CartSessionManager - Using local guest cart: $_currentCartId',
            );
          }
        }
      } catch (networkError) {
        print(
          'CartSessionManager - Network error accessing guest cart: $networkError',
        );
        // Use a proper UUID for local cart ID instead of string concatenation
        _currentCartId = tempCustomerId;
        _guestCartId = tempCustomerId;
        print('CartSessionManager - Using local guest cart: $_currentCartId');
      }
    } catch (e) {
      print('CartSessionManager - Error in _initializeGuestSession: $e');
      throw Exception('Error initializing guest session: $e');
    }
  }

  // Initialize simple guest session (fallback)
  Future<void> _initializeSimpleGuestSession() async {
    try {
      final sessionId = await getGuestSessionId();
      print(
        'CartSessionManager - Initializing simple guest session with ID: $sessionId',
      );

      // Use a simpler approach - create customer with a different strategy
      final tempCustomerId = _generateUUID();

      // Try to create customer with minimal data
      try {
        await SupabaseService.instance.client.from('customers').insert({
          'id': tempCustomerId,
          'phone': 'guest_${sessionId.substring(0, 8)}',
          'name': 'Guest',
          'address': 'Guest Address',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print(
          'CartSessionManager - Simple guest customer created successfully',
        );
      } catch (customerError) {
        print(
          'CartSessionManager - Error creating simple guest customer: $customerError',
        );
        // If customer creation fails, we can't proceed
        throw Exception('Failed to create guest customer: $customerError');
      }

      // Create cart
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
        print(
          'CartSessionManager - Simple guest cart created: ${response['id']}',
        );
      } catch (cartError) {
        print(
          'CartSessionManager - Error creating simple guest cart: $cartError',
        );
        throw Exception('Failed to create guest cart: $cartError');
      }
    } catch (e) {
      print('CartSessionManager - Error in _initializeSimpleGuestSession: $e');
      throw Exception('Error initializing simple guest session: $e');
    }
  }

  // Add item to cart with optimized performance
  Future<void> addItem(String productId, {int quantity = 1}) async {
    // Check network connectivity first
    final isNetworkAvailable = await _isNetworkAvailable();
    if (!isNetworkAvailable) {
      print('CartSessionManager - No network connectivity available');

      // For guest users, we can work offline
      if (!CustomerSession.instance.isLoggedIn) {
        print(
          'CartSessionManager - Guest user in offline mode, using local storage',
        );
        await _addItemToLocalCart(productId, quantity);
        return;
      }

      throw Exception(
        'No network connectivity. Please check your internet connection.',
      );
    }

    int retryCount = 0;
    const maxRetries = 2; // Reduced from 3 to 2

    while (retryCount < maxRetries) {
      try {
        if (_currentCartId == null) {
          await initializeSession();
        }

        if (_currentCartId == null) {
          throw Exception('Failed to initialize cart session');
        }

        // For guest users, check if we need to create the cart first
        if (!CustomerSession.instance.isLoggedIn &&
            _currentCartId == _guestCartId) {
          // Check if the cart exists in the database
          try {
            final existingCart = await SupabaseService.instance.client
                .from('carts')
                .select('id')
                .eq('id', _currentCartId!)
                .maybeSingle();

            if (existingCart == null) {
              // Cart doesn't exist, create it first
              final response = await SupabaseService.instance.client
                  .from('carts')
                  .insert({
                    'id': _currentCartId!,
                    'customer_id':
                        _currentCartId!, // Use the same UUID for customer_id
                    'created_at': DateTime.now().toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .select()
                  .single();

              print(
                'CartSessionManager - Created guest cart: ${response['id']}',
              );
            }
          } catch (cartError) {
            print('CartSessionManager - Error creating guest cart: $cartError');
            // If we can't create the cart, fall back to local storage
            await _addItemToLocalCart(productId, quantity);
            return;
          }
        }

        // Optimized: Use upsert operation instead of separate check and insert
        await _upsertCartItemWithoutConstraint(
          cartId: _currentCartId!,
          productId: productId,
          quantity: quantity,
        );

        // If we get here, the operation was successful
        print('CartSessionManager - Successfully added item to cart');
        return;
      } catch (e) {
        retryCount++;
        print(
          'CartSessionManager - Error adding item (attempt $retryCount): $e',
        );

        if (retryCount >= maxRetries) {
          print('CartSessionManager - Max retries reached, throwing error');
          throw Exception('Error adding item after $maxRetries attempts: $e');
        }

        // Reduced delay before retrying (faster retry)
        final delay = Duration(
          milliseconds: 300 * retryCount,
        ); // Reduced from 1000 to 300
        print('CartSessionManager - Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
      }
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

        print(
          'CartSessionManager - Merging guest cart for customer: $customerId',
        );

        // Get or create user cart
        final userCart = await SupabaseService.instance.client
            .from('carts')
            .select('*')
            .eq('customer_id', customerId)
            .maybeSingle();

        String userCartId;
        if (userCart != null) {
          userCartId = userCart['id'];
          print('CartSessionManager - Found existing user cart: $userCartId');
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
          print('CartSessionManager - Created new user cart: $userCartId');
        }

        // Merge database guest cart items
        if (_guestCartId != null) {
          print('CartSessionManager - Checking for guest cart: $_guestCartId');
          final guestCart = await SupabaseService.instance.client
              .from('carts')
              .select('*, cart_items(*)')
              .eq('id', _guestCartId!)
              .maybeSingle();

          if (guestCart != null && guestCart['cart_items'] != null) {
            print(
              'CartSessionManager - Found ${guestCart['cart_items'].length} items in guest cart',
            );

            // Move items from guest cart to user cart
            for (final item in guestCart['cart_items']) {
              print(
                'CartSessionManager - Merging item: ${item['product_id']} x${item['quantity']}',
              );
              // Use upsert to handle existing items properly
              await _upsertCartItemWithoutConstraint(
                cartId: userCartId,
                productId: item['product_id'] as String,
                quantity: item['quantity'] as int,
              );
            }

            // Delete guest cart
            await SupabaseService.instance.client
                .from('carts')
                .delete()
                .eq('id', _guestCartId!);
            print('CartSessionManager - Deleted guest cart: $_guestCartId');
          }
        }

        // Merge local guest cart items (offline mode)
        try {
          final prefs = await SharedPreferences.getInstance();
          final localCartJson = prefs.getString('local_cart_items') ?? '[]';
          final localCartItems = List<Map<String, dynamic>>.from(
            jsonDecode(localCartJson),
          );

          if (localCartItems.isNotEmpty) {
            print(
              'CartSessionManager - Found ${localCartItems.length} local cart items',
            );

            for (final item in localCartItems) {
              print(
                'CartSessionManager - Merging local item: ${item['product_id']} x${item['quantity']}',
              );
              await SupabaseService.instance.client.from('cart_items').upsert({
                'cart_id': userCartId,
                'product_id': item['product_id'],
                'quantity': item['quantity'],
                'created_at':
                    item['created_at'] ?? DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              }, onConflict: 'cart_id,product_id');
            }

            // Clear local cart items after successful merge
            await prefs.remove('local_cart_items');
            print('CartSessionManager - Cleared local cart items');
          }
        } catch (e) {
          print('CartSessionManager - Error merging local cart items: $e');
        }

        // Update current cart ID to user cart
        _currentCartId = userCartId;
        _guestCartId = null; // Clear guest cart ID

        print(
          'CartSessionManager - Successfully merged guest cart into user cart',
        );
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

      // Check if this is a local guest cart (offline mode)
      // Since we now use proper UUIDs, we need to check if the cart exists in the database
      // If not, it means we're in offline mode
      try {
        final cartExists = await SupabaseService.instance.client
            .from('carts')
            .select('id')
            .eq('id', _currentCartId!)
            .maybeSingle();

        if (cartExists == null) {
          print(
            'CartSessionManager - Using local guest cart summary (offline mode)',
          );
          // Get local cart items from shared preferences
          final prefs = await SharedPreferences.getInstance();
          final localCartJson = prefs.getString('local_cart_items') ?? '[]';
          final localCartItems = List<Map<String, dynamic>>.from(
            jsonDecode(localCartJson),
          );

          // Fetch actual product data for local items
          final itemsWithProducts = <Map<String, dynamic>>[];
          int itemCount = 0;
          double total = 0.0;

          for (final item in localCartItems) {
            final quantity = item['quantity'] as int;
            final productId = item['product_id'] as String;

            try {
              // Fetch product data from database
              final product = await SupabaseService.instance.client
                  .from('products')
                  .select('*')
                  .eq('id', productId)
                  .maybeSingle();

              if (product != null) {
                final itemWithProduct = Map<String, dynamic>.from(item);
                itemWithProduct['products'] = product;
                itemsWithProducts.add(itemWithProduct);

                final price = product['price'] as double;
                itemCount += quantity;
                total += quantity * price;
              } else {
                print('CartSessionManager - Product not found: $productId');
                // Add item without product data as fallback
                itemsWithProducts.add(item);
                itemCount += quantity;
                total += quantity * 5.0; // Default price
              }
            } catch (e) {
              print(
                'CartSessionManager - Error fetching product $productId: $e',
              );
              // Add item without product data as fallback
              itemsWithProducts.add(item);
              itemCount += quantity;
              total += quantity * 5.0; // Default price
            }
          }

          return {
            'cartId': _currentCartId,
            'itemCount': itemCount,
            'total': total,
            'items': itemsWithProducts,
          };
        }
      } catch (e) {
        print(
          'CartSessionManager - Error checking cart existence, using local mode: $e',
        );
        // If we can't check the database, assume offline mode
        final prefs = await SharedPreferences.getInstance();
        final localCartJson = prefs.getString('local_cart_items') ?? '[]';
        final localCartItems = List<Map<String, dynamic>>.from(
          jsonDecode(localCartJson),
        );

        // Fetch actual product data for local items
        final itemsWithProducts = <Map<String, dynamic>>[];
        int itemCount = 0;
        double total = 0.0;

        for (final item in localCartItems) {
          final quantity = item['quantity'] as int;
          final productId = item['product_id'] as String;

          try {
            // Fetch product data from database
            final product = await SupabaseService.instance.client
                .from('products')
                .select('*')
                .eq('id', productId)
                .maybeSingle();

            if (product != null) {
              final itemWithProduct = Map<String, dynamic>.from(item);
              itemWithProduct['products'] = product;
              itemsWithProducts.add(itemWithProduct);

              final price = product['price'] as double;
              itemCount += quantity;
              total += quantity * price;
            } else {
              print('CartSessionManager - Product not found: $productId');
              // Add item without product data as fallback
              itemsWithProducts.add(item);
              itemCount += quantity;
              total += quantity * 5.0; // Default price
            }
          } catch (e) {
            print('CartSessionManager - Error fetching product $productId: $e');
            // Add item without product data as fallback
            itemsWithProducts.add(item);
            itemCount += quantity;
            total += quantity * 5.0; // Default price
          }
        }

        return {
          'cartId': _currentCartId,
          'itemCount': itemCount,
          'total': total,
          'items': itemsWithProducts,
        };
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

  // Save guest session data locally
  Future<void> _saveGuestSessionData(
    String customerId,
    String sessionId,
  ) async {
    try {
      // Store guest session data in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guest_customer_id', customerId);
      await prefs.setString('guest_session_id', sessionId);
      await prefs.setString(
        'guest_session_created',
        DateTime.now().toIso8601String(),
      );
      print('CartSessionManager - Guest session data saved locally');
    } catch (e) {
      print('CartSessionManager - Error saving guest session data: $e');
    }
  }

  // Add item to local cart (offline mode)
  Future<void> _addItemToLocalCart(String productId, int quantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing local cart items
      final localCartJson = prefs.getString('local_cart_items') ?? '[]';
      final localCartItems = List<Map<String, dynamic>>.from(
        jsonDecode(localCartJson),
      );

      // Check if item already exists
      final existingItemIndex = localCartItems.indexWhere(
        (item) => item['product_id'] == productId,
      );

      if (existingItemIndex != -1) {
        // Update existing item quantity
        localCartItems[existingItemIndex]['quantity'] =
            (localCartItems[existingItemIndex]['quantity'] as int) + quantity;
      } else {
        // Add new item
        localCartItems.add({
          'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
          'product_id': productId,
          'quantity': quantity,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // Save back to shared preferences
      await prefs.setString('local_cart_items', jsonEncode(localCartItems));
      print(
        'CartSessionManager - Added item to local cart: $productId x$quantity',
      );
    } catch (e) {
      print('CartSessionManager - Error adding item to local cart: $e');
      throw Exception('Error adding item to local cart: $e');
    }
  }

  // Sync local cart items to server when network becomes available
  Future<void> syncLocalCartToServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localCartJson = prefs.getString('local_cart_items') ?? '[]';
      final localCartItems = List<Map<String, dynamic>>.from(
        jsonDecode(localCartJson),
      );

      if (localCartItems.isEmpty) {
        print('CartSessionManager - No local cart items to sync');
        return;
      }

      // Check if network is available
      final isNetworkAvailable = await _isNetworkAvailable();
      if (!isNetworkAvailable) {
        print('CartSessionManager - Network not available for sync');
        return;
      }

      // Ensure we have a valid cart session
      if (_currentCartId == null) {
        await initializeSession();
      }

      // For guest users, ensure the cart exists in the database
      if (!CustomerSession.instance.isLoggedIn &&
          _currentCartId == _guestCartId) {
        try {
          final existingCart = await SupabaseService.instance.client
              .from('carts')
              .select('id')
              .eq('id', _currentCartId!)
              .maybeSingle();

          if (existingCart == null) {
            // Create the cart first
            await SupabaseService.instance.client.from('carts').insert({
              'id': _currentCartId!,
              'customer_id':
                  _currentCartId!, // Use the same UUID for customer_id
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
            print(
              'CartSessionManager - Created guest cart for sync: $_currentCartId',
            );
          }
        } catch (cartError) {
          print(
            'CartSessionManager - Error creating cart for sync: $cartError',
          );
          return; // Can't sync without a valid cart
        }
      }

      // Add each local item to the server
      for (final item in localCartItems) {
        await _upsertCartItemWithoutConstraint(
          cartId: _currentCartId!,
          productId: item['product_id'] as String,
          quantity: item['quantity'] as int,
        );
      }

      // Clear local cart items after successful sync
      await prefs.remove('local_cart_items');
      print('CartSessionManager - Successfully synced local cart to server');
    } catch (e) {
      print('CartSessionManager - Error syncing local cart to server: $e');
    }
  }

  // Helper to upsert cart item without onConflict constraint
  Future<void> _upsertCartItemWithoutConstraint({
    required String cartId,
    required String productId,
    required int quantity,
  }) async {
    try {
      final existing = await SupabaseService.instance.client
          .from('cart_items')
          .select('id, quantity')
          .eq('cart_id', cartId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existing != null) {
        final currentQty = (existing['quantity'] as int?) ?? 0;
        await SupabaseService.instance.client
            .from('cart_items')
            .update({
              'quantity': currentQty + quantity,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      } else {
        await SupabaseService.instance.client.from('cart_items').insert({
          'cart_id': cartId,
          'product_id': productId,
          'quantity': quantity,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('CartSessionManager - Error upserting cart item: $e');
      throw Exception('Error upserting cart item: $e');
    }
  }
}
