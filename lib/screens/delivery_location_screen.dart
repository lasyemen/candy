// lib/screens/delivery_location_screen.dart
library delivery_location_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/cart_session_manager.dart';
import '../core/services/customer_session.dart';
import '../core/services/supabase_service.dart';
import '../models/customer.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/design_system.dart';
import '../widgets/navigation/navigation_wrapper.dart';
// header card removed - keep import commented out for potential reuse
// import '../widgets/delivery/gradient_header_card.dart';
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

  void _showAddAddressSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: DesignSystem.primaryBottomSheetDecoration,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'أضف عنواناً جديداً',
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: DesignSystem.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                DesignSystem.gradientTextFormField(
                  controller: _addressController,
                  labelText: 'العنوان',
                  hintText: 'أدخل العنوان التفصيلي...',
                  prefixIcon: Icons.edit_location_alt,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: DesignSystem.gradientButtonStyle,
                  onPressed: () async {
                    // Save address locally (guest) or update customer via API
                    final addr = _addressController.text.trim();
                    if (addr.isEmpty) return;
                    if (CustomerSession.instance.isLoggedIn) {
                      // Update customer address via Supabase
                      try {
                        final id = CustomerSession.instance.currentCustomerId;
                        if (id != null) {
                          await SupabaseService.instance.updateData(
                            'customers',
                            id,
                            {'address': addr},
                          );
                          // Update local session
                          final customer =
                              CustomerSession.instance.currentCustomer;
                          if (customer != null) {
                            await CustomerSession.instance.setCurrentCustomer(
                              Customer(
                                id: customer.id,
                                name: customer.name,
                                phone: customer.phone,
                                address: addr,
                                avatar: customer.avatar,
                                isActive: customer.isActive,
                                lastLogin: customer.lastLogin,
                                totalSpent: customer.totalSpent,
                                ordersCount: customer.ordersCount,
                                rating: customer.rating,
                                createdAt: customer.createdAt,
                                updatedAt: DateTime.now(),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        print('Failed to update customer address: $e');
                      }
                    } else {
                      // Save as guest user address
                      await CustomerSession.instance.setGuestUser(
                        name: CustomerSession.instance.customerName,
                        phone:
                            CustomerSession.instance.currentCustomerPhone ?? '',
                        address: addr,
                      );
                    }
                    Navigator.of(context).pop();
                    setState(() {});
                  },
                  child: const Text('حفظ العنوان'),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    // notes removed
    _animationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationWrapper(
      child: Stack(
        children: [
          Column(
            children: [
              // Custom App Bar
              _buildCustomAppBar(),

              // Main Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: DesignSystem.surface),
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

          // Floating Add Address Button
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton(
              backgroundColor: DesignSystem.primary,
              onPressed: () => _showAddAddressSheet(),
              child: const Icon(Icons.add_location_alt, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: DesignSystem.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // placeholder for left-side add button (moved to end for RTL)
              const SizedBox.shrink(),
              const SizedBox(width: 8),
              // Title aligned to the right (RTL style)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'مكان التوصيل',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Rubik',
                      color: DesignSystem.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Add-location icon with gradient color
              IconButton(
                onPressed: () async {
                  final result =
                      await Navigator.of(context).pushNamed('/full-map')
                          as Map<String, dynamic>?;
                  if (result != null && mounted) {
                    setState(() {
                      selectedDeliveryType = 'custom';
                      final lat = result['lat'];
                      final lng = result['lng'];
                      _addressController.text = 'Lat: $lat, Lng: $lng';
                    });
                  }
                },
                icon: ShaderMask(
                  shaderCallback: (bounds) =>
                      DesignSystem.primaryGradient.createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: const Icon(
                    Icons.add_location_alt,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                iconSize: 22,
                splashRadius: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 0),

          // Search bar removed
          const SizedBox(height: 8),

          // Header above location cards
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'اختار موقع التوصيل',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: DesignSystem.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Recent / suggested addresses
          _addressListItem(
            id: 'home',
            title: 'المنزل',
            subtitle: 'شارع الملك فيصل، حي العليا، الرياض',
            // onUse -> edit action, should NOT select the address
            onUse: () => _showAddAddressSheet(),
            // onTap -> select address (makes continue button prominent)
            onTap: () {
              setState(() {
                selectedDeliveryType = 'home';
                _addressController.text =
                    'شارع الملك فيصل، حي العليا، الرياض، منزل رقم 12';
              });
            },
          ),

          const SizedBox(height: 20),

          _addressListItem(
            id: 'work',
            title: 'العمل',
            subtitle: 'شارع التحلية، الظهران',
            onUse: () => _showAddAddressSheet(),
            onTap: () {
              setState(() {
                selectedDeliveryType = 'work';
                _addressController.text = 'شارع التحلية، الظهران';
              });
            },
          ),

          const SizedBox(height: 70),

          // Re-added add-address button under the cards. Gradient when an address is selected, grey otherwise.
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Builder(
              builder: (context) {
                final bool isActive = selectedDeliveryType != null;
                if (isActive) {
                  return Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: DesignSystem.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: DesignSystem.primary.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _handleContinuePressed(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'متابعة الدفع',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'متابعة الدفع',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                );
              },
            ),
          ),

          // Continue button removed per request
          const SizedBox(height: 100), // Extra space for navigation bar
        ],
      ),
    );
  }

  Widget _addressListItem({
    String? id,
    required String title,
    required String subtitle,
    required VoidCallback onUse,
    required VoidCallback onTap,
  }) {
    final bool isSelected = id != null && selectedDeliveryType == id;
    final double cardWidth = MediaQuery.of(context).size.width - 48;

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: isSelected
            ? Container(
                width: cardWidth,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: DesignSystem.primaryGradient,
                  // Outer radius = inner radius (20) + padding (2) for uniform thickness
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: Theme.of(context).brightness == Brightness.dark
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.09),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: DesignSystem.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.place,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Rubik',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: DesignSystem.textPrimary.withOpacity(
                                  0.9,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontFamily: 'Rubik',
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: DesignSystem.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ElevatedButton(
                          onPressed: onUse,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isSelected ? 18 : 14,
                            ),
                          ),
                          child: Text(
                            'تعديل',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSelected ? 14 : 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                width: cardWidth,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: Theme.of(context).brightness == Brightness.dark
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 1,
                            offset: const Offset(0, -1),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                            spreadRadius: 0,
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: DesignSystem.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.place, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'Rubik',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: DesignSystem.textPrimary.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: DesignSystem.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: DesignSystem.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: onUse,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isSelected ? 18 : 14,
                          ),
                        ),
                        child: Text(
                          'تعديل',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSelected ? 14 : 12,
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

  // Delivery option helpers removed — screen now shows saved address and add-new flow

  // Notes removed

  Widget _buildContinueButton() {
    final bool isActive = selectedDeliveryType != null;
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      scale: isActive ? 1.02 : 1.0,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [DesignSystem.primary, DesignSystem.secondary],
                )
              : null,
          color: !isActive ? AppColors.textSecondary.withOpacity(0.3) : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: DesignSystem.primary.withOpacity(0.38),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: _handleContinuePressed,
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
                color: isActive
                    ? Colors.white
                    : DesignSystem.textSecondary.withOpacity(0.6),
              ),
              const SizedBox(width: 12),
              Text(
                'متابعة الدفع',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Rubik',
                  color: isActive
                      ? Colors.white
                      : DesignSystem.textSecondary.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
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

  Future<void> _continueToPayment() async {
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
      'notes': null,
    };

    // Get cart total and pass it to payment methods
    double total = 0.0;
    try {
      final cartSummary = await CartSessionManager.instance.getCartSummary();
      total = (cartSummary['total'] as double?) ?? 0.0;
    } catch (e) {
      print('DeliveryLocationScreen - Error fetching cart total: $e');
    }

    // Navigate to payment methods screen with the calculated total
    Navigator.of(context).pushNamed(
      '/payment-methods',
      arguments: {'total': total, 'deliveryData': deliveryData},
    );
  }
}
