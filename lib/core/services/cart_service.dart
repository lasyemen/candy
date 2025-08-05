import '../../models/cart.dart';
import 'supabase_service.dart';
import 'customer_session.dart';

class CartService {
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
      final response = await SupabaseService.instance.client
          .from('cart_items')
          .update({
            'quantity': quantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', itemId)
          .select()
          .single();

      return CartItem.fromJson(response);
    } catch (e) {
      throw Exception('Error updating cart item: $e');
    }
  }

  // Remove item from cart
  static Future<void> removeFromCart(String itemId) async {
    try {
      await SupabaseService.instance.client
          .from('cart_items')
          .delete()
          .eq('id', itemId);
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
}
