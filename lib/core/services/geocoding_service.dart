import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/mapbox_constants.dart';

class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  Future<String?> reverseGeocode(
    double lat,
    double lng, {
    String language = 'ar',
  }) async {
    final token = MapboxConstants.accessToken;
    final uri = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json'
      '?language=$language&limit=1&types=address,poi,neighborhood,locality,place,region&access_token=$token',
    );
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>?;
      if (features == null || features.isEmpty) return null;
      final f = features.first as Map<String, dynamic>;
      final String primary = ((f['text_ar'] ?? f['text']) as String? ?? '').trim();
      final List<dynamic> ctx = (f['context'] as List<dynamic>?) ?? const [];
      String area = '';
      for (final c in ctx) {
        final m = (c as Map).cast<String, dynamic>();
        final id = (m['id'] as String?) ?? '';
        if (id.startsWith('neighborhood') || id.startsWith('locality') || id.startsWith('place')) {
          area = ((m['text_ar'] ?? m['text']) as String? ?? '').trim();
          if (area.isNotEmpty) break;
        }
      }
      String composed = '';
      if (primary.isNotEmpty && area.isNotEmpty) {
        composed = '$primary، $area';
      } else if (primary.isNotEmpty) {
        composed = primary;
      } else if (area.isNotEmpty) {
        composed = area;
      }
      if (composed.isNotEmpty) return composed;
      final String? placeName = (f['place_name_ar'] ?? f['place_name']) as String?;
      return placeName;
    } catch (_) {
      return null;
    }
  }
}
