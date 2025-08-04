import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/ads.dart';

class AdsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all ads from the database
  static Future<List<Ads>> fetchAds() async {
    try {
      final response = await _supabase
          .from('ads')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((json) => Ads.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching ads: $e');
      return [];
    }
  }
}
