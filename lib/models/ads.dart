import 'package:json_annotation/json_annotation.dart';

part 'ads.g.dart';

@JsonSerializable()
class Ads {
  final String id;
  @JsonKey(name: 'image_url')
  final String imageUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Ads({required this.id, required this.imageUrl, required this.createdAt});

  factory Ads.fromJson(Map<String, dynamic> json) => _$AdsFromJson(json);
  Map<String, dynamic> toJson() => _$AdsToJson(this);
}
