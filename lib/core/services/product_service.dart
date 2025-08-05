import '../../models/products.dart';
import 'supabase_service.dart';
import '../../core/utils/home_utils.dart';

class ProductService {
  // Test database connection
  static Future<bool> testConnection() async {
    try {
      print('ProductService - Testing database connection...');
      
      // Test Supabase client
      final client = SupabaseService.instance.client;
      print('ProductService - Supabase client initialized: ${client != null}');
      
      // Test basic connection
      final response = await client
          .from('products')
          .select('*')
          .limit(5);
      print('ProductService - Connection test successful: $response');
      print('ProductService - Number of products found: ${response.length}');
      
      // Test table structure
      if (response.isNotEmpty) {
        final firstProduct = response.first;
        print('ProductService - Table structure test:');
        print('  - Has id: ${firstProduct.containsKey('id')}');
        print('  - Has name: ${firstProduct.containsKey('name')}');
        print('  - Has price: ${firstProduct.containsKey('price')}');
        print('  - Has category: ${firstProduct.containsKey('category')}');
        print('  - Has status: ${firstProduct.containsKey('status')}');
        print('  - Has created_at: ${firstProduct.containsKey('created_at')}');
        print('  - Has updated_at: ${firstProduct.containsKey('updated_at')}');
      }
      
      return true;
    } catch (e) {
      print('ProductService - Connection test failed: $e');
      return false;
    }
  }

  // Show current products in database
  static Future<void> showCurrentProducts() async {
    try {
      print('ProductService - === SHOWING CURRENT PRODUCTS IN DATABASE ===');
      
      final allProducts = await SupabaseService.instance.client
          .from('products')
          .select('*');
      
      print('ProductService - Total products found: ${allProducts.length}');
      
      if (allProducts.isNotEmpty) {
        for (int i = 0; i < allProducts.length; i++) {
          final product = allProducts[i];
          print('Product ${i + 1}:');
          print('  ID: ${product['id']}');
          print('  Name: ${product['name']}');
          print('  Price: ${product['price']}');
          print('  Category: ${product['category']}');
          print('  Status: ${product['status']}');
          print('  Description: ${product['description']}');
          print('  Stock: ${product['stock_quantity']}');
          print('  Rating: ${product['rating']}');
          print('  Total Sold: ${product['total_sold']}');
          print('  Created: ${product['created_at']}');
          print('  Updated: ${product['updated_at']}');
          print('---');
        }
      } else {
        print('ProductService - No products found in database');
      }
      
      print('ProductService - === END OF PRODUCTS LIST ===');
    } catch (e) {
      print('ProductService - Error showing current products: $e');
    }
  }

  // Check if products table exists and has data
  static Future<void> checkProductsTable() async {
    try {
      print('ProductService - Checking products table...');

      // First, let's see if the table exists by trying to select all
      final allProducts =
          await SupabaseService.instance.client.from('products').select('*');

      print('ProductService - All products in table: $allProducts');
      print('ProductService - Total products found: ${allProducts.length}');

      if (allProducts.isNotEmpty) {
        print('ProductService - First product structure: ${allProducts.first}');
        print('ProductService - First product keys: ${allProducts.first.keys.toList()}');
        
        // Show all products
        print('ProductService - === CURRENT PRODUCTS IN DATABASE ===');
        for (int i = 0; i < allProducts.length; i++) {
          final product = allProducts[i];
          print('Product ${i + 1}:');
          print('  ID: ${product['id']}');
          print('  Name: ${product['name']}');
          print('  Price: ${product['price']}');
          print('  Category: ${product['category']}');
          print('  Status: ${product['status']}');
          print('---');
        }
      } else {
        print('ProductService - No products found in table');
      }
    } catch (e) {
      print('ProductService - Error checking products table: $e');
    }
  }

  // Check if products table has data
  static Future<bool> hasProducts() async {
    try {
      print('ProductService - Checking if products table has data...');
      
      // First test if we can access the table at all
      try {
        final testResponse = await SupabaseService.instance.client
            .from('products')
            .select('count')
            .limit(1);
        print('ProductService - Table access test successful');
      } catch (e) {
        print('ProductService - Table access test failed: $e');
        return false;
      }
      
      final response = await SupabaseService.instance.client
          .from('products')
          .select('id')
          .limit(1);
      print('ProductService - hasProducts response: $response');
      print('ProductService - hasProducts response length: ${response.length}');
      final hasData = response.isNotEmpty;
      print('ProductService - Products table has data: $hasData');
      return hasData;
    } catch (e) {
      print('ProductService - Error checking if products exist: $e');
      return false;
    }
  }

  // Add sample products to the database
  static Future<bool> addSampleProducts() async {
    try {
      print('ProductService - Adding sample products to database...');
      
      // Clear existing products first
      try {
        await SupabaseService.instance.client
            .from('products')
            .delete()
            .neq('id', 'dummy'); // Delete all products
        print('ProductService - Cleared existing products');
      } catch (e) {
        print('ProductService - Error clearing products: $e');
      }
      
      // Get static products from HomeUtils
      final staticProducts = HomeUtils.getProducts('ar'); // Use Arabic as default
      print('ProductService - Got ${staticProducts.length} static products from HomeUtils');
      
      // Convert static products to database format
      final sampleProducts = staticProducts.map((product) => {
        'id': product.id,
        'name': product.name,
        'description': product.description ?? '',
        'price': product.price,
        'category': product.category,
        'image_url': product.imageUrl ?? 'assets/icon/iconApp.png',
        'stock_quantity': product.stockQuantity ?? 0,
        'rating': product.rating,
        'total_sold': product.totalSold ?? 0,
        'status': product.status,
        'created_at': product.createdAt.toIso8601String(),
        'updated_at': product.updatedAt.toIso8601String(),
      }).toList();
      
      print('ProductService - Inserting ${sampleProducts.length} sample products...');

      print('ProductService - Inserting sample products into database...');
      await SupabaseService.instance.client
          .from('products')
          .insert(sampleProducts);

      print('ProductService - Successfully added ${sampleProducts.length} sample products');
      
      // Verify the products were added
      final verifyResponse = await SupabaseService.instance.client
          .from('products')
          .select('id')
          .limit(10);
      print('ProductService - Verification: found ${verifyResponse.length} products after insertion');
      
      return true;
    } catch (e) {
      print('ProductService - Error adding sample products: $e');
      return false;
    }
  }

  // Test database permissions
  static Future<bool> testDatabasePermissions() async {
    try {
      print('ProductService - Testing database permissions...');
      
      // Test 1: Read permission
      try {
        final readTest = await SupabaseService.instance.client
            .from('products')
            .select('*')
            .limit(1);
        print('ProductService - Read permission: OK');
      } catch (e) {
        print('ProductService - Read permission failed: $e');
        return false;
      }
      
      // Test 2: Insert permission
      try {
        final testProduct = {
          'id': 'test-${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Test Product',
          'description': 'Test Description',
          'price': 10.0,
          'category': 'test',
          'image_url': 'assets/icon/iconApp.png',
          'stock_quantity': 10,
          'rating': 4.0,
          'total_sold': 0,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        await SupabaseService.instance.client
            .from('products')
            .insert(testProduct);
        print('ProductService - Insert permission: OK');
        
        // Clean up test product
        await SupabaseService.instance.client
            .from('products')
            .delete()
            .eq('id', testProduct['id'] as String);
        print('ProductService - Delete permission: OK');
        
        return true;
      } catch (e) {
        print('ProductService - Insert/Delete permission failed: $e');
        return false;
      }
    } catch (e) {
      print('ProductService - Database permissions test failed: $e');
      return false;
    }
  }

  // Add single test product
  static Future<bool> addSingleTestProduct() async {
    try {
      print('ProductService - Adding single test product...');
      
      final testProduct = {
        'id': 'test-single-${DateTime.now().millisecondsSinceEpoch}',
        'name': 'Test Product Single',
        'description': 'Test Description Single',
        'price': 15.0,
        'category': 'test',
        'image_url': 'assets/icon/iconApp.png',
        'stock_quantity': 50,
        'rating': 4.5,
        'total_sold': 10,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      print('ProductService - Test product data: $testProduct');
      
      await SupabaseService.instance.client
          .from('products')
          .insert(testProduct);
      
      print('ProductService - Successfully added single test product');
      
      // Verify it was added
      final verifyResponse = await SupabaseService.instance.client
          .from('products')
          .select('*')
          .eq('id', testProduct['id'] as String);
      
      print('ProductService - Verification: found ${verifyResponse.length} products with test ID');
      
      return verifyResponse.isNotEmpty;
    } catch (e) {
      print('ProductService - Failed to add single test product: $e');
      return false;
    }
  }

  // Force populate database with products
  static Future<bool> forcePopulateProducts() async {
    try {
      print('ProductService - Force populating products...');
      
      // Clear existing products first
      try {
        await SupabaseService.instance.client
            .from('products')
            .delete()
            .neq('id', 'dummy'); // Delete all products
        print('ProductService - Cleared existing products');
      } catch (e) {
        print('ProductService - Error clearing products: $e');
      }
      
      // Add products one by one
      final products = [
        {
          'id': '1',
          'name': 'كاندي ٣٣٠ مل',
          'description': '١ كرتون - ٤٠ عبوة بلاستيك',
          'price': 21.84,
          'category': '330 مل',
          'image_url': 'assets/icon/iconApp.png',
          'stock_quantity': 100,
          'rating': 4.5,
          'total_sold': 120,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'id': '2',
          'name': 'كاندي ٢٠٠ مل',
          'description': '١ كرتون - ٤٨ عبوة بلاستيك',
          'price': 15.50,
          'category': '200 مل',
          'image_url': 'assets/icon/iconApp.png',
          'stock_quantity': 80,
          'rating': 4.3,
          'total_sold': 85,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'id': '3',
          'name': 'كاندي ٥٠٠ مل',
          'description': '١ كرتون - ٢٤ عبوة بلاستيك',
          'price': 28.90,
          'category': '500 مل',
          'image_url': 'assets/icon/iconApp.png',
          'stock_quantity': 60,
          'rating': 4.7,
          'total_sold': 200,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'id': '4',
          'name': 'كاندي ١ لتر',
          'description': '١ كرتون - ١٢ عبوة بلاستيك',
          'price': 45.00,
          'category': '1 لتر',
          'image_url': 'assets/icon/iconApp.png',
          'stock_quantity': 50,
          'rating': 4.6,
          'total_sold': 150,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'id': '5',
          'name': 'كاندي معدنية',
          'description': 'مياه معدنية غنية بالمعادن الطبيعية',
          'price': 32.50,
          'category': 'معدنية',
          'image_url': 'assets/icon/iconApp.png',
          'stock_quantity': 70,
          'rating': 4.4,
          'total_sold': 95,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'id': '6',
          'name': 'كاندي غازية',
          'description': 'مياه غازية منعشة للاستهلاك اليومي',
          'price': 18.75,
          'category': 'غازية',
          'image_url': 'assets/icon/iconApp.png',
          'stock_quantity': 90,
          'rating': 4.2,
          'total_sold': 75,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      ];
      
      for (int i = 0; i < products.length; i++) {
        try {
          print('ProductService - Adding product ${i + 1}: ${products[i]['name']}');
          await SupabaseService.instance.client
              .from('products')
              .insert(products[i]);
          print('ProductService - Successfully added product ${i + 1}');
        } catch (e) {
          print('ProductService - Failed to add product ${i + 1}: $e');
          return false;
        }
      }
      
      // Verify products were added
      final verifyResponse = await SupabaseService.instance.client
          .from('products')
          .select('*');
      print('ProductService - Verification: found ${verifyResponse.length} products after force insertion');
      
      return verifyResponse.length > 0;
    } catch (e) {
      print('ProductService - Force population failed: $e');
      return false;
    }
  }

  // Manually populate database with products (for testing)
  static Future<bool> manuallyPopulateProducts() async {
    try {
      print('ProductService - Manually populating products...');
      
      // Clear existing products first
      try {
        await SupabaseService.instance.client
            .from('products')
            .delete()
            .neq('id', 'dummy'); // Delete all products
        print('ProductService - Cleared existing products');
      } catch (e) {
        print('ProductService - Error clearing products: $e');
      }
      
      // Add products one by one to see which one fails
      final products = [
        {
          'id': '1',
          'name': 'كاندي ٣٣٠ مل',
          'description': '١ كرتون - ٤٠ عبوة بلاستيك',
          'price': 21.84,
          'category': '330 مل',
          'image_url': 'assets/icon/iconApp.png',
          'stock_quantity': 100,
          'rating': 4.5,
          'total_sold': 120,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'id': '2',
          'name': 'كاندي ٢٠٠ مل',
          'description': '١ كرتون - ٤٨ عبوة بلاستيك',
          'price': 15.50,
          'category': '200 مل',
          'image_url': 'assets/icon/iconApp.png',
          'stock_quantity': 80,
          'rating': 4.3,
          'total_sold': 85,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      ];
      
      for (int i = 0; i < products.length; i++) {
        try {
          print('ProductService - Adding product ${i + 1}: ${products[i]['name']}');
          await SupabaseService.instance.client
              .from('products')
              .insert(products[i]);
          print('ProductService - Successfully added product ${i + 1}');
        } catch (e) {
          print('ProductService - Failed to add product ${i + 1}: $e');
          return false;
        }
      }
      
      // Verify products were added
      final verifyResponse = await SupabaseService.instance.client
          .from('products')
          .select('*');
      print('ProductService - Verification: found ${verifyResponse.length} products after manual insertion');
      
      return verifyResponse.length > 0;
    } catch (e) {
      print('ProductService - Manual population failed: $e');
      return false;
    }
  }

  // Test database connection and table access
  static Future<void> testDatabaseAccess() async {
    try {
      print('ProductService - Testing database access...');
      
      // Test 1: Basic connection
      print('ProductService - Test 1: Basic connection');
      final client = SupabaseService.instance.client;
      print('ProductService - Supabase client initialized: ${client != null}');
      
      // Test 2: Table existence
      print('ProductService - Test 2: Table existence');
      try {
        final tableTest = await client.from('products').select('count').limit(1);
        print('ProductService - Table exists and is accessible');
      } catch (e) {
        print('ProductService - Table access error: $e');
      }
      
      // Test 3: Insert permission
      print('ProductService - Test 3: Insert permission');
      try {
        final testProduct = {
          'id': 'test-${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Test Product',
          'description': 'Test Description',
          'price': 10.0,
          'category': 'test',
          'image_url': 'assets/icon/iconApp.png',
          'stock_quantity': 10,
          'rating': 4.0,
          'total_sold': 0,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        await client.from('products').insert(testProduct);
        print('ProductService - Insert permission: OK');
        
        // Clean up test product
        await client.from('products').delete().eq('id', testProduct['id'] as String);
        print('ProductService - Delete permission: OK');
      } catch (e) {
        print('ProductService - Insert/Delete permission error: $e');
      }
      
      // Test 4: Current data
      print('ProductService - Test 4: Current data');
      final currentData = await client.from('products').select('*');
      print('ProductService - Current products in table: ${currentData.length}');
      if (currentData.isNotEmpty) {
        print('ProductService - Sample product: ${currentData.first}');
      }
      
    } catch (e) {
      print('ProductService - Database access test failed: $e');
    }
  }

  // Fetch all products from database
  static Future<List<Products>> fetchProducts() async {
    try {
      print('ProductService - Attempting to fetch products from database...');

      final response = await SupabaseService.instance.client
          .from('products')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      print('ProductService - Raw response: $response');
      print('ProductService - Response type: ${response.runtimeType}');
      print('ProductService - Response length: ${response.length}');

      final List<Products> products = [];

      for (var json in response as List) {
        try {
          print('ProductService - Processing product JSON: $json');
          
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
            print('ProductService - Skipping product with null required fields: $json');
            continue;
          }

          final product = Products.fromJson(json);
          print('ProductService - Successfully created product: ${product.name}');
          products.add(product);
        } catch (e) {
          print('ProductService - Error parsing product: $e');
          print('ProductService - Product data: $json');
          continue;
        }
      }

      print('ProductService - Successfully loaded ${products.length} products');
      return products;
    } catch (e) {
      print('ProductService - Error fetching products: $e');
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
