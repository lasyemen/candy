import '../../models/customer.dart';
import 'supabase_service.dart';
import 'customer_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

      // Validate input data
      if (name.trim().isEmpty) {
        throw Exception('Name is required');
      }
      if (phone.trim().isEmpty) {
        throw Exception('Phone number is required');
      }

      // Prepare customer data
      final customerData = {
        'name': name.trim(),
        'phone': phone.trim(),
        'address':
            address?.trim() ??
            '', // Provide empty string as default for NOT NULL constraint
        'is_active': true,
        'total_spent': 0,
        'orders_count': 0,
        'rating': 0.0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Upserting customer: ${customerData['phone']}');

      // Single round-trip: upsert on phone to avoid existence pre-check
      // Prefer a DB-agnostic manual upsert to avoid reliance on UNIQUE constraints
      // 1) Try to find an existing customer by phone
      final existing = await _supabaseService.client
          .from('customers')
          .select('id')
          .eq('phone', customerData['phone'] as String)
          .maybeSingle()
          .timeout(const Duration(seconds: 6));

      if (existing != null) {
        // 2) Update existing customer
        final updated = await _supabaseService.client
            .from('customers')
            .update({
              'name': customerData['name'],
              'address': customerData['address'],
              'is_active': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id'])
            .select('*')
            .single()
            .timeout(const Duration(seconds: 6));

        print('Customer updated successfully');
        return Customer.fromJson(updated);
      } else {
        // 3) Insert new customer
        final inserted = await _supabaseService.client
            .from('customers')
            .insert(customerData)
            .select('*')
            .single()
            .timeout(const Duration(seconds: 6));

        print('Customer inserted successfully');
        return Customer.fromJson(inserted);
      }
    } catch (e) {
      print('Error registering customer: $e');
      print('Error details: ${e.toString()}');
      print('Error type: ${e.runtimeType}');

      if (e is PostgrestException) {
        print('PostgrestException details: ${e.message}');
        print('PostgrestException details: ${e.details}');
        print('PostgrestException hint: ${e.hint}');
        print('PostgrestException code: ${e.code}');

        // Provide more specific error messages based on PostgrestException
        if (e.code == '23505') {
          // Unique violation
          throw Exception('Phone number already exists');
        } else if (e.code == '23502') {
          // Not null violation
          throw Exception('Required fields are missing');
        } else if (e.code == '42P01') {
          // Undefined table
          throw Exception('Database table not found');
        } else if (e.code == '42501') {
          // Insufficient privilege - RLS policy issue
          throw Exception('Database permission denied - Check RLS policies');
        } else {
          throw Exception('Database error: ${e.message}');
        }
      } else if (e.toString().contains('connection') ||
          e.toString().contains('network')) {
        throw Exception('Network connection failed');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Request timeout');
      } else {
        rethrow; // Re-throw the exception to let the calling code handle it
      }
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

        // Set current customer in session and wait until session, cart merge, and cache updates complete
        await CustomerSession.instance.setCurrentCustomer(customer);

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
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

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

  // Test database connectivity
  Future<bool> testDatabaseConnection() async {
    try {
      print('Testing database connection...');
      print('Supabase client: ${_supabaseService.client}');

      // Try to check if the table exists by attempting a simple query
      final response = await _supabaseService.client
          .from('customers')
          .select('*')
          .limit(1);
      print('Database connection test successful: $response');

      // Also test the table structure (no assignment to avoid lints)
      print('Testing table structure...');
      await _supabaseService.client
          .from('customers')
          .select(
            'id, name, phone, address, is_active, total_spent, orders_count, rating, created_at, updated_at',
          )
          .limit(0);
      print('Table structure test successful');

      return true;
    } catch (e) {
      print('Database connection test failed: $e');
      print('Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        print('PostgrestException message: ${e.message}');
        print('PostgrestException details: ${e.details}');
        print('PostgrestException hint: ${e.hint}');
        print('PostgrestException code: ${e.code}');
      }
      return false;
    }
  }

  // Test signup process
  Future<Map<String, dynamic>> testSignupProcess({
    required String name,
    required String phone,
    String? address,
  }) async {
    try {
      print('Testing signup process for: $name, $phone');

      // Test database connection
      final connectionOk = await testDatabaseConnection();
      if (!connectionOk) {
        return {
          'success': false,
          'error': 'Database connection failed',
          'step': 'connection_test',
        };
      }

      // Test customer existence check
      final exists = await customerExists(phone: phone);
      print('Customer exists test result: $exists');

      // Test registration
      final customer = await registerCustomer(
        name: name,
        phone: phone,
        address: address,
      );

      if (customer != null) {
        return {'success': true, 'customer': customer, 'step': 'registration'};
      } else {
        return {
          'success': false,
          'error': 'Registration returned null',
          'step': 'registration',
        };
      }
    } catch (e) {
      print('Test signup process failed: $e');
      return {'success': false, 'error': e.toString(), 'step': 'unknown'};
    }
  }

  // Comprehensive debugging method for account creation issues
  Future<Map<String, dynamic>> debugAccountCreation({
    required String name,
    required String phone,
    String? address,
  }) async {
    final debugInfo = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'input_data': {'name': name, 'phone': phone, 'address': address},
      'steps': <Map<String, dynamic>>[],
    };

    try {
      // Step 1: Validate input
      debugInfo['steps'].add({
        'step': 'input_validation',
        'status': 'started',
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (name.trim().isEmpty) {
        debugInfo['steps'].last['status'] = 'failed';
        debugInfo['steps'].last['error'] = 'Name is empty';
        return debugInfo;
      }
      if (phone.trim().isEmpty) {
        debugInfo['steps'].last['status'] = 'failed';
        debugInfo['steps'].last['error'] = 'Phone is empty';
        return debugInfo;
      }

      debugInfo['steps'].last['status'] = 'success';

      // Step 2: Test database connection
      debugInfo['steps'].add({
        'step': 'database_connection',
        'status': 'started',
        'timestamp': DateTime.now().toIso8601String(),
      });

      final connectionOk = await testDatabaseConnection();
      if (!connectionOk) {
        debugInfo['steps'].last['status'] = 'failed';
        debugInfo['steps'].last['error'] = 'Database connection failed';
        return debugInfo;
      }

      debugInfo['steps'].last['status'] = 'success';

      // Step 3: Check customer existence
      debugInfo['steps'].add({
        'step': 'customer_existence_check',
        'status': 'started',
        'timestamp': DateTime.now().toIso8601String(),
      });

      final exists = await customerExists(phone: phone);
      debugInfo['steps'].last['status'] = 'success';
      debugInfo['steps'].last['result'] = exists;

      // Step 4: Attempt registration
      debugInfo['steps'].add({
        'step': 'customer_registration',
        'status': 'started',
        'timestamp': DateTime.now().toIso8601String(),
      });

      final customer = await registerCustomer(
        name: name,
        phone: phone,
        address: address,
      );

      if (customer != null) {
        debugInfo['steps'].last['status'] = 'success';
        debugInfo['steps'].last['customer_id'] = customer.id;
        debugInfo['final_result'] = 'success';
      } else {
        debugInfo['steps'].last['status'] = 'failed';
        debugInfo['steps'].last['error'] = 'Registration returned null';
        debugInfo['final_result'] = 'failed';
      }
    } catch (e) {
      if (debugInfo['steps'].isNotEmpty) {
        debugInfo['steps'].last['status'] = 'failed';
        debugInfo['steps'].last['error'] = e.toString();
      }
      debugInfo['final_result'] = 'failed';
      debugInfo['exception'] = e.toString();
    }

    return debugInfo;
  }
}
