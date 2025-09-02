// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Customer _$CustomerFromJson(Map<String, dynamic> json) => Customer(
  id: json['id'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String,
  address: json['address'] as String?,
  avatar: json['avatar'] as String?,
  isActive: json['is_active'] as bool,
  lastLogin: json['last_login'] == null
      ? null
      : DateTime.parse(json['last_login'] as String),
  totalSpent: (json['total_spent'] as num).toDouble(),
  ordersCount: (json['orders_count'] as num).toInt(),
  rating: (json['rating'] as num).toDouble(),
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$CustomerToJson(Customer instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phone': instance.phone,
  'address': instance.address,
  'avatar': instance.avatar,
  'is_active': instance.isActive,
  'last_login': instance.lastLogin?.toIso8601String(),
  'total_spent': instance.totalSpent,
  'orders_count': instance.ordersCount,
  'rating': instance.rating,
  'lat': instance.lat,
  'lng': instance.lng,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
