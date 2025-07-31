import 'water_product.dart';

class CartItem {
  final WaterProduct product;
  final int quantity;
  final double totalPrice;

  CartItem({
    required this.product,
    required this.quantity,
    required this.totalPrice,
  });

  // Calculate total price
  double get calculatedTotalPrice => product.price * quantity;

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }

  // Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: WaterProduct.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      totalPrice: json['totalPrice'] as double,
    );
  }

  // Copy with method
  CartItem copyWith({
    WaterProduct? product,
    int? quantity,
    double? totalPrice,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.product == product &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => product.hashCode ^ quantity.hashCode;
}
