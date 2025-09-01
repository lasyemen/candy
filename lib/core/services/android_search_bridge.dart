import 'dart:io' show Platform;
import 'package:flutter/services.dart';

class AndroidSearchBridge {
  static const MethodChannel _ch = MethodChannel('com.example.candy_water/search');

  static bool get isAvailable => Platform.isAndroid;

  static Future<List<Map<String, dynamic>>> suggest(String query) async {
    if (!isAvailable) return const [];
    final res = await _ch.invokeMethod<List<dynamic>>('suggest', { 'query': query });
  return (res ?? const [])
    .whereType<Map>()
    .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  static Future<Map<String, dynamic>?> selectFirst(String query) async {
    if (!isAvailable) return null;
    final res = await _ch.invokeMethod<Map<dynamic, dynamic>?>('selectFirst', { 'query': query });
    return res == null ? null : Map<String, dynamic>.from(res);
  }
}
