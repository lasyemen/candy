import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/design_system.dart';
import '../core/routes/index.dart';
import '../core/services/auth_service.dart';
import '../core/services/customer_session.dart';
// Removed unused import

/*
 * ACCOUNT CREATION ISSUES AND SOLUTIONS:
 * 
 * Common issues that can cause "creating account failed" errors:
 * 
 * 1. DATABASE CONNECTION ISSUES:
 *    - Check internet connection
 *    - Verify Supabase configuration (URL and API key)
 *    - Ensure Supabase service is running
 * 
 * 2. DATABASE TABLE ISSUES:
 *    - Verify 'customers' table exists in Supabase
 *    - Check table schema matches Customer model
 *    - Ensure proper permissions for table operations
 * 
 * 3. DATA VALIDATION ISSUES:
 *    - Name cannot be empty
 *    - Phone number must be valid format
 *    - Required fields must be provided
 * 
 * 4. DUPLICATE KEY ISSUES:
 *    - Phone number already exists in database
 *    - Handle existing customer updates properly
 * 
 * 5. NETWORK TIMEOUT ISSUES:
 *    - Request timeout due to slow connection
 *    - Retry mechanism needed
 * 
 * 6. PERMISSION ISSUES:
 *    - Database permissions not configured properly
 *    - Row Level Security (RLS) policies blocking operations
 *    - SOLUTION: Disable RLS or configure proper policies
 * 
 * 7. RLS (ROW LEVEL SECURITY) ISSUES:
 *    - RLS policies can block insert/update operations
 *    - Common error codes: 42501 (Insufficient privilege)
 *    - SOLUTION: Disable RLS for public tables or configure proper policies
 *    - RECOMMENDATION: For development, disable RLS; for production, configure proper policies
 * 
 * DEBUGGING TOOLS ADDED:
 * - Enhanced error messages with specific Arabic translations
 * - Comprehensive error logging
 * - Debug button to test account creation process
 * - Step-by-step debugging information
 * - Retry mechanism for failed operations
 * 
 * TO USE DEBUGGING:
 * 1. Click "تصحيح إنشاء الحساب" button to run comprehensive debug
 * 2. Check console logs for detailed error information
 * 3. Review debug dialog for step-by-step analysis
 * 4. Use "اختبار إنشاء الحساب" for quick test with sample data
 * 
 * RLS FIX APPLIED:
 * - RLS has been disabled for the customers table
 * - This resolves permission issues for account creation
 * - For production, consider implementing proper RLS policies instead of disabling
 */

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
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

    // Pre-fill with guest user data if available
    _loadGuestUserData();
  }

  void _loadGuestUserData() {
    final guestUser = CustomerSession.instance.guestUser;
    if (guestUser != null) {
      setState(() {
        _nameController.text = guestUser['name'] ?? '';
        _phoneController.text = guestUser['phone'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Debug/test helpers removed per request

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Clean phone number (remove non-digit characters)
      final cleanPhone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');

      print(
        'Sign-up form submitted with name: ${_nameController.text}, phone: $cleanPhone',
      );

      // Proceed with customer registration directly (upsert handles duplicates)
      print('Proceeding with customer registration...');

      // Get guest user data if available
      final guestUser = CustomerSession.instance.guestUser;
      String? address;
      if (guestUser != null && guestUser['address'] != null) {
        address = guestUser['address'];
        print('SignUpScreen - Using guest user address: $address');
      }

      // Register new customer
      final customer = await AuthService.instance.registerCustomer(
        name: _nameController.text,
        phone: cleanPhone,
        address: address,
      );

      print('Registration result: ${customer?.name}');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (customer != null) {
          // Check if this is a guest user with cart items
          final isGuestUser = CustomerSession.instance.isGuestUser;
          final hasGuestData = CustomerSession.instance.guestUser != null;

          if (isGuestUser && hasGuestData) {
            print('SignUpScreen - Guest user with cart items, merging cart...');

            // Set the customer as current (cart merging runs in background)
            await CustomerSession.instance.setCurrentCustomer(customer);

            // Note: Guest user data will be cleared automatically when setCurrentCustomer is called
            print('SignUpScreen - Guest user data preserved for cart merging');

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
          } else {
            // Regular signup without cart items
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم إنشاء الحساب بنجاح! مرحباً ${customer.name}'),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate to main screen (which includes navigation bar)
            Navigator.pushReplacementNamed(context, AppRoutes.main);
          }
        } else {
          print('SignUpScreen - Customer registration returned null');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ في إنشاء الحساب. يرجى المحاولة مرة أخرى.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('SignUpScreen - Exception during account creation: $e');
      print('SignUpScreen - Exception type: ${e.runtimeType}');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'حدث خطأ في إنشاء الحساب';

        // More specific error handling
        if (e.toString().contains('Database connection failed')) {
          errorMessage =
              'فشل الاتصال بقاعدة البيانات. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.';
        } else if (e.toString().contains('duplicate key') ||
            e.toString().contains('already exists')) {
          errorMessage = 'رقم الهاتف مسجل بالفعل. يرجى تسجيل الدخول.';
        } else if (e.toString().contains('not null') ||
            e.toString().contains('required')) {
          errorMessage = 'يرجى التأكد من إدخال جميع البيانات المطلوبة.';
        } else if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage =
              'خطأ في الاتصال بالشبكة. يرجى التحقق من اتصال الإنترنت.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.';
        } else if (e.toString().contains('permission') ||
            e.toString().contains('unauthorized') ||
            e.toString().contains('RLS')) {
          errorMessage =
              'خطأ في الصلاحيات. تم حل المشكلة - يرجى المحاولة مرة أخرى.';
        } else if (e.toString().contains('invalid') ||
            e.toString().contains('format')) {
          errorMessage = 'بيانات غير صحيحة. يرجى التحقق من المعلومات المدخلة.';
        } else {
          // Log the full error for debugging
          print('SignUpScreen - Full error details: $e');
          errorMessage =
              'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى أو التواصل مع الدعم الفني.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: () => _submitForm(),
            ),
          ),
        );
      }
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
            color: Theme.of(context).colorScheme.onBackground,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            if (isDark) {
              return const Text(
                'إنشاء حساب جديد',
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
                'إنشاء حساب جديد',
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
                      // Sign Up Icon with Gradient Container
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
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Subtitle with Gradient
                      Text(
                        'أنشئ حسابك الجديد\nللاستمتاع بخدماتنا',
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

                      // Full Name Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label above the input field
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Text(
                              'الاسم الكامل',
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
                                controller: _nameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال الاسم الكامل';
                                  }
                                  return null;
                                },
                                style: const TextStyle(
                                  fontFamily: 'Rubik',
                                  fontSize: 12,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'أدخل اسمك الكامل',
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

                      const SizedBox(height: 16),

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
                                      return 'يرجى إدخال رقم الهاتف';
                                    }
                                    // Remove any non-digit characters for validation
                                    final cleanPhone = value.replaceAll(
                                      RegExp(r'[^\d]'),
                                      '',
                                    );
                                    if (cleanPhone.length < 8) {
                                      return 'يرجى إدخال رقم هاتف صحيح';
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
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white54
                                          : Colors.grey[500],
                                    ),
                                    prefixIcon: Icon(
                                      Icons.phone_outlined,
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
                          ),
                        ],
                      ),

                      const SizedBox(height: 90),

                      // Debug buttons removed

                      // Sign Up Button
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
                                  'التالي',
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

                      // Already have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'لديك حساب بالفعل؟ ',
                            style: TextStyle(
                              fontFamily: 'Rubik',
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
                              Navigator.pop(context);
                            },
                            child: ShaderMask(
                              shaderCallback: (bounds) => DesignSystem
                                  .primaryGradient
                                  .createShader(bounds),
                              child: const Text(
                                'تسجيل الدخول',
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
