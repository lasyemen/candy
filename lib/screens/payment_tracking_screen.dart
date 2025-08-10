// lib/screens/payment_tracking_screen.dart
library payment_tracking_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
// import '../core/constants/design_system.dart';
import '../widgets/payment/payment_header.dart';
import '../widgets/payment/order_summary_card.dart';
import '../widgets/payment/payment_method.dart' as pm;
import '../widgets/payment/payment_method_tile.dart';
import '../widgets/navigation/navigation_wrapper.dart';
part 'functions/payment_tracking_screen.functions.dart';

class PaymentTrackingScreen extends StatefulWidget {
  final Map<String, dynamic>? deliveryData;

  const PaymentTrackingScreen({super.key, this.deliveryData});

  @override
  State<PaymentTrackingScreen> createState() => _PaymentTrackingScreenState();
}

class _PaymentTrackingScreenState extends State<PaymentTrackingScreen>
    with TickerProviderStateMixin, PaymentTrackingScreenFunctions {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? selectedPaymentMethod;

  final List<pm.PaymentMethod> paymentMethods = const [
    pm.PaymentMethod(
      id: 'visa',
      name: 'فيزا',
      subtitle: 'الدفع بالبطاقة الائتمانية',
      icon: Icons.credit_card,
      color: const Color(0xFF1A1F71),
    ),
    pm.PaymentMethod(
      id: 'mastercard',
      name: 'ماستركارد',
      subtitle: 'الدفع بالبطاقة الائتمانية',
      icon: Icons.credit_card,
      color: const Color(0xFFEB001B),
    ),
    pm.PaymentMethod(
      id: 'mada',
      name: 'مدى',
      subtitle: 'البطاقة السعودية',
      icon: Icons.payment,
      color: const Color(0xFF00B4D8),
    ),
    pm.PaymentMethod(
      id: 'apple_pay',
      name: 'Apple Pay',
      subtitle: 'الدفع السريع والآمن',
      icon: Icons.phone_iphone,
      color: const Color(0xFF000000),
    ),
    pm.PaymentMethod(
      id: 'stc_pay',
      name: 'STC Pay',
      subtitle: 'محفظة إس تي سي الرقمية',
      icon: Icons.account_balance_wallet,
      color: const Color(0xFF663399),
    ),
    pm.PaymentMethod(
      id: 'cash',
      name: 'الدفع عند الاستلام',
      subtitle: 'ادفع نقداً عند التوصيل',
      icon: Icons.money,
      color: const Color(0xFF4CAF50),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _animationController.forward();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationWrapper(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.background,
              AppColors.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildPaymentScreen(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildPaymentHeader(),
          const SizedBox(height: 32),
          _buildOrderSummary(),
          const SizedBox(height: 32),
          Expanded(child: _buildPaymentMethodsList()),
          _buildConfirmPaymentButton(),
          const SizedBox(height: 100), // Space for navigation bar
        ],
      ),
    );
  }

  Widget _buildPaymentHeader() => const GradientHeaderCard(
    icon: Icons.payment_rounded,
    title: 'اختر طريقة الدفع',
    subtitle: 'اختر الطريقة المناسبة لإتمام عملية الدفع',
  );

  Widget _buildOrderSummary() => OrderSummaryCard(
    deliveryLocationText: _getDeliveryLocationText(),
    notes: widget.deliveryData?['notes'],
    totalText: '45.00 ريال',
  );

  // Summary row moved into OrderSummaryCard

  Widget _buildPaymentMethodsList() {
    return ListView.builder(
      itemCount: paymentMethods.length,
      itemBuilder: (context, index) {
        final method = paymentMethods[index];
        final isSelected = selectedPaymentMethod == method.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: RepaintBoundary(
            child: PaymentMethodTile(
              method: method,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  selectedPaymentMethod = method.id;
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmPaymentButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: selectedPaymentMethod != null
            ? LinearGradient(colors: [AppColors.primary, AppColors.secondary])
            : null,
        color: selectedPaymentMethod == null
            ? AppColors.textSecondary.withOpacity(0.3)
            : null,
        borderRadius: BorderRadius.circular(18),
        boxShadow: selectedPaymentMethod != null
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: selectedPaymentMethod != null
            ? _handlePaymentConfirmation
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 22,
              color: selectedPaymentMethod != null
                  ? Colors.white
                  : AppColors.textSecondary.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Text(
              'تأكيد الدفع',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Rubik',
                color: selectedPaymentMethod != null
                    ? Colors.white
                    : AppColors.textSecondary.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDeliveryLocationText() {
    final type = widget.deliveryData?['type'];
    switch (type) {
      case 'home':
        return 'المنزل';
      case 'mosque':
        return 'المسجد';
      case 'custom':
        return widget.deliveryData?['address'] ?? 'مكان محدد';
      default:
        return 'غير محدد';
    }
  }

  void _handlePaymentConfirmation() {
    HapticFeedback.mediumImpact();

    // Show confirmation for cash payment
    if (selectedPaymentMethod == 'cash') {
      _showCashPaymentConfirmation();
    } else {
      _showPaymentSuccessDialog();
    }
  }

  void _showCashPaymentConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.money,
                color: Color(0xFF4CAF50),
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'الدفع عند الاستلام',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Rubik',
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'سيتم تأكيد طلبك وستدفع المبلغ نقداً عند استلام الطلب',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontFamily: 'Rubik',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showPaymentSuccessDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'تأكيد',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'تم تأكيد طلبك!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Rubik',
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              selectedPaymentMethod == 'cash'
                  ? 'تم تأكيد طلبك، ادفع نقداً عند الاستلام'
                  : 'تم الدفع بنجاح وسيتم التوصيل قريباً',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontFamily: 'Rubik',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'رقم الطلب: #${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontFamily: 'Rubik',
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'العودة للرئيسية',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Rubik',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
