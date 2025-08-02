import 'package:json_annotation/json_annotation.dart';

part 'ticket_message.g.dart';

@JsonSerializable()
class TicketMessage {
  final String id;
  @JsonKey(name: 'ticket_id')
  final String ticketId;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'employee_id')
  final String? employeeId;
  final String message;
  @JsonKey(name: 'is_internal')
  final bool isInternal;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  TicketMessage({
    required this.id,
    required this.ticketId,
    this.userId,
    this.employeeId,
    required this.message,
    required this.isInternal,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) =>
      _$TicketMessageFromJson(json);
  Map<String, dynamic> toJson() => _$TicketMessageToJson(this);
}
