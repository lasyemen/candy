import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../blocs/app_bloc.dart';
import '../widgets/index.dart';
import 'index.dart';
import '../core/services/app_settings.dart';
import '../core/constants/design_system.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late PageController _pageController;

  final List<Widget> _screens = [
    const UserDashboard(), // My Account (index 0)
    const HealthTracker(), // Health (index 1)
    const HomeScreen(), // Home (index 2) - CENTER - Main screen with products
    const CartScreen(), // Cart (index 3)
    const MyOrdersScreen(), // My Orders (index 4)
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 2); // Start at home
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    final appBloc = context.read<AppBloc>();

    // Only navigate if it's a different page
    if (appBloc.currentIndex != index) {
      // Update bloc state first
      appBloc.add(SetCurrentIndexEvent(index));

      // Smart navigation: if distance is more than 2 pages, jump directly
      // Otherwise animate smoothly
      final currentIndex = appBloc.currentIndex;
      final distance = (index - currentIndex).abs();

      if (distance > 2) {
        // For far distances, jump directly to avoid passing through all pages
        _pageController.jumpToPage(index);
      } else {
        // For close distances, animate smoothly
        _pageController.animateToPage(
          index,
          duration: Duration(milliseconds: 150 + (distance * 50)),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettings, AppBloc>(
      builder: (context, appSettings, appBloc, child) {
        final isDarkMode = appSettings.isDarkMode;

        return Scaffold(
          backgroundColor: isDarkMode
              ? DesignSystem.darkBackground
              : DesignSystem.background,
          body: Stack(
            children: [
              // Page view with simplified logic
              PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(), // Better swiping feel
                onPageChanged: (index) {
                  // Only update bloc if different from current
                  if (appBloc.currentIndex != index) {
                    appBloc.add(SetCurrentIndexEvent(index));

                    // Add subtle haptic feedback
                    HapticFeedback.selectionClick();
                  }
                },
                children: _screens,
              ),
              CandyNavigationBar(onNavTap: _onNavTap),
            ],
          ),
        );
      },
    );
  }
}
