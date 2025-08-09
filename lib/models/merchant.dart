import 'package:json_annotation/json_annotation.dart';

part 'merchant.g.dart';

@JsonSerializable()
class Merchant {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? avatar;
  final String status;
  @JsonKey(name: 'total_orders')
  final int totalOrders;
  @JsonKey(name: 'total_revenue')
  final double totalRevenue;
  final double rating;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Merchant({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.avatar,
    required this.status,
    required this.totalOrders,
    required this.totalRevenue,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) =>
      _$MerchantFromJson(json);
  Map<String, dynamic> toJson() => _$MerchantToJson(this);
}
