import 'package:json_annotation/json_annotation.dart';

part 'products.g.dart';

@JsonSerializable()
class Products {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String category;
  @JsonKey(name: 'merchant_id')
  final String? merchantId; // Made nullable to match database
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final String status;
  @JsonKey(name: 'total_sold')
  final int totalSold;
  final double rating;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Products({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    this.merchantId, // Made optional
    this.imageUrl,
    required this.status,
    required this.totalSold,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Products.fromJson(Map<String, dynamic> json) =>
      _$ProductsFromJson(json);
  Map<String, dynamic> toJson() => _$ProductsToJson(this);
}
