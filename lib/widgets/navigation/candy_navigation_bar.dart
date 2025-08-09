import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../blocs/app_bloc.dart';
import '../../core/constants/design_system.dart';
import 'dart:ui'; // Added for ImageFilter

class CandyNavigationBar extends StatefulWidget {
  final Function(int) onNavTap;

  const CandyNavigationBar({super.key, required this.onNavTap});

  @override
  State<CandyNavigationBar> createState() => _CandyNavigationBarState();
}

class _CandyNavigationBarState extends State<CandyNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start the animation after the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    // Direct navigation without haptic feedback
    widget.onNavTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppBloc>(
      builder: (context, appBloc, child) {
        return AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - _slideAnimation.value)),
              child: Opacity(
                opacity: _slideAnimation.value,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(
                      bottom: 16,
                      left: 12,
                      right: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      // Dark: solid same color as cards; Light: soft gradient
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : null,
                      gradient: Theme.of(context).brightness == Brightness.dark
                          ? null
                          : const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color.fromARGB(179, 255, 255, 255),
                                Color.fromARGB(255, 255, 255, 255),
                              ],
                              stops: [0.0, 1.0],
                            ),
                      boxShadow: Theme.of(context).brightness == Brightness.dark
                          ? [
                              // Very light, subtle shadows in dark mode
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                              // Subtle top highlight for separation
                              BoxShadow(
                                color: Colors.white.withOpacity(0.02),
                                blurRadius: 3,
                                offset: const Offset(0, -2),
                                spreadRadius: 0,
                              ),
                            ]
                          : [
                              // Light mode shadows (unchanged)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 1,
                                offset: const Offset(0, -1),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 1,
                                offset: const Offset(0, 1),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 1,
                                offset: const Offset(-1, 0),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 1,
                                offset: const Offset(1, 0),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(-3, 0),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(3, 0),
                                spreadRadius: 0,
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildModernNavItem(
                                icon: FontAwesomeIcons.user,
                                label: 'حسابي',
                                isActive: appBloc.currentIndex == 0,
                                onTap: () => _onNavTap(0),
                              ),
                              _buildModernNavItem(
                                icon: FontAwesomeIcons.heart,
                                label: 'الصحة',
                                isActive: appBloc.currentIndex == 1,
                                onTap: () => _onNavTap(1),
                              ),
                              _buildModernNavItem(
                                icon: FontAwesomeIcons.home,
                                label: 'الرئيسية',
                                isActive: appBloc.currentIndex == 2,
                                onTap: () => _onNavTap(2),
                                isHome: true,
                              ),
                              _buildModernNavItem(
                                icon: FontAwesomeIcons.shoppingCart,
                                label: 'السلة',
                                isActive: appBloc.currentIndex == 3,
                                onTap: () => _onNavTap(3),
                                badge: appBloc.cartItemCount > 0
                                    ? appBloc.cartItemCount
                                    : null,
                              ),
                              _buildModernNavItem(
                                icon: FontAwesomeIcons.listAlt,
                                label: 'طلباتي',
                                isActive: appBloc.currentIndex == 4,
                                onTap: () => _onNavTap(4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    int? badge,
    bool isHome = false,
  }) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Enhanced active background for home
                  if (isHome)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: 56,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: DesignSystem.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  // Icon with enhanced micro-interactions
                  isHome
                      ? Container(
                          width: 56,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: DesignSystem.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: AnimatedScale(
                              scale: isActive ? 1.05 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              child: Icon(icon, color: Colors.white, size: 20),
                            ),
                          ),
                        )
                      : isActive
                      ? AnimatedScale(
                          scale: isActive ? 1.05 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: Theme.of(context).brightness == Brightness.dark
                              ? Icon(icon, color: Colors.white, size: 20)
                              : ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return DesignSystem.primaryGradient
                                        .createShader(bounds);
                                  },
                                  blendMode: BlendMode.srcIn,
                                  child: Icon(
                                    icon,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                        )
                      : AnimatedScale(
                          scale: isActive ? 1.05 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            icon,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.grey[600],
                            size: 24,
                          ),
                        ),
                  // Enhanced badge with animation
                  if (badge != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[500],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red[500]!.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            badge.toString(),
                            style: const TextStyle(
                              fontFamily: 'Rubik',
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 10,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : (isActive ? DesignSystem.primary : Colors.grey[600]),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
