// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ads.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ads _$AdsFromJson(Map<String, dynamic> json) => Ads(
  id: json['id'] as String,
  imageUrl: json['image_url'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  storageBucket: json['storage_bucket'] as String?,
  storagePath: json['storage_path'] as String?,
);

Map<String, dynamic> _$AdsToJson(Ads instance) => <String, dynamic>{
  'id': instance.id,
  'image_url': instance.imageUrl,
  'created_at': instance.createdAt.toIso8601String(),
  'storage_bucket': instance.storageBucket,
  'storage_path': instance.storagePath,
};
