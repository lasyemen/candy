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

  @override
  void initState() {
    super.initState();
    _loadRewardsOverview();
  }

  Future<void> _loadRewardsOverview() async {
    final points = await RewardsService.instance.getPointsBalance();
    final progress =
        (points % RewardsService.pointsRequiredForVoucher) /
        RewardsService.pointsRequiredForVoucher;
    final checkIn = await RewardsService.instance.isDailyCheckInAvailable();
    final spin = await RewardsService.instance.isDailySpinAvailable();

    if (!mounted) return;
    setState(() {
      _pointsBalance = points;
      _voucherProgress = progress.clamp(0.0, 1.0);
      _checkInAvailable = checkIn;
      _spinAvailable = spin;
    });
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
        child: SingleChildScrollView(
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
              _buildPointsHeader(
                context,
                language: language,
                isEnglish: isEnglish,
              ),
              const SizedBox(height: 16),
              _buildActionsRow(context, language: language),
              const SizedBox(height: 16),
              _buildVouchersSection(context, language: language),
              const SizedBox(height: 24),
              _buildRulesSection(
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

  Widget _buildPointsHeader(
    BuildContext context, {
    required String language,
    required bool isEnglish,
  }) {
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
            AppTranslations.getText('points', language),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_pointsBalance',
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
              value: _voucherProgress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.getText('voucher_threshold_rule', language)
                .replaceAll(
                  '{points}',
                  RewardsService.pointsRequiredForVoucher.toString(),
                )
                .replaceAll(
                  '{amount}',
                  RewardsService.voucherValueSar.toStringAsFixed(0),
                ),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
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

  Widget _buildRulesSection(
    BuildContext context, {
    required String language,
    required bool isEnglish,
  }) {
    final theme = Theme.of(context);
    // Optionally, show dynamic rate via FutureBuilder if desired
    // Keeping rules static to avoid async in build; rate shown as em dash
    final rules = <String>[
      AppTranslations.getText(
        'points_per_sar_rule',
        language,
      ).replaceAll('{rate}', '—'),
      AppTranslations.getText(
        'daily_check_in_points_rule',
        language,
      ).replaceAll('{points}', RewardsService.dailyCheckInPoints.toString()),
      AppTranslations.getText('daily_spin_range_rule', language)
          .replaceAll('{min}', RewardsService.dailySpinMinPoints.toString())
          .replaceAll('{max}', RewardsService.dailySpinMaxPoints.toString()),
      AppTranslations.getText(
        'referral_share_points_rule',
        language,
      ).replaceAll('{points}', RewardsService.referralSharePoints.toString()),
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
            AppTranslations.getText('how_to_earn', language),
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
