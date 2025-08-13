// lib/screens/card_payment_screen.dart
library card_payment_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/design_system.dart';
import '../core/constants/app_colors.dart';
import '../core/services/rewards_service.dart';
import '../core/routes/app_routes.dart';

part 'functions/card_payment_screen.functions.dart';

class CardPaymentScreen extends StatefulWidget {
  final double? orderTotal;

  const CardPaymentScreen({super.key, this.orderTotal});

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen>
    with CardPaymentScreenFunctions, TickerProviderStateMixin {
  late final TextEditingController cardNumberController;
  late final TextEditingController nameController;
  late final TextEditingController expiryController;
  late final TextEditingController cvvController;

  bool saveCard = true;
  bool isPaying = false;

  @override
  void initState() {
    super.initState();
    cardNumberController = TextEditingController();
    nameController = TextEditingController();
    expiryController = TextEditingController();
    cvvController = TextEditingController();
  }

  @override
  void dispose() {
    cardNumberController.dispose();
    nameController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double amount = (widget.orderTotal ?? 0) > 0
        ? widget.orderTotal!
        : 120;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Card Payment'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewPadding.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderTotal(context, amount),
              const SizedBox(height: 16),
              _buildCardPreview(context),
              const SizedBox(height: 16),
              _buildCardForm(context),
              const SizedBox(height: 20),
              _buildSaveCardSwitch(context),
              const SizedBox(height: 24),
              _buildPayButton(context, amount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTotal(BuildContext context, double amount) {
    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }

  Widget _buildCardPreview(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: DesignSystem.getBrandGradient('primary'),
        borderRadius: BorderRadius.circular(20),
        boxShadow: DesignSystem.getBrandShadow('heavy'),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'CANDY PAY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.credit_card, color: Colors.white, size: 28),
            ],
          ),
          Text(
            formatCardNumber(cardNumberController.text),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  (nameController.text.isEmpty
                          ? 'CARDHOLDER'
                          : nameController.text)
                      .toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                expiryController.text.isEmpty ? 'MM/YY' : expiryController.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).dividerColor.withOpacity(0.4),
      ),
    );

    return Column(
      children: [
        TextField(
          controller: cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CardNumberInputFormatter(),
          ],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            border: inputBorder,
            enabledBorder: inputBorder,
            focusedBorder: inputBorder,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Name on Card',
            hintText: 'Full Name',
            border: inputBorder,
            enabledBorder: inputBorder,
            focusedBorder: inputBorder,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: expiryController,
                keyboardType: TextInputType.number,
                inputFormatters: [ExpiryDateInputFormatter()],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Expiry',
                  hintText: 'MM/YY',
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: cvvController,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '***',
                  border: inputBorder,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveCardSwitch(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: DesignSystem.getBrandShadow('light'),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline),
          const SizedBox(width: 10),
          const Expanded(child: Text('Save card for faster checkout')),
          Switch(
            value: saveCard,
            onChanged: (v) => setState(() => saveCard = v),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(BuildContext context, double amount) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isPaying
            ? null
            : () async {
                setState(() => isPaying = true);
                await Future.delayed(const Duration(milliseconds: 200));

                // Award points for this order with configured rate
                final rate = await RewardsService.instance
                    .getPointsRatePerSar();
                int earned = (amount * rate).floor();
                if (amount >= 500) {
                  earned += 300; // big order bonus
                } else if (amount >= 300) {
                  earned += 150;
                } else if (amount >= 150) {
                  earned += 50;
                }
                try {
                  await RewardsService.instance.addPoints(
                    earned,
                    reason: 'purchase',
                  );
                } catch (_) {}

                if (!mounted) return;
                Navigator.of(context).pushReplacementNamed(
                  AppRoutes.thankYou,
                  arguments: {'total': amount, 'earned': earned},
                );
                if (mounted) setState(() => isPaying = false);
              },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          isPaying ? 'Processing...' : 'Pay ${amount.toStringAsFixed(0)} SAR',
        ),
      ),
    );
  }

  // _onPay legacy handler removed in favor of direct routing to Thank You
}
