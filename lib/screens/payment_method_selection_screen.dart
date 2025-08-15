// lib/screens/payment_method_selection_screen.dart
library payment_method_selection_screen;

import 'package:flutter/material.dart';
import '../core/constants/design_system.dart';
import '../core/constants/app_colors.dart';
import '../core/routes/app_routes.dart';

part 'functions/payment_method_selection_screen.functions.dart';

class PaymentMethodSelectionScreen extends StatefulWidget {
  final double? orderTotal;
  final Map<String, dynamic>? deliveryData;

  const PaymentMethodSelectionScreen({
    super.key,
    this.orderTotal,
    this.deliveryData,
  });

  @override
  State<PaymentMethodSelectionScreen> createState() =>
      _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState
    extends State<PaymentMethodSelectionScreen>
    with PaymentMethodSelectionScreenFunctions {
  String? selectedMethodId;

  @override
  Widget build(BuildContext context) {
    final double amount = (widget.orderTotal ?? 0) > 0
        ? widget.orderTotal!
        : 120;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Choose Payment Method'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewPadding.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: DesignSystem.getBrandShadow('light'),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: Theme.of(context).textTheme.titleMedium),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: DesignSystem.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${amount.toStringAsFixed(0)} SAR',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: methods.map((m) {
                  final active = selectedMethodId == m.id;
                  return InkWell(
                    onTap: () => setState(() => selectedMethodId = m.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: DesignSystem.getBrandShadow('light'),
                        border: Border.all(
                          color: active
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white10
                                : Colors.grey[100],
                            child: Icon(m.icon, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                if (m.subtitle != null)
                                  Text(
                                    m.subtitle!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            active
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: active
                                ? AppColors.primary
                                : Theme.of(context).iconTheme.color,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedMethodId == null
                    ? null
                    : () {
                        final args = {
                          'total': amount,
                          'deliveryData': widget.deliveryData,
                          'method': selectedMethodId,
                        };
                        // For all methods, proceed to card screen placeholder
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.cardPayment, arguments: args);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

