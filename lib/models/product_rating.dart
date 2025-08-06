import 'package:json_annotation/json_annotation.dart';

part 'product_rating.g.dart';

@JsonSerializable()
class ProductRating {
  final String id;
  @JsonKey(name: 'product_id')
  final String productId;
  @JsonKey(name: 'customer_id')
  final String customerId;
  final int rating;
  final String? review;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  ProductRating({
    required this.id,
    required this.productId,
    required this.customerId,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  factory ProductRating.fromJson(Map<String, dynamic> json) =>
      _$ProductRatingFromJson(json);
  Map<String, dynamic> toJson() => _$ProductRatingToJson(this);
}

// Model for average rating data
@JsonSerializable()
class ProductRatingSummary {
  @JsonKey(name: 'average_rating')
  final double averageRating;
  @JsonKey(name: 'total_ratings')
  final int totalRatings;

  ProductRatingSummary({
    required this.averageRating,
    required this.totalRatings,
  });

  factory ProductRatingSummary.fromJson(Map<String, dynamic> json) =>
      _$ProductRatingSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$ProductRatingSummaryToJson(this);
}
