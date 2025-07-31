import 'package:flutter/material.dart';
import '../core/models/cart_item.dart';
import '../core/models/water_product.dart';

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
  final WaterProduct product;
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
  final List<CartItem> cartItems;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;
  final String currentLanguage;

  AppLoadedState({
    required this.currentIndex,
    required this.cartItemCount,
    required this.cartItems,
    required this.isLoading,
    this.errorMessage,
    required this.isInitialized,
    required this.currentLanguage,
  });

  AppLoadedState copyWith({
    int? currentIndex,
    int? cartItemCount,
    List<CartItem>? cartItems,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    String? currentLanguage,
  }) {
    return AppLoadedState(
      currentIndex: currentIndex ?? this.currentIndex,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      cartItems: cartItems ?? this.cartItems,
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
    cartItems: [],
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

  void _addToCart(WaterProduct product) {
    if (_state is AppLoadedState) {
      final currentState = _state as AppLoadedState;
      final cartItems = List<CartItem>.from(currentState.cartItems);

      // Check if product already exists in cart
      final existingItemIndex = cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );

      if (existingItemIndex >= 0) {
        // Update quantity of existing item
        final existingItem = cartItems[existingItemIndex];
        cartItems[existingItemIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + 1,
          totalPrice: (existingItem.quantity + 1) * product.price,
        );
      } else {
        // Add new item to cart
        cartItems.add(
          CartItem(product: product, quantity: 1, totalPrice: product.price),
        );
      }

      _state = currentState.copyWith(
        cartItems: cartItems,
        cartItemCount: cartItems.fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        ),
      );
      notifyListeners();
    }
  }

  void _removeFromCart(String productId) {
    if (_state is AppLoadedState) {
      final currentState = _state as AppLoadedState;
      final cartItems = List<CartItem>.from(currentState.cartItems);

      cartItems.removeWhere((item) => item.product.id == productId);

      _state = currentState.copyWith(
        cartItems: cartItems,
        cartItemCount: cartItems.fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        ),
      );
      notifyListeners();
    }
  }

  void _updateCartItemQuantity(String productId, int quantity) {
    if (_state is AppLoadedState) {
      final currentState = _state as AppLoadedState;
      final cartItems = List<CartItem>.from(currentState.cartItems);

      final itemIndex = cartItems.indexWhere(
        (item) => item.product.id == productId,
      );

      if (itemIndex >= 0) {
        if (quantity <= 0) {
          cartItems.removeAt(itemIndex);
        } else {
          final item = cartItems[itemIndex];
          cartItems[itemIndex] = item.copyWith(
            quantity: quantity,
            totalPrice: quantity * item.product.price,
          );
        }

        _state = currentState.copyWith(
          cartItems: cartItems,
          cartItemCount: cartItems.fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          ),
        );
        notifyListeners();
      }
    }
  }

  void _clearCart() {
    if (_state is AppLoadedState) {
      final currentState = _state as AppLoadedState;
      _state = currentState.copyWith(cartItems: [], cartItemCount: 0);
      notifyListeners();
    }
  }

  void _refresh() {
    notifyListeners();
  }

  // Convenience getters for backward compatibility
  int get currentIndex => (_state as AppLoadedState).currentIndex;
  int get cartItemCount => (_state as AppLoadedState).cartItemCount;
  List<CartItem> get cartItems => (_state as AppLoadedState).cartItems;
  bool get isLoading => (_state as AppLoadedState).isLoading;
  String? get errorMessage => (_state as AppLoadedState).errorMessage;
  bool get isInitialized => (_state as AppLoadedState).isInitialized;
  String get currentLanguage => (_state as AppLoadedState).currentLanguage;

  // Cart utilities
  double get cartTotal =>
      cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  int get cartItemsCount => cartItems.length;

  @override
  void dispose() {
    super.dispose();
  }
}
