// lib/screens/rewards_test_screen.dart
library rewards_test_screen;

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/rewards_service.dart';

part 'functions/rewards_test_screen.functions.dart';

class RewardsTestScreen extends StatefulWidget {
  const RewardsTestScreen({super.key});

  @override
  State<RewardsTestScreen> createState() => _RewardsTestScreenState();
}

class _RewardsTestScreenState extends State<RewardsTestScreen>
    with RewardsTestScreenFunctions {
  @override
  void initState() {
    super.initState();
    refreshRewards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildPointsCard(),
            const SizedBox(height: 16),
            _buildPurchaseSimulator(),
            const SizedBox(height: 16),
            _buildHealthSimulator(),
            const SizedBox(height: 16),
            _buildDailyGoalSimulator(),
            const SizedBox(height: 16),
            _buildVouchersCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Points Balance',
              style: TextStyle(fontSize: 16, fontFamily: 'Rubik'),
            ),
            const SizedBox(height: 8),
            Text(
              '$points pts',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Rubik',
              ),
            ),
            if (lastMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                lastMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'Rubik',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseSimulator() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simulate Purchase',
              style: TextStyle(fontSize: 16, fontFamily: 'Rubik'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final amount in [50.0, 100.0, 200.0])
                  ElevatedButton(
                    onPressed: () async {
                      await simulatePurchase(amount);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('${amount.toStringAsFixed(0)} SAR'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSimulator() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simulate Healthy Change',
              style: TextStyle(fontSize: 16, fontFamily: 'Rubik'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => addHealthyChange('hc-a'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Healthy Change A'),
                ),
                ElevatedButton(
                  onPressed: () => addHealthyChange('hc-b'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Healthy Change B'),
                ),
                ElevatedButton(
                  onPressed: () => addHealthyChange(
                    'hc-${DateTime.now().millisecondsSinceEpoch}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Random ID Change'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGoalSimulator() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simulate Daily Water Goal',
              style: TextStyle(fontSize: 16, fontFamily: 'Rubik'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await RewardsService.instance
                    .awardPointsForDailyWaterGoalIfNeeded(
                      currentIntakeMl: 3000,
                      dailyGoalMl: 3000,
                    );
                await refreshRewards();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tried to award daily goal')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Award if not yet today'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVouchersCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Vouchers',
              style: TextStyle(fontSize: 16, fontFamily: 'Rubik'),
            ),
            const SizedBox(height: 12),
            if (vouchers.isEmpty)
              const Text(
                'None',
                style: TextStyle(fontSize: 14, fontFamily: 'Rubik'),
              )
            else
              Column(
                children: [
                  for (final v in vouchers)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Voucher ${v['id'].toString().substring(0, 6)}',
                                  style: const TextStyle(
                                    fontFamily: 'Rubik',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Expires: ${v['expires_at']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontFamily: 'Rubik',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final discount = await RewardsService.instance
                                  .redeemVoucher(v['id'] as String);
                              await refreshRewards();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      discount > 0
                                          ? 'Redeemed ${discount.toStringAsFixed(0)} SAR'
                                          : 'Voucher invalid/expired',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Redeem'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}




