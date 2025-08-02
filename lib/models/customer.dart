import 'package:json_annotation/json_annotation.dart';

part 'customer.g.dart';

@JsonSerializable()
class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? avatar;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'last_login')
  final DateTime? lastLogin;
  @JsonKey(name: 'total_spent')
  final double totalSpent;
  @JsonKey(name: 'orders_count')
  final int ordersCount;
  final double rating;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.avatar,
    required this.isActive,
    this.lastLogin,
    required this.totalSpent,
    required this.ordersCount,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerToJson(this);
}
