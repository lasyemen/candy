library guest_user_input_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/constants/design_system.dart';
import '../core/services/customer_session.dart';
import '../core/services/auth_service.dart';
import '../core/routes/index.dart';
// Removed unused imports
part 'functions/guest_user_input_screen.functions.dart';

class GuestUserInputScreen extends StatefulWidget {
  final Map<String, dynamic> deliveryData;

  const GuestUserInputScreen({super.key, required this.deliveryData});

  @override
  State<GuestUserInputScreen> createState() => _GuestUserInputScreenState();
}

class _GuestUserInputScreenState extends State<GuestUserInputScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Removed unused field _isLoading
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
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

    // Pre-fill with existing guest data if available
    _loadExistingGuestData();
  }

  Future<void> _loadExistingGuestData() async {
    final guestUser = CustomerSession.instance.guestUser;
    if (guestUser != null) {
      setState(() {
        _nameController.text = guestUser['name'] ?? '';
        _phoneController.text = guestUser['phone'] ?? '';
        _addressController.text = guestUser['address'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('GuestUserInputScreen - Creating customer account directly...');

      // Check if customer already exists
      final customerExists = await AuthService.instance.customerExists(
        phone: _phoneController.text.trim(),
      );

      if (customerExists) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('رقم الهاتف مسجل بالفعل. يرجى تسجيل الدخول.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create customer account directly (skip OTP)
      final customer = await AuthService.instance.registerCustomer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
      );

      if (customer != null) {
        print('GuestUserInputScreen - Customer account created successfully');

        // Set as current customer (cart merging happens in background)
        await CustomerSession.instance.setCurrentCustomer(customer);

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إنشاء الحساب بنجاح! مرحباً ${customer.name}'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to main and open the Cart tab so the bottom nav is visible
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.main,
            arguments: {'initialIndex': 3},
          );
        }
      } else {
        throw Exception('Failed to create customer account');
      }
    } catch (e) {
      print('GuestUserInputScreen - Error creating customer account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'حدث خطأ أثناء إنشاء الحساب. يرجى المحاولة مرة أخرى.',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'معلومات العميل',
          style: TextStyle(
            fontFamily: 'Rubik',
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.onBackground,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: DesignSystem.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: DesignSystem.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              FontAwesomeIcons.userPlus,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'أدخل معلوماتك',
                                  style: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'لإتمام عملية الشراء',
                                  style: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Name Field
                    _buildTextField(
                      controller: _nameController,
                      label: 'الاسم الكامل',
                      icon: FontAwesomeIcons.user,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال الاسم';
                        }
                        if (value.trim().length < 3) {
                          return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Phone Field
                    _buildTextField(
                      controller: _phoneController,
                      label: 'رقم الجوال',
                      icon: FontAwesomeIcons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال رقم الجوال';
                        }
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                          return 'يرجى إدخال رقم جوال صحيح (10 أرقام)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Address Field (Optional)
                    _buildTextField(
                      controller: _addressController,
                      label: 'العنوان (اختياري)',
                      icon: FontAwesomeIcons.locationDot,
                      maxLines: 3,
                    ),

                    const Spacer(),

                    // Continue Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleContinue,
                        style:
                            ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ).copyWith(
                              backgroundColor: MaterialStateProperty.all(
                                Colors.transparent,
                              ),
                            ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _isSubmitting
                                ? LinearGradient(
                                    colors: [
                                      Colors.grey.withOpacity(0.3),
                                      Colors.grey.withOpacity(0.3),
                                    ],
                                  )
                                : DesignSystem.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isSubmitting
                                ? null
                                : [
                                    BoxShadow(
                                      color: DesignSystem.primary.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: _isSubmitting
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'جاري إنشاء الحساب...',
                                        style: TextStyle(
                                          fontFamily: 'Rubik',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.creditCard,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'إنشاء حساب ومتابعة الدفع',
                                        style: TextStyle(
                                          fontFamily: 'Rubik',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(
          fontFamily: 'Rubik',
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: 'Rubik',
            fontSize: 14,
            color: Colors.grey[600],
          ),
          prefixIcon: Icon(icon, color: DesignSystem.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
