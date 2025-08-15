# App Routes Documentation

## Overview
This directory contains the routing configuration for the Candy Water application. All routes are centralized in `app_routes.dart` for easy management and maintenance.

## Route Constants

### Authentication Routes
- `AppRoutes.auth` - Authentication screen (login/signup)

### Main Application Routes
- `AppRoutes.main` - Main application screen with bottom navigation
- `AppRoutes.home` - Home screen with products
- `AppRoutes.cart` - Shopping cart screen
- `AppRoutes.orders` - User orders screen
- `AppRoutes.userDashboard` - User dashboard/profile
 - `AppRoutes.rewards` - Rewards and vouchers

### Delivery & Payment Routes
- `AppRoutes.deliveryLocation` - Delivery location selection

## Usage Examples

### Basic Navigation
```dart
// Navigate to a route
AppRoutes.navigateTo(context, AppRoutes.home);

// Navigate with arguments
// Payment tracking removed; use AppRoutes.cardPayment for payment
  arguments: {'orderId': '123', 'status': 'pending'});
```

### Replacement Navigation
```dart
// Replace current route
AppRoutes.navigateToReplacement(context, AppRoutes.main);

// Clear all routes and navigate
AppRoutes.navigateToAndClearAll(context, AppRoutes.auth);
```

### Navigation Back
```dart
// Go back to previous screen
AppRoutes.goBack(context);

// Go back to specific route
AppRoutes.goBackTo(context, AppRoutes.main);
```

## Adding New Routes

1. Add the route constant in `AppRoutes` class:
```dart
static const String newScreen = '/new-screen';
```

2. Add the route builder in `getRoutes()` method:
```dart
newScreen: (context) => const NewScreen(),
```

3. Import the new screen in `screens/index.dart`

## Best Practices

- Always use route constants instead of hardcoded strings
- Use appropriate navigation methods based on the use case
- Pass arguments when needed for screen-specific data
- Keep route names descriptive and consistent 