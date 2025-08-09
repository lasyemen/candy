import 'package:flutter/material.dart';
import '../../screens/index.dart';
import '../../screens/product_details_screen.dart';
import '../../models/products.dart';

/// App Routes Configuration
/// This file contains all the routes for the application
/// Each route is defined with a constant string and a builder function
class AppRoutes {
  // Route names as constants for easy reference
  static const String splash = '/';
  static const String auth = '/auth';
  static const String signin = '/signin';
  static const String signup = '/signup';

  static const String otp = '/otp';
  static const String merchantSignup = '/merchant-signup';
  static const String merchantDocuments = '/merchant-documents';
  static const String merchantApproval = '/merchant-approval';
  static const String main = '/main';
  static const String home = '/home';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String userDashboard = '/user-dashboard';
  static const String healthTracker = '/health-tracker';
  static const String deliveryLocation = '/delivery-location';
  static const String paymentTracking = '/payment-tracking';
  static const String productDetails = '/product-details';

  /// Get all routes for the application
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // Authentication Routes
      auth: (context) => const AuthScreen(),
      signin: (context) => const SignInScreen(),
      signup: (context) => const SignUpScreen(),
      merchantSignup: (context) => const MerchantSignupScreen(),
      merchantDocuments: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return MerchantDocumentsScreen(merchantData: args ?? {});
      },
      merchantApproval: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return MerchantApprovalScreen(merchantData: args ?? {});
      },

      otp: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return OtpScreen(
          userName: args?['userName'] ?? '',
          userPhone: args?['userPhone'] ?? '',
        );
      },

      // Main Application Routes
      main: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final initialIndex = (args != null && args['initialIndex'] is int)
            ? args['initialIndex'] as int
            : 2;
        return MainScreen(initialIndex: initialIndex);
      },
      home: (context) => const HomeScreen(),
      cart: (context) => const CartScreen(),
      orders: (context) => const MyOrdersScreen(),
      userDashboard: (context) => const UserDashboard(),
      healthTracker: (context) => const HealthTracker(),

      // Delivery and Payment Routes
      deliveryLocation: (context) => const DeliveryLocationScreen(),
      paymentTracking: (context) {
        final deliveryData =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return PaymentTrackingScreen(deliveryData: deliveryData);
      },

      // Product Routes
      productDetails: (context) {
        final product = ModalRoute.of(context)?.settings.arguments as Products?;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: ProductDetailsScreen(product: product!),
        );
      },
    };
  }

  /// Navigate to a route with optional arguments
  static void navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  /// Navigate to a route and replace the current route
  static void navigateToReplacement(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  /// Navigate to a route and clear all previous routes
  static void navigateToAndClearAll(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Go back to previous route
  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }

  /// Go back to a specific route
  static void goBackTo(BuildContext context, String routeName) {
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }

  /// Show product details as a bottom sheet
  static void showProductDetails(BuildContext context, Products product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailsScreen(product: product),
    );
  }
}
