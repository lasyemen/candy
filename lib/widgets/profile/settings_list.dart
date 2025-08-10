import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/design_system.dart';
import '../../core/constants/translations.dart';
import '../../core/services/app_settings.dart';

class SettingsList extends StatelessWidget {
  final String language;
  final List<Map<String, dynamic>> items;
  const SettingsList({super.key, required this.language, required this.items});

  @override
  Widget build(BuildContext context) {
    final Color titleColor = Theme.of(context).colorScheme.onBackground;
    final Color subtitleColor = Theme.of(context).hintColor;
    final Color dividerColor = Theme.of(context).dividerColor.withOpacity(0.12);

    final appSettings = context.watch<AppSettings>();
    final isDark = appSettings.isDarkMode;

    return Column(
      children: [
        // Theme toggle row
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          leading: ShaderMask(
            shaderCallback: (bounds) =>
                DesignSystem.primaryGradient.createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: Colors.white,
              size: 22,
            ),
          ),
          title: Text(
            isDark
                ? AppTranslations.getText('dark_mode', language)
                : AppTranslations.getText('light_mode', language),
            style: DesignSystem.bodyLarge.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Switch(
            value: isDark,
            activeColor: Colors.white,
            activeTrackColor: DesignSystem.primary.withOpacity(0.5),
            inactiveTrackColor: Theme.of(context).dividerColor.withOpacity(0.3),
            onChanged: (v) => context.read<AppSettings>().setTheme(
              v ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 50),
          child: Divider(height: 1, color: dividerColor),
        ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                leading: Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 22,
                ),
                title: Text(
                  item['title'] as String,
                  style: DesignSystem.bodyLarge.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  item['subtitle'] as String,
                  style: DesignSystem.bodySmall.copyWith(
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                trailing: null,
                onTap: () {},
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 50),
                  child: Divider(height: 1, color: dividerColor),
                ),
            ],
          );
        }).toList(),
      ],
    );
  }
}
