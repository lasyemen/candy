class WaterProduct {
  final String id;
  final String name;
  final double price;
  final int size;
  final String image;
  final double rating;
  final int reviewCount;
  final String description;
  bool isFavorite;
  final double discount;

  WaterProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.size,
    required this.image,
    required this.rating,
    required this.reviewCount,
    required this.description,
    this.isFavorite = false,
    this.discount = 0.0,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'size': size,
      'image': image,
      'rating': rating,
      'reviewCount': reviewCount,
      'description': description,
      'isFavorite': isFavorite,
      'discount': discount,
    };
  }

  // Create from JSON
  factory WaterProduct.fromJson(Map<String, dynamic> json) {
    return WaterProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as double,
      size: json['size'] as int,
      image: json['image'] as String,
      rating: json['rating'] as double,
      reviewCount: json['reviewCount'] as int,
      description: json['description'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      discount: json['discount'] as double? ?? 0.0,
    );
  }

  // Copy with method
  WaterProduct copyWith({
    String? id,
    String? name,
    double? price,
    int? size,
    String? image,
    double? rating,
    int? reviewCount,
    String? description,
    bool? isFavorite,
    double? discount,
  }) {
    return WaterProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      size: size ?? this.size,
      image: image ?? this.image,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      discount: discount ?? this.discount,
    );
  }
}
