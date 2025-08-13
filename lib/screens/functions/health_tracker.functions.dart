part of health_tracker;

mixin HealthTrackerFunctions on State<HealthTracker> {
  // Award daily water goal points (idempotent per day)
  Future<bool> maybeAwardDailyWaterGoalPoints({
    required double currentIntakeMl,
    required double dailyGoalMl,
  }) async {
    try {
      final awarded = await RewardsService.instance
          .awardPointsForDailyWaterGoalIfNeeded(
            currentIntakeMl: currentIntakeMl,
            dailyGoalMl: dailyGoalMl,
          );
      if (awarded && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('+20 points for today’s goal')),
        );
      }
      return awarded;
    } catch (_) {
      // no-op
      return false;
    }
  }

  // Streak storage helpers (local-only)
  static const String _streakCurrentKey = 'health_streak_current_v1';
  static const String _streakBestKey = 'health_streak_best_v1';
  static const String _streakLastDayKey = 'health_streak_last_day_v1';

  Future<void> updateStreakOnGoalAwarded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDay = prefs.getString(_streakLastDayKey);
    final today = DateTime.now();
    final todayKey = _formatDayKey(today);

    int current = prefs.getInt(_streakCurrentKey) ?? 0;
    int best = prefs.getInt(_streakBestKey) ?? 0;

    if (lastDay == null) {
      current = 1;
    } else {
      final last = _parseDayKey(lastDay);
      final diff = today.difference(last).inDays;
      if (diff == 0) {
        // already counted today (idempotent)
        return;
      } else if (diff == 1) {
        current += 1;
      } else {
        current = 1; // streak broken
      }
    }

    if (current > best) best = current;

    await prefs.setString(_streakLastDayKey, todayKey);
    await prefs.setInt(_streakCurrentKey, current);
    await prefs.setInt(_streakBestKey, best);
  }

  Future<(_Streak current, _Streak best)> loadRawStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_streakCurrentKey) ?? 0;
    final best = prefs.getInt(_streakBestKey) ?? 0;
    return (_Streak(current), _Streak(best));
  }

  Future<_StreakSummary> loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_streakCurrentKey) ?? 0;
    final best = prefs.getInt(_streakBestKey) ?? 0;
    return _StreakSummary(current: current, best: best);
  }

  String _formatDayKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  DateTime _parseDayKey(String key) {
    final y = int.tryParse(key.substring(0, 4)) ?? DateTime.now().year;
    final m = int.tryParse(key.substring(4, 6)) ?? DateTime.now().month;
    final d = int.tryParse(key.substring(6, 8)) ?? DateTime.now().day;
    return DateTime(y, m, d);
  }

  // Compute recommended daily goal in milliliters based on simple heuristics
  // Defaults used if no profile data is available
  Future<double> calculateRecommendedDailyGoalMl() async {
    // TODO: integrate real profile data (weight, age, activity, weather)
    // Simple heuristic: 35 ml per kg, adjusted by activity and age
    const double defaultWeightKg = 70.0;
    const int defaultAgeYears = 30;
    const String defaultActivity = 'moderate'; // sedentary | moderate | active

    double weightKg = defaultWeightKg;
    int ageYears = defaultAgeYears;
    String activity = defaultActivity;

    // Base
    double baseMl = weightKg * 35.0;

    // Age adjustment
    if (ageYears >= 55) {
      baseMl *= 0.9; // -10%
    } else if (ageYears <= 18) {
      baseMl *= 1.05; // +5%
    }

    // Activity adjustment
    switch (activity) {
      case 'active':
        baseMl *= 1.2;
        break;
      case 'sedentary':
        baseMl *= 0.95;
        break;
      case 'moderate':
      default:
        baseMl *= 1.1;
        break;
    }

    // Clamp to sensible bounds
    baseMl = baseMl.clamp(1500.0, 5000.0);

    // Round to nearest 100 ml
    final rounded = (baseMl / 100.0).round() * 100.0;
    return rounded.toDouble();
  }
}

class _Streak {
  final int days;
  _Streak(this.days);
}

class _StreakSummary {
  final int current;
  final int best;
  _StreakSummary({required this.current, required this.best});
}
