import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/products.dart';
import '../core/services/cart_service.dart';

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
  final Cart? cart;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;
  final String currentLanguage;

  AppLoadedState({
    required this.currentIndex,
    required this.cartItemCount,
    this.cart,
    required this.isLoading,
    this.errorMessage,
    required this.isInitialized,
    required this.currentLanguage,
  });

  AppLoadedState copyWith({
    int? currentIndex,
    int? cartItemCount,
    Cart? cart,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    String? currentLanguage,
  }) {
    return AppLoadedState(
      currentIndex: currentIndex ?? this.currentIndex,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      cart: cart ?? this.cart,
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
    cart: null,
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

        // For now, we'll use a simple approach
        // In a real app, you'd get the customer ID from user session
        const customerId = 'temp-customer-id';

        // Get or create cart
        Cart? cart = currentState.cart;
        if (cart == null) {
          print('AppBloc - Creating new cart for customer: $customerId');
          cart = await CartService.createCart(customerId);
          print('AppBloc - New cart created with ID: ${cart.id}');
        } else {
          print('AppBloc - Using existing cart: ${cart.id}');
        }

        // Add item to cart
        print('AppBloc - Adding item to cart: ${cart.id}');
        final cartItem = await CartService.addToCart(cart.id, product.id, 1);
        print('AppBloc - Cart item added successfully: ${cartItem.id}');

        // Refresh cart
        print('AppBloc - Refreshing cart data');
        cart = await CartService.getCurrentCustomerCart();
        print(
          'AppBloc - Cart items after refresh: ${cart?.items?.length ?? 0}',
        );

        if (cart != null) {
          print(
            'AppBloc - Updating state with cart: ${cart.items?.length ?? 0} items',
          );
          _state = currentState.copyWith(
            cart: cart,
            cartItemCount: cart.items?.length ?? 0,
          );
          notifyListeners();
          print('AppBloc - Cart updated successfully in state');
        } else {
          print('AppBloc - Warning: Cart is null after refresh');
          _state = currentState.copyWith(
            errorMessage: 'Failed to refresh cart data',
          );
          notifyListeners();
        }
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
        if (currentState.cart != null) {
          // Find the cart item with this product ID and remove it
          final items = currentState.cart!.items ?? [];
          final itemToRemove = items.firstWhere(
            (item) => item.productId == productId,
            orElse: () => throw Exception('Item not found'),
          );

          await CartService.removeFromCart(itemToRemove.id);

          // Refresh cart
          final cart = await CartService.getCurrentCustomerCart();

          _state = currentState.copyWith(
            cart: cart,
            cartItemCount: cart?.items?.length ?? 0,
          );
          notifyListeners();
        }
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
        if (currentState.cart != null) {
          final items = currentState.cart!.items ?? [];
          final itemToUpdate = items.firstWhere(
            (item) => item.productId == productId,
            orElse: () => throw Exception('Item not found'),
          );

          if (quantity <= 0) {
            await CartService.removeFromCart(itemToUpdate.id);
          } else {
            await CartService.updateCartItem(itemToUpdate.id, quantity);
          }

          // Refresh cart
          final cart = await CartService.getCurrentCustomerCart();

          _state = currentState.copyWith(
            cart: cart,
            cartItemCount: cart?.items?.length ?? 0,
          );
          notifyListeners();
        }
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
        if (currentState.cart != null) {
          await CartService.clearCart(currentState.cart!.id);

          _state = currentState.copyWith(cart: null, cartItemCount: 0);
          notifyListeners();
        }
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
  Cart? get cart => (_state as AppLoadedState).cart;
  bool get isLoading => (_state as AppLoadedState).isLoading;
  String? get errorMessage => (_state as AppLoadedState).errorMessage;
  bool get isInitialized => (_state as AppLoadedState).isInitialized;
  String get currentLanguage => (_state as AppLoadedState).currentLanguage;

  // Cart utilities
  double get cartTotal {
    final currentCart = cart;
    if (currentCart?.items == null) return 0;

    double total = 0;
    for (final item in currentCart!.items!) {
      // Use a default price of 5.0 for now
      // In a real app, you'd fetch product details to get the actual price
      total += item.quantity * 5.0;
    }
    return total;
  }

  int get cartItemsCount => cart?.items?.length ?? 0;

  // Helper method to get cart items with product details for UI
  List<Map<String, dynamic>> get cartItemsWithDetails {
    final currentCart = cart;
    if (currentCart?.items == null) return [];

    return currentCart!.items!.map((item) {
      // Create a mock product for now
      // In a real app, you'd fetch the actual product details
      final mockProduct = {
        'id': item.productId,
        'name': 'مياه كاندي ${item.productId}', // Mock name
        'price': 5.0, // Mock price
      };

      return {
        'id': item.id,
        'product': mockProduct,
        'quantity': item.quantity,
        'totalPrice': item.quantity * 5.0, // Mock calculation
      };
    }).toList();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
