// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Inventory _$InventoryFromJson(Map<String, dynamic> json) => Inventory(
  id: json['id'] as String,
  productId: json['product_id'] as String,
  quantity: (json['quantity'] as num).toInt(),
  minQuantity: (json['min_quantity'] as num).toInt(),
  maxQuantity: (json['max_quantity'] as num).toInt(),
  location: json['location'] as String?,
  lastRestocked: json['last_restocked'] == null
      ? null
      : DateTime.parse(json['last_restocked'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$InventoryToJson(Inventory instance) => <String, dynamic>{
  'id': instance.id,
  'product_id': instance.productId,
  'quantity': instance.quantity,
  'min_quantity': instance.minQuantity,
  'max_quantity': instance.maxQuantity,
  'location': instance.location,
  'last_restocked': instance.lastRestocked?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
