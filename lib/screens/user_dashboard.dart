// lib/screens/user_dashboard.dart
library user_dashboard;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/routes/index.dart';
import '../core/constants/translations.dart';
import '../core/services/app_settings.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/settings_list.dart';
import '../widgets/shared/sliver_title_app_bar.dart';
import '../utils/profile_menu.dart';
import '../core/services/customer_session.dart';
part 'functions/user_dashboard.functions.dart';

// moved to utils/profile_menu.dart: getProfileMenuItems

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard>
    with TickerProviderStateMixin, UserDashboardFunctions {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _statsController;

  // Removed legacy _user data

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _statsController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  Widget _buildSliverAppBar(String language) {
    return SliverTitleAppBar(
      title: AppTranslations.getText('profile_title', language),
    );
  }

  // Legacy header replaced by ProfileHeader widget

  // Legacy dialogs removed (language/theme handled elsewhere)

  // Legacy dialogs removed

  // Stats section removed

  // Legacy menu section removed (extracted to widget)

  // Logout moved into SettingsList items

  // Settings items removed

  // Edit profile bottom sheet removed (placeholder)

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppTranslations.getText(
            'logout',
            context.watch<AppSettings>().currentLanguage,
          ),
        ),
        content: Text(
          AppTranslations.getText(
            'confirm',
            context.watch<AppSettings>().currentLanguage,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.getText(
                'cancel',
                context.watch<AppSettings>().currentLanguage,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Clear customer session and navigate to main as guest
              CustomerSession.instance.clearCurrentCustomer();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.main,
                  (route) => false,
                );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Placeholder tap handlers removed

  // End legacy placeholders

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final language = appSettings.currentLanguage;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _animation,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(language),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    ProfileHeader(language: language),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final items = getProfileMenuItems(language);
                        if (!CustomerSession.instance.isLoggedIn) {
                          items.insert(0, {
                            'icon': Icons.person_add_alt,
                            'title': AppTranslations.getText(
                              'create_account',
                              language,
                            ),
                            'color': Theme.of(context).colorScheme.primary,
                            'onTap': () =>
                                Navigator.pushNamed(context, AppRoutes.signup),
                          });
                        }
                        items.add({
                          'icon': Icons.logout,
                          'title': AppTranslations.getText('logout', language),
                          'color': Colors.red,
                          'onTap': _showLogoutDialog,
                        });
                        return SettingsList(language: language, items: items);
                      },
                    ),
                    SizedBox(
                      height:
                          kBottomNavigationBarHeight +
                          MediaQuery.of(context).padding.bottom +
                          24,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
