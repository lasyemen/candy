import '../core/services/auth_service.dart';
import '../core/services/customer_session.dart';
import '../core/services/merchant_service.dart';
import 'phone_utils.dart';

class AuthActions {
  /// Logs in customer by phone, sets session, and returns whether the phone belongs to a merchant
  static Future<bool> signInAndSetSession(String rawPhone) async {
    final String? normalized = PhoneUtils.normalizeKsaPhone(rawPhone);
    if (normalized == null) return false;
    final String phone = normalized;

    // Check merchant record to tag session (optional)
    final merchantRecord = await MerchantService.instance.findMerchantByPhone(
      phone,
    );

    // Ensure customer exists
    final customerExists = await AuthService.instance.customerExists(
      phone: phone,
    );
    if (!customerExists) {
      return false; // caller should show proper message
    }

    // Login
    final customer = await AuthService.instance.loginCustomer(phone: phone);
    if (customer == null) {
      return false;
    }

    // Mark session merchant flag but always return true on successful login
    final bool isMerchant = merchantRecord != null;
    await CustomerSession.instance.setMerchant(isMerchant);
    return true;
  }

  /// Registers a new customer and sets session. Returns the customer's name if successful.
  static Future<String?> signUpAndSetSession({
    required String name,
    required String phone,
    String? address,
  }) async {
    final String? normalized = PhoneUtils.normalizeKsaPhone(phone);
    if (normalized == null) return null;

    final customer = await AuthService.instance.registerCustomer(
      name: name,
      phone: normalized,
      address: address,
    );

    if (customer == null) {
      return null;
    }

    // Set current customer (handles guest/cart merging internally)
    await CustomerSession.instance.setCurrentCustomer(customer);
    return customer.name;
  }
}
