import 'products.dart';

class AppCartItem {
  final Products product;
  final int quantity;

  AppCartItem({required this.product, required this.quantity});

  double get totalPrice => product.price * quantity;

  AppCartItem copyWith({Products? product, int? quantity}) {
    return AppCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
