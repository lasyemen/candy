import 'package:flutter/material.dart';
import '../../models/products.dart';

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
    return ['الكل', '330 مل', '200 مل', '500 مل', '1 لتر'];
  }

  // Product data
  static List<Products> getProducts(String language) {
    return [
      Products(
        id: '1',
        name: language == 'ar' ? 'كاندي ٣٣٠ مل' : 'Candy 330ml',
        description: language == 'ar'
            ? '١ كرتون - ٤٠ عبوة بلاستيك'
            : '1 Carton - 40 Plastic Bottles',
        price: 21.84,
        category: '330 مل',
        imageUrl: 'assets/icon/iconApp.png',
        stockQuantity: 100,
        rating: 4.5,
        totalSold: 120,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Products(
        id: '2',
        name: language == 'ar' ? 'كاندي ٢٠٠ مل' : 'Candy 200ml',
        description: language == 'ar'
            ? '١ كرتون - ٤٨ عبوة بلاستيك'
            : '1 Carton - 48 Plastic Bottles',
        price: 15.50,
        category: '200 مل',
        imageUrl: 'assets/icon/iconApp.png',
        stockQuantity: 80,
        rating: 4.3,
        totalSold: 85,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Products(
        id: '3',
        name: language == 'ar' ? 'كاندي ٥٠٠ مل' : 'Candy 500ml',
        description: language == 'ar'
            ? '١ كرتون - ٢٤ عبوة بلاستيك'
            : '1 Carton - 24 Plastic Bottles',
        price: 28.90,
        category: '500 مل',
        imageUrl: 'assets/icon/iconApp.png',
        stockQuantity: 60,
        rating: 4.7,
        totalSold: 200,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Products(
        id: '4',
        name: language == 'ar' ? 'كاندي ١ لتر' : 'Candy 1L',
        description: language == 'ar'
            ? '١ كرتون - ١٢ عبوة بلاستيك'
            : '1 Carton - 12 Plastic Bottles',
        price: 45.00,
        category: '1 لتر',
        imageUrl: 'assets/icon/iconApp.png',
        stockQuantity: 50,
        rating: 4.6,
        totalSold: 150,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  // Filter products by category
  static List<Products> filterProducts(
    List<Products> products,
    int selectedCategory,
    String language,
  ) {
    if (selectedCategory == 0) {
      return products; // All products
    }

    return products.where((product) {
      switch (selectedCategory) {
        case 1: // 330 مل
          return product.name.contains('330') || product.name.contains('٣٣٠');
        case 2: // 200 مل
          return product.name.contains('200') || product.name.contains('٢٠٠');
        case 3: // 500 مل
          return product.name.contains('500') || product.name.contains('٥٠٠');
        case 4: // 1 لتر
          return product.name.contains('1 لتر') || product.name.contains('1L');
        
        default:
          return true;
      }
    }).toList();
  }

  // Get product description based on language
  static String getProductDescription(Products product, String language) {
    if (language == 'ar') {
      switch (product.id) {
        case '1':
          return 'مياه نقية مع معادن طبيعية';
        case '2':
          return 'مياه معدنية طبيعية';
        case '3':
          return 'مياه نقية للعائلة';
        case '4':
          return 'مياه معدنية للاستخدام اليومي';
        case '5':
          return 'مياه معدنية غنية بالمعادن';
        case '6':
          return 'مياه غازية منعشة';
        default:
          return 'مياه نقية';
      }
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
          return 'Pure water';
      }
    }
  }
}
