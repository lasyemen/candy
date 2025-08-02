// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditLog _$AuditLogFromJson(Map<String, dynamic> json) => AuditLog(
  id: json['id'] as String,
  userId: json['user_id'] as String?,
  action: json['action'] as String,
  tableName: json['table_name'] as String,
  recordId: json['record_id'] as String,
  oldValues: json['old_values'] as Map<String, dynamic>?,
  newValues: json['new_values'] as Map<String, dynamic>?,
  ipAddress: json['ip_address'] as String?,
  userAgent: json['user_agent'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$AuditLogToJson(AuditLog instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'action': instance.action,
  'table_name': instance.tableName,
  'record_id': instance.recordId,
  'old_values': instance.oldValues,
  'new_values': instance.newValues,
  'ip_address': instance.ipAddress,
  'user_agent': instance.userAgent,
  'created_at': instance.createdAt.toIso8601String(),
};
