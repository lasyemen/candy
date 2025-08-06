import '../../models/customer.dart';
import 'cart_service.dart';

class CustomerSession {
  static CustomerSession? _instance;
  static CustomerSession get instance => _instance ??= CustomerSession._();

  CustomerSession._();

  Customer? _currentCustomer;

  // Get current customer
  Customer? get currentCustomer => _currentCustomer;

  // Get current customer phone
  String? get currentCustomerPhone => _currentCustomer?.phone;

  // Get current customer ID
  String? get currentCustomerId => _currentCustomer?.id;

  // Set current customer (called after successful login)
  Future<void> setCurrentCustomer(Customer customer) async {
    _currentCustomer = customer;
    print(
      'CustomerSession - Customer logged in: ${customer.name} (${customer.phone})',
    );

    // Merge guest cart into user cart if there was a guest session
    try {
      await CartService.mergeGuestCartIntoUserCart(customer.id);
    } catch (e) {
      print('CustomerSession - Error merging guest cart: $e');
      // Don't throw here as login should still succeed even if cart merge fails
    }
  }

  // Clear current customer (called on logout)
  void clearCurrentCustomer() {
    _currentCustomer = null;
    print('CustomerSession - Customer logged out');
  }

  // Check if customer is logged in
  bool get isLoggedIn => _currentCustomer != null;

  // Get customer name for display
  String get customerName => _currentCustomer?.name ?? 'Guest';
}
