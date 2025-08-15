// lib/screens/myordrs.dart
library my_orders_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/constants/design_system.dart';
import '../widgets/riyal_icon.dart';
part 'functions/myordrs.functions.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with TickerProviderStateMixin, MyOrdersScreenFunctions {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Mock data for orders
  final List<Map<String, dynamic>> _currentOrders = [
    {
      'id': 'ORD-001',
      'items': ['ماء زمزم 5 لتر × 2', 'ماء نستله 1.5 لتر × 6'],
      'total': 85.50,
      'status': 'قيد التوصيل',
      'date': '2024-01-15',
      'estimatedTime': '30 دقيقة',
      'statusColor': Colors.orange,
      'icon': FontAwesomeIcons.truck,
    },
    {
      'id': 'ORD-002',
      'items': ['ماء أكوافينا 500 مل × 12'],
      'total': 42.00,
      'status': 'قيد التحضير',
      'date': '2024-01-15',
      'estimatedTime': '45 دقيقة',
      'statusColor': Colors.blue,
      'icon': FontAwesomeIcons.kitchenSet,
    },
  ];

  final List<Map<String, dynamic>> _previousOrders = [
    {
      'id': 'ORD-003',
      'items': ['ماء زمزم 5 لتر × 1', 'ماء الهدا 1 لتر × 8'],
      'total': 67.25,
      'status': 'تم التوصيل',
      'date': '2024-01-14',
      'statusColor': Colors.green,
      'icon': FontAwesomeIcons.circleCheck,
    },
    {
      'id': 'ORD-004',
      'items': ['ماء نستله 1.5 لتر × 4', 'ماء أكوافينا 500 مل × 6'],
      'total': 38.50,
      'status': 'تم التوصيل',
      'date': '2024-01-13',
      'statusColor': Colors.green,
      'icon': FontAwesomeIcons.circleCheck,
    },
    {
      'id': 'ORD-005',
      'items': ['ماء زمزم 5 لتر × 3'],
      'total': 128.25,
      'status': 'تم التوصيل',
      'date': '2024-01-12',
      'statusColor': Colors.green,
      'icon': FontAwesomeIcons.circleCheck,
    },
    {
      'id': 'ORD-006',
      'items': ['ماء الهدا 1 لتر × 12'],
      'total': 96.00,
      'status': 'ملغي',
      'date': '2024-01-11',
      'statusColor': Colors.red,
      'icon': FontAwesomeIcons.circleXmark,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: DesignSystem.getBrandGradient('primary'),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                FontAwesomeIcons.clipboardList,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'طلباتي',
              style: DesignSystem.headlineSmall.copyWith(
                color: DesignSystem.textPrimary,
                fontWeight: FontWeight.bold,
                fontFamily: 'Rubik',
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: DesignSystem.primary,
              unselectedLabelColor: DesignSystem.textSecondary,
              indicatorColor: DesignSystem.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: DesignSystem.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'Rubik',
              ),
              unselectedLabelStyle: DesignSystem.titleMedium.copyWith(
                fontWeight: FontWeight.w500,
                fontFamily: 'Rubik',
              ),
              tabs: const [
                Tab(text: 'الطلبات الحالية'),
                Tab(text: 'الطلبات السابقة'),
              ],
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [_buildCurrentOrders(), _buildPreviousOrders()],
        ),
      ),
    );
  }

  Widget _buildCurrentOrders() {
    if (_currentOrders.isEmpty) {
      return _buildEmptyState(
        icon: FontAwesomeIcons.clipboard,
        title: 'لا توجد طلبات حالية',
        subtitle: 'لم تقم بإنشاء أي طلبات بعد',
        actionText: 'تصفح المنتجات',
        onAction: () {
          // Navigate to home/products
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _currentOrders.length,
      itemBuilder: (context, index) {
        final order = _currentOrders[index];
        return _buildCurrentOrderCard(order, index);
      },
    );
  }

  Widget _buildPreviousOrders() {
    if (_previousOrders.isEmpty) {
      return _buildEmptyState(
        icon: FontAwesomeIcons.clockRotateLeft,
        title: 'لا توجد طلبات سابقة',
        subtitle: 'سيتم عرض طلباتك المكتملة هنا',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _previousOrders.length,
      itemBuilder: (context, index) {
        final order = _previousOrders[index];
        return _buildPreviousOrderCard(order, index);
      },
    );
  }

  Widget _buildCurrentOrderCard(Map<String, dynamic> order, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order['statusColor'].withOpacity(0.2),
          width: 1,
        ),
        boxShadow: DesignSystem.getBrandShadow('medium'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: order['statusColor'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        order['icon'],
                        color: order['statusColor'],
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلب رقم: ${order['id']}',
                          style: DesignSystem.titleMedium.copyWith(
                            color: DesignSystem.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'تاريخ الطلب: ${order['date']}',
                          style: DesignSystem.bodySmall.copyWith(
                            color: DesignSystem.textSecondary,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      order['statusColor'].withOpacity(0.1),
                      order['statusColor'].withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: order['statusColor'], width: 1),
                ),
                child: Text(
                  order['status'],
                  style: DesignSystem.labelMedium.copyWith(
                    color: order['statusColor'],
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Rubik',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(FontAwesomeIcons.clock, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Text(
                  'الوقت المتوقع للتوصيل: ${order['estimatedTime']}',
                  style: DesignSystem.bodyMedium.copyWith(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Rubik',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'المنتجات:',
            style: DesignSystem.titleSmall.copyWith(
              color: DesignSystem.textPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignSystem.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: order['items']
                  .map<Widget>(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.droplet,
                            color: DesignSystem.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: DesignSystem.bodyMedium.copyWith(
                                color: DesignSystem.textSecondary,
                                fontFamily: 'Rubik',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المجموع:',
                style: DesignSystem.titleMedium.copyWith(
                  color: DesignSystem.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Rubik',
                ),
              ),
              Row(
                children: [
                  Text(
                    '${order['total'].toStringAsFixed(2)}',
                    style: DesignSystem.headlineSmall.copyWith(
                      color: DesignSystem.primary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Rubik',
                    ),
                  ),
                  const SizedBox(width: 4),
                  const RiyalIcon(size: 18, color: DesignSystem.primary),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: DesignSystem.getBrandGradient('primary'),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: DesignSystem.getBrandShadow('light'),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _trackOrder(order['id']),
                    icon: Icon(FontAwesomeIcons.locationDot, size: 16),
                    label: Text(
                      'تتبع الطلب',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _contactSupport(order['id']),
                icon: Icon(FontAwesomeIcons.headset, size: 16),
                label: Text(
                  'الدعم',
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DesignSystem.primary,
                  side: BorderSide(color: DesignSystem.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousOrderCard(Map<String, dynamic> order, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: DesignSystem.getBrandShadow('light'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: order['statusColor'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        order['icon'],
                        color: order['statusColor'],
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلب رقم: ${order['id']}',
                          style: DesignSystem.titleMedium.copyWith(
                            color: DesignSystem.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'تاريخ الطلب: ${order['date']}',
                          style: DesignSystem.bodySmall.copyWith(
                            color: DesignSystem.textSecondary,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: order['statusColor'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: order['statusColor'], width: 1),
                ),
                child: Text(
                  order['status'],
                  style: DesignSystem.labelMedium.copyWith(
                    color: order['statusColor'],
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Rubik',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'المنتجات:',
            style: DesignSystem.titleSmall.copyWith(
              color: DesignSystem.textPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignSystem.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: order['items']
                  .map<Widget>(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.droplet,
                            color: DesignSystem.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: DesignSystem.bodyMedium.copyWith(
                                color: DesignSystem.textSecondary,
                                fontFamily: 'Rubik',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المجموع:',
                style: DesignSystem.titleMedium.copyWith(
                  color: DesignSystem.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Rubik',
                ),
              ),
              Row(
                children: [
                  Text(
                    '${order['total'].toStringAsFixed(2)}',
                    style: DesignSystem.headlineSmall.copyWith(
                      color: DesignSystem.primary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Rubik',
                    ),
                  ),
                  const SizedBox(width: 4),
                  const RiyalIcon(size: 18, color: DesignSystem.primary),
                ],
              ),
            ],
          ),

          if (order['status'] == 'تم التوصيل') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: DesignSystem.getBrandGradient('primary'),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: DesignSystem.getBrandShadow('light'),
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _reorderItems(order),
                  icon: Icon(FontAwesomeIcons.arrowRotateRight, size: 16),
                  label: Text(
                    'إعادة الطلب',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DesignSystem.surface,
                    DesignSystem.surface.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: DesignSystem.getBrandShadow('light'),
              ),
              child: Icon(
                icon,
                size: 64,
                color: DesignSystem.textSecondary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: DesignSystem.headlineSmall.copyWith(
                color: DesignSystem.textPrimary,
                fontWeight: FontWeight.bold,
                fontFamily: 'Rubik',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: DesignSystem.bodyLarge.copyWith(
                color: DesignSystem.textSecondary,
                fontFamily: 'Rubik',
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: DesignSystem.getBrandGradient('primary'),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: DesignSystem.getBrandShadow('light'),
                ),
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: Icon(FontAwesomeIcons.magnifyingGlass, size: 16),
                  label: Text(
                    actionText,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _trackOrder(String orderId) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(FontAwesomeIcons.locationDot, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('تتبع الطلب $orderId', style: TextStyle(fontFamily: 'Rubik')),
          ],
        ),
        backgroundColor: DesignSystem.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _contactSupport(String orderId) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(FontAwesomeIcons.headset, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'تواصل مع الدعم للطلب $orderId',
              style: TextStyle(fontFamily: 'Rubik'),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _reorderItems(Map<String, dynamic> order) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(FontAwesomeIcons.cartShopping, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تم إضافة منتجات الطلب ${order['id']} إلى السلة',
                style: TextStyle(fontFamily: 'Rubik'),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'عرض السلة',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to cart
          },
        ),
      ),
    );
  }
}
