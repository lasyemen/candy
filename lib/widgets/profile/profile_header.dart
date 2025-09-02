import 'package:flutter/material.dart';
import '../../core/constants/design_system.dart';
import '../../core/constants/translations.dart';
import '../../core/services/customer_session.dart';

class ProfileHeader extends StatelessWidget {
  final String language;
  const ProfileHeader({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = CustomerSession.instance.isLoggedIn;
    final String displayName = CustomerSession.instance.customerName;
    final String rawPhone =
        CustomerSession.instance.currentCustomerPhone ?? '—';
    String displayPhone = rawPhone;
    // Always display with country code (+966) when it's a Saudi number
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+966')) {
      // e.g. +9665XXXXXXXX -> +966 5X XXX XXXX
      final tail = digits.substring(4); // after +966
      final national = tail.replaceFirst(RegExp(r'^0+'), '');
      if (national.length >= 9) {
        final op = national.substring(0, 2); // operator (e.g. 50, 53, ...)
        final mid = national.substring(2, 5);
        final last = national.substring(5, 9);
        displayPhone = '+966 $op $mid $last';
      } else {
        displayPhone = '+966 $national';
      }
    } else if (digits.startsWith('05')) {
      // Local format 05XXXXXXXX -> convert to +966 5X XXX XXXX
      final national = digits.substring(1); // drop leading 0
      if (national.length >= 9) {
        final op = national.substring(0, 2);
        final mid = national.substring(2, 5);
        final last = national.substring(5, 9);
        displayPhone = '+966 $op $mid $last';
      } else {
        displayPhone = '+966 $national';
      }
    } else {
      displayPhone = rawPhone;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 1, 1, 20),
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar first: in RTL it will appear on the right side
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: DesignSystem.getBrandGradient('primary'),
              boxShadow: DesignSystem.getBrandShadow('medium'),
            ),
            child: Center(
              child: Text(
                (displayName.isNotEmpty
                    ? displayName.trim().substring(0, 1).toUpperCase()
                    : '👤'),
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name and phone next to avatar
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        isLoggedIn
                            ? displayPhone
                            : AppTranslations.getText('guest', language),
                        style: DesignSystem.labelLarge.copyWith(
                          fontSize: 13,
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
