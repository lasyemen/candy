// lib/screens/myordrs.dart
library my_orders_screen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../core/services/supabase_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/constants/design_system.dart';
part 'functions/myordrs.functions.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});
  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _searchCtrl;
  late final ScrollController _scrollCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  // Orders loaded from backend
  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoadingOrders = false;

  String _query = '';
  String _statusFilter =
      'الكل'; // الكل / قيد التحضير / قيد التوصيل / تم التوصيل
  String _timeFilter = 'الكل'; // الكل / الأسبوع / الشهر
  String _viewMode = 'current'; // 'current' or 'previous'

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _scrollCtrl = ScrollController();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoadingOrders = true;
    });
    try {
      final rows = await SupabaseService.instance.fetchData('orders');
      // Debug logs to inspect driver fields
      if (rows.isNotEmpty) {
        for (var i = 0; i < (rows.length < 5 ? rows.length : 5); i++) {
          final r = rows[i];
          print('MyOrdersScreen - fetched order #$i keys: ${r.keys.toList()}');
          print(
            'MyOrdersScreen - driver raw fields: driver=${r['driver']}, driver_id=${r['driver_id']}, driverId=${r['driverId']}, driver_name=${r['driver_name']}',
          );
        }
      }
      final parsed = rows.map<Map<String, dynamic>>((r) {
        dynamic itemsRaw = r['items'];
        List<String> itemsList = [];
        if (itemsRaw is String) {
          try {
            final decoded = jsonDecode(itemsRaw);
            if (decoded is List) {
              itemsList = decoded.map((e) => e.toString()).toList();
            } else {
              itemsList = [decoded.toString()];
            }
          } catch (_) {
            itemsList = [itemsRaw];
          }
        } else if (itemsRaw is List) {
          itemsList = itemsRaw.map((e) => e.toString()).toList();
        }

        Color? statusColor;
        final sc = r['status_color'] ?? r['statusColor'];
        if (sc != null) {
          if (sc is int) statusColor = Color(sc);
          if (sc is String) {
            final s = sc.replaceAll('#', '');
            try {
              statusColor = Color(int.parse('0xFF$s'));
            } catch (_) {}
          }
        }

        // attempt to extract driver name from multiple possible shapes
        dynamic _driverRaw =
            r['driver'] ??
            r['driver_name'] ??
            r['driverName'] ??
            r['driver_id'] ??
            r['driverId'] ??
            r['driver_full_name'] ??
            r['driverFullName'];
        String? _driverVal;
        if (_driverRaw != null) {
          if (_driverRaw is Map) {
            _driverVal =
                (_driverRaw['name'] ??
                        _driverRaw['full_name'] ??
                        _driverRaw['driver_name'])
                    ?.toString();
          } else {
            _driverVal = _driverRaw.toString();
          }
          if (_driverVal != null && _driverVal.trim().isEmpty)
            _driverVal = null;
        }

        return {
          'id': r['id']?.toString() ?? '',
          'items': itemsList,
          'total': (r['total'] is num)
              ? r['total']
              : double.tryParse(r['total']?.toString() ?? '') ?? 0.0,
          'status': r['status']?.toString() ?? '',
          'date': r['date']?.toString() ?? r['created_at']?.toString() ?? '',
          'eta': r['eta']?.toString(),
          'driver': _driverVal,
          'vehicle': r['vehicle']?.toString(),
          'statusColor': statusColor ?? Colors.blue,
          'step': r['step'] is int
              ? r['step']
              : int.tryParse(r['step']?.toString() ?? '') ?? 0,
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _allOrders = parsed;
        _isLoadingOrders = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOrders = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في جلب الطلبات: $e')));
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // Simple filters (you can replace with real logic later)
  List<Map<String, dynamic>> _filterList(List<Map<String, dynamic>> src) {
    final now = DateTime(2024, 1, 15); // mock for demo
    return src.where((o) {
      final matchesQuery = _query.isEmpty
          ? true
          : (o['id'].toString().contains(_query) ||
                (o['items'] as List).join(' ').contains(_query));
      final matchesStatus = _statusFilter == 'الكل'
          ? true
          : (o['status'] == _statusFilter);

      bool matchesTime = true;
      if (_timeFilter != 'الكل') {
        final date = DateTime.tryParse(o['date'] ?? '') ?? now;
        final diff = now.difference(date).inDays;
        if (_timeFilter == 'الأسبوع') {
          matchesTime = diff <= 7;
        } else if (_timeFilter == 'الشهر') {
          matchesTime = diff <= 30;
        }
      }

      return matchesQuery && matchesStatus && matchesTime;
    }).toList();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم التحديث'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  double _progressForStep(int step) {
    // 0..3 -> 0.15, 0.5, 0.8, 1.0
    switch (step) {
      case 0:
        return 0.15;
      case 1:
        return 0.5;
      case 2:
        return 0.8;
      case 3:
        return 1.0;
      default:
        return 0.15;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Match product card background: white in light mode, 0xFF2A2A2A in dark mode
    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A2A)
        : Colors.white;

    final unfilteredCurrent = _allOrders
        .where((o) => (o['status']?.toString() ?? '') != 'تم التوصيل')
        .toList();
    final unfilteredPrevious = _allOrders
        .where((o) => (o['status']?.toString() ?? '') == 'تم التوصيل')
        .toList();
    final current = _filterList(unfilteredCurrent);
    final previous = _filterList(unfilteredPrevious);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ?? cardColor,
        title: Text(
          'طلباتي',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'الدعم',
            onPressed: () => _contactSupport(''),
            icon: const Icon(FontAwesomeIcons.headset, size: 18),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fade,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          edgeOffset: 8,
          child: ListView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: _SearchField(
                  controller: _searchCtrl,
                  hint: 'ابحث برقم الطلب أو المنتج',
                  onChanged: (v) => setState(() => _query = v.trim()),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
              const SizedBox(height: 12),

              // removed top status bars; status will be inside cards
              const SizedBox(height: 8),

              // View toggle: Current / Previous (use gradient ChipPill)
              Row(
                children: [
                  _ChipPill(
                    label: 'الطلبات الحالية',
                    selected: _viewMode == 'current',
                    onTap: () => setState(() => _viewMode = 'current'),
                  ),
                  _ChipPill(
                    label: 'الطلبات السابقة',
                    selected: _viewMode == 'previous',
                    onTap: () => setState(() => _viewMode = 'previous'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Show selected category (no extra title — filters above already indicate selection)
              if (_viewMode == 'current') ...[
                const SizedBox(height: 6),
                if (current.isEmpty)
                  const _EmptyBlock(
                    icon: FontAwesomeIcons.truckFast,
                    title: 'لا توجد طلبات قيد التنفيذ',
                    subtitle: 'ابدأ التسوق وسيظهر طلبك الحي هنا',
                  )
                else
                  for (final o in current)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: _LiveOrderCard(
                        order: o,
                        progress: _progressForStep((o['step'] as int?) ?? 0),
                        onTrack: _trackOrder,
                        onSupport: _contactSupport,
                        onCallDriver: _callDriver,
                        onReorder: _reorderItems,
                      ),
                    ),
              ] else ...[
                const SizedBox(height: 6),
                if (previous.isEmpty)
                  const _EmptyBlock(
                    icon: FontAwesomeIcons.clockRotateLeft,
                    title: 'لا توجد طلبات سابقة',
                    subtitle: 'ستظهر هنا جميع الطلبات المكتملة',
                  )
                else
                  for (final o in previous)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: _PastOrderTile(
                        order: o,
                        onReorder: _reorderItems,
                        onViewDetails: _openOrderDetails,
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ===== Actions =====

  void _trackOrder(String orderId) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(FontAwesomeIcons.locationDot, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text('فتح شاشة تتبُّع الطلب…')),
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
        content: const Row(
          children: [
            Icon(FontAwesomeIcons.headset, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text('سيتم تحويلك للدعم')),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _callDriver(String orderId) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(FontAwesomeIcons.phone, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text('جارٍ الاتصال بالسائق…')),
          ],
        ),
        backgroundColor: Colors.teal,
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
            const Icon(
              FontAwesomeIcons.cartShopping,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تمت إضافة منتجات ${order['id']} إلى السلة',
                style: const TextStyle(fontFamily: 'Rubik'),
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
          onPressed: () {},
        ),
      ),
    );
  }

  void _openOrderDetails(Map<String, dynamic> order) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(FontAwesomeIcons.receipt, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('فتح تفاصيل ${order['id']}')),
          ],
        ),
        backgroundColor: Colors.indigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ============= Widgets =============

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Let parent control width (we wrap _SearchField with padding where used)
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontSize: 12),
        prefixIcon: Icon(
          FontAwesomeIcons.magnifyingGlass,
          size: 16,
          color: scheme.onSurface.withOpacity(0.7),
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: Icon(
                  FontAwesomeIcons.xmark,
                  size: 16,
                  color: scheme.onSurface.withOpacity(0.7),
                ),
              ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.24)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.24)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.status,
    required this.time,
    required this.onStatus,
    required this.onTime,
  });

  final String status;
  final String time;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onTime;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ChipPill(
          label: 'الكل',
          selected: status == 'الكل',
          onTap: () => onStatus('الكل'),
        ),
        _ChipPill(
          label: 'قيد التحضير',
          selected: status == 'قيد التحضير',
          onTap: () => onStatus('قيد التحضير'),
        ),
        _ChipPill(
          label: 'قيد التوصيل',
          selected: status == 'قيد التوصيل',
          onTap: () => onStatus('قيد التوصيل'),
        ),
        _ChipPill(
          label: 'تم التوصيل',
          selected: status == 'تم التوصيل',
          onTap: () => onStatus('تم التوصيل'),
        ),
        const SizedBox(width: 4),
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outline.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: time,
              icon: Icon(
                FontAwesomeIcons.chevronDown,
                size: 12,
                color: scheme.onSurface.withOpacity(0.7),
              ),
              style: Theme.of(context).textTheme.bodySmall,
              items: const [
                DropdownMenuItem(value: 'الكل', child: Text('كل الفترات')),
                DropdownMenuItem(value: 'الأسبوع', child: Text('آخر أسبوع')),
                DropdownMenuItem(value: 'الشهر', child: Text('آخر شهر')),
              ],
              onChanged: (v) {
                if (v != null) onTime(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({required this.label, required this.selected, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = DesignSystem.getBrandGradient('primary');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: selected
            ? Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: DesignSystem.getBrandShadow('light'),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              )
            : Container(
                // Gradient outline: outer gradient with inner surface container
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: scheme.outline.withOpacity(0.2),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _LiveOrderCard extends StatelessWidget {
  const _LiveOrderCard({
    required this.order,
    required this.progress,
    required this.onTrack,
    required this.onSupport,
    required this.onCallDriver,
    required this.onReorder,
  });

  final Map<String, dynamic> order;
  final double progress;
  final void Function(String) onTrack;
  final void Function(String) onSupport;
  final void Function(String) onCallDriver;
  final void Function(Map<String, dynamic>) onReorder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Use same product card background here as well
    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A2A)
        : Colors.white;
    final color = (order['statusColor'] as Color?) ?? scheme.primary;
    final items = (order['items'] as List).cast<String>();
    final status = order['status']?.toString() ?? '';
    final id = order['id']?.toString() ?? '';
    final eta = order['eta']?.toString();
    // Prefer backend driver if present, otherwise show a realistic assigned mock
    final rawDriver =
        order['driver'] ?? order['driver_name'] ?? order['driverName'];
    String? driver = rawDriver?.toString();
    final rawVehicle = order['vehicle'];
    String? vehicle = rawVehicle?.toString();
    final String driverDisplay = (driver != null && driver.isNotEmpty)
        ? driver
        : 'سامي';
    final String vehicleDisplay = (vehicle != null && vehicle.isNotEmpty)
        ? vehicle
        : 'تويوتا هايلكس • 1234';

    final cardWidth = MediaQuery.of(context).size.width - 16; // slightly wider

    return Center(
      child: Container(
        width: cardWidth,
        constraints: const BoxConstraints(minHeight: 180),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: id + total + status chip
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'طلب رقم: $id',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Status chip: translate pending to Arabic and show gradient outline
                  Builder(
                    builder: (context) {
                      final statusRaw = status;
                      final statusLower = statusRaw.toLowerCase();
                      final isPending =
                          statusLower.contains('pending') ||
                          statusRaw.contains('قيد');
                      final displayStatus = isPending
                          ? 'قيد الانتظار'
                          : statusRaw;
                      if (isPending) {
                        final grad = DesignSystem.getBrandGradient('primary');
                        return Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            gradient: grad,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(10.5),
                              border: Border.all(color: Colors.transparent),
                            ),
                            child: Text(
                              displayStatus,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          displayStatus,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                items.take(2).join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 12),

              // Timeline with connected dots/lines + aligned labels
              _OrderTimeline(step: (order['step'] as int?) ?? 0, accent: color),
              const SizedBox(height: 10),

              // progress removed — keep slight spacing before driver row
              const SizedBox(height: 8),

              // Single row: driver info and buttons on same line; buttons slightly wider
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: DesignSystem.getBrandGradient('primary'),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        FontAwesomeIcons.motorcycle,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$driverDisplay • $vehicleDisplay',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Call (outlined) button — slightly wider
                  SizedBox(
                    width: 56,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: DesignSystem.getBrandGradient('primary'),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(1.5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onCallDriver(id),
                              borderRadius: BorderRadius.circular(8),
                              child: const Center(
                                child: Icon(
                                  FontAwesomeIcons.phone,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Track (filled) button — slightly wider
                  SizedBox(
                    width: 56,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: DesignSystem.getBrandGradient('primary'),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: DesignSystem.getBrandShadow('medium'),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onTrack(id),
                          borderRadius: BorderRadius.circular(10),
                          child: const Center(
                            child: Text(
                              'تتبُّع',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
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
    );
  }
}

/// Connected timeline: lines are drawn center-to-center between the four dots,
/// and labels are perfectly centered under each dot.
class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.step, required this.accent});
  final int step;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const labels = [
      'مراجعة\nالطلب',
      'تحضير\nالطلب',
      'جاري\nالتوصيل',
      'تم\nالتوصيل',
    ];

    const double dotSize = 18.0;
    const double stroke = 2.0;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final usable = width - dotSize;
          final segment = usable / 3.0;

          // centers for each dot
          final centers = List.generate(
            4,
            (i) => Offset(dotSize / 2 + (segment * i), dotSize / 2),
          );

          return Column(
            children: [
              SizedBox(
                height: dotSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // connectors
                    CustomPaint(
                      size: Size(width, dotSize),
                      painter: _ConnectorPainter(
                        step: step,
                        centers: centers,
                        accent: accent,
                        inactive: scheme.outline.withOpacity(0.3),
                        strokeWidth: stroke,
                      ),
                    ),
                    // dots on top of line — visual positions left->right, logical stages right->left
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (i) {
                        final stageIndex =
                            3 - i; // map visual position to logical stage
                        final done = stageIndex <= step;
                        return SizedBox(
                          width: dotSize,
                          height: dotSize,
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                DesignSystem.getBrandGradient(
                                  'primary',
                                ).createShader(bounds),
                            blendMode: BlendMode.srcIn,
                            child: _DotStep(
                              filled: done,
                              color: Colors.white,
                              size: dotSize,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // labels: position each label centered under its dot using the computed centers
              SizedBox(
                width: width,
                height: 40,
                child: Stack(
                  children: List.generate(4, (i) {
                    final labelWidth = segment + dotSize; // roomy label box
                    final left = centers[i].dx - (labelWidth / 2);
                    return Positioned(
                      left: left,
                      top: 0,
                      width: labelWidth,
                      child: Center(
                        child: Text(
                          labels[i],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 10,
                                color: scheme.onSurface.withOpacity(0.72),
                                height: 1.05,
                              ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({
    required this.step,
    required this.centers,
    required this.accent,
    required this.inactive,
    required this.strokeWidth,
  });

  final int step;
  final List<Offset> centers;
  final Color accent;
  final Color inactive;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paintActive = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = DesignSystem.getBrandGradient(
        'primary',
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paintInactive = Paint()
      ..color = inactive
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final from = centers[i];
      final to = centers[i + 1];
      // map visual connector index to logical connector: logical s = 2 - i
      // connector should be active when s < step -> equivalently i >= (3 - step)
      final isActive = i >= (3 - step);
      canvas.drawLine(from, to, isActive ? paintActive : paintInactive);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.step != step || old.accent != accent;
}

class _DotStep extends StatelessWidget {
  const _DotStep({required this.filled, required this.color, this.size = 12});
  final bool filled;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.transparent,
        border: filled ? null : Border.all(color: color, width: 2),
      ),
    );
  }
}

class _PastOrderTile extends StatelessWidget {
  const _PastOrderTile({
    required this.order,
    required this.onReorder,
    required this.onViewDetails,
  });

  final Map<String, dynamic> order;
  final void Function(Map<String, dynamic>) onReorder;
  final void Function(Map<String, dynamic>) onViewDetails;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = (order['items'] as List).cast<String>();
    final color = (order['statusColor'] as Color?) ?? scheme.primary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(FontAwesomeIcons.circleCheck, size: 18, color: color),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'طلب ${order['id']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(order['total'] as num).toStringAsFixed(2)} SAR',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${order['date']} • ${items.take(2).join(' • ')}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
      trailing: FilledButton.tonal(
        onPressed: () => onReorder(order),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('اطلب مجدداً'),
      ),
      onTap: () => onViewDetails(order),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 54, color: scheme.onSurface.withOpacity(0.18)),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
