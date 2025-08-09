import 'package:json_annotation/json_annotation.dart';

part 'inventory.g.dart';

@JsonSerializable()
class Inventory {
  final String id;
  @JsonKey(name: 'product_id')
  final String productId;
  final int quantity;
  @JsonKey(name: 'min_quantity')
  final int minQuantity;
  @JsonKey(name: 'max_quantity')
  final int maxQuantity;
  final String? location;
  @JsonKey(name: 'last_restocked')
  final DateTime? lastRestocked;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Inventory({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.minQuantity,
    required this.maxQuantity,
    this.location,
    this.lastRestocked,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) =>
      _$InventoryFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryToJson(this);
}
