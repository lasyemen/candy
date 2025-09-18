import 'package:json_annotation/json_annotation.dart';

part 'products.g.dart';

@JsonSerializable()
class Products {
  final String id;
  final String name;
  final String? translationKey;
  final String? description;
  final double price;
  final String category;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'stock_quantity')
  final int? stockQuantity;
  final double rating;
  @JsonKey(name: 'total_sold')
  final int? totalSold;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Products({
  required this.id,
  required this.name,
  this.translationKey,
    this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.stockQuantity,
    required this.rating,
    this.totalSold,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Products.fromJson(Map<String, dynamic> json) =>
    _$ProductsFromJson(json);
  Map<String, dynamic> toJson() => _$ProductsToJson(this);
}
