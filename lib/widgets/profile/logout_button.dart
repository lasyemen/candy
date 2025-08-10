import 'package:flutter/material.dart';
import '../../core/constants/design_system.dart';
import '../../core/constants/translations.dart';
import '../../core/routes/index.dart';
import '../../core/services/customer_session.dart';

class LogoutButton extends StatelessWidget {
  final String language;
  const LogoutButton({super.key, required this.language});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.getText('logout', language)),
        content: Text(AppTranslations.getText('logout_confirm', language)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.getText('cancel', language)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              CustomerSession.instance.clearCurrentCustomer();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.main,
                  (route) => false,
                );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppTranslations.getText('logout_success', language),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: DesignSystem.getBrandGlassDecoration(
        backgroundColor: Colors.red.withOpacity(0.1),
        borderColor: Colors.red.withOpacity(0.2),
        borderRadius: 16,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showLogoutDialog(context),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  AppTranslations.getText('logout', language),
                  style: DesignSystem.bodyLarge.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
