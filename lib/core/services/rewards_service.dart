import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_session.dart';

/// Minimal compatible RewardsService singleton used by checkout and payment flow.
/// Provides: instance, addPointsFromPurchase, addPoints, getPointsRatePerSar, getPointsBalance,
/// and small helpers used by the UI tests and rewards screen.
class RewardsService {
  RewardsService._();
  static RewardsService? _instance;
  static RewardsService get instance => _instance ??= RewardsService._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  // --- constants used by UI ---
  static const int pointsRequiredForVoucher = 1000;
  static const int pointsExpiryDays = 60;
  static const int _healthyChangePoints = 30;
  static const int _dailyCheckInPoints = 15;
  static const int _dailySpinMin = 5;
  static const int _dailySpinMax = 50;

  // cycle keys
  String get _cycleStartKey => 'rewards_cycle_start_v2';
  String get _cycleSpendingKey => 'rewards_cycle_spending_v2';
  String get _cyclePointsKey => 'rewards_cycle_points_v2';

  /// Add points from a purchase — primary integration point used by checkout.
  Future<void> addPointsFromPurchase(double totalSar) async {
    // Award simple points: 1 point per SAR as fallback.
    final int points = totalSar.floor();
    await addPoints(points, reason: 'purchase');

    // Track spending in current cycle
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getDouble(_cycleSpendingKey) ?? 0.0;
      await prefs.setDouble(_cycleSpendingKey, current + totalSar);
      // Optionally increment cycle points tracker (but don't exceed required)
      final cp = prefs.getInt(_cyclePointsKey) ?? 0;
      final toAward = min(points, pointsRequiredForVoucher - cp);
      if (toAward > 0) await prefs.setInt(_cyclePointsKey, cp + toAward);
    } catch (_) {}

    // Optionally persist a rewards record in Supabase (best-effort)
    try {
      await _supabase.from('rewards').insert({
        'user_id': CustomerSession.instance.currentCustomerId,
        'points': points,
        'total_spend': totalSar,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  /// Add raw points to local ledger (SharedPreferences) and return new balance.
  Future<int> addPoints(int points, {String? reason}) async {
    if (points <= 0) return getPointsBalance();
    final prefs = await SharedPreferences.getInstance();
    final ledgerRaw = prefs.getString('rewards_ledger') ?? '[]';
    final ledger = List<Map<String, dynamic>>.from(jsonDecode(ledgerRaw));
    ledger.add({
      'points': points,
      'reason': reason ?? 'generic',
      'ts': DateTime.now().toIso8601String(),
    });
    await prefs.setString('rewards_ledger', jsonEncode(ledger));
    return getPointsBalance();
  }

  Future<int> getPointsBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final ledgerRaw = prefs.getString('rewards_ledger') ?? '[]';
    final ledger = List<Map<String, dynamic>>.from(jsonDecode(ledgerRaw));
    int total = 0;
    for (final e in ledger) {
      total += (e['points'] as num).toInt();
    }
    return total;
  }

  /// Rate used to compute immediate earned points in the payment UI.
  Future<double> getPointsRatePerSar() async {
    // Simple fallback: 1 point per SAR
    return 1.0;
  }

  /// Return locally stored vouchers (UI test needs this).
  Future<List<Map<String, dynamic>>> getActiveVouchers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('rewards_vouchers') ?? '[]';
    try {
      final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Redeem a voucher by id; returns discount amount (0 if invalid/expired)
  Future<double> redeemVoucher(String voucherId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('rewards_vouchers') ?? '[]';
    try {
      final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
      final idx = list.indexWhere((v) => v['id'] == voucherId);
      if (idx == -1) return 0.0;
      final v = list[idx];
      final used = v['used'] == true;
      final expiresAt = DateTime.tryParse(v['expires_at'] as String? ?? '');
      final isExpired = expiresAt == null
          ? true
          : !expiresAt.isAfter(DateTime.now());
      if (used || isExpired) return 0.0;
      // mark used
      list[idx]['used'] = true;
      list[idx]['used_at'] = DateTime.now().toIso8601String();
      await prefs.setString('rewards_vouchers', jsonEncode(list));
      return (v['amount'] as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Add spending to current cycle (used by TestCheckout flow)
  Future<void> addSpendingToCycle(double amountSar) async {
    if (amountSar <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getDouble(_cycleSpendingKey) ?? 0.0;
    await prefs.setDouble(_cycleSpendingKey, current + amountSar);
    // Optionally update cycle points tracker (award in chunks without exceeding)
    final cp = prefs.getInt(_cyclePointsKey) ?? 0;
    final toAward = min((amountSar).floor(), pointsRequiredForVoucher - cp);
    if (toAward > 0) await prefs.setInt(_cyclePointsKey, cp + toAward);
  }

  /// Award points for daily water goal if met. Returns points awarded (0 if none)
  Future<int> awardPointsForDailyWaterGoalIfNeeded({
    required double currentIntakeMl,
    required double dailyGoalMl,
  }) async {
    if (dailyGoalMl <= 0) return 0;
    if (currentIntakeMl < dailyGoalMl) return 0;
    final prefs = await SharedPreferences.getInstance();
    final key = 'water_goal_awarded_${_formatDayKey(DateTime.now())}';
    if (prefs.getBool(key) == true) return 0;
    // legacy: no health points by default, award 0 but mark claimed
    await prefs.setBool(key, true);
    return 0;
  }

  /// Award points for a healthy change once per changeId. Returns true if awarded now.
  Future<bool> addPointsForHealthyChange(String changeId) async {
    if (changeId.trim().isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final key = 'healthy_change_awarded_$changeId';
    if (prefs.getBool(key) == true) return false; // already awarded
    await addPoints(_healthyChangePoints, reason: 'healthy_change');
    await prefs.setBool(key, true);
    return true;
  }

  // --- Methods required by rewards UI ---
  /// Check if daily check-in is available (simple per-day flag)
  Future<bool> isDailyCheckInAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'checkin_${_formatDayKey(DateTime.now())}';
    return prefs.getBool(key) != true;
  }

  /// Award daily check-in if available; returns points awarded (0 if none)
  Future<int> awardDailyCheckInIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'checkin_${_formatDayKey(DateTime.now())}';
    if (prefs.getBool(key) == true) return 0;
    await addPoints(_dailyCheckInPoints, reason: 'daily_checkin');
    await prefs.setBool(key, true);
    return _dailyCheckInPoints;
  }

  /// Check if daily spin is available
  Future<bool> isDailySpinAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'spin_${_formatDayKey(DateTime.now())}';
    return prefs.getBool(key) != true;
  }

  /// Spin reward if available; returns points earned (0 if not available)
  Future<int> dailySpinIfAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'spin_${_formatDayKey(DateTime.now())}';
    if (prefs.getBool(key) == true) return 0;
    final rnd = Random();
    final pts = _dailySpinMin + rnd.nextInt(_dailySpinMax - _dailySpinMin + 1);
    await addPoints(pts, reason: 'daily_spin');
    await prefs.setBool(key, true);
    return pts;
  }

  /// Get current cycle information used by UI
  Future<Map<String, dynamic>> getCurrentCycleInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final cycleStartStr = prefs.getString(_cycleStartKey);
    final cycleSpending = prefs.getDouble(_cycleSpendingKey) ?? 0.0;
    final cyclePoints = prefs.getInt(_cyclePointsKey) ?? 0;

    DateTime cycleStart;
    if (cycleStartStr == null) {
      cycleStart = DateTime.now();
      await prefs.setString(_cycleStartKey, cycleStart.toIso8601String());
      await prefs.setDouble(_cycleSpendingKey, 0.0);
      await prefs.setInt(_cyclePointsKey, 0);
    } else {
      cycleStart = DateTime.parse(cycleStartStr);
    }

    final now = DateTime.now();
    final daysElapsed = now.difference(cycleStart).inDays;
    final daysRemaining = 60 - daysElapsed;
    final isCycleComplete = daysRemaining <= 0;

    final pointValueSar = cycleSpending > 0
        ? (cycleSpending * 0.05) / pointsRequiredForVoucher
        : 0.0;

    return {
      'cycleStart': cycleStart,
      'daysElapsed': daysElapsed,
      'daysRemaining': daysRemaining,
      'isCycleComplete': isCycleComplete,
      'cycleSpending': cycleSpending,
      'cyclePoints': cyclePoints,
      'pointValueSar': pointValueSar,
      'totalRewardValue': cycleSpending * 0.05,
    };
  }

  String _formatDayKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }
}
