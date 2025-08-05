import '../../models/index.dart';
import 'supabase_service.dart';
import 'customer_session.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  final SupabaseService _supabaseService = SupabaseService.instance;

  // Customer registration
  Future<Customer?> registerCustomer({
    required String name,
    required String phone,
    String? address,
  }) async {
    try {
      print('Starting customer registration for: $name, $phone');

      // Generate a unique ID for the customer
      final customerId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create customer record directly in customers table
      final customerData = {
        'id': customerId,
        'name': name,
        'phone': phone,
        'address': address,
        'is_active': true,
        'total_spent': 0.0,
        'orders_count': 0,
        'rating': 0.0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Inserting customer data: $customerData');
      await _supabaseService.insertData('customers', customerData);

      // Fetch the created customer
      print('Fetching created customer with ID: $customerId');
      final customerResponse = await _supabaseService.fetchById(
        'customers',
        customerId,
      );

      print('Customer response: $customerResponse');
      if (customerResponse != null) {
        return Customer.fromJson(customerResponse);
      }

      return null;
    } catch (e) {
      print('Error registering customer: $e');
      return null;
    }
  }

  // Customer login by phone
  Future<Customer?> loginCustomer({required String phone}) async {
    try {
      print('Attempting to login customer with phone: $phone');

      // Find customer by phone number directly from customers table
      final response = await _supabaseService.client
          .from('customers')
          .select()
          .eq('phone', phone)
          .eq('is_active', true)
          .maybeSingle();

      print('Login response: $response');
      if (response != null) {
        // Update last login
        await _supabaseService.updateData('customers', response['id'], {
          'last_login': DateTime.now().toIso8601String(),
        });

        final customer = Customer.fromJson(response);

        // Set current customer in session
        CustomerSession.instance.setCurrentCustomer(customer);

        return customer;
      }

      return null;
    } catch (e) {
      print('Error logging in customer: $e');
      return null;
    }
  }

  // Check if customer exists
  Future<bool> customerExists({required String phone}) async {
    try {
      print('Checking if customer exists with phone: $phone');
      final response = await _supabaseService.client
          .from('customers')
          .select('id')
          .eq('phone', phone)
          .eq('is_active', true)
          .maybeSingle();

      print('Customer exists response: $response');
      return response != null;
    } catch (e) {
      print('Error checking customer existence: $e');
      return false;
    }
  }

  // Get current customer
  Customer? getCurrentCustomer() {
    final user = _supabaseService.currentUser;
    if (user != null) {
      // You might want to fetch the full customer data here
      // For now, return null and let the calling code handle it
      return null;
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    await _supabaseService.signOut();
  }
}
