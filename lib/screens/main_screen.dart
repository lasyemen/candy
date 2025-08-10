// lib/screens/main_screen.dart
library main_screen;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../blocs/app_bloc.dart';
import '../widgets/index.dart';
import 'index.dart';
import '../core/services/app_settings.dart';
part 'functions/main_screen.functions.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 2});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin, MainScreenFunctions {
  late PageController _pageController;
  final PageStorageBucket _bucket = PageStorageBucket();

  late final List<Widget> _screens;
  late final List<CandyNavItem> _navItems;
  bool _configured = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    // Ensure bloc index matches the initial page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppBloc>().add(SetCurrentIndexEvent(widget.initialIndex));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_configured) return;

    // Build screens and nav items. If the app is in a merchant session, hide Health.
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final bool isMerchant = args is Map && (args['isMerchant'] == true);

    _screens = [
      const UserDashboard(),
      if (!isMerchant) const HealthTracker(),
      const HomeScreen(),
      const CartScreen(),
      const MyOrdersScreen(),
    ];

    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    if (isMerchant) {
      final homeItem = CandyNavItem(
        icon: FontAwesomeIcons.home,
        label: 'الرئيسية',
        pageIndex: 1,
        isHome: true,
      );
      final others = [
        CandyNavItem(icon: FontAwesomeIcons.user, label: 'حسابي', pageIndex: 0),
        CandyNavItem(
          icon: FontAwesomeIcons.shoppingCart,
          label: 'السلة',
          pageIndex: 2,
        ),
        CandyNavItem(
          icon: FontAwesomeIcons.listAlt,
          label: 'طلباتي',
          pageIndex: 3,
        ),
      ];
      // Place home at the visual right edge depending on text direction
      _navItems = isRtl ? [homeItem, ...others] : [...others, homeItem];
    } else {
      _navItems = [
        CandyNavItem(icon: FontAwesomeIcons.user, label: 'حسابي', pageIndex: 0),
        CandyNavItem(
          icon: FontAwesomeIcons.heart,
          label: 'الصحة',
          pageIndex: 1,
        ),
        CandyNavItem(
          icon: FontAwesomeIcons.home,
          label: 'الرئيسية',
          pageIndex: 2,
          isHome: true,
        ),
        CandyNavItem(
          icon: FontAwesomeIcons.shoppingCart,
          label: 'السلة',
          pageIndex: 3,
        ),
        CandyNavItem(
          icon: FontAwesomeIcons.listAlt,
          label: 'طلباتي',
          pageIndex: 4,
        ),
      ];
    }

    _configured = true;
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
        // final isDarkMode = appSettings.isDarkMode; // reserved for theming

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: PageStorage(
            bucket: _bucket,
            child: Stack(
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
                CandyNavigationBar(onNavTap: _onNavTap, items: _navItems),
              ],
            ),
          ),
        );
      },
    );
  }
}
