// lib/screens/merchant_approval_screen.dart
library merchant_approval_screen;

import 'package:flutter/material.dart';
import '../core/constants/design_system.dart';
import '../core/routes/index.dart';
import '../core/services/merchant_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/customer_session.dart';
import '../widgets/merchant/summary_row.dart';
part 'functions/merchant_approval_screen.functions.dart';

class MerchantApprovalScreen extends StatefulWidget {
  final Map<String, dynamic> merchantData;

  const MerchantApprovalScreen({super.key, required this.merchantData});

  @override
  State<MerchantApprovalScreen> createState() => _MerchantApprovalScreenState();
}

class _MerchantApprovalScreenState extends State<MerchantApprovalScreen>
    with TickerProviderStateMixin, MerchantApprovalScreenFunctions {
  bool _isLoading = false;
  bool _agreedToTerms = false;

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
    _animationController.dispose();
    super.dispose();
  }

  void _createAccount() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى الموافقة على الشروط والأحكام'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String merchantId = (widget.merchantData['merchantId'] ?? '')
          .toString();
      if (merchantId.isEmpty) {
        throw Exception('merchantId is missing');
      }
      await MerchantService.instance.acceptTerms(merchantId: merchantId);

      // Ensure customer session exists for owner (so app doesn't treat as guest)
      final String ownerName = (widget.merchantData['ownerName'] ?? '')
          .toString();
      final String phoneDisplay = (widget.merchantData['phone'] ?? '')
          .toString();
      final String phoneNormalized = phoneDisplay.replaceAll(
        RegExp(r'\s+'),
        '',
      );

      // Try login; if not exists, register then login to set session
      final existing = await AuthService.instance.loginCustomer(
        phone: phoneNormalized,
      );
      if (existing == null) {
        await AuthService.instance.registerCustomer(
          name: ownerName.isNotEmpty ? ownerName : 'Merchant',
          phone: phoneNormalized,
          address: widget.merchantData['address']?.toString(),
        );
        await AuthService.instance.loginCustomer(phone: phoneNormalized);
      }
      // Mark session as merchant for future app launches
      await CustomerSession.instance.setMerchant(true);

      if (!mounted) return;
      setState(() => _isLoading = false);
      // Navigate to main with merchant flag to hide Health tab
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.main,
        arguments: {'isMerchant': true},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر إكمال التسجيل: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            if (isDark) {
              return const Text(
                'تسجيل تاجر جديد',
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
              child: const Text(
                'تسجيل تاجر جديد',
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Progress Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: DesignSystem.primaryGradient,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: DesignSystem.primaryGradient,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: DesignSystem.primaryGradient,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الشروط والأحكام',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Approval Icon with Gradient Container
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
                        Icons.handshake_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Subtitle
                    Text(
                      'مراجعة البيانات والموافقة\nعلى الشروط والأحكام',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 20,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                        height: 1.8,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Data Summary Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF121212)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ملخص بياناتك',
                            style: TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SummaryRow(
                            label: 'اسم المتجر',
                            value: widget.merchantData['storeName'] ?? '',
                          ),
                          SummaryRow(
                            label: 'اسم المالك',
                            value: widget.merchantData['ownerName'] ?? '',
                          ),
                          SummaryRow(
                            label: 'رقم الجوال',
                            value: widget.merchantData['phone'] ?? '',
                          ),
                          SummaryRow(
                            label: 'العنوان',
                            value: widget.merchantData['address'] ?? '',
                          ),
                          const SummaryRow(
                            label: 'المستندات',
                            value: 'تم رفع جميع المستندات',
                            showCheckmark: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Agreement Checkbox
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF121212)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _agreedToTerms = !_agreedToTerms;
                              });
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _agreedToTerms
                                    ? const Color(0xFF6B46C1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _agreedToTerms
                                      ? const Color(0xFF6B46C1)
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                              child: _agreedToTerms
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'أوافق على شروط الاستخدام وسياسة الخصوصية لشركاء كاندي',
                              style: TextStyle(
                                fontFamily: 'Rubik',
                                fontSize: 14,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Create Account Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: _agreedToTerms
                            ? DesignSystem.primaryGradient
                            : null,
                        color: _agreedToTerms ? null : Colors.grey[300],
                        boxShadow: _agreedToTerms
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6B46C1,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton(
                        onPressed: _agreedToTerms && !_isLoading
                            ? _createAccount
                            : null,
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'إنشاء الحساب',
                                    style: TextStyle(
                                      fontFamily: 'Rubik',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
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

  // Summary rows extracted
}
