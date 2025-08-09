// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Permission _$PermissionFromJson(Map<String, dynamic> json) => Permission(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      canModifyUsers: json['can_modify_users'] as bool? ?? false,
      canViewOrders: json['can_view_orders'] as bool? ?? false,
      canAssignDeliverer: json['can_assign_deliverer'] as bool? ?? false,
      canAddProducts: json['can_add_products'] as bool? ?? false,
      canModifyPrices: json['can_modify_prices'] as bool? ?? false,
      canExportReports: json['can_export_reports'] as bool? ?? false,
      canUpdateOrderStatus: json['can_update_order_status'] as bool? ?? false,
      canSendNotifications: json['can_send_notifications'] as bool? ?? false,
      canProcessComplaints: json['can_process_complaints'] as bool? ?? false,
      canViewLiveMap: json['can_view_live_map'] as bool? ?? false,
      canViewUsers: json['can_view_users'] as bool? ?? false,
      canViewMerchants: json['can_view_merchants'] as bool? ?? false,
      canViewEmployees: json['can_view_employees'] as bool? ?? false,
      canViewProducts: json['can_view_products'] as bool? ?? false,
      canViewInventory: json['can_view_inventory'] as bool? ?? false,
      canViewReports: json['can_view_reports'] as bool? ?? false,
      canViewAuditLog: json['can_view_audit_log'] as bool? ?? false,
      canViewSupport: json['can_view_support'] as bool? ?? false,
      canViewPermissions: json['can_view_permissions'] as bool? ?? false,
      canManageMerchants: json['can_manage_merchants'] as bool? ?? false,
      canManageEmployees: json['can_manage_employees'] as bool? ?? false,
      canManageInventory: json['can_manage_inventory'] as bool? ?? false,
      canViewDashboard: json['can_view_dashboard'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PermissionToJson(Permission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'can_modify_users': instance.canModifyUsers,
      'can_view_orders': instance.canViewOrders,
      'can_assign_deliverer': instance.canAssignDeliverer,
      'can_add_products': instance.canAddProducts,
      'can_modify_prices': instance.canModifyPrices,
      'can_export_reports': instance.canExportReports,
      'can_update_order_status': instance.canUpdateOrderStatus,
      'can_send_notifications': instance.canSendNotifications,
      'can_process_complaints': instance.canProcessComplaints,
      'can_view_live_map': instance.canViewLiveMap,
      'can_view_users': instance.canViewUsers,
      'can_view_merchants': instance.canViewMerchants,
      'can_view_employees': instance.canViewEmployees,
      'can_view_products': instance.canViewProducts,
      'can_view_inventory': instance.canViewInventory,
      'can_view_reports': instance.canViewReports,
      'can_view_audit_log': instance.canViewAuditLog,
      'can_view_support': instance.canViewSupport,
      'can_view_permissions': instance.canViewPermissions,
      'can_manage_merchants': instance.canManageMerchants,
      'can_manage_employees': instance.canManageEmployees,
      'can_manage_inventory': instance.canManageInventory,
      'can_view_dashboard': instance.canViewDashboard,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
