import 'dart:convert';

import 'package:http/http.dart' as http;

class TaqnyatSmsService {
  TaqnyatSmsService({required String bearerToken})
    : _bearerToken = bearerToken.trim();

  static const String _baseUrl = 'https://api.taqnyat.sa';

  final String _bearerToken;

  Map<String, String> get _headers => <String, String>{
    'Authorization': 'Bearer $_bearerToken',
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  // System status (no auth required)
  Future<Map<String, dynamic>> getSystemStatus() async {
    final uri = Uri.parse('$_baseUrl/system/status');
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    return _decodeJson(response);
  }

  // Account balance (auth required)
  Future<Map<String, dynamic>> getAccountBalance() async {
    final uri = Uri.parse('$_baseUrl/account/balance');
    final response = await http.get(uri, headers: _headers);
    return _decodeJson(response);
  }

  // Send message (immediate or scheduled when scheduledDatetime provided)
  Future<Map<String, dynamic>> sendMessage({
    required List<String> recipients,
    required String body,
    required String sender,
    DateTime? scheduledDatetime,
    String? deleteId,
  }) async {
    final uri = Uri.parse('$_baseUrl/v1/messages');
    final payload = <String, dynamic>{
      'recipients': recipients,
      'body': body,
      'sender': sender,
      if (scheduledDatetime != null)
        'scheduledDatetime': _formatIsoMinute(scheduledDatetime.toUtc()),
      if (deleteId != null) 'deleteId': deleteId,
    };

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );
    return _decodeJson(response);
  }

  // Delete scheduled message
  Future<Map<String, dynamic>> deleteScheduled({
    required String deleteId,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/v1/messages/delete',
    ).replace(queryParameters: <String, String>{'deleteId': deleteId});

    final response = await http.delete(uri, headers: _headers);
    return _decodeJson(response);
  }

  // List sender names
  Future<Map<String, dynamic>> getSenderNames() async {
    final uri = Uri.parse('$_baseUrl/v1/messages/senders');
    final response = await http.get(uri, headers: _headers);
    return _decodeJson(response);
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    final statusCode = response.statusCode;
    final bodyString = response.body.isEmpty ? '{}' : response.body;
    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(bodyString) as Map<String, dynamic>;
    } catch (_) {
      parsed = <String, dynamic>{'raw': bodyString};
    }
    parsed['statusCode'] = statusCode;
    return parsed;
  }

  String _formatIsoMinute(DateTime dt) {
    // Expected like 2020-09-30T14:26
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}T${two(dt.hour)}:${two(dt.minute)}';
  }
}
