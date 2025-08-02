// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: json['id'] as String,
  customerId: json['customer_id'] as String,
  merchantId: json['merchant_id'] as String,
  delivererId: json['deliverer_id'] as String?,
  status: json['status'] as String,
  totalAmount: (json['total_amount'] as num).toDouble(),
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  deliveryAddress: json['delivery_address'] as String,
  deliveryPhone: json['delivery_phone'] as String,
  notes: json['notes'] as String?,
  estimatedDeliveryTime: json['estimated_delivery_time'] == null
      ? null
      : DateTime.parse(json['estimated_delivery_time'] as String),
  actualDeliveryTime: json['actual_delivery_time'] == null
      ? null
      : DateTime.parse(json['actual_delivery_time'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'customer_id': instance.customerId,
  'merchant_id': instance.merchantId,
  'deliverer_id': instance.delivererId,
  'status': instance.status,
  'total_amount': instance.totalAmount,
  'items': instance.items?.map((e) => e.toJson()).toList(),
  'delivery_address': instance.deliveryAddress,
  'delivery_phone': instance.deliveryPhone,
  'notes': instance.notes,
  'estimated_delivery_time': instance.estimatedDeliveryTime?.toIso8601String(),
  'actual_delivery_time': instance.actualDeliveryTime?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
