import '../../models/cart.dart';

import 'supabase_service.dart';

class CartService {
  // Get cart for a customer
  static Future<Cart?> getCart(String customerId) async {
    try {
      final response = await SupabaseService.instance.client
          .from('carts')
          .select('*, cart_items(*)')
          .eq('customer_id', customerId)
          .single();

      return Cart.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Create a new cart
  static Future<Cart> createCart(String customerId) async {
    try {
      final response = await SupabaseService.instance.client
          .from('carts')
          .insert({
            'customer_id': customerId,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Cart.fromJson(response);
    } catch (e) {
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

      return CartItem.fromJson(response);
    } catch (e) {
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
