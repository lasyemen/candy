import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartCacheManager {
  static CartCacheManager? _instance;
  static CartCacheManager get instance => _instance ??= CartCacheManager._();

  CartCacheManager._();

  static const String _cacheKey = 'cart_cache';
  static const String _cacheTimeKey = 'cart_cache_time';
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Cache cart items
  Future<void> cacheCartItems(List<Map<String, dynamic>> cartItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartItemsJson = jsonEncode(cartItems);
      await prefs.setString(_cacheKey, cartItemsJson);
      await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
      print('CartCacheManager - Cart items cached successfully');
    } catch (e) {
      print('CartCacheManager - Error caching cart items: $e');
    }
  }

  // Get cached cart items
  Future<List<Map<String, dynamic>>> getCachedCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartItemsJson = prefs.getString(_cacheKey);
      final cacheTimeStr = prefs.getString(_cacheTimeKey);

      if (cartItemsJson == null || cacheTimeStr == null) {
        return [];
      }

      final cacheTime = DateTime.parse(cacheTimeStr);
      final timeSinceCache = DateTime.now().difference(cacheTime);

      if (timeSinceCache > _cacheValidDuration) {
        // Cache is expired, clear it
        await clearCache();
        return [];
      }

      final cartItems = List<Map<String, dynamic>>.from(
        jsonDecode(
          cartItemsJson,
        ).map((item) => Map<String, dynamic>.from(item)),
      );
      print(
        'CartCacheManager - Retrieved cached cart items: ${cartItems.length}',
      );
      return cartItems;
    } catch (e) {
      print('CartCacheManager - Error getting cached cart items: $e');
      return [];
    }
  }

  // Check if cache is valid
  Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimeStr = prefs.getString(_cacheTimeKey);

      if (cacheTimeStr == null) {
        return false;
      }

      final cacheTime = DateTime.parse(cacheTimeStr);
      final timeSinceCache = DateTime.now().difference(cacheTime);
      return timeSinceCache < _cacheValidDuration;
    } catch (e) {
      print('CartCacheManager - Error checking cache validity: $e');
      return false;
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimeKey);
      print('CartCacheManager - Cache cleared successfully');
    } catch (e) {
      print('CartCacheManager - Error clearing cache: $e');
    }
  }

  // Invalidate cache (mark as invalid)
  Future<void> invalidateCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimeKey);
      print('CartCacheManager - Cache invalidated successfully');
    } catch (e) {
      print('CartCacheManager - Error invalidating cache: $e');
    }
  }

  // Update cache with new items
  Future<void> updateCache(List<Map<String, dynamic>> cartItems) async {
    await cacheCartItems(cartItems);
  }
}
