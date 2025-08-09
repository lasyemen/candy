import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/customer.dart';
import 'supabase_service.dart';

class GuestUserService {
  static const String _guestUserKey = 'guest_user_data';
  static const String _guestSessionKey = 'guest_session_id';

  static GuestUserService? _instance;
  static GuestUserService get instance => _instance ??= GuestUserService._();

  GuestUserService._();

  // Save guest user data to shared preferences
  Future<void> saveGuestUser({
    required String name,
    required String phone,
    String? address,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final guestData = {
      'name': name,
      'phone': phone,
      'address': address,
      'created_at': DateTime.now().toIso8601String(),
      'is_guest': true,
    };

    await prefs.setString(_guestUserKey, jsonEncode(guestData));
    print('GuestUserService - Guest user data saved: $name ($phone)');
  }

  // Get guest user data from shared preferences
  Future<Map<String, dynamic>?> getGuestUser() async {
    final prefs = await SharedPreferences.getInstance();
    final guestDataString = prefs.getString(_guestUserKey);

    if (guestDataString != null) {
      final guestData = jsonDecode(guestDataString) as Map<String, dynamic>;
      print('GuestUserService - Retrieved guest user: ${guestData['name']}');
      return guestData;
    }

    return null;
  }

  // Save guest session ID
  Future<void> saveGuestSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestSessionKey, sessionId);
    print('GuestUserService - Guest session ID saved: $sessionId');
  }

  // Get guest session ID
  Future<String?> getGuestSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_guestSessionKey);
  }

  // Clear guest user data
  Future<void> clearGuestUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestUserKey);
    await prefs.remove(_guestSessionKey);
    print('GuestUserService - Guest user data cleared');
  }

  // Convert guest user to regular customer (only called during sign-up)
  Future<Customer?> convertGuestToCustomer({
    required String name,
    required String phone,
    String? address,
  }) async {
    try {
      print(
        'GuestUserService - Converting guest user to customer: $name ($phone)',
      );

      // Check if user already exists by phone
      final existingUser = await SupabaseService.instance.client
          .from('customers')
          .select('*')
          .eq('phone', phone)
          .maybeSingle();

      if (existingUser != null) {
        print('GuestUserService - User already exists, updating...');

        // Update existing user
        final updatedUser = await SupabaseService.instance.client
            .from('customers')
            .update({
              'name': name,
              'address': address,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('phone', phone)
            .select()
            .single();

        print('GuestUserService - User updated successfully');
        return Customer.fromJson(updatedUser);
      } else {
        print('GuestUserService - Creating new customer...');

        // Create new customer
        final newUser = await SupabaseService.instance.client
            .from('customers')
            .insert({
              'name': name,
              'phone': phone,
              'address': address,
              'is_active': true,
              'total_spent': 0,
              'orders_count': 0,
              'rating': 0.0,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        print('GuestUserService - New customer created successfully');
        return Customer.fromJson(newUser);
      }
    } catch (e) {
      print('GuestUserService - Error converting guest to customer: $e');
      throw Exception('Failed to convert guest to customer: $e');
    }
  }

  // Check if current user is a guest
  Future<bool> isGuestUser() async {
    final guestData = await getGuestUser();
    return guestData != null && guestData['is_guest'] == true;
  }

  // Get guest user display name
  Future<String> getGuestDisplayName() async {
    final guestData = await getGuestUser();
    if (guestData != null) {
      return guestData['name'] ?? 'Guest';
    }
    return 'Guest';
  }
}
