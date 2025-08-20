import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/orders.dart';

class OrdersService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<bool> createOrder(Orders order) async {
    try {
      final response = await _supabase.from('orders').insert(order.toJson());
      // response is typically the created row(s) or an error will throw
      return response != null;
    } catch (e) {
      print('createOrder error: $e');
      return false;
    }
  }

  static Future<List<Orders>> fetchOrdersForCustomer(String customerId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      final data = response as List;
      return data.map((e) => Orders.fromJson(e)).toList();
    } catch (e) {
      print('fetchOrdersForCustomer error: $e');
      return [];
    }
  }
}
