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
    final appSettings = context.watch<AppSettings>();
    final isDark = appSettings.isDarkMode;
    final Color titleColor = isDark ? Colors.white : Colors.black;
    final Color subtitleColor = Theme.of(context).hintColor;
    final Color dividerColor = Theme.of(context).dividerColor.withOpacity(0.12);

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
            style: DesignSystem.bodyMedium.copyWith(
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
        // Language selection row
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          leading: ShaderMask(
            shaderCallback: (bounds) =>
                DesignSystem.primaryGradient.createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: const Icon(Icons.language, color: Colors.white, size: 22),
          ),
          title: Text(
            AppTranslations.getText('language', language),
            style: DesignSystem.bodyMedium.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w600,
              fontSize: 16
            ),
          ),
          subtitle: Text(
            AppTranslations.getText('language_subtitle', language),
            style: DesignSystem.bodySmall.copyWith(
              color: subtitleColor,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
          onTap: () async {
            final codes = AppTranslations.getSupportedLanguages();
            await showModalBottomSheet<void>(
              context: context,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) {
                final current = appSettings.currentLanguage;
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...codes.map((code) {
                        final isSelected = code == current;
                        return ListTile(
                          leading: Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected
                                ? DesignSystem.primary
                                : subtitleColor,
                            size: 22,
                          ),
                          title: Text(
                            AppTranslations.getLanguageName(code),
                            style: DesignSystem.bodyMedium.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            context.read<AppSettings>().setLanguage(code);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            );
          },
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
                  style: DesignSystem.bodyMedium.copyWith(
                    color: (item['titleColor'] as Color?) ?? titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: item['subtitle'] != null
                    ? Text(
                        item['subtitle'] as String,
                        style: DesignSystem.bodySmall.copyWith(
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      )
                    : null,
                trailing: null,
                onTap: item['onTap'] as VoidCallback?,
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
