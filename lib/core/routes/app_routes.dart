import 'package:flutter/material.dart';
import '../../screens/index.dart';

/// App Routes Configuration
/// This file contains all the routes for the application
/// Each route is defined with a constant string and a builder function
class AppRoutes {
  // Route names as constants for easy reference
  static const String splash = '/';
  static const String auth = '/auth';
  static const String signin = '/signin';
  static const String signup = '/signup';
  static const String createPassword = '/create-password';
  static const String otp = '/otp';
  static const String merchantSignup = '/merchant-signup';
  static const String merchantDocuments = '/merchant-documents';
  static const String main = '/main';
  static const String home = '/home';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String userDashboard = '/user-dashboard';
  static const String healthTracker = '/health-tracker';
  static const String deliveryLocation = '/delivery-location';
  static const String paymentTracking = '/payment-tracking';

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
      createPassword: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return CreatePasswordScreen(
          userName: args?['userName'] ?? '',
          userPhone: args?['userPhone'] ?? '',
        );
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
      main: (context) => const MainScreen(),
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
}
