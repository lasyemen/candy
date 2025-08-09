import 'package:json_annotation/json_annotation.dart';

part 'ads.g.dart';

@JsonSerializable()
class Ads {
  final String id;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'storage_bucket')
  final String? storageBucket;
  @JsonKey(name: 'storage_path')
  final String? storagePath;

  Ads({
    required this.id,
    this.imageUrl,
    required this.createdAt,
    this.storageBucket,
    this.storagePath,
  });

  factory Ads.fromJson(Map<String, dynamic> json) => _$AdsFromJson(json);
  Map<String, dynamic> toJson() => _$AdsToJson(this);
}
