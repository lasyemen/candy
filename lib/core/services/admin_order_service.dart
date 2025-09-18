import 'package:candy_water/core/services/supabase_service.dart';

class AdminOrderService {
  AdminOrderService._();
  static final instance = AdminOrderService._();

  // Approve an order so it becomes visible to drivers
  Future<void> approveOrder({
    required String orderId,
    String? notes,
    String? adminUserId,
  }) async {
    final client = SupabaseService.instance.client;
    // Update status to approved
    await client
        .from('orders')
        .update({
          'status': 'approved',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);

    // Insert status history entry (best-effort)
    try {
      await client.from('order_status_history').insert({
        'order_id': orderId,
        'status': 'approved',
        'previous_status': 'pending',
        'notes': notes,
        'created_by': adminUserId,
      });
    } catch (_) {
      // ignore optional history failures
    }
  }
}
