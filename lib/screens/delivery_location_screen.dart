// lib/screens/delivery_location_screen.dart
library delivery_location_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
// import '../core/constants/design_system.dart';
import '../widgets/navigation/navigation_wrapper.dart';
import 'payment_tracking_screen.dart';
import '../widgets/delivery/delivery_option_tile.dart';
import '../widgets/delivery/gradient_header_card.dart';
part 'functions/delivery_location_screen.functions.dart';

class DeliveryLocationScreen extends StatefulWidget {
  const DeliveryLocationScreen({super.key});

  @override
  State<DeliveryLocationScreen> createState() => _DeliveryLocationScreenState();
}

class _DeliveryLocationScreenState extends State<DeliveryLocationScreen>
    with TickerProviderStateMixin, DeliveryLocationScreenFunctions {
  String? selectedDeliveryType;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScaleAnimation;

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

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 120),
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

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationWrapper(
      child: Column(
        children: [
          // Custom App Bar
          _buildCustomAppBar(),

          // Main Content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    AppColors.background,
                    AppColors.secondary.withOpacity(0.02),
                  ],
                ),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildMainContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مكان التوصيل',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Rubik',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'اختر المكان المناسب لك',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Rubik',
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Header section
          const GradientHeaderCard(
            icon: Icons.delivery_dining,
            title: 'اختر مكان التوصيل',
            subtitle: 'حدد المكان المناسب لاستلام طلبك بسهولة',
          ),
          const SizedBox(height: 32),

          // Delivery options
          _buildDeliveryOptions(),
          const SizedBox(height: 32),

          // Address input if custom location is selected
          if (selectedDeliveryType == 'custom') ...[
            _buildAddressInput(),
            const SizedBox(height: 20),
          ],

          // Notes input
          _buildNotesInput(),
          const SizedBox(height: 40),

          // Continue button
          _buildContinueButton(),
          const SizedBox(height: 100), // Extra space for navigation bar
        ],
      ),
    );
  }

  // Header extracted to GradientHeaderCard

  Widget _buildDeliveryOptions() {
    return Column(
      children: [
        DeliveryOptionTile(
          isSelected: selectedDeliveryType == 'home',
          title: 'التوصيل للمنزل',
          subtitle: 'سيتم التوصيل إلى عنوان منزلك',
          icon: Icons.home_rounded,
          accentColor: AppColors.primary,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => selectedDeliveryType = 'home');
          },
        ),
        const SizedBox(height: 16),

        DeliveryOptionTile(
          isSelected: selectedDeliveryType == 'custom',
          title: 'مكان محدد',
          subtitle: 'حدد عنوان مخصص للتوصيل',
          icon: Icons.location_on_rounded,
          accentColor: AppColors.secondary,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => selectedDeliveryType = 'custom');
          },
        ),
        const SizedBox(height: 16),

        DeliveryOptionTile(
          isSelected: selectedDeliveryType == 'mosque',
          title: 'المسجد',
          subtitle: 'التوصيل للمسجد القريب',
          icon: Icons.place_rounded,
          accentColor: const Color(0xFF4CAF50),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => selectedDeliveryType = 'mosque');
          },
        ),
      ],
    );
  }

  // Delivery option extracted to DeliveryOptionTile

  Widget _buildAddressInput() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _addressController,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'أدخل العنوان التفصيلي هنا...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.7),
            fontFamily: 'Rubik',
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(24),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(
              Icons.edit_location_alt,
              color: AppColors.secondary,
              size: 22,
            ),
          ),
        ),
        style: const TextStyle(
          fontFamily: 'Rubik',
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildNotesInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _notesController,
        textAlign: TextAlign.right,
        maxLines: 4,
        decoration: InputDecoration(
          hintText:
              'ملاحظات إضافية (اختياري)\nمثل: الدور الثاني، بجانب المحل...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.7),
            fontFamily: 'Rubik',
            fontSize: 15,
            height: 1.5,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(24),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(
              Icons.note_alt_outlined,
              color: AppColors.primary.withOpacity(0.7),
              size: 22,
            ),
          ),
        ),
        style: const TextStyle(
          fontFamily: 'Rubik',
          color: AppColors.textPrimary,
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return AnimatedBuilder(
      animation: _buttonAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScaleAnimation.value,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: selectedDeliveryType != null
                  ? LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    )
                  : null,
              color: selectedDeliveryType == null
                  ? AppColors.textSecondary.withOpacity(0.3)
                  : null,
              borderRadius: BorderRadius.circular(18),
              boxShadow: selectedDeliveryType != null
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
              onPressed: selectedDeliveryType != null
                  ? _handleContinuePressed
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
                    Icons.payment_rounded,
                    size: 22,
                    color: selectedDeliveryType != null
                        ? Colors.white
                        : AppColors.textSecondary.withOpacity(0.6),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'متابعة الدفع',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Rubik',
                      color: selectedDeliveryType != null
                          ? Colors.white
                          : AppColors.textSecondary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleContinuePressed() {
    HapticFeedback.mediumImpact();
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _continueToPayment();
    });
  }

  void _continueToPayment() {
    // Validate custom address if selected
    if (selectedDeliveryType == 'custom' &&
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'يرجى إدخال العنوان التفصيلي',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
      return;
    }

    // Get delivery data
    final deliveryData = {
      'type': selectedDeliveryType,
      'address': selectedDeliveryType == 'custom'
          ? _addressController.text.trim()
          : null,
      'notes': _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    };

    // Navigate to payment tracking screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentTrackingScreen(deliveryData: deliveryData),
      ),
    );
  }
}
