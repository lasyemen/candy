import 'package:json_annotation/json_annotation.dart';

part 'report.g.dart';

@JsonSerializable()
class Report {
  final String id;
  final String name;
  final String? description;
  @JsonKey(name: 'report_type')
  final String reportType;
  final Map<String, dynamic>? parameters;
  @JsonKey(name: 'generated_by')
  final String? generatedBy;
  @JsonKey(name: 'file_url')
  final String? fileUrl;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Report({
    required this.id,
    required this.name,
    this.description,
    required this.reportType,
    this.parameters,
    this.generatedBy,
    this.fileUrl,
    required this.status,
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);
  Map<String, dynamic> toJson() => _$ReportToJson(this);
}
