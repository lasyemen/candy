// lib/screens/test_checkout_screen.dart
library test_checkout_screen;

import 'dart:math';

import 'package:flutter/material.dart';
import '../core/services/rewards_service.dart';
import '../core/routes/app_routes.dart';
import '../core/constants/app_colors.dart';

part 'functions/test_checkout_screen.functions.dart';

class TestCheckoutScreen extends StatefulWidget {
  const TestCheckoutScreen({super.key});

  @override
  State<TestCheckoutScreen> createState() => _TestCheckoutScreenState();
}

class _TestCheckoutScreenState extends State<TestCheckoutScreen>
    with TestCheckoutScreenFunctions {
  final TextEditingController _amountController = TextEditingController(
    text: '100',
  );
  String? _selectedVoucherId;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Checkout'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewPadding.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAmountCard(context),
            const SizedBox(height: 16),
            _buildVoucherCard(context),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPaying
                    ? null
                    : () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.cardPayment,
                          arguments: {
                            'total':
                                double.tryParse(_amountController.text) ??
                                100.0,
                          },
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_isPaying ? 'Processing...' : 'Go to Card Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Amount (SAR)',
              style: TextStyle(fontSize: 16, fontFamily: 'Rubik'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: false,
              ),
              decoration: const InputDecoration(
                hintText: 'e.g., 100',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apply Voucher (optional)',
              style: TextStyle(fontSize: 16, fontFamily: 'Rubik'),
            ),
            const SizedBox(height: 8),
            if (vouchers.isEmpty)
              const Text(
                'No active vouchers',
                style: TextStyle(fontFamily: 'Rubik'),
              )
            else
              ...vouchers.map((v) {
                final id = v['id'] as String?;
                final amount = (v['amount'] as num?)?.toDouble() ?? 0;
                return RadioListTile<String>(
                  value: id ?? '',
                  groupValue: _selectedVoucherId,
                  onChanged: (val) {
                    setState(() => _selectedVoucherId = val);
                  },
                  title: Text(
                    'Voucher ${id?.substring(0, 6) ?? ''} - ${amount.toStringAsFixed(0)} SAR',
                    style: const TextStyle(fontFamily: 'Rubik'),
                  ),
                  subtitle: Text(
                    'Expires: ${v['expires_at']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // Legacy helper (unused)
  Future<void> _simulatePay() async {
    final raw = _amountController.text.trim();
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _isPaying = true);

    try {
      double discount = 0.0;
      if (_selectedVoucherId != null && _selectedVoucherId!.isNotEmpty) {
        discount = await RewardsService.instance.redeemVoucher(
          _selectedVoucherId!,
        );
      }

      final net = max(0.0, amount - discount);

      // Award points based on configured rate per SAR
      final rate = await RewardsService.instance.getPointsRatePerSar();
      final earned = (net * rate).floor();
      await RewardsService.instance.addPoints(earned, reason: 'test_checkout');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Paid ${net.toStringAsFixed(0)} SAR, +$earned pts' +
                (discount > 0
                    ? ' (voucher -${discount.toStringAsFixed(0)})'
                    : ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }
}
