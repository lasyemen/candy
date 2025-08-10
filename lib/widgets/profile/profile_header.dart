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
    final String displayPhone =
        CustomerSession.instance.currentCustomerPhone ?? '—';

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.transparent,
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
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
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Rubik',
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone, size: 14, color: Theme.of(context).hintColor),
                const SizedBox(width: 6),
                Text(
                  isLoggedIn
                      ? displayPhone
                      : AppTranslations.getText('guest', language),
                  style: DesignSystem.labelLarge.copyWith(
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
