// lib/screens/thank_you_screen.dart
library thank_you_screen;

import 'package:flutter/material.dart';
import '../core/constants/design_system.dart';
import '../core/constants/app_colors.dart';
import '../core/services/rewards_service.dart';

class ThankYouScreen extends StatelessWidget {
  final double? total;
  final int? earned;
  const ThankYouScreen({super.key, this.total, this.earned});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: RewardsService.instance.getPointsBalance(),
      builder: (context, snapshot) {
        final points = snapshot.data ?? 0;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Thank You'),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: DesignSystem.primaryGradient,
                      borderRadius: BorderRadius.circular(45),
                      boxShadow: DesignSystem.getBrandShadow('heavy'),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Payment successful',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (total != null)
                    Text(
                      'Amount paid: ${total!.toStringAsFixed(0)} SAR',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: DesignSystem.getBrandShadow('light'),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Points collected',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          earned != null ? '+$earned pts' : '$points',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/main', (r) => false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Back to Home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
