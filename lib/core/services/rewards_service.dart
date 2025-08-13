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
  static const int dailyCheckInPoints = 15; // daily check-in
  static const int dailySpinMinPoints = 5; // daily spin min
  static const int dailySpinMaxPoints = 50; // daily spin max
  static const int referralSharePoints = 10; // sharing referral once
  static const int quickTapBonusPoints =
      5; // award when logging within reminder window
  static const int bodyStatusDailyPoints = 10; // daily body status log
  static const int comboBonusPoints = 30; // steps + hydration combo in a day
  static const int weeklyChallengeRewardPoints = 300; // weekly challenge reward
  static const int perLogPoints = 5; // +5 points per water log
  static const int streakBonus7Points = 50; // +50 for 7-day streak
  static const int streakBonus30Points = 150; // +150 for 30-day streak
  static const int earlyBirdPoints = 10; // before 9 AM
  static const int healthyMealChoicePoints = 10; // healthy meal pairing
  static const int pointsExpiryDays = 60; // seasonal points expiry

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
  String get _streakCurrentKey => 'hydration_streak_current_${_profileKey}_v1';
  String get _streakBestKey => 'hydration_streak_best_${_profileKey}_v1';
  String get _streakLastDayKey => 'hydration_streak_last_${_profileKey}_v1';
  String get _lastReminderKey => 'hydration_last_reminder_${_profileKey}_v1';
  String get _ledgerKey => 'rewards_points_ledger_${_profileKey}_v1';
  String _championKey(String ym) => 'champion_claimed_${_profileKey}_$ym';

  Future<int> getPointsBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return _purgeExpiredAndGetBalance(prefs);
  }

  Future<void> resetPoints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsKey, 0);
  }

  Future<void> _setPointsBalance(int points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsKey, max(0, points));
  }

  List<Map<String, dynamic>> _loadLedger(SharedPreferences prefs) {
    final raw = prefs.getString(_ledgerKey);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> _saveLedger(
    SharedPreferences prefs,
    List<Map<String, dynamic>> ledger,
  ) async {
    await prefs.setString(_ledgerKey, jsonEncode(ledger));
  }

  int _purgeExpiredAndGetBalance(SharedPreferences prefs) {
    final ledger = _loadLedger(prefs);
    final now = DateTime.now();
    final fresh = ledger.where((e) {
      final ts = DateTime.tryParse((e['ts'] as String?) ?? '') ?? now;
      return now.difference(ts).inDays < pointsExpiryDays;
    }).toList();
    if (fresh.length != ledger.length) {
      // persist purge
      _saveLedger(prefs, fresh);
    }
    int balance = 0;
    for (final e in fresh) {
      balance += (e['points'] as num?)?.toInt() ?? 0;
    }
    return max(0, balance);
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

  // Availability helpers for UI
  Future<bool> isDailyCheckInAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final flags = _loadAwardFlags(prefs);
    final dayKey = _formatDayKey(DateTime.now());
    final key = 'checkin_$dayKey';
    return flags[key] != true;
  }

  Future<bool> isDailySpinAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final flags = _loadAwardFlags(prefs);
    final dayKey = _formatDayKey(DateTime.now());
    final key = 'spin_$dayKey';
    return flags[key] != true;
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

    final prefs = await SharedPreferences.getInstance();
    // Append to ledger
    final ledger = _loadLedger(prefs);
    ledger.add({
      'points': points,
      'reason': reason ?? 'generic',
      'ts': DateTime.now().toIso8601String(),
    });
    await _saveLedger(prefs, ledger);

    // Recalculate balance (purging expired)
    int updated = _purgeExpiredAndGetBalance(prefs);

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
    // Update streak and compute multiplier (5% per day up to 50%)
    final currentStreak = await _updateStreakAndGetCount(prefs, today);
    final bonusPercent = (currentStreak - 1) * 0.05;
    final clamped = bonusPercent.clamp(0.0, 0.5);
    int daily = dailyWaterGoalPoints;
    // Weekend double
    if (today.weekday == DateTime.saturday ||
        today.weekday == DateTime.sunday) {
      daily *= 2;
    }
    final pointsToAdd = (daily * (1.0 + clamped)).round();
    await addPoints(pointsToAdd, reason: 'daily_water_goal');

    // Milestone bonuses (once on the day they are hit)
    final streak7Key = 'streak7_$dayKey';
    final streak30Key = 'streak30_$dayKey';
    if (currentStreak == 7 && flags[streak7Key] != true) {
      await addPoints(streakBonus7Points, reason: 'streak_7');
      flags[streak7Key] = true;
    }
    if (currentStreak == 30 && flags[streak30Key] != true) {
      await addPoints(streakBonus30Points, reason: 'streak_30');
      flags[streak30Key] = true;
      // Issue Hydration Champion voucher once per month
      final ym = _formatYearMonth(today);
      if (prefs.getBool(_championKey(ym)) != true) {
        final vouchers = await _loadVouchers();
        vouchers.add(_createVoucher());
        await _saveVouchers(vouchers);
        await prefs.setBool(_championKey(ym), true);
      }
    }
    flags[awardKey] = true;
    await _saveAwardFlags(prefs, flags);
    return true;
  }

  // Daily check-in (once per calendar day). Returns points awarded (0 if already claimed)
  Future<int> awardDailyCheckInIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final flags = _loadAwardFlags(prefs);
    final dayKey = _formatDayKey(DateTime.now());
    final key = 'checkin_$dayKey';
    if (flags[key] == true) return 0;
    await addPoints(dailyCheckInPoints, reason: 'daily_check_in');
    flags[key] = true;
    await _saveAwardFlags(prefs, flags);
    return dailyCheckInPoints;
  }

  // Daily spin (once per calendar day). Returns points won (0 if already spun)
  Future<int> dailySpinIfAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final flags = _loadAwardFlags(prefs);
    final dayKey = _formatDayKey(DateTime.now());
    final key = 'spin_$dayKey';
    if (flags[key] == true) return 0;
    final rand = Random();
    final points =
        dailySpinMinPoints +
        rand.nextInt(dailySpinMaxPoints - dailySpinMinPoints + 1);
    await addPoints(points, reason: 'daily_spin');
    flags[key] = true;
    await _saveAwardFlags(prefs, flags);
    return points;
  }

  // Referral share (once per profile). Returns true if awarded now
  Future<bool> awardReferralShareOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final flags = _loadAwardFlags(prefs);
    const key = 'referral_shared';
    if (flags[key] == true) return false;
    await addPoints(referralSharePoints, reason: 'referral_share');
    flags[key] = true;
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

  String _formatYearMonth(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$y$m';
  }

  // Streak management: returns current streak length
  Future<int> _updateStreakAndGetCount(
    SharedPreferences prefs,
    DateTime today,
  ) async {
    final lastDay = prefs.getString(_streakLastDayKey);
    int current = prefs.getInt(_streakCurrentKey) ?? 0;
    int best = prefs.getInt(_streakBestKey) ?? 0;

    if (lastDay == null) {
      current = 1;
    } else {
      final last = DateTime(
        int.parse(lastDay.substring(0, 4)),
        int.parse(lastDay.substring(4, 6)),
        int.parse(lastDay.substring(6, 8)),
      );
      final diff = today.difference(last).inDays;
      if (diff == 0) {
        // already awarded today; keep streak unchanged
      } else if (diff == 1) {
        current += 1;
      } else {
        current = 1; // streak broken
      }
    }

    if (current > best) best = current;

    await prefs.setString(_streakLastDayKey, _formatDayKey(today));
    await prefs.setInt(_streakCurrentKey, current);
    await prefs.setInt(_streakBestKey, best);

    return current;
  }

  Future<Map<String, int>> getStreakSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_streakCurrentKey) ?? 0;
    final best = prefs.getInt(_streakBestKey) ?? 0;
    return {'current': current, 'best': best};
  }

  // Quick Tap Bonus: call when a notification fires
  Future<void> recordHydrationReminderFired() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastReminderKey, DateTime.now().toIso8601String());
  }

  // +5 points per water log
  Future<void> addPointsForWaterLog() async {
    await addPoints(perLogPoints, reason: 'water_log');
  }

  // Record a water log (amount with timestamp)
  Future<void> recordWaterLog(int amountMl) async {
    final prefs = await SharedPreferences.getInstance();
    final dayKey = _formatDayKey(DateTime.now());
    final raw = prefs.getString('water_logs_${_profileKey}_$dayKey');
    List<Map<String, dynamic>> logs = [];
    if (raw != null && raw.isNotEmpty) {
      logs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    }
    logs.add({'ts': DateTime.now().toIso8601String(), 'ml': amountMl});
    await prefs.setString(
      'water_logs_${_profileKey}_$dayKey',
      jsonEncode(logs),
    );
  }

  // Early bird bonus before 9 AM (once per day)
  Future<bool> awardEarlyBirdIfEligible() async {
    final now = DateTime.now();
    if (now.hour >= 9) return false;
    final prefs = await SharedPreferences.getInstance();
    final flags = _loadAwardFlags(prefs);
    final dayKey = _formatDayKey(now);
    final key = 'early_bird_$dayKey';
    if (flags[key] == true) return false;
    await addPoints(earlyBirdPoints, reason: 'early_bird');
    flags[key] = true;
    await _saveAwardFlags(prefs, flags);
    return true;
  }

  // Award bonus if logging within 5 minutes of last reminder and not yet claimed
  Future<bool> awardQuickTapBonusIfEligible() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastReminderKey);
    if (raw == null) return false;
    final lastReminder = DateTime.tryParse(raw);
    if (lastReminder == null) return false;
    final now = DateTime.now();
    final within5 = now.difference(lastReminder).inMinutes <= 5;
    if (!within5) return false;

    final flags = _loadAwardFlags(prefs);
    final dayKey = _formatDayKey(now);
    final key = 'quick_tap_$dayKey';
    if (flags[key] == true) return false;

    await addPoints(quickTapBonusPoints, reason: 'quick_tap_bonus');
    flags[key] = true;
    await _saveAwardFlags(prefs, flags);
    return true;
  }

  // Body status daily points (once per day)
  Future<bool> awardBodyStatusDailyIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final flags = _loadAwardFlags(prefs);
    final dayKey = _formatDayKey(DateTime.now());
    final key = 'body_status_$dayKey';
    if (flags[key] == true) return false;
    await addPoints(bodyStatusDailyPoints, reason: 'body_status');
    flags[key] = true;
    await _saveAwardFlags(prefs, flags);
    return true;
  }

  // Weekly challenge utilities (simple current week id)
  String getCurrentWeekId() {
    final now = DateTime.now();
    final week = ((now.day - now.weekday + 10) / 7).floor();
    return '${now.year}W$week';
  }

  Future<bool> isChallengeActive(String weekId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('challenge_active_${_profileKey}_$weekId') ?? false;
  }

  Future<void> joinChallenge(String weekId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('challenge_active_${_profileKey}_$weekId', true);
  }

  Future<bool> canClaimChallenge(String weekId, int currentStreak) async {
    final active = await isChallengeActive(weekId);
    if (!active) return false;
    // Simple rule: 7+ day streak
    if (currentStreak < 7) return false;
    final prefs = await SharedPreferences.getInstance();
    final claimed =
        prefs.getBool('challenge_claimed_${_profileKey}_$weekId') ?? false;
    return !claimed;
  }

  Future<bool> claimChallenge(String weekId) async {
    final prefs = await SharedPreferences.getInstance();
    final claimedKey = 'challenge_claimed_${_profileKey}_$weekId';
    if (prefs.getBool(claimedKey) == true) return false;
    await addPoints(weeklyChallengeRewardPoints, reason: 'weekly_challenge');
    await prefs.setBool(claimedKey, true);
    return true;
  }

  // Habit combos (both tasks done in a day)
  Future<void> setComboTaskDone(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final flags = _loadAwardFlags(prefs);
    final dayKey = _formatDayKey(DateTime.now());
    flags['combo_${taskId}_$dayKey'] = true;
    await _saveAwardFlags(prefs, flags);
  }

  Future<bool> claimComboBonusIfEligible() async {
    final prefs = await SharedPreferences.getInstance();
    final flags = _loadAwardFlags(prefs);
    final dayKey = _formatDayKey(DateTime.now());
    final a = flags['combo_breakfast_$dayKey'] == true;
    final b = flags['combo_workout_$dayKey'] == true;
    final claimed = flags['combo_claimed_$dayKey'] == true;
    if (!(a && b) || claimed) return false;
    await addPoints(comboBonusPoints, reason: 'combo_bonus');
    flags['combo_claimed_$dayKey'] = true;
    await _saveAwardFlags(prefs, flags);
    return true;
  }
}
