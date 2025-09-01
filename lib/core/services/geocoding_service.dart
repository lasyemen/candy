import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../constants/mapbox_constants.dart';

class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  // Lightweight session token for Search Box API billing and relevance
  String? _searchSessionToken;
  int _searchSessionStartedAtMs = 0;
  final _rand = Random();

  void resetSearchSession() {
    _searchSessionToken = null;
    _searchSessionStartedAtMs = 0;
  }

  String _ensureSearchSession() {
    final now = DateTime.now().millisecondsSinceEpoch;
    // refresh session token every ~10 minutes
    if (_searchSessionToken == null || now - _searchSessionStartedAtMs > 10 * 60 * 1000) {
      final bytes = List<int>.generate(16, (_) => _rand.nextInt(256));
      _searchSessionToken = base64Url.encode(bytes);
      _searchSessionStartedAtMs = now;
    }
    return _searchSessionToken!;
  }

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

  // Simple forward geocoding (search) using Mapbox API
  Future<List<GeocodeResult>> forwardGeocode(
    String query, {
    String language = 'ar',
    int limit = 5,
    double? proximityLat,
    double? proximityLng,
    String? country, // e.g. "sa,ye"
    String types = 'address,poi,neighborhood,locality,place,region',
  }) async {
    final token = MapboxConstants.accessToken;
    final encoded = Uri.encodeComponent(query.trim());
    if (encoded.isEmpty) return const [];
    final params = <String, String>{
      'language': language,
      'limit': '$limit',
      'types': types,
      'autocomplete': 'true',
      'fuzzyMatch': 'true',
      'access_token': token,
    };
    if (proximityLat != null && proximityLng != null) {
      params['proximity'] = '${proximityLng.toStringAsFixed(6)},${proximityLat.toStringAsFixed(6)}';
    }
    if (country != null && country.isNotEmpty) {
      params['country'] = country;
    }
    final uri = Uri.https(
      'api.mapbox.com',
      '/geocoding/v5/mapbox.places/$encoded.json',
      params,
    );
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return const [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final features = (data['features'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      final results = <GeocodeResult>[];
      for (final f in features) {
        final center = (f['center'] as List).cast<num>();
        final lng = center[0].toDouble();
        final lat = center[1].toDouble();
        final name = ((f['text_ar'] ?? f['text']) as String? ?? '').trim();
        final placeName = ((f['place_name_ar'] ?? f['place_name']) as String?)?.trim();
        results.add(GeocodeResult(
          name: name.isNotEmpty ? name : (placeName ?? ''),
          placeName: placeName ?? name,
          lat: lat,
          lng: lng,
        ));
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  // Mapbox Search Box API - Suggest
  Future<List<SearchboxSuggestion>> searchboxSuggest(
    String query, {
    String language = 'ar',
    int limit = 8,
    double? proximityLat,
    double? proximityLng,
    String? country,
    String types = 'address,place,poi',
  }) async {
    final token = MapboxConstants.accessToken;
    final encoded = Uri.encodeComponent(query.trim());
    if (encoded.isEmpty) return const [];
    final session = _ensureSearchSession();
    final params = <String, String>{
      'q': query.trim(),
      'language': language,
      'limit': '$limit',
      'types': types,
      'session_token': session,
      'access_token': token,
    };
    if (proximityLat != null && proximityLng != null) {
      params['proximity'] = '${proximityLng.toStringAsFixed(6)},${proximityLat.toStringAsFixed(6)}';
    }
    if (country != null && country.isNotEmpty) {
      params['country'] = country;
    }
    final uri = Uri.https('api.mapbox.com', '/search/searchbox/v1/suggest', params);
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return const [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final items = (data['suggestions'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      final out = <SearchboxSuggestion>[];
      for (final it in items) {
        final id = (it['mapbox_id'] as String?) ?? (it['id'] as String?);
        if (id == null) continue;
        // Prefer name + place_formatted/description
        final props = (it['place'] as Map<String, dynamic>?) ?? (it['feature'] as Map<String, dynamic>?);
        String name = it['name'] as String? ?? props?['name'] as String? ?? '';
        final desc = it['place_formatted'] as String? ?? it['description'] as String? ?? props?['full_address'] as String? ?? '';
        if (name.isEmpty) name = desc;
  out.add(SearchboxSuggestion(mapboxId: id, name: name, description: desc));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  // Mapbox Search Box API - Retrieve (returns a single feature)
  Future<GeocodeResult?> searchboxRetrieve(
    String mapboxId, {
    String language = 'ar',
  }) async {
    final token = MapboxConstants.accessToken;
    final session = _ensureSearchSession();
    final params = <String, String>{
      'language': language,
      'session_token': session,
      'access_token': token,
    };
    final path = '/search/searchbox/v1/retrieve/$mapboxId';
    final uri = Uri.https('api.mapbox.com', path, params);
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final feats = (data['features'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      if (feats.isEmpty) return null;
      final f = feats.first;
      final geom = (f['geometry'] as Map<String, dynamic>?);
      final coords = (geom?['coordinates'] as List?)?.cast<num>();
      if (coords == null || coords.length < 2) return null;
      final lng = coords[0].toDouble();
      final lat = coords[1].toDouble();
      final props = (f['properties'] as Map<String, dynamic>?);
      final name = (props?['name'] as String?) ?? (f['text'] as String?) ?? '';
      final placeName = (props?['full_address'] as String?) ?? (props?['place_formatted'] as String?) ?? (f['place_name'] as String?) ?? name;
  return GeocodeResult(name: name, placeName: placeName, lat: lat, lng: lng);
    } catch (_) {
      return null;
    }
  }
}

class GeocodeResult {
  final String name;
  final String placeName;
  final double lat;
  final double lng;
  GeocodeResult({
    required this.name,
    required this.placeName,
    required this.lat,
    required this.lng,
  });
}

class SearchboxSuggestion {
  final String mapboxId;
  final String name;
  final String description;
  SearchboxSuggestion({
    required this.mapboxId,
    required this.name,
    required this.description,
  });
}
