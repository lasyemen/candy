// lib/screens/rewards_screen.dart
library rewards_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/rewards_service.dart';
import '../core/routes/app_routes.dart';
import '../core/constants/translations.dart';
import '../core/services/app_settings.dart';
import '../core/constants/design_system.dart';

part 'functions/rewards_screen.functions.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with TickerProviderStateMixin, RewardsScreenFunctions {
  int _pointsBalance = 0;
  double _voucherProgress = 0.0;
  bool _checkInAvailable = true;
  bool _spinAvailable = true;

  // New cycle information
  Map<String, dynamic> _cycleInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRewardsOverview();
  }

  Future<void> _loadRewardsOverview() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final points = await RewardsService.instance.getPointsBalance();
      final progress =
          (points % RewardsService.pointsRequiredForVoucher) /
          RewardsService.pointsRequiredForVoucher;
      final checkIn = await RewardsService.instance.isDailyCheckInAvailable();
      final spin = await RewardsService.instance.isDailySpinAvailable();

      // Load new cycle information
      final cycleInfo = await RewardsService.instance.getCurrentCycleInfo();

      if (!mounted) return;
      setState(() {
        _pointsBalance = points;
        _voucherProgress = progress.clamp(0.0, 1.0);
        _checkInAvailable = checkIn;
        _spinAvailable = spin;
        _cycleInfo = cycleInfo;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<AppSettings>();
    final language = settings.currentLanguage;
    final isEnglish = language == 'en';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppTranslations.getText('rewards', language),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: isEnglish
                ? 'PublicSans'
                : theme.textTheme.titleLarge?.fontFamily,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRewardsOverview,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(context).viewPadding.bottom +
                      kBottomNavigationBarHeight +
                      16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNewPointsHeader(
                      context,
                      language: language,
                      isEnglish: isEnglish,
                    ),
                    const SizedBox(height: 16),
                    _buildCycleProgressCard(
                      context,
                      language: language,
                      isEnglish: isEnglish,
                    ),
                    const SizedBox(height: 16),
                    _buildActionsRow(context, language: language),
                    const SizedBox(height: 16),
                    _buildVouchersSection(context, language: language),
                    const SizedBox(height: 24),
                    _buildNewRulesSection(
                      context,
                      language: language,
                      isEnglish: isEnglish,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.testCheckout);
                      },
                      icon: const Icon(Icons.shopping_bag),
                      label: const Text('Open Test Checkout'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildNewPointsHeader(
    BuildContext context, {
    required String language,
    required bool isEnglish,
  }) {
    final cyclePoints = _cycleInfo['cyclePoints'] ?? 0;
    final totalRewardValue = _cycleInfo['totalRewardValue'] ?? 0.0;
    final pointValueSar = _cycleInfo['pointValueSar'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: DesignSystem.getBrandGradient('primary'),
        borderRadius: BorderRadius.circular(24),
        boxShadow: DesignSystem.getBrandShadow('heavy'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppTranslations.getText('points', language)} (${AppTranslations.getText('new_system', language)})',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$cyclePoints / 1,000',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              fontFamily: isEnglish ? 'PublicSans' : null,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: cyclePoints / 1000.0,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${AppTranslations.getText('point_value', language)}: ${pointValueSar.toStringAsFixed(3)} SAR',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppTranslations.getText('total_reward', language)}: ${totalRewardValue.toStringAsFixed(2)} SAR',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleProgressCard(
    BuildContext context, {
    required String language,
    required bool isEnglish,
  }) {
    final daysRemaining = _cycleInfo['daysRemaining'] ?? 0;
    final cycleSpending = _cycleInfo['cycleSpending'] ?? 0.0;
    final cycleStart = _cycleInfo['cycleStart'] as DateTime?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: DesignSystem.getBrandShadow('light'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.getText('current_cycle', language),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCycleStat(
                  context,
                  AppTranslations.getText('days_remaining', language),
                  '$daysRemaining',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildCycleStat(
                  context,
                  AppTranslations.getText('cycle_spending', language),
                  '${cycleSpending.toStringAsFixed(2)} SAR',
                  Icons.payment,
                  Colors.green,
                ),
              ),
            ],
          ),
          if (cycleStart != null) ...[
            const SizedBox(height: 12),
            Text(
              '${AppTranslations.getText('cycle_started', language)}: ${_formatDate(cycleStart, language)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCycleStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime date, String language) {
    if (language == 'ar') {
      return '${date.day}/${date.month}/${date.year}';
    } else if (language == 'ur') {
      return '${date.day}/${date.month}/${date.year}';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Widget _buildActionsRow(BuildContext context, {required String language}) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _checkInAvailable
                ? () async {
                    final pts = await RewardsService.instance
                        .awardDailyCheckInIfNeeded();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          pts > 0
                              ? '+$pts'
                              : AppTranslations.getText('done', language),
                        ),
                      ),
                    );
                    await _loadRewardsOverview();
                  }
                : null,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              _checkInAvailable
                  ? AppTranslations.getText('check_in', language)
                  : AppTranslations.getText('done', language),
            ),
            style: ElevatedButton.styleFrom(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _spinAvailable
                ? () async {
                    final pts = await RewardsService.instance
                        .dailySpinIfAvailable();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          pts > 0
                              ? '+$pts'
                              : AppTranslations.getText('done', language),
                        ),
                      ),
                    );
                    await _loadRewardsOverview();
                  }
                : null,
            icon: const Icon(Icons.casino),
            label: Text(AppTranslations.getText('daily_spin', language)),
          ),
        ),
      ],
    );
  }

  Widget _buildVouchersSection(
    BuildContext context, {
    required String language,
  }) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: RewardsService.instance.getActiveVouchers(),
      builder: (context, snapshot) {
        final vouchers = snapshot.data ?? const <Map<String, dynamic>>[];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: DesignSystem.getBrandShadow('light'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppTranslations.getText('rewards', language),
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    '${vouchers.length}',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (vouchers.isEmpty)
                Text(
                  AppTranslations.getText('no_vouchers', language),
                  style: theme.textTheme.bodyMedium,
                )
              else
                ...vouchers.map(
                  (v) => ListTile(
                    leading: const Icon(Icons.confirmation_number_outlined),
                    title: Text(
                      '${AppTranslations.getText('voucher', language)} ${v['amount']} ${AppTranslations.getText('sar', language)}',
                    ),
                    subtitle: Text(
                      '${AppTranslations.getText('expires', language)}: ${v['expires_at']}',
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewRulesSection(
    BuildContext context, {
    required String language,
    required bool isEnglish,
  }) {
    final theme = Theme.of(context);
    final rules = <String>[
      AppTranslations.getText('fixed_points_rule', language),
      AppTranslations.getText('five_percent_rule', language),
      AppTranslations.getText('cycle_duration_rule', language),
      AppTranslations.getText(
        'points_expiry_rule',
        language,
      ).replaceAll('{days}', RewardsService.pointsExpiryDays.toString()),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: DesignSystem.getBrandShadow('light'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.getText('how_new_system_works', language),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...rules.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 8),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
