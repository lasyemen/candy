import 'package:json_annotation/json_annotation.dart';

part 'support_ticket.g.dart';

@JsonSerializable()
class SupportTicket {
  final String id;
  @JsonKey(name: 'customer_id')
  final String customerId;
  final String title;
  final String description;
  final String status;
  final String priority;
  @JsonKey(name: 'assigned_to')
  final String? assignedTo;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  SupportTicket({
    required this.id,
    required this.customerId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketFromJson(json);
  Map<String, dynamic> toJson() => _$SupportTicketToJson(this);
}
