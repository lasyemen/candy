import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _userKey = 'user_data';
  static const String _cartKey = 'cart_data';
  static const String _waterGoalKey = 'water_goal';
  static const String _waterHistoryKey = 'water_history';
  static const String _ordersKey = 'orders_data';
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';

  // User data storage
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert to JSON string for storage
    // Note: In a real app, you'd use proper JSON serialization
    await prefs.setString(_userKey, userData.toString());
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data != null) {
      // Parse the stored data
      // Note: In a real app, you'd use proper JSON deserialization
      return {};
    }
    return null;
  }

  // Cart data storage
  static Future<void> saveCartData(List<Map<String, dynamic>> cartItems) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert cart items to JSON string
    await prefs.setString(_cartKey, cartItems.toString());
  }

  static Future<List<Map<String, dynamic>>> getCartData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_cartKey);
    if (data != null) {
      // Parse the stored cart data
      return [];
    }
    return [];
  }

  // Water goal storage
  static Future<void> saveWaterGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_waterGoalKey, goal);
  }

  static Future<int> getWaterGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_waterGoalKey) ?? 2000; // Default 2L (2000ml)
  }

  // Water history storage
  static Future<void> saveWaterHistory(
    List<Map<String, dynamic>> history,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_waterHistoryKey, history.toString());
  }

  static Future<List<Map<String, dynamic>>> getWaterHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_waterHistoryKey);
    if (data != null) {
      // Parse the stored history data
      return [];
    }
    return [];
  }

  // Orders storage
  static Future<void> saveOrders(List<Map<String, dynamic>> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ordersKey, orders.toString());
  }

  static Future<List<Map<String, dynamic>>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_ordersKey);
    if (data != null) {
      // Parse the stored orders data
      return [];
    }
    return [];
  }

  // Theme storage
  static Future<void> saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  static Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  // Language storage
  static Future<void> saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'ar';
  }

  // Clear all data
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Clear specific data
  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  static Future<void> clearWaterHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_waterHistoryKey);
  }
}
