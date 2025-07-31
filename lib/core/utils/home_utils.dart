import 'package:flutter/material.dart';
import '../../core/models/water_product.dart';

class HomeUtils {
  // Banner data
  static List<Map<String, dynamic>> getBanners() {
    return [
      {
        'title': 'عرض خاص!',
        'subtitle': 'احصل على خصم ٢٠٪ على جميع منتجات كاندي',
        'image': 'assets/icon/iconApp.png',
        'color': const Color(0xFF6B46C1),
        'gradient': const LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        'title': 'توصيل مجاني',
        'subtitle': 'للطلبات التي تزيد عن ٥٠ ريال',
        'image': 'assets/icon/iconApp.png',
        'color': const Color(0xFF3B82F6),
        'gradient': const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF6B46C1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
    ];
  }

  // Categories
  static List<String> getCategories() {
    return ['الكل', '330 مل', '200 مل', '500 مل', '1 لتر', 'معدنية', 'غازية'];
  }

  // Product data
  static List<WaterProduct> getProducts(String language) {
    return [
      WaterProduct(
        id: '1',
        name: language == 'ar' ? 'كاندي ٣٣٠ مل' : 'Candy 330ml',
        price: 21.84,
        size: 330,
        image: 'assets/icon/iconApp.png',
        rating: 4.5,
        reviewCount: 120,
        description: 'مياه نقية مع معادن طبيعية',
        discount: 15.0,
      ),
      WaterProduct(
        id: '2',
        name: language == 'ar' ? 'كاندي ٢٠٠ مل' : 'Candy 200ml',
        price: 15.50,
        size: 200,
        image: 'assets/icon/iconApp.png',
        rating: 4.3,
        reviewCount: 85,
        description: 'مياه معدنية طبيعية',
        discount: 0.0,
      ),
      WaterProduct(
        id: '3',
        name: language == 'ar' ? 'كاندي ٥٠٠ مل' : 'Candy 500ml',
        price: 28.90,
        size: 500,
        image: 'assets/icon/iconApp.png',
        rating: 4.7,
        reviewCount: 200,
        description: 'مياه نقية للعائلة',
        discount: 10.0,
      ),
      WaterProduct(
        id: '4',
        name: language == 'ar' ? 'كاندي ١ لتر' : 'Candy 1L',
        price: 45.00,
        size: 1000,
        image: 'assets/icon/iconApp.png',
        rating: 4.6,
        reviewCount: 150,
        description: 'مياه معدنية للاستخدام اليومي',
        discount: 20.0,
      ),
      WaterProduct(
        id: '5',
        name: language == 'ar' ? 'كاندي معدنية' : 'Candy Mineral',
        price: 32.50,
        size: 500,
        image: 'assets/icon/iconApp.png',
        rating: 4.4,
        reviewCount: 95,
        description: 'مياه معدنية غنية بالمعادن',
        discount: 5.0,
      ),
      WaterProduct(
        id: '6',
        name: language == 'ar' ? 'كاندي غازية' : 'Candy Sparkling',
        price: 18.75,
        size: 330,
        image: 'assets/icon/iconApp.png',
        rating: 4.2,
        reviewCount: 75,
        description: 'مياه غازية منعشة',
        discount: 0.0,
      ),
    ];
  }

  // Filter products by category
  static List<WaterProduct> filterProducts(
    List<WaterProduct> products,
    int selectedCategory,
    String language,
  ) {
    if (selectedCategory == 0) {
      return products; // All products
    }

    final categories = getCategories();
    final category = categories[selectedCategory];

    return products.where((product) {
      switch (selectedCategory) {
        case 1: // 330 مل
          return product.size == 330;
        case 2: // 200 مل
          return product.size == 200;
        case 3: // 500 مل
          return product.size == 500;
        case 4: // 1 لتر
          return product.size == 1000;
        case 5: // معدنية
          return product.description.contains('معدنية') ||
              product.description.contains('Mineral');
        case 6: // غازية
          return product.description.contains('غازية') ||
              product.description.contains('Sparkling');
        default:
          return true;
      }
    }).toList();
  }

  // Get product description based on language
  static String getProductDescription(WaterProduct product, String language) {
    if (language == 'ar') {
      return product.description;
    } else {
      // English descriptions
      switch (product.id) {
        case '1':
          return 'Pure water with natural minerals';
        case '2':
          return 'Natural mineral water';
        case '3':
          return 'Pure water for family';
        case '4':
          return 'Mineral water for daily use';
        case '5':
          return 'Mineral-rich water';
        case '6':
          return 'Refreshing sparkling water';
        default:
          return product.description;
      }
    }
  }
}
