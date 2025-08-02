import 'package:flutter/material.dart';
import '../core/constants/design_system.dart';
import '../core/routes/index.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
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

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Navigate to OTP screen
      Navigator.pushNamed(
        context,
        AppRoutes.otp,
        arguments: {
          'userName': 'User', // Generic name for signin
          'userPhone': _phoneController.text,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            'تسجيل الدخول',
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
                        'سجل دخولك للوصول\nإلى حسابك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 20,
                          color: Colors.black87,
                          height: 1.8,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Phone Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label above the input field
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Text(
                              'رقم الهاتف',
                              style: TextStyle(
                                fontFamily: 'Rubik',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال رقم الهاتف';
                                  }
                                  return null;
                                },
                                style: const TextStyle(
                                  fontFamily: 'Rubik',
                                  fontSize: 12,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'أدخل رقم هاتفك',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.phone_outlined,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

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
                              : const Text(
                                  'تسجيل الدخول',
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

                      // Don't have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ليس لديك حساب؟ ',
                            style: TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 12,
                              color: Colors.grey[600],
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
                              child: const Text(
                                'إنشاء حساب',
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
      ),
    );
  }
}
