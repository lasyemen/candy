import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/customer.dart';
import 'cart_service.dart';
import 'guest_user_service.dart';
import 'cart_cache_manager.dart';
import 'cart_session_manager.dart';

class CustomerSession {
  static CustomerSession? _instance;
  static CustomerSession get instance => _instance ??= CustomerSession._();

  CustomerSession._();

  Customer? _currentCustomer;
  Map<String, dynamic>? _guestUser;

  static const String _currentCustomerKey = 'current_customer_data_v1';
  static const String _isMerchantKey = 'current_customer_is_merchant_v1';
  bool _isMerchant = false;

  // Get current customer
  Customer? get currentCustomer => _currentCustomer;

  // Get current customer phone
  String? get currentCustomerPhone =>
      _currentCustomer?.phone ?? _guestUser?['phone'];

  // Get current customer ID
  String? get currentCustomerId => _currentCustomer?.id;

  // Set current customer (called after successful login)
  Future<void> setCurrentCustomer(Customer customer) async {
    _currentCustomer = customer;
    _guestUser = null; // Clear guest user when logged in
    print(
      'CustomerSession - Customer logged in: ${customer.name} (${customer.phone})',
    );

    // Persist current customer locally for auto-login across app restarts
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentCustomerKey, jsonEncode(customer.toJson()));
    } catch (e) {
      print('CustomerSession - Failed to persist current customer: $e');
    }

    // Merge guest cart into user cart and wait for completion
    try {
      await CartService.mergeGuestCartIntoUserCart(customer.id);
      print('CustomerSession - Guest cart merged successfully');
    } catch (e) {
      print('CustomerSession - Error merging guest cart: $e');
      // Don't throw here as login should still succeed even if cart merge fails
    }

    // Clear guest user data from shared preferences after cart merging
    await GuestUserService.instance.clearGuestUser();
    print('CustomerSession - Guest user data cleared from shared preferences');

    // Invalidate cart cache and re-initialize cart session so UI fetches fresh data
    try {
      await CartCacheManager.instance.invalidateCache();
      print('CustomerSession - Cart cache invalidated after login');
    } catch (e) {
      print('CustomerSession - Failed to invalidate cart cache: $e');
    }

    try {
      await CartSessionManager.instance.initializeSession();
      print('CustomerSession - Cart session re-initialized after login');
    } catch (e) {
      print('CustomerSession - Failed to re-initialize cart session: $e');
    }
  }

  // Set guest user (called when guest user data is saved)
  Future<void> setGuestUser({
    required String name,
    required String phone,
    String? address,
  }) async {
    _guestUser = {
      'name': name,
      'phone': phone,
      'address': address,
      'is_guest': true,
    };

    // Save to shared preferences
    await GuestUserService.instance.saveGuestUser(
      name: name,
      phone: phone,
      address: address,
    );

    print('CustomerSession - Guest user set: $name ($phone)');
  }

  // Load guest user from shared preferences
  Future<void> loadGuestUser() async {
    _guestUser = await GuestUserService.instance.getGuestUser();
    if (_guestUser != null) {
      print('CustomerSession - Guest user loaded: ${_guestUser!['name']}');
    }
  }

  // Clear current customer (called on logout)
  void clearCurrentCustomer() {
    _currentCustomer = null;
    _guestUser = null;
    print('CustomerSession - Customer logged out');

    // Clear persisted customer
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_currentCustomerKey);
      prefs.remove(_isMerchantKey);
    });
    _isMerchant = false;
  }

  // Check if customer is logged in
  bool get isLoggedIn => _currentCustomer != null;

  // Check if user is a guest
  bool get isGuestUser => _guestUser != null && _guestUser!['is_guest'] == true;

  // Get customer name for display
  String get customerName {
    if (_currentCustomer != null) {
      return _currentCustomer!.name;
    } else if (_guestUser != null) {
      return _guestUser!['name'] ?? 'Guest';
    }
    return 'Guest';
  }

  // Get guest user data
  Map<String, dynamic>? get guestUser => _guestUser;

  bool get isMerchant => _isMerchant;
  Future<void> setMerchant(bool value) async {
    _isMerchant = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isMerchantKey, value);
    } catch (e) {
      print('CustomerSession - Failed to persist isMerchant: $e');
    }
  }

  // Load current customer from local storage (call on app start)
  Future<void> loadCurrentCustomer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_currentCustomerKey);
      if (data != null && data.isNotEmpty) {
        final Map<String, dynamic> json =
            jsonDecode(data) as Map<String, dynamic>;
        _currentCustomer = Customer.fromJson(json);
        print(
          'CustomerSession - Restored current customer: ${_currentCustomer!.name}',
        );
      }
      _isMerchant = prefs.getBool(_isMerchantKey) ?? false;
    } catch (e) {
      print('CustomerSession - Failed to restore current customer: $e');
    }
  }
}
