import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../blocs/app_bloc.dart';
import 'candy_navigation_bar.dart';
import '../../core/constants/design_system.dart';
import '../../core/services/app_settings.dart';

class NavigationWrapper extends StatelessWidget {
  final Widget child;
  final bool showBackButton;

  const NavigationWrapper({
    super.key,
    required this.child,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettings, AppBloc>(
      builder: (context, appSettings, appBloc, _) {
        final isDarkMode = appSettings.isDarkMode;

        return Scaffold(
          backgroundColor: isDarkMode
              ? DesignSystem.darkBackground
              : DesignSystem.background,
          body: Stack(
            children: [
              // Main content
              child,

              // Navigation bar at bottom
              CandyNavigationBar(
                onNavTap: (index) {
                  final appBloc = context.read<AppBloc>();
                  
                  // Always go back to main screen and navigate to the selected tab
                  if (appBloc.currentIndex != index) {
                    // Update the selected index first
                    appBloc.add(SetCurrentIndexEvent(index));
                    
                    // Pop all screens until we get back to main screen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } else {
                    // If same tab is pressed, just go back to main screen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
