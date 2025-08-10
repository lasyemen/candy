import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// Removed unused app_settings import
import '../i18n/product_dictionary.dart';

class AutoTranslator {
  AutoTranslator._internal();
  static final AutoTranslator instance = AutoTranslator._internal();
  static const String _googleApiKey = String.fromEnvironment(
    'GOOGLE_TRANSLATE_API_KEY',
  );
  static const String _libreBaseUrl = String.fromEnvironment(
    'LIBRE_TRANSLATE_BASE_URL',
  );
  static const String _libreApiKey = String.fromEnvironment(
    'LIBRE_TRANSLATE_API_KEY',
  );

  static const String _cacheKey = 'auto_translate_cache_v1';
  Map<String, String> _memoryCache = {};
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        _memoryCache = decoded.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (_) {
      // ignore cache errors
    } finally {
      _initialized = true;
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep cache size reasonable (truncate oldest by rebuilding map)
      if (_memoryCache.length > 500) {
        final entries = _memoryCache.entries.toList();
        final start = entries.length - 500;
        _memoryCache = Map.fromEntries(entries.sublist(start));
      }
      await prefs.setString(_cacheKey, json.encode(_memoryCache));
    } catch (_) {
      // ignore persist errors
    }
  }

  String _detectSourceLang(String text) {
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    return hasArabic ? 'ar' : 'en';
  }

  String _cacheKeyFor(String text, String from, String to) => '$from|$to|$text';

  Future<String> translate(
    String text, {
    String? from,
    required String to,
  }) async {
    await initialize();
    if (text.trim().isEmpty) return text;
    final source = from ?? _detectSourceLang(text);
    if (source == to) return text;

    final key = _cacheKeyFor(text, source, to);
    final cached = _memoryCache[key];
    if (cached != null) return cached;

    // Heuristic fallback for known product names (fast, offline)
    if (source == 'ar' && to == 'en') {
      final viaDict = ProductDictionary.translateName(text, 'en');
      if (!identical(viaDict, text)) {
        _memoryCache[key] = viaDict;
        _persist();
        return viaDict;
      }
    }

    // Prefer LibreTranslate (self-hosted) if configured
    if (_libreBaseUrl.isNotEmpty && _libreApiKey.isNotEmpty) {
      final viaLibre = await _translateWithLibre(text, source, to);
      if (viaLibre != null && viaLibre.isNotEmpty) {
        _memoryCache[key] = viaLibre;
        _persist();
        return viaLibre;
      }
    }

    // Prefer Google Cloud Translation API if API key is provided
    if (_googleApiKey.isNotEmpty) {
      final viaGoogle = await _translateWithGoogleV2(text, source, to);
      if (viaGoogle != null && viaGoogle.isNotEmpty) {
        _memoryCache[key] = viaGoogle;
        _persist();
        return viaGoogle;
      }
    }

    // Try public MyMemory API as default fallback (rate-limited, best-effort)
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeQueryComponent(text)}&langpair=$source|$to',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final jsonBody = json.decode(resp.body) as Map<String, dynamic>;
        final data = jsonBody['responseData'] as Map<String, dynamic>?;
        final translated = (data?['translatedText'] as String?)?.trim();
        if (translated != null && translated.isNotEmpty) {
          _memoryCache[key] = translated;
          _persist();
          return translated;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AutoTranslator: network translation failed: $e');
      }
    }

    // Fallback to original on failure
    _memoryCache[key] = text;
    _persist();
    return text;
  }

  Future<String?> _translateWithLibre(
    String text,
    String source,
    String target,
  ) async {
    try {
      final uri = Uri.parse('$_libreBaseUrl/translate');
      final body = <String, dynamic>{
        'q': text,
        if (source.isNotEmpty) 'source': source, // allow auto-detect otherwise
        'target': target,
        'format': 'text',
        'api_key': _libreApiKey,
      };
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final translated = (data['translatedText'] as String?)?.trim();
        return translated;
      } else {
        if (kDebugMode) {
          print(
            'AutoTranslator: LibreTranslate error ${resp.statusCode} ${resp.body}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AutoTranslator: LibreTranslate exception: $e');
      }
    }
    return null;
  }

  Future<String?> _translateWithGoogleV2(
    String text,
    String source,
    String target,
  ) async {
    try {
      final uri = Uri.parse(
        'https://translation.googleapis.com/language/translate/v2?key=$_googleApiKey',
      );
      final body = <String, dynamic>{
        'q': text,
        'target': target,
        if (source.isNotEmpty) 'source': source,
        'format': 'text',
      };
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final translations = (data['data']?['translations'] as List?)
            ?.cast<dynamic>();
        if (translations != null && translations.isNotEmpty) {
          final first = translations.first as Map<String, dynamic>;
          final translated = (first['translatedText'] as String?)?.trim();
          return translated;
        }
      } else {
        if (kDebugMode) {
          print(
            'AutoTranslator: Google API error ${resp.statusCode} ${resp.body}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AutoTranslator: Google API exception: $e');
      }
    }
    return null;
  }
}
