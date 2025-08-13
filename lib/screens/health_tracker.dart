// lib/screens/health_tracker.dart
library health_tracker;

import 'package:provider/provider.dart';
import '../core/constants/translations.dart';
import '../core/services/app_settings.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// removed unused imports
import '../core/constants/design_system.dart';
// removed unused imports
import '../core/services/storage_service.dart';
import '../core/services/rewards_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// removed unused imports
part 'functions/health_tracker.functions.dart';

class HealthTracker extends StatefulWidget {
  const HealthTracker({super.key});

  @override
  State<HealthTracker> createState() => _HealthTrackerState();
}

class _HealthTrackerState extends State<HealthTracker>
    with TickerProviderStateMixin, HealthTrackerFunctions {
  double _dailyGoal = 3000.0; // ml
  double _currentIntake = 1200.0; // ml
  // removed unused field
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  // Rewards & streak state
  int _pointsBalance = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  double _voucherProgress = 0.0; // 0..1 toward next voucher

  // Weekly data removed in rewards-first redesign

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _progressAnimation =
        Tween<double>(begin: 0.0, end: _currentIntake / _dailyGoal).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );

    _animationController.forward();
    _progressController.forward();
    _loadDailyGoal();
    _loadRewardsAndStreak();
  }

  Future<void> _loadDailyGoal() async {
    // Prefer recommended goal; fall back to stored if available and reasonable
    final recommended = await calculateRecommendedDailyGoalMl();
    final stored = await StorageService.getWaterGoal();
    final effective = (stored >= 1500 && stored <= 5000)
        ? stored.toDouble()
        : recommended;
    setState(() {
      _dailyGoal = effective;
    });
    _updateProgress();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _addWater(double amount) {
    setState(() {
      _currentIntake += amount;
      if (_currentIntake > _dailyGoal) {
        _currentIntake = _dailyGoal;
      }
    });
    _updateProgress();
    HapticFeedback.lightImpact();

    // Record a plausible log entry for anti-cheat and challenges
    RewardsService.instance.recordWaterLog(amount.toInt());

    // +5 points per water log
    RewardsService.instance.addPointsForWaterLog();

    // Early bird bonus before 9 AM
    RewardsService.instance.awardEarlyBirdIfEligible();

    // Quick Tap Bonus if within 5 minutes of a reminder
    RewardsService.instance.awardQuickTapBonusIfEligible().then((awarded) {
      if (!mounted) return;
      if (awarded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('+5 points (Quick Tap Bonus)')),
        );
        _loadRewardsAndStreak();
      }
    });

    // Try award daily goal points once per day when goal met
    _maybeHandleGoalAwardAndStreak();
  }

  Future<void> _maybeHandleGoalAwardAndStreak() async {
    final awarded = await maybeAwardDailyWaterGoalPoints(
      currentIntakeMl: _currentIntake,
      dailyGoalMl: _dailyGoal,
    );
    if (awarded) {
      await updateStreakOnGoalAwarded();
      await _loadRewardsAndStreak();
    }
  }

  void _updateProgress() {
    _progressAnimation =
        Tween<double>(
          begin: _progressAnimation.value,
          end: _currentIntake / _dailyGoal,
        ).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );
    _progressController.forward(from: 0.0);
  }

  Future<void> _loadRewardsAndStreak() async {
    try {
      final points = await RewardsService.instance.getPointsBalance();
      await RewardsService.instance.getActiveVouchers();
      final progress =
          (points % RewardsService.pointsRequiredForVoucher) /
          RewardsService.pointsRequiredForVoucher;
      final streak = await loadStreak();
      if (!mounted) return;
      setState(() {
        _pointsBalance = points;
        _voucherProgress = progress.clamp(0.0, 1.0);
        _currentStreak = streak.current;
        _bestStreak = streak.best;
      });
    } catch (_) {
      // ignore
    }
  }

  void _showCustomAmountDialog() {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppTranslations.getText(
            'add',
            context.read<AppSettings>().currentLanguage,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppTranslations.getText(
                    'amount_ml',
                    context.read<AppSettings>().currentLanguage,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.getText(
                'cancel',
                context.read<AppSettings>().currentLanguage,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                _addWater(amount);
                Navigator.pop(context);
              }
            },
            child: Text(
              AppTranslations.getText(
                'add',
                context.read<AppSettings>().currentLanguage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appSettings = context.watch<AppSettings>();
    final isEnglish = appSettings.currentLanguage == 'en';
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leadingWidth: 140,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GestureDetector(
            onTap: () async {
              final vouchers = await RewardsService.instance
                  .getActiveVouchers();
              if (!mounted) return;
              showModalBottomSheet(
                context: context,
                backgroundColor: theme.cardColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.getText(
                            'rewards',
                            context.read<AppSettings>().currentLanguage,
                          ),
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (vouchers.isEmpty)
                          Text(
                            AppTranslations.getText(
                              'no_vouchers',
                              context.read<AppSettings>().currentLanguage,
                            ),
                            style: theme.textTheme.bodyMedium,
                          )
                        else
                          ...vouchers.map(
                            (v) => ListTile(
                              leading: const Icon(
                                Icons.confirmation_number_outlined,
                              ),
                              title: Text(
                                '${AppTranslations.getText('voucher', context.read<AppSettings>().currentLanguage)} ${v['amount']} ${AppTranslations.getText('sar', context.read<AppSettings>().currentLanguage)}',
                              ),
                              subtitle: Text(
                                '${AppTranslations.getText('expires', context.read<AppSettings>().currentLanguage)}: ${v['expires_at']}',
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: DesignSystem.getBrandShadow('light'),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stars, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${AppTranslations.getText('points', context.read<AppSettings>().currentLanguage)}: $_pointsBalance',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
        title: Text(
          AppTranslations.getText('health', appSettings.currentLanguage),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color:
                theme.appBarTheme.titleTextStyle?.color ??
                theme.colorScheme.onBackground,
            fontFamily: isEnglish
                ? 'PublicSans'
                : theme.textTheme.titleLarge?.fontFamily,
          ),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewPadding.bottom +
              kBottomNavigationBarHeight +
              16,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's Progress
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  gradient: DesignSystem.getBrandGradient('primary'),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: DesignSystem.getBrandShadow('heavy'),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTranslations.getText(
                            'today_progress',
                            appSettings.currentLanguage,
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: Text(
                              '${((_currentIntake / _dailyGoal) * 100).toInt()}%',
                              key: ValueKey(_currentIntake.toInt()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  return Text(
                                    '${_currentIntake.toInt()} ml',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                              Text(
                                '${AppTranslations.getText('daily_goal', appSettings.currentLanguage)}: ${(_dailyGoal / 1000).toStringAsFixed(1)} L',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: _progressAnimation.value,
                                strokeWidth: 8,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Rewards & Streak header under Today's Progress
              _buildRewardsHeader(context, isEnglish: isEnglish),
              const SizedBox(height: 16),
              _buildWeeklyChallengeInline(context, isEnglish: isEnglish),
              const SizedBox(height: 12),
              _buildChampionInline(context, isEnglish: isEnglish),
              const SizedBox(height: 12),
              _buildDailySpinInline(context),
              const SizedBox(height: 12),
              _buildPointsExpiryInfo(context),
              const SizedBox(height: 24),

              // Quick Add Buttons
              Text(
                AppTranslations.getText(
                  'quick_add',
                  appSettings.currentLanguage,
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAddButton(
                      250,
                      AppTranslations.getText(
                        'small_cup',
                        appSettings.currentLanguage,
                      ),
                      Icons.local_drink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAddButton(
                      500,
                      AppTranslations.getText(
                        'large_cup',
                        appSettings.currentLanguage,
                      ),
                      Icons.local_drink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAddButton(
                      1000,
                      AppTranslations.getText(
                        'bottle',
                        appSettings.currentLanguage,
                      ),
                      Icons.water_drop,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _buildQuickAddButton(
                  0,
                  AppTranslations.getText(
                    'custom_amount',
                    appSettings.currentLanguage,
                  ),
                  Icons.add,
                  isCustom: true,
                ),
              ),

              const SizedBox(height: 30),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardsHeader(BuildContext context, {required bool isEnglish}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: DesignSystem.getBrandShadow('light'),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: DesignSystem.primaryGradient,
            ),
            child: const Icon(Icons.local_fire_department, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Streak: $_currentStreak days',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.titleMedium?.color,
                        fontFamily: isEnglish
                            ? 'PublicSans'
                            : theme.textTheme.titleMedium?.fontFamily,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Best $_bestStreak',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: isEnglish
                              ? 'PublicSans'
                              : theme.textTheme.bodySmall?.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Points: $_pointsBalance',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontFamily: isEnglish
                            ? 'PublicSans'
                            : theme.textTheme.bodyMedium?.fontFamily,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: _voucherProgress,
                    backgroundColor: theme.brightness == Brightness.dark
                        ? Colors.white10
                        : Colors.black12,
                    valueColor: AlwaysStoppedAnimation(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(_voucherProgress * 100).toStringAsFixed(0)}% to next voucher',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final vouchers = await RewardsService.instance
                  .getActiveVouchers();
              if (!mounted) return;
              showModalBottomSheet(
                context: context,
                backgroundColor: theme.cardColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.getText(
                            'rewards',
                            context.read<AppSettings>().currentLanguage,
                          ),
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (vouchers.isEmpty)
                          Text(
                            AppTranslations.getText(
                              'no_vouchers',
                              context.read<AppSettings>().currentLanguage,
                            ),
                            style: theme.textTheme.bodyMedium,
                          )
                        else
                          ...vouchers.map(
                            (v) => ListTile(
                              leading: const Icon(
                                Icons.confirmation_number_outlined,
                              ),
                              title: Text(
                                '${AppTranslations.getText('voucher', context.read<AppSettings>().currentLanguage)} ${v['amount']} ${AppTranslations.getText('sar', context.read<AppSettings>().currentLanguage)}',
                              ),
                              subtitle: Text(
                                '${AppTranslations.getText('expires', context.read<AppSettings>().currentLanguage)}: ${v['expires_at']}',
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.redeem),
            label: Text(
              AppTranslations.getText(
                'rewards',
                context.read<AppSettings>().currentLanguage,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChallengeInline(
    BuildContext context, {
    required bool isEnglish,
  }) {
    final theme = Theme.of(context);
    final weekId = RewardsService.instance.getCurrentWeekId();
    return FutureBuilder<Map<String, int>>(
      future: RewardsService.instance.getStreakSummary(),
      builder: (context, snapshot) {
        final currentStreak = snapshot.data?['current'] ?? 0;
        return FutureBuilder<bool>(
          future: RewardsService.instance.canClaimChallenge(
            weekId,
            currentStreak,
          ),
          builder: (context, snap2) {
            final canClaim = snap2.data == true;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: DesignSystem.getBrandShadow('light'),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Color(0xFF6B46C1),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${AppTranslations.getText('streak_7', context.read<AppSettings>().currentLanguage)}: $currentStreak/7',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final active = await RewardsService.instance
                          .isChallengeActive(weekId);
                      if (!active) {
                        await RewardsService.instance.joinChallenge(weekId);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Joined challenge')),
                        );
                      } else if (canClaim) {
                        final ok = await RewardsService.instance.claimChallenge(
                          weekId,
                        );
                        if (!mounted) return;
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Challenge claimed! +100 pts'),
                            ),
                          );
                          await _loadRewardsAndStreak();
                          setState(() {});
                        }
                      }
                    },
                    child: Text(
                      isEnglish
                          ? (canClaim ? 'Claim' : 'In Progress')
                          : (canClaim
                                ? AppTranslations.getText(
                                    'claim',
                                    context.read<AppSettings>().currentLanguage,
                                  )
                                : AppTranslations.getText(
                                    'in_progress',
                                    context.read<AppSettings>().currentLanguage,
                                  )),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChampionInline(BuildContext context, {required bool isEnglish}) {
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, int>>(
      future: RewardsService.instance.getStreakSummary(),
      builder: (context, snapshot) {
        final current = snapshot.data?['current'] ?? 0;
        final unlocked = current >= 30;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: DesignSystem.getBrandShadow('light'),
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFF6B46C1)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '30-Day Hydration Champion: $current/30',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: unlocked
                      ? Colors.green.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unlocked ? 'Unlocked' : 'Keep going',
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailySpinInline(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<bool>(
      future: RewardsService.instance.isDailySpinAvailable(),
      builder: (context, snapshot) {
        final available = snapshot.data ?? true;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: DesignSystem.getBrandShadow('light'),
          ),
          child: Row(
            children: [
              const Icon(Icons.casino, color: Color(0xFF6B46C1)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Daily Spin: 1 free spin for bonus rewards',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              ElevatedButton(
                onPressed: available
                    ? () async {
                        final pts = await RewardsService.instance
                            .dailySpinIfAvailable();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              pts > 0 ? '+$pts points' : 'Try again tomorrow',
                            ),
                          ),
                        );
                        await _loadRewardsAndStreak();
                        setState(() {});
                      }
                    : null,
                child: Text(available ? 'Spin' : 'Used'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPointsExpiryInfo(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: DesignSystem.getBrandShadow('light'),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Color(0xFF6B46C1), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Points expire after 60 days. Use them before they expire.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // Removed previously added engagement cards

  Widget _buildQuickAddButton(
    double amount,
    String label,
    IconData icon, {
    bool isCustom = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isCustom) {
          _showCustomAmountDialog();
        } else {
          _addWater(amount);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.05,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFBFA4FF)
                    : Colors.purple[600],
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCustom ? label : '$amount ml',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            if (!isCustom)
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
