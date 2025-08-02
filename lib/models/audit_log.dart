import 'package:json_annotation/json_annotation.dart';

part 'audit_log.g.dart';

@JsonSerializable()
class AuditLog {
  final String id;
  @JsonKey(name: 'user_id')
  final String? userId;
  final String action;
  @JsonKey(name: 'table_name')
  final String tableName;
  @JsonKey(name: 'record_id')
  final String recordId;
  @JsonKey(name: 'old_values')
  final Map<String, dynamic>? oldValues;
  @JsonKey(name: 'new_values')
  final Map<String, dynamic>? newValues;
  @JsonKey(name: 'ip_address')
  final String? ipAddress;
  @JsonKey(name: 'user_agent')
  final String? userAgent;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  AuditLog({
    required this.id,
    this.userId,
    required this.action,
    required this.tableName,
    required this.recordId,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) =>
      _$AuditLogFromJson(json);
  Map<String, dynamic> toJson() => _$AuditLogToJson(this);
}
