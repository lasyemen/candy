import 'package:flutter/material.dart';

import '../core/constants/translations.dart';

/// Builds the static profile menu items based on current language
List<Map<String, dynamic>> getProfileMenuItems(String language) {
  return [
    {
      'icon': Icons.person_outline,
      'title': AppTranslations.getText('edit_profile', language),
      'subtitle': AppTranslations.getText('edit_profile_subtitle', language),
      'color': Colors.blue,
    },
    {
      'icon': Icons.location_on_outlined,
      'title': AppTranslations.getText('saved_addresses', language),
      'subtitle': AppTranslations.getText('saved_addresses_subtitle', language),
      'color': Colors.green,
    },
    {
      'icon': Icons.payment_outlined,
      'title': AppTranslations.getText('payment_methods', language),
      'subtitle': AppTranslations.getText('payment_methods_subtitle', language),
      'color': Colors.orange,
    },
    {
      'icon': Icons.notifications_outlined,
      'title': AppTranslations.getText('notifications', language),
      'subtitle': AppTranslations.getText('notifications_subtitle', language),
      'color': Colors.purple,
    },
    {
      'icon': Icons.help_outline,
      'title': AppTranslations.getText('help_support', language),
      'subtitle': AppTranslations.getText('help_support_subtitle', language),
      'color': Colors.teal,
    },
    {
      'icon': Icons.settings_outlined,
      'title': AppTranslations.getText('settings', language),
      'subtitle': AppTranslations.getText('settings_subtitle', language),
      'color': Colors.grey,
    },
  ];
}


