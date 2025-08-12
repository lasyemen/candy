part of health_tracker;

mixin HealthTrackerFunctions on State<HealthTracker> {
  // Award daily water goal points (idempotent per day)
  Future<void> maybeAwardDailyWaterGoalPoints({
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('+20 نقاط لصحة اليوم')));
      }
    } catch (_) {
      // no-op
    }
  }
}
