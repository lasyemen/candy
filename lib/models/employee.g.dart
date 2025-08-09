// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Employee _$EmployeeFromJson(Map<String, dynamic> json) => Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      avatar: json['avatar'] as String?,
      status: json['status'] as String,
      totalDeliveries: (json['total_deliveries'] as num).toInt(),
      rating: (json['rating'] as num).toDouble(),
      currentLocation: (json['current_location'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$EmployeeToJson(Employee instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'role': instance.role,
      'avatar': instance.avatar,
      'status': instance.status,
      'total_deliveries': instance.totalDeliveries,
      'rating': instance.rating,
      'current_location': instance.currentLocation,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
