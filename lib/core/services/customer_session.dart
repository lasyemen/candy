import '../../models/customer.dart';

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
  void setCurrentCustomer(Customer customer) {
    _currentCustomer = customer;
    print(
      'CustomerSession - Customer logged in: ${customer.name} (${customer.phone})',
    );
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
