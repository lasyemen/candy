import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'customer_session.dart';

class RewardsService {
  RewardsService._();
  static RewardsService? _instance;
  static RewardsService get instance => _instance ??= RewardsService._();

  // Tunable constants
  static const int pointsRequiredForVoucher = 900; // 900 pts => 50 SAR
  static const double voucherValueSar = 50.0; // 50 SAR voucher value
  static const int voucherValidityDays = 60; // must be used within 60 days
  static const int pointsPerSar = 1; // purchase accrual rate
  static const int dailyWaterGoalPoints = 20; // award for meeting daily goal
  static const int healthyChangePoints =
      30; // award for a verified healthy change

  // Storage keys (namespaced by profile key)
  String get _profileKey {
    final customerId = CustomerSession.instance.currentCustomerId;
    if (customerId != null && customerId.isNotEmpty) return 'u_$customerId';
    // fallback to device-scoped guest
    return 'guest';
  }

  String get _pointsKey => 'rewards_points_${_profileKey}_v1';
  String get _vouchersKey => 'rewards_vouchers_${_profileKey}_v1';
  String get _awardFlagsKey => 'rewards_award_flags_${_profileKey}_v1';

  Future<int> getPointsBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 0;
  }

  Future<void> resetPoints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsKey, 0);
  }

  Future<void> _setPointsBalance(int points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsKey, max(0, points));
  }

  // Voucher model (simple map)
  Map<String, dynamic> _createVoucher() {
    final id = _generateId();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: voucherValidityDays));
    return {
      'id': id,
      'amount': voucherValueSar,
      'issued_at': now.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'used': false,
      'used_at': null,
    };
  }

  String _generateId() {
    final rand = Random();
    final bytes = List<int>.generate(12, (_) => rand.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Future<List<Map<String, dynamic>>> _loadVouchers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_vouchersKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return _cleanExpired(list);
  }

  Future<void> _saveVouchers(List<Map<String, dynamic>> vouchers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vouchersKey, jsonEncode(vouchers));
  }

  List<Map<String, dynamic>> _cleanExpired(
    List<Map<String, dynamic>> vouchers,
  ) {
    final now = DateTime.now();
    return vouchers.where((v) {
      final used = v['used'] == true;
      final expiresAt = DateTime.tryParse(v['expires_at'] as String? ?? '');
      if (expiresAt == null) return false; // drop invalid
      return !used && expiresAt.isAfter(now);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getActiveVouchers() async {
    final vouchers = await _loadVouchers();
    // Persist cleanup
    await _saveVouchers(vouchers);
    return vouchers;
  }

  Future<Map<String, dynamic>?> getVoucherById(String voucherId) async {
    final vouchers = await _loadVouchers();
    try {
      return vouchers.firstWhere((v) => v['id'] == voucherId);
    } catch (_) {
      return null;
    }
  }

  // Add raw points and issue vouchers automatically when threshold reached
  Future<int> addPoints(int points, {String? reason}) async {
    if (points <= 0) return getPointsBalance();

    final current = await getPointsBalance();
    int updated = current + points;

    // Issue as many vouchers as possible
    final vouchers = await _loadVouchers();
    while (updated >= pointsRequiredForVoucher) {
      updated -= pointsRequiredForVoucher;
      vouchers.add(_createVoucher());
    }

    await _setPointsBalance(updated);
    await _saveVouchers(vouchers);
    return updated;
  }

  // Purchase accrual (pointsPerSar)
  Future<int> addPointsFromPurchase(double orderTotalSar) async {
    final pts = (orderTotalSar * pointsPerSar).floor();
    return addPoints(pts, reason: 'purchase');
  }

  // Healthy change accrual (idempotent per changeId)
  Future<bool> addPointsForHealthyChange(String changeId) async {
    if (changeId.trim().isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final flags = _loadAwardFlags(prefs);
    final key = 'healthy_$changeId';
    if (flags[key] == true) return false; // already awarded

    await addPoints(healthyChangePoints, reason: 'healthy_change');
    flags[key] = true;
    await _saveAwardFlags(prefs, flags);
    return true;
  }

  // Daily water goal accrual (once per calendar day)
  Future<bool> awardPointsForDailyWaterGoalIfNeeded({
    required double currentIntakeMl,
    required double dailyGoalMl,
  }) async {
    if (dailyGoalMl <= 0) return false;
    if (currentIntakeMl + 0.001 < dailyGoalMl) return false; // not yet met

    final prefs = await SharedPreferences.getInstance();
    final flags = _loadAwardFlags(prefs);
    final today = DateTime.now();
    final dayKey = _formatDayKey(today);
    final awardKey = 'water_goal_$dayKey';

    if (flags[awardKey] == true) return false; // already awarded today

    await addPoints(dailyWaterGoalPoints, reason: 'daily_water_goal');
    flags[awardKey] = true;
    await _saveAwardFlags(prefs, flags);
    return true;
  }

  // Redeem a voucher by ID (marks as used). Returns discount amount if success.
  Future<double> redeemVoucher(String voucherId) async {
    final vouchers = await _loadVouchers();
    for (final v in vouchers) {
      if (v['id'] == voucherId) {
        final used = v['used'] == true;
        final expiresAt = DateTime.tryParse(v['expires_at'] as String? ?? '');
        final isExpired = expiresAt == null
            ? true
            : !expiresAt.isAfter(DateTime.now());
        if (used || isExpired) return 0.0;
        v['used'] = true;
        v['used_at'] = DateTime.now().toIso8601String();
        await _saveVouchers(vouchers);
        return (v['amount'] as num?)?.toDouble() ?? voucherValueSar;
      }
    }
    return 0.0;
  }

  // Utilities for award flags
  Map<String, dynamic> _loadAwardFlags(SharedPreferences prefs) {
    final raw = prefs.getString(_awardFlagsKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    return (jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _saveAwardFlags(
    SharedPreferences prefs,
    Map<String, dynamic> flags,
  ) async {
    await prefs.setString(_awardFlagsKey, jsonEncode(flags));
  }

  String _formatDayKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }
}
