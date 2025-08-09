import 'package:json_annotation/json_annotation.dart';
import 'cart_item.dart';

part 'cart.g.dart';

@JsonSerializable()
class Cart {
  final String id;
  @JsonKey(name: 'customer_id')
  final String customerId;
  final List<CartItem>? items;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.customerId,
    this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);
  Map<String, dynamic> toJson() => _$CartToJson(this);
}
