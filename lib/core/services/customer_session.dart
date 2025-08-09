import '../../models/customer.dart';
import 'cart_service.dart';
import 'guest_user_service.dart';

class CustomerSession {
  static CustomerSession? _instance;
  static CustomerSession get instance => _instance ??= CustomerSession._();

  CustomerSession._();

  Customer? _currentCustomer;
  Map<String, dynamic>? _guestUser;

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
}
