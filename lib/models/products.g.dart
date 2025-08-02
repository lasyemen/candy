// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'products.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Products _$ProductsFromJson(Map<String, dynamic> json) => Products(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  price: (json['price'] as num).toDouble(),
  category: json['category'] as String,
  merchantId: json['merchant_id'] as String?,
  imageUrl: json['image_url'] as String?,
  status: json['status'] as String,
  totalSold: (json['total_sold'] as num).toInt(),
  rating: (json['rating'] as num).toDouble(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ProductsToJson(Products instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'category': instance.category,
  'merchant_id': instance.merchantId,
  'image_url': instance.imageUrl,
  'status': instance.status,
  'total_sold': instance.totalSold,
  'rating': instance.rating,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
