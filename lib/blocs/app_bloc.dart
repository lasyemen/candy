import 'package:flutter/material.dart';
import '../models/products.dart';
import '../core/services/cart_service.dart';
import '../core/services/customer_session.dart';
import '../core/services/cart_cache_manager.dart';

// Events
abstract class AppEvent {}

class SetCurrentIndexEvent extends AppEvent {
  final int index;
  SetCurrentIndexEvent(this.index);
}

class SetCartItemCountEvent extends AppEvent {
  final int count;
  SetCartItemCountEvent(this.count);
}

class AddToCartEvent extends AppEvent {
  final Products product;
  AddToCartEvent(this.product);
}

class RemoveFromCartEvent extends AppEvent {
  final String productId;
  RemoveFromCartEvent(this.productId);
}

class UpdateCartItemQuantityEvent extends AppEvent {
  final String productId;
  final int quantity;
  UpdateCartItemQuantityEvent(this.productId, this.quantity);
}

class ClearCartEvent extends AppEvent {}

class SetLoadingEvent extends AppEvent {
  final bool loading;
  SetLoadingEvent(this.loading);
}

class SetErrorEvent extends AppEvent {
  final String? message;
  SetErrorEvent(this.message);
}

class ClearErrorEvent extends AppEvent {}

class SetInitializedEvent extends AppEvent {
  final bool initialized;
  SetInitializedEvent(this.initialized);
}

class SetLanguageEvent extends AppEvent {
  final String language;
  SetLanguageEvent(this.language);
}

class RefreshAppEvent extends AppEvent {}

// States
abstract class AppState {}

class AppInitialState extends AppState {}

class AppLoadedState extends AppState {
  final int currentIndex;
  final int cartItemCount;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;
  final String currentLanguage;

  AppLoadedState({
    required this.currentIndex,
    required this.cartItemCount,
    required this.isLoading,
    this.errorMessage,
    required this.isInitialized,
    required this.currentLanguage,
  });

  AppLoadedState copyWith({
    int? currentIndex,
    int? cartItemCount,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    String? currentLanguage,
  }) {
    return AppLoadedState(
      currentIndex: currentIndex ?? this.currentIndex,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
      currentLanguage: currentLanguage ?? this.currentLanguage,
    );
  }
}

// BLoC
class AppBloc extends ChangeNotifier {
  AppState _state = AppLoadedState(
    currentIndex: 2, // Home is default
    cartItemCount: 0,
    isLoading: false,
    errorMessage: null,
    isInitialized: false,
    currentLanguage: 'ar',
  );

  AppState get state => _state;

  void add(AppEvent event) {
    if (event is SetCurrentIndexEvent) {
      _setCurrentIndex(event.index);
    } else if (event is SetCartItemCountEvent) {
      _setCartItemCount(event.count);
    } else if (event is AddToCartEvent) {
      _addToCart(event.product);
    } else if (event is RemoveFromCartEvent) {
      _removeFromCart(event.productId);
    } else if (event is UpdateCartItemQuantityEvent) {
      _updateCartItemQuantity(event.productId, event.quantity);
    } else if (event is ClearCartEvent) {
      _clearCart();
    } else if (event is SetLoadingEvent) {
      _setLoading(event.loading);
    } else if (event is SetErrorEvent) {
      _setError(event.message);
    } else if (event is ClearErrorEvent) {
      _clearError();
    } else if (event is SetInitializedEvent) {
      _setInitialized(event.initialized);
    } else if (event is SetLanguageEvent) {
      _setLanguage(event.language);
    } else if (event is RefreshAppEvent) {
      _refresh();
    }
  }

  void _setCurrentIndex(int index) {
    if (_state is AppLoadedState) {
      final currentState = _state as AppLoadedState;
      _state = currentState.copyWith(currentIndex: index);
      notifyListeners();
    }
  }

  void _setCartItemCount(int count) {
    if (_state is AppLoadedState) {
      final currentState = _state as AppLoadedState;
      _state = currentState.copyWith(cartItemCount: count);
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_state is AppLoadedState) {
      final currentState = _state as AppLoadedState;
      _state = currentState.copyWith(isLoading: loading);
      notifyListeners();
    }
  }

  void _setError(String? message) {
    if (_state is AppLoadedState) {
      final currentState = _state as AppLoadedState;
      _state = currentState.copyWith(errorMessage: message);
      notifyListeners();
    }
  }

  void _clearError() {
    if (_state is AppLoadedState) {
      final currentState = _state as AppLoadedState;
      _state = currentState.copyWith(errorMessage: null);
      notifyListeners();
    }
  }

  void _setInitialized(bool initialized) {
    if (_state is AppLoadedState) {
      final currentState = _state as AppLoadedState;
      _state = currentState.copyWith(isInitialized: initialized);
      notifyListeners();
    }
  }

  void _setLanguage(String language) {
    if (_state is AppLoadedState) {
      final currentState = _state as AppLoadedState;
      _state = currentState.copyWith(currentLanguage: language);
      notifyListeners();
    }
  }

  void _addToCart(Products product) async {
    if (_state is AppLoadedState) {
      final currentState = _state as AppLoadedState;

      try {
        // Debug: Print product information
        print('AppBloc - Adding to cart - Product ID: ${product.id}');
        print('AppBloc - Adding to cart - Product Name: ${product.name}');

        // Create basic guest user if not logged in and no guest user exists
        if (!CustomerSession.instance.isLoggedIn &&
            !CustomerSession.instance.isGuestUser) {
          await CartService.createBasicGuestUser();
        }

        // Cart is now managed by CartManager, no need to manually create it
        print('AppBloc - Using CartManager for cart operations');

        // Add item to cart using CartManager
        print('AppBloc - Adding item to cart: ${product.id}');
        await CartManager.instance.addProduct(product.id, quantity: 1);
        print('AppBloc - Cart item added successfully');

        // Invalidate cart cache to force refresh
        await CartCacheManager.instance.invalidateCache();
        print('AppBloc - Cart cache invalidated');

        // Refresh cart
        print('AppBloc - Refreshing cart data');
        final cartSummary = await CartManager.instance.getCartSummary();
        print(
          'AppBloc - Cart items after refresh: ${cartSummary['itemCount'] ?? 0}',
        );
        print('AppBloc - Cart summary: $cartSummary');

        final itemCount = cartSummary['itemCount'] ?? 0;
        print('AppBloc - Updating state with cart: $itemCount items');
        _state = currentState.copyWith(cartItemCount: itemCount);
        notifyListeners();
        print('AppBloc - Cart updated successfully in state');
      } catch (e) {
        print('AppBloc - Error adding to cart: $e');
        _state = currentState.copyWith(
          errorMessage: 'Error adding to cart: $e',
        );
        notifyListeners();
      }
    } else {
      print('AppBloc - Error: App is not in loaded state');
    }
  }

  void _removeFromCart(String productId) async {
    if (_state is AppLoadedState) {
      final currentState = _state as AppLoadedState;

      try {
        // Get cart summary to find the item ID
        final cartSummary = await CartManager.instance.getCartSummary();
        final items = cartSummary['items'] as List<dynamic>? ?? [];

        // Find the item with this product ID
        final itemToRemove = items.firstWhere(
          (item) => item['product_id'] == productId,
          orElse: () => throw Exception('Item not found'),
        );

        await CartManager.instance.removeProduct(itemToRemove['id'].toString());

        // Invalidate cart cache to force refresh
        await CartCacheManager.instance.invalidateCache();

        // Refresh cart
        final updatedCartSummary = await CartManager.instance.getCartSummary();
        final itemCount = updatedCartSummary['itemCount'] ?? 0;

        _state = currentState.copyWith(cartItemCount: itemCount);
        notifyListeners();
      } catch (e) {
        _state = currentState.copyWith(
          errorMessage: 'Error removing from cart: $e',
        );
        notifyListeners();
      }
    }
  }

  void _updateCartItemQuantity(String productId, int quantity) async {
    if (_state is AppLoadedState) {
      final currentState = _state as AppLoadedState;

      try {
        // Get cart summary to find the item ID
        final cartSummary = await CartManager.instance.getCartSummary();
        final items = cartSummary['items'] as List<dynamic>? ?? [];

        // Find the item with this product ID
        final itemToUpdate = items.firstWhere(
          (item) => item['product_id'] == productId,
          orElse: () => throw Exception('Item not found'),
        );

        if (quantity <= 0) {
          await CartManager.instance.removeProduct(
            itemToUpdate['id'].toString(),
          );
        } else {
          await CartManager.instance.updateQuantity(
            itemToUpdate['id'].toString(),
            quantity,
          );
        }

        // Invalidate cart cache to force refresh
        await CartCacheManager.instance.invalidateCache();

        // Refresh cart
        final updatedCartSummary = await CartManager.instance.getCartSummary();
        final itemCount = updatedCartSummary['itemCount'] ?? 0;

        _state = currentState.copyWith(cartItemCount: itemCount);
        notifyListeners();
      } catch (e) {
        _state = currentState.copyWith(errorMessage: 'Error updating cart: $e');
        notifyListeners();
      }
    }
  }

  void _clearCart() async {
    if (_state is AppLoadedState) {
      final currentState = _state as AppLoadedState;

      try {
        await CartManager.instance.clearCart();

        _state = currentState.copyWith(cartItemCount: 0);
        notifyListeners();
      } catch (e) {
        _state = currentState.copyWith(errorMessage: 'Error clearing cart: $e');
        notifyListeners();
      }
    }
  }

  void _refresh() {
    notifyListeners();
  }

  // Convenience getters for backward compatibility
  int get currentIndex => (_state as AppLoadedState).currentIndex;
  int get cartItemCount => (_state as AppLoadedState).cartItemCount;
  bool get isLoading => (_state as AppLoadedState).isLoading;
  String? get errorMessage => (_state as AppLoadedState).errorMessage;
  bool get isInitialized => (_state as AppLoadedState).isInitialized;
  String get currentLanguage => (_state as AppLoadedState).currentLanguage;

  // Cart utilities - These will be updated to use CartManager in the future
  double get cartTotal {
    // TODO: Implement using CartManager.getCartSummary()
    return 0.0;
  }

  int get cartItemsCount => cartItemCount;

  // Helper method to get cart items with product details for UI
  List<Map<String, dynamic>> get cartItemsWithDetails {
    // TODO: Implement using CartManager.getCartSummary()
    return [];
  }

  @override
  void dispose() {
    super.dispose();
  }
}
