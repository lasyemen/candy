import '../../models/products.dart';
import 'supabase_service.dart';

class ProductService {
  // Fetch all products from database
  static Future<List<Products>> fetchProducts() async {
    try {
      final response = await SupabaseService.instance.client
          .from('products')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final List<Products> products = [];

      for (var json in response as List) {
        try {
          // Validate required fields before creating Products object
          if (json['id'] == null ||
              json['name'] == null ||
              json['price'] == null ||
              json['category'] == null ||
              json['status'] == null ||
              json['total_sold'] == null ||
              json['rating'] == null ||
              json['created_at'] == null ||
              json['updated_at'] == null) {
            print('Skipping product with null required fields: $json');
            continue;
          }

          products.add(Products.fromJson(json));
        } catch (e) {
          print('Error parsing product: $e');
          print('Product data: $json');
          continue;
        }
      }

      return products;
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // Fetch products by category
  static Future<List<Products>> fetchProductsByCategory(String category) async {
    try {
      final response = await SupabaseService.instance.client
          .from('products')
          .select()
          .eq('status', 'active')
          .eq('category', category)
          .order('created_at', ascending: false);

      final List<Products> products = [];

      for (var json in response as List) {
        try {
          // Validate required fields before creating Products object
          if (json['id'] == null ||
              json['name'] == null ||
              json['price'] == null ||
              json['category'] == null ||
              json['status'] == null ||
              json['total_sold'] == null ||
              json['rating'] == null ||
              json['created_at'] == null ||
              json['updated_at'] == null) {
            print('Skipping product with null required fields: $json');
            continue;
          }

          products.add(Products.fromJson(json));
        } catch (e) {
          print('Error parsing product: $e');
          print('Product data: $json');
          continue;
        }
      }

      return products;
    } catch (e) {
      throw Exception('Error fetching products by category: $e');
    }
  }

  // Add a new product
  static Future<Products> addProduct(Products product) async {
    try {
      final response = await SupabaseService.instance.client
          .from('products')
          .insert(product.toJson())
          .select()
          .single();

      return Products.fromJson(response);
    } catch (e) {
      throw Exception('Error adding product: $e');
    }
  }

  // Update product
  static Future<Products> updateProduct(String id, Products product) async {
    try {
      final response = await SupabaseService.instance.client
          .from('products')
          .update(product.toJson())
          .eq('id', id)
          .select()
          .single();

      return Products.fromJson(response);
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  // Delete product
  static Future<void> deleteProduct(String id) async {
    try {
      await SupabaseService.instance.client
          .from('products')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }

  // Search products by name
  static Future<List<Products>> searchProducts(String query) async {
    try {
      final response = await SupabaseService.instance.client
          .from('products')
          .select()
          .eq('status', 'active')
          .ilike('name', '%$query%')
          .order('created_at', ascending: false);

      final List<Products> products = [];

      for (var json in response as List) {
        try {
          // Validate required fields before creating Products object
          if (json['id'] == null ||
              json['name'] == null ||
              json['price'] == null ||
              json['category'] == null ||
              json['status'] == null ||
              json['total_sold'] == null ||
              json['rating'] == null ||
              json['created_at'] == null ||
              json['updated_at'] == null) {
            print('Skipping product with null required fields: $json');
            continue;
          }

          products.add(Products.fromJson(json));
        } catch (e) {
          print('Error parsing product: $e');
          print('Product data: $json');
          continue;
        }
      }

      return products;
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }
}
