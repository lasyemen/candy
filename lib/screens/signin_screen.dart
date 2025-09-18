// lib/screens/signin_screen.dart
library signin_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/design_system.dart';
import '../core/constants/translations.dart';
import '../core/services/app_settings.dart';
import 'package:provider/provider.dart';
import '../core/routes/index.dart';
import '../core/services/customer_session.dart';
import '../utils/auth_actions.dart';
import '../utils/phone_utils.dart';
import '../widgets/shared/phone_text_field.dart';
part 'functions/signin_screen.functions.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin, SignInScreenFunctions {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

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
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Implemented in SignInScreenFunctions (see part file)

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppSettings>().currentLanguage;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.onBackground,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            if (isDark) {
              return Text(
                AppTranslations.getText('create_account', language) ==
                        'Create Account'
                    ? 'Sign In'
                    : 'تسجيل الدخول',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }
            return ShaderMask(
              shaderCallback: (bounds) =>
                  DesignSystem.primaryGradient.createShader(bounds),
              child: Text(
                AppTranslations.getText('create_account', language) ==
                        'Create Account'
                    ? 'Sign In'
                    : 'تسجيل الدخول',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          },
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Sign In Icon with Gradient Container
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: DesignSystem.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B46C1).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Subtitle
                      Text(
                        language == 'en'
                            ? 'Sign in to access\nyour account'
                            : 'سجّل الدخول للوصول إلى حسابك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: language == 'en'
                              ? 'Inter'
                              : 'Rubik',
                          fontSize: 20,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                          height: 1.8,
                        ),
                      ),

                      const SizedBox(height: 72),

                      // Phone Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label above the input field
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Text(
                              language == 'en' ? 'Phone number' : 'رقم الهاتف',
                              style: TextStyle(
                                fontFamily: language == 'en'
                                    ? 'Inter'
                                    : 'Rubik',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          // Input field
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: DesignSystem.primaryGradient,
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: PhoneTextField(
                                controller: _phoneController,
                                hintText: language == 'en'
                                    ? '5X XXX XXXX'
                                    : '5X XXX XXXX',
                                // Require Saudi number with country code on sign-in
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال رقم الهاتف';
                                  }
                                  final normalized =
                                      PhoneUtils.normalizeKsaPhone(value);
                                  if (normalized == null)
                                    return 'أدخل رقم هاتف صحيح';
                                  if (!normalized.startsWith('+966'))
                                    return 'يرجى إدخال رقم سعودي مع رمز الدولة (+966)';
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 80),

                      // Sign In Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: DesignSystem.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B46C1).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  language == 'en' ? 'Sign In' : 'تسجيل الدخول',
                                  style: TextStyle(
                                    fontFamily: language == 'en'
                                        ? 'Inter'
                                        : 'Rubik',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Don't have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            language == 'en'
                                ? "Don't have an account? "
                                : 'ليس لديك حساب؟ ',
                            style: TextStyle(
                              fontFamily: language == 'en'
                                  ? 'Inter'
                                  : 'Rubik',
                              fontSize: 12,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.signup);
                            },
                            child: ShaderMask(
                              shaderCallback: (bounds) => DesignSystem
                                  .primaryGradient
                                  .createShader(bounds),
                              child: Text(
                                language == 'en'
                                    ? 'Create Account'
                                    : 'إنشاء حساب',
                                style: TextStyle(
                                  fontFamily: language == 'en'
                                      ? 'Inter'
                                      : 'Rubik',
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
      ),
    );
  }
}
