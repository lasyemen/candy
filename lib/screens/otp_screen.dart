// lib/screens/otp_screen.dart
library otp_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/design_system.dart';
import '../core/routes/index.dart';
import 'dart:async';
part 'functions/otp_screen.functions.dart';

class OtpScreen extends StatefulWidget {
  final String userName;
  final String userPhone;

  const OtpScreen({super.key, required this.userName, required this.userPhone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with TickerProviderStateMixin, OtpScreenFunctions {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  bool _isLoading = false;
  int _remainingTime = 60; // 60 seconds countdown

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
    _startCountdown();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  // Functions moved to OtpScreenFunctions mixin (see part file)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) =>
              DesignSystem.primaryGradient.createShader(bounds),
          child: const Text(
            'رمز التحقق',
            style: TextStyle(
              fontFamily: 'Rubik',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // OTP Icon with Gradient Container
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: DesignSystem.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6B46C1,
                            ).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.phone_android_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Subtitle
                    Text(
                      'أدخل رمز التحقق المرسل\nإلى رقم هاتفك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 20,
                        color: Colors.black87,
                        height: 1.8,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Phone number display
                    Text(
                      widget.userPhone,
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // OTP Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        4,
                        (index) => Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: DesignSystem.primaryGradient,
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TextFormField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) => _onOtpChanged(value, index),
                              style: const TextStyle(
                                fontFamily: 'Rubik',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Verify Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: DesignSystem.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6B46C1,
                            ).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'تحقق',
                          style: TextStyle(
                            fontFamily: 'Rubik',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Resend OTP Section
                    Column(
                      children: [
                        Text(
                          'لم تستلم الرمز؟',
                          style: TextStyle(
                            fontFamily: 'Rubik',
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _remainingTime > 0
                            ? Text(
                                'إعادة الإرسال خلال $_remainingTime ثانية',
                                style: TextStyle(
                                  fontFamily: 'Rubik',
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              )
                            : GestureDetector(
                                onTap: _resendOtp,
                                child: ShaderMask(
                                  shaderCallback: (bounds) => DesignSystem
                                      .primaryGradient
                                      .createShader(bounds),
                                  child: const Text(
                                    'إعادة إرسال الرمز',
                                    style: TextStyle(
                                      fontFamily: 'Rubik',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
