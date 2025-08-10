// lib/screens/merchant_signup_screen.dart
library merchant_signup_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/design_system.dart';
import '../core/services/merchant_service.dart';
import 'merchant_documents_screen.dart'; // Added import for MerchantDocumentsScreen
part 'functions/merchant_signup_screen.functions.dart';

class MerchantSignupScreen extends StatefulWidget {
  const MerchantSignupScreen({super.key});

  @override
  State<MerchantSignupScreen> createState() => _MerchantSignupScreenState();
}

class _MerchantSignupScreenState extends State<MerchantSignupScreen>
    with TickerProviderStateMixin, MerchantSignupScreenFunctions {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

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
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final String rawPhone = _phoneController.text.trim();
      final String digitsOnly = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
      final String phoneDisplay = '+966 ${digitsOnly}';
      final String phoneE164 = '+966$digitsOnly';

      final String merchantId = await MerchantService.instance.createMerchant(
        storeName: _storeNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        phoneE164: phoneE164,
        address: _addressController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              MerchantDocumentsScreen(
                merchantData: {
                  'merchantId': merchantId,
                  'storeName': _storeNameController.text.trim(),
                  'ownerName': _ownerNameController.text.trim(),
                  'phone': phoneDisplay,
                  'address': _addressController.text.trim(),
                },
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إنشاء التاجر: $e'),
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
                child: Form(
                  key: _formKey,
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
                              color: Colors.grey[300],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 60,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'البيانات الأساسية',
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Merchant Icon with Gradient Container
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
                          Icons.store_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Subtitle
                      Text(
                        'معلومات المتجر الأساسية\nأدخل بيانات متجرك الأساسية',
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

                      // Store Name Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label above the input field
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Text(
                              'اسم المتجر',
                              style: TextStyle(
                                fontFamily: 'Rubik',
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
                              child: TextFormField(
                                controller: _storeNameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال اسم المتجر';
                                  }
                                  return null;
                                },
                                style: const TextStyle(
                                  fontFamily: 'Rubik',
                                  fontSize: 12,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'أدخل اسم متجرك',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white54
                                        : Colors.grey[500],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.store_outlined,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white60
                                        : Colors.grey[600],
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

                      const SizedBox(height: 24),

                      // Owner Name Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label above the input field
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Text(
                              'اسم صاحب المتجر',
                              style: TextStyle(
                                fontFamily: 'Rubik',
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
                              child: TextFormField(
                                controller: _ownerNameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال اسم صاحب المتجر';
                                  }
                                  return null;
                                },
                                style: const TextStyle(
                                  fontFamily: 'Rubik',
                                  fontSize: 12,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'أدخل اسم صاحب المتجر',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white54
                                        : Colors.grey[500],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white60
                                        : Colors.grey[600],
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

                      const SizedBox(height: 24),

                      // Phone Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label above the input field
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Text(
                              'رقم الجوال',
                              style: TextStyle(
                                fontFamily: 'Rubik',
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
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  textAlign: TextAlign.left,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9+ ]'),
                                    ),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'يرجى إدخال رقم الجوال';
                                    }
                                    return null;
                                  },
                                  style: const TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 12,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '5X XXX XXXX',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Rubik',
                                      fontSize: 12,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white54
                                          : Colors.grey[500],
                                    ),
                                    prefixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 16,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 20,
                                                height: 15,
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                                child: const Icon(
                                                  Icons.flag,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '+966',
                                                style: TextStyle(
                                                  fontFamily: 'Rubik',
                                                  fontSize: 12,
                                                  color:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white60
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.phone_outlined,
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white60
                                              : Colors.grey[600],
                                          size: 20,
                                        ),
                                      ],
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
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Address Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label above the input field
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Text(
                              'عنوان المتجر',
                              style: TextStyle(
                                fontFamily: 'Rubik',
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
                              child: TextFormField(
                                controller: _addressController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال عنوان المتجر';
                                  }
                                  return null;
                                },
                                style: const TextStyle(
                                  fontFamily: 'Rubik',
                                  fontSize: 12,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'أدخل عنوان متجرك',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white54
                                        : Colors.grey[500],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.location_on_outlined,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white60
                                        : Colors.grey[600],
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

                      // Next Button
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.arrow_back_ios,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'التالي',
                                      style: TextStyle(
                                        fontFamily: 'Rubik',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
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
      ),
    );
  }
}
