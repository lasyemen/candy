// lib/screens/splash_screen.dart
library splash_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    print('SplashScreen: Waiting 1.2 seconds before navigation');
    await Future.delayed(const Duration(milliseconds: 1200));
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
      backgroundColor: const Color(0xFF6B46C1),
      body: Container(
        decoration: const BoxDecoration(gradient: DesignSystem.primaryGradient),
        child: Center(
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
      ),
    );
  }
}
