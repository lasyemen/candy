// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TicketMessage _$TicketMessageFromJson(Map<String, dynamic> json) =>
    TicketMessage(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      userId: json['user_id'] as String?,
      employeeId: json['employee_id'] as String?,
      message: json['message'] as String,
      isInternal: json['is_internal'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TicketMessageToJson(TicketMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticket_id': instance.ticketId,
      'user_id': instance.userId,
      'employee_id': instance.employeeId,
      'message': instance.message,
      'is_internal': instance.isInternal,
      'created_at': instance.createdAt.toIso8601String(),
    };
