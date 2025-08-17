// lib/screens/splash_screen.dart
library splash_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../core/constants/design_system.dart';
import '../core/routes/index.dart';
import '../core/services/customer_session.dart';
part 'functions/splash_screen.functions.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin, SplashScreenFunctions {
  late AnimationController _fadeController;
  late AnimationController _slideController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _bubblesController;

  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Initialize controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // lightweight repeating controller for background bubbles
    _bubblesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Mark animations as initialized
    _animationsInitialized = true;

    // Start animations after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _startAnimations();
      }
    });
  }

  void _startAnimations() async {
    if (!_animationsInitialized) return;

    print('SplashScreen: Starting animations');

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted && _animationsInitialized) {
      print('SplashScreen: Starting fade animation');
      _fadeController.forward();
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted && _animationsInitialized) {
      print('SplashScreen: Starting slide animation');
      _slideController.forward();
    }

    // Navigate depending on session
    // Wait a bit longer so the splash animation is visible
    print('SplashScreen: Waiting 2.2 seconds before navigation');
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final isLoggedIn = CustomerSession.instance.isLoggedIn;
    final isMerchant = CustomerSession.instance.isMerchant;
    print('SplashScreen: isLoggedIn=$isLoggedIn isMerchant=$isMerchant');
    Navigator.pushReplacementNamed(
      context,
      isLoggedIn ? AppRoutes.main : AppRoutes.auth,
      arguments: isLoggedIn ? {'isMerchant': isMerchant} : null,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _bubblesController.dispose();
    // no splash controller to dispose (only bubbles remain)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('SplashScreen: Building splash screen');

    // Safety check - if animations aren't initialized yet, show a simple loading screen
    if (!_animationsInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF6B46C1),
        body: Container(
          decoration: const BoxDecoration(
            gradient: DesignSystem.primaryGradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      // make scaffold transparent so the full-bleed gradient container below
      // exactly matches the native launch background and avoids any white frame
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: DesignSystem.primaryGradient,
            ),
          ),
          // animated bubbles layer
          Positioned.fill(child: _buildBubbles()),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon (no animations)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      // subtle shadow to match app icon presentation
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Image.asset(
                        'assets/icon/iconApp.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // App Title with slide animation (Arabic only)
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'مياه كاندي',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Rubik',
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbles() {
    // Bubble definitions: each entry controls size, horizontal factor, delay and base opacity
    final bubbles = [
      {'size': 48.0, 'x': 0.12, 'delay': 0.0, 'opacity': 0.10},
      {'size': 34.0, 'x': 0.28, 'delay': 0.12, 'opacity': 0.08},
      {'size': 22.0, 'x': 0.5, 'delay': 0.24, 'opacity': 0.06},
      {'size': 40.0, 'x': 0.72, 'delay': 0.36, 'opacity': 0.09},
      {'size': 16.0, 'x': 0.84, 'delay': 0.5, 'opacity': 0.05},
      {'size': 28.0, 'x': 0.62, 'delay': 0.66, 'opacity': 0.07},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return AnimatedBuilder(
          animation: _bubblesController,
          builder: (context, child) {
            final t = _bubblesController.value;
            return Stack(
              children: bubbles.map<Widget>((b) {
                final double size = b['size'] as double;
                final double xFactor = b['x'] as double;
                final double delay = b['delay'] as double;
                final double baseOp = b['opacity'] as double;

                // stagger progress
                var p = (t + delay) % 1.0;
                // vertical position: start slightly below center, float upward and fade
                final startY = h * 0.6;
                final endY = -h * 0.2;
                final y =
                    startY + (endY - startY) * Curves.easeInOut.transform(p);

                // subtle horizontal drift
                final drift = math.sin(p * math.pi * 2) * (w * 0.03);
                final x = (w * xFactor) + drift - (size / 2);

                // opacity curve (fade out as it rises)
                final opacity = (1.0 - p) * baseOp;

                return Positioned(
                  left: x,
                  top: y,
                  width: size,
                  height: size,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // Droplet-based water splash removed; wave painter is used instead.
}
