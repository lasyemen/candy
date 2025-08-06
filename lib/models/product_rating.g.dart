// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_rating.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductRating _$ProductRatingFromJson(Map<String, dynamic> json) =>
    ProductRating(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      customerId: json['customer_id'] as String,
      rating: (json['rating'] as num).toInt(),
      review: json['review'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ProductRatingToJson(ProductRating instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product_id': instance.productId,
      'customer_id': instance.customerId,
      'rating': instance.rating,
      'review': instance.review,
      'created_at': instance.createdAt.toIso8601String(),
    };

ProductRatingSummary _$ProductRatingSummaryFromJson(
        Map<String, dynamic> json) =>
    ProductRatingSummary(
      averageRating: (json['average_rating'] as num).toDouble(),
      totalRatings: (json['total_ratings'] as num).toInt(),
    );

Map<String, dynamic> _$ProductRatingSummaryToJson(
        ProductRatingSummary instance) =>
    <String, dynamic>{
      'average_rating': instance.averageRating,
      'total_ratings': instance.totalRatings,
    };
