import 'dart:convert';

class Orders {
  final String id;
  final String customerId;
  final List<Map<String, dynamic>> items;
  final double total;
  final String status;
  final DateTime createdAt;

  Orders({
    required this.id,
    required this.customerId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory Orders.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    List<Map<String, dynamic>> parsedItems = [];
    if (itemsRaw is String) {
      try {
        final dec = jsonDecode(itemsRaw);
        parsedItems = List<Map<String, dynamic>>.from(dec);
      } catch (_) {
        parsedItems = [];
      }
    } else if (itemsRaw is List) {
      parsedItems = List<Map<String, dynamic>>.from(itemsRaw);
    }

    return Orders(
      id: json['id'].toString(),
      customerId: json['customer_id'].toString(),
      items: parsedItems,
      total: (json['total'] is num)
          ? (json['total'] as num).toDouble()
          : double.parse(json['total'].toString()),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at'] is DateTime
          ? json['created_at'] as DateTime
          : DateTime.parse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'items': jsonEncode(items),
      'total': total,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
