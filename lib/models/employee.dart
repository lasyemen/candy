import 'package:json_annotation/json_annotation.dart';

part 'employee.g.dart';

@JsonSerializable()
class Employee {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? avatar;
  final String status;
  @JsonKey(name: 'total_deliveries')
  final int totalDeliveries;
  final double rating;
  @JsonKey(name: 'current_location')
  final List<double>? currentLocation; // [lat, lng]
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar,
    required this.status,
    required this.totalDeliveries,
    required this.rating,
    this.currentLocation,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) =>
      _$EmployeeFromJson(json);
  Map<String, dynamic> toJson() => _$EmployeeToJson(this);
}
