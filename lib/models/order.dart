import 'package:json_annotation/json_annotation.dart';
import 'order_item.dart';

part 'order.g.dart';

@JsonSerializable(explicitToJson: true)
class Order {
  final String id;
  @JsonKey(name: 'customer_id')
  final String customerId;
  @JsonKey(name: 'merchant_id')
  final String merchantId;
  @JsonKey(name: 'deliverer_id')
  final String? delivererId;
  final String status;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  final List<OrderItem>? items;
  @JsonKey(name: 'delivery_address')
  final String deliveryAddress;
  @JsonKey(name: 'delivery_phone')
  final String deliveryPhone;
  final String? notes;
  @JsonKey(name: 'estimated_delivery_time')
  final DateTime? estimatedDeliveryTime;
  @JsonKey(name: 'actual_delivery_time')
  final DateTime? actualDeliveryTime;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.customerId,
    required this.merchantId,
    this.delivererId,
    required this.status,
    required this.totalAmount,
    this.items,
    required this.deliveryAddress,
    required this.deliveryPhone,
    this.notes,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}
