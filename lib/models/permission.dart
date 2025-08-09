import 'package:json_annotation/json_annotation.dart';

part 'permission.g.dart';

@JsonSerializable()
class Permission {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'can_modify_users')
  final bool canModifyUsers;
  @JsonKey(name: 'can_view_orders')
  final bool canViewOrders;
  @JsonKey(name: 'can_assign_deliverer')
  final bool canAssignDeliverer;
  @JsonKey(name: 'can_add_products')
  final bool canAddProducts;
  @JsonKey(name: 'can_modify_prices')
  final bool canModifyPrices;
  @JsonKey(name: 'can_export_reports')
  final bool canExportReports;
  @JsonKey(name: 'can_update_order_status')
  final bool canUpdateOrderStatus;
  @JsonKey(name: 'can_send_notifications')
  final bool canSendNotifications;
  @JsonKey(name: 'can_process_complaints')
  final bool canProcessComplaints;

  @JsonKey(name: 'can_view_live_map')
  final bool canViewLiveMap;
  @JsonKey(name: 'can_view_users')
  final bool canViewUsers;
  @JsonKey(name: 'can_view_merchants')
  final bool canViewMerchants;
  @JsonKey(name: 'can_view_employees')
  final bool canViewEmployees;
  @JsonKey(name: 'can_view_products')
  final bool canViewProducts;
  @JsonKey(name: 'can_view_inventory')
  final bool canViewInventory;
  @JsonKey(name: 'can_view_reports')
  final bool canViewReports;
  @JsonKey(name: 'can_view_audit_log')
  final bool canViewAuditLog;
  @JsonKey(name: 'can_view_support')
  final bool canViewSupport;
  @JsonKey(name: 'can_view_permissions')
  final bool canViewPermissions;
  @JsonKey(name: 'can_manage_merchants')
  final bool canManageMerchants;
  @JsonKey(name: 'can_manage_employees')
  final bool canManageEmployees;
  @JsonKey(name: 'can_manage_inventory')
  final bool canManageInventory;
  @JsonKey(name: 'can_view_dashboard')
  final bool canViewDashboard;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Permission({
    required this.id,
    required this.userId,
    this.canModifyUsers = false,
    this.canViewOrders = false,
    this.canAssignDeliverer = false,
    this.canAddProducts = false,
    this.canModifyPrices = false,
    this.canExportReports = false,
    this.canUpdateOrderStatus = false,
    this.canSendNotifications = false,
    this.canProcessComplaints = false,
    this.canViewLiveMap = false,
    this.canViewUsers = false,
    this.canViewMerchants = false,
    this.canViewEmployees = false,
    this.canViewProducts = false,
    this.canViewInventory = false,
    this.canViewReports = false,
    this.canViewAuditLog = false,
    this.canViewSupport = false,
    this.canViewPermissions = false,
    this.canManageMerchants = false,
    this.canManageEmployees = false,
    this.canManageInventory = false,
    this.canViewDashboard = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Permission.fromJson(Map<String, dynamic> json) =>
      _$PermissionFromJson(json);
  Map<String, dynamic> toJson() => _$PermissionToJson(this);
}
