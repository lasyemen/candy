// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Report _$ReportFromJson(Map<String, dynamic> json) => Report(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  reportType: json['report_type'] as String,
  parameters: json['parameters'] as Map<String, dynamic>?,
  generatedBy: json['generated_by'] as String?,
  fileUrl: json['file_url'] as String?,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ReportToJson(Report instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'report_type': instance.reportType,
  'parameters': instance.parameters,
  'generated_by': instance.generatedBy,
  'file_url': instance.fileUrl,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
};
