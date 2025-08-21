// lib/screens/payment_method_selection_screen.dart
library payment_method_selection_screen;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

    final bool isAr = Localizations.localeOf(context).languageCode == 'ar';
    final String titleText = isAr
        ? 'اختر طريقة الدفع'
        : 'Choose Payment Method';
    final String totalText = isAr ? 'المجموع' : 'Total';
    final String continueText = isAr ? 'متابعة' : 'Continue';
    // Arabic localized names/subtitles for payment methods
    final Map<String, String> methodNamesAr = {
      'mada': 'مدى',
      'visa': 'فيزا',
      'mastercard': 'ماستركارد',
      'apple_pay': 'آبل باي',
      'cod': 'الدفع عند الاستلام',
    };

    final Map<String, String> methodSubtitlesAr = {
      'mada': 'شبكة مدى المحلية',
      'visa': 'بطاقة ائتمان/خصم',
      'mastercard': 'بطاقة ماستركارد',
      'apple_pay': 'الدفع عبر آبل',
      'cod': 'ادفع نقداً عند الاستلام',
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(titleText),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    totalText,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Price badge with gradient and riyal icon on the left
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: DesignSystem.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/icon/rsak.svg',
                                width: 18,
                                height: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        // Flat list style (not card) — keep selectable border only
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.transparent, width: 0),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white10
                                : Colors.transparent,
                            child: Builder(
                              builder: (context) {
                                try {
                                  if (m.id == 'visa') {
                                    return Image.asset(
                                      'assets/icon/visa-brandmark-blue-1960x622.webp',
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.contain,
                                    );
                                  }

                                  if (m.id == 'apple_pay') {
                                    return SvgPicture.asset(
                                      'assets/icon/Apple_Pay_Mark_RGB_041619.svg',
                                      width: 28,
                                      height: 28,
                                    );
                                  }

                                  if (m.id == 'mada') {
                                    return SvgPicture.asset(
                                      'assets/icon/شعار مدى – SVG.svg',
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.contain,
                                    );
                                  }

                                  if (m.id == 'mastercard') {
                                    return SvgPicture.asset(
                                      'assets/icon/mc_symbol.svg',
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.contain,
                                    );
                                  }

                                  if (m.id == 'cod') {
                                    return Icon(
                                      Icons.money,
                                      color: AppColors.primary,
                                    );
                                  }

                                  // Default fallback: try generic asset path in assets/icon by id
                                  return Image.asset(
                                    'assets/icon/${m.id}.png',
                                    width: 28,
                                    height: 28,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          m.icon,
                                          color: AppColors.primary,
                                        ),
                                  );
                                } catch (_) {
                                  return Icon(m.icon, color: AppColors.primary);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr && methodNamesAr.containsKey(m.id)
                                      ? methodNamesAr[m.id]!
                                      : m.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                if (m.subtitle != null)
                                  Text(
                                    isAr && methodSubtitlesAr.containsKey(m.id)
                                        ? methodSubtitlesAr[m.id]!
                                        : m.subtitle!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                          // Selection indicator: when active show a gradient filled dot; otherwise standard off-radio icon
                          active
                              ? Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    gradient: DesignSystem.primaryGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: DesignSystem.primary.withOpacity(
                                          0.22,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                )
                              : Icon(
                                  Icons.radio_button_off,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Builder(
                builder: (context) {
                  final bool isActive = selectedMethodId != null;
                  if (isActive) {
                    return Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: DesignSystem.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: DesignSystem.primary.withOpacity(0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final args = {
                            'total': amount,
                            'deliveryData': widget.deliveryData,
                            'method': selectedMethodId,
                          };
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.cardPayment, arguments: args);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          continueText,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        continueText,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
