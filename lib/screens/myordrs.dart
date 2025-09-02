// lib/screens/myordrs.dart
library my_orders_screen;

import '../core/routes/app_routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../core/services/supabase_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/constants/design_system.dart';
import 'package:provider/provider.dart';
import '../core/services/app_settings.dart';
import '../core/constants/translations.dart';
part 'functions/myordrs.functions.dart';

// Map order status (enum/text) to a 0..3 step index for the timeline
int _stepForStatus(String statusRaw) {
  final s = statusRaw.toLowerCase();
  if (s == 'delivery_done' || s.contains('تم التوصيل') || s.contains('delivered')) return 3;
  if (s == 'delivering' || s.contains('التوصيل') || s.contains('out_for_delivery')) return 2;
  if (s == 'choose_delivery_captain' || s.contains('اختيار') || s.contains('driver')) return 1;
  if (s == 'review_order' || s.contains('review') || s.contains('مراجعة')) return 0;
  if (s == 'accept' || s.contains('accept') || s.contains('قبول')) return 0;
  return 0;
}

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
  // ignore: unused_field
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

    // attempt to extract driver phone from multiple possible shapes
    dynamic _driverPhoneRaw =
      r['driver_phone'] ??
      r['driverPhone'] ??
      r['driver_mobile'] ??
      r['driverMobile'] ??
      r['driver_number'] ??
      r['driverNumber'] ??
      r['phone'] ??
      r['phone_number'] ??
      r['phoneNumber'] ??
      r['mobile'] ??
      r['mobile_number'] ??
      r['mobileNumber'] ??
      r['contact_phone'] ??
      r['contactPhone'] ??
      r['contact_number'] ??
      r['contactNumber'] ??
      r['driver_phone_no'] ??
      r['driverPhoneNo'] ??
      r['driver_phone_number'] ??
      r['driverPhoneNumber'] ??
      r['driver_contact'] ??
      r['driverContact'];
        String? _driverPhoneVal;
  if (_driverPhoneRaw == null && _driverRaw is Map) {
    final m = _driverRaw;
    _driverPhoneVal = (m['phone'] ??
      m['phone_number'] ??
      m['phoneNumber'] ??
      m['mobile'] ??
      m['mobile_number'] ??
      m['mobileNumber'] ??
      m['contact_phone'] ??
      m['contactPhone'] ??
      m['number'] ??
      m['driver_phone'] ??
      m['driverPhone'] ??
      m['driver_mobile'] ??
      m['driverMobile'])
        ?.toString();
        } else if (_driverPhoneRaw != null) {
          _driverPhoneVal = _driverPhoneRaw.toString();
        }
        if (_driverPhoneVal != null && _driverPhoneVal.trim().isEmpty) {
          _driverPhoneVal = null;
        }
        // Fallback: extract any phone-like pattern from available text fields
        if (_driverPhoneVal == null) {
          String concat = '';
          void addText(dynamic v) {
            if (v == null) return;
            final s = v.toString().trim();
            if (s.isNotEmpty) concat += ' $s';
          }
          addText(r['driver']);
          addText(r['driver_name']);
          addText(r['driverName']);
          addText(r['notes']);
          addText(r['description']);
          // If nested driver map, add its fields
          if (_driverRaw is Map) {
            addText(_driverRaw['phone']);
            addText(_driverRaw['mobile']);
            addText(_driverRaw['number']);
            addText(_driverRaw['contact']);
          }
          // Regex: match +966 XX XXX XXXX, 05XXXXXXXX, or 9-12 digit sequences
          final reg = RegExp(r'(?:\+?966\s?\d{1,2}\s?\d{3}\s?\d{4}|05\d{8}|\d{9,12})');
          final m = reg.firstMatch(concat);
          if (m != null) {
            _driverPhoneVal = m.group(0);
          }
        }
  // Debug: surface detected driver phone for first few rows
  // ignore: avoid_print
  print('MyOrdersScreen - parsed driverPhone: \\u200E${_driverPhoneVal ?? '(none)'}');

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
          'driverPhone': _driverPhoneVal,
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
    // final scheme = Theme.of(context).colorScheme; // not needed at this scope
    // Match product card background: white in light mode, 0xFF2A2A2A in dark mode
    final cardColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A2A)
        : Colors.white;

    // Use enum values when present; fallback to Arabic/English strings for legacy rows
    bool isDelivered(Map<String, dynamic> o) {
      final s = (o['status']?.toString() ?? '').toLowerCase();
      return s == 'delivery_done' || s == 'تم التوصيل' || s == 'delivered';
    }
    final unfilteredCurrent = _allOrders.where((o) => !isDelivered(o)).toList();
    final unfilteredPrevious = _allOrders.where(isDelivered).toList();
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
            padding: EdgeInsets.fromLTRB(
              8,
              12,
              8,
              20 +
                  MediaQuery.of(context).viewPadding.bottom +
                  kBottomNavigationBarHeight,
            ),
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
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
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
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
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
    // TODO: Pass userLat/userLng if available from order address
    AppRoutes.navigateTo(
      context,
      AppRoutes.orderTracking,
      arguments: {'orderId': orderId},
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchFillColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF0F0F0);
    final searchIconColor = isDark
        ? scheme.onSurface.withOpacity(0.7)
        : Colors.black;
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
          color: searchIconColor,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: Icon(
                  FontAwesomeIcons.xmark,
                  size: 16,
                  color: searchIconColor,
                ),
              ),
        filled: true,
        fillColor: searchFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none, // remove grey outline when enabled
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: scheme.primary),
        ),
      ),
    );
  }
}

// ignore: unused_element
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
          label: 'اختيار موصل',
          selected: status == 'اختيار موصل',
          onTap: () => onStatus('اختيار موصل'),
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
    // When a chip is not selected, show a white inner surface while keeping the
    // gradient outline intact.
    final innerColor = Colors.white;

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
                  // reduce padding so gradient outline appears thinner
                  padding: const EdgeInsets.all(1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: innerColor,
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(
                        color: scheme.outline.withOpacity(0.18),
                        width: 1,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    // stronger shadow in light mode for order cards
    final cardShadows = isDark
        ? [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];
    final color = (order['statusColor'] as Color?) ?? scheme.primary;
    final items = (order['items'] as List).cast<String>();
    final status = order['status']?.toString() ?? '';
    final id = order['id']?.toString() ?? '';
    // final eta = order['eta']?.toString();
    // Prefer backend driver if present, otherwise show a realistic assigned mock
    final rawDriver =
        order['driver'] ?? order['driver_name'] ?? order['driverName'];
    String? driver = rawDriver?.toString();
  // vehicle omitted in the compact driver layout
    final String driverDisplay = (driver != null && driver.isNotEmpty)
        ? driver
        : 'سامي';
  // vehicle not shown in the new compact layout

    final cardWidth =
        double.infinity; // fill available width to match nav bar margins

    return Center(
      child: Container(
        width: cardWidth,
        // increase the minimum height slightly for breathing room
        constraints: const BoxConstraints(minHeight: 140),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: cardShadows,
        ),
        child: Padding(
          // slightly larger vertical padding
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                      final s = statusRaw.toString().toLowerCase();
                      // Map enum -> translation keys
                      String key;
                      if (s == 'accept' || s == 'accepted' || s == 'قبول') {
                        key = 'status_accept';
                      } else if (s == 'review_order' || s.contains('review') || s.contains('مراجعة')) {
                        key = 'status_review_order';
                      } else if (s == 'choose_delivery_captain' || s.contains('choose') || s.contains('driver') || s.contains('اختيار')) {
                        key = 'status_choose_delivery_captain';
                      } else if (s == 'delivering' || s.contains('delivery') || s.contains('التوصيل')) {
                        key = 'status_delivering';
                      } else if (s == 'delivery_done' || s.contains('delivered') || s.contains('تم التوصيل')) {
                        key = 'status_delivery_done';
                      } else if (s.contains('pending') || statusRaw.contains('قيد')) {
                        key = 'status_pending';
                      } else {
                        key = 'status_unknown';
                      }
            final lang = Provider.of<AppSettings>(context, listen: false).currentLanguage;
            final displayStatus = AppTranslations.getText(key, lang);
            final isPending = (key == 'status_pending');
            const red = Color(0xFFEF4444);
            return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
              color: isPending ? cardColor : color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: isPending ? Border.all(color: red, width: 1.5) : null,
                        ),
                        child: Text(
                          displayStatus,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                color: isPending ? red : color,
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
              _OrderTimeline(step: _stepForStatus((order['status']?.toString() ?? '')), accent: color),
              // spacing between timeline and driver row
              const SizedBox(height: 10),

              // Single row: driver info and buttons on same line; buttons slightly wider
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: DesignSystem.getBrandGradient('primary'),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        FontAwesomeIcons.motorcycle,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          driverDisplay,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Builder(builder: (context) {
                          final dp = (order['driverPhone']?.toString() ?? '').trim();
                          final phoneToShow = dp.isEmpty ? '+966 55 123 4567' : dp;
                          return Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              phoneToShow,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurface.withOpacity(0.7),
                                  ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Call button — filled green, taller, no shadow
                  SizedBox(
                    width: 64,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981), // green
                        borderRadius: BorderRadius.circular(12),
                        // intentionally no shadow
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onCallDriver(id),
                          borderRadius: BorderRadius.circular(12),
                          child: const Center(
                            child: Icon(
                              FontAwesomeIcons.phone,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Track (filled gradient) button — same width, taller
                  SizedBox(
                    width: 64,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: DesignSystem.getBrandGradient('primary'),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: DesignSystem.getBrandShadow('medium'),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onTrack(id),
                          borderRadius: BorderRadius.circular(12),
                          child: const Center(
                            child: Text(
                              'تتبُّع',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
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
// Make sure you have: import 'dart:math' as math;

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.step, required this.accent});
  final int step;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const labels = [
      'مراجعة\nالطلب',
  'اختيار\nموصل',
      'جاري\nالتوصيل',
      'تم\nالتوصيل',
    ];

    const double dotSize = 18.0;
    const double stroke = 1.6;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const double horizontalPadding =
              30.0; // padding from left/right edges
          final usable = width - dotSize - (horizontalPadding * 2);
          final segment = usable / 3.0;

          // centers for each dot (visual order: left -> right) with padding
          final centers = List.generate(4, (i) {
            return Offset(
              horizontalPadding + (dotSize / 2) + (segment * i),
              dotSize / 2,
            );
          });

          return Column(
            children: [
              SizedBox(
                height: dotSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // connectors (shorter stretch but still visually connected to dots)
                    CustomPaint(
                      size: Size(width, dotSize),
                      painter: _ConnectorPainter(
                        step: step,
                        centers: centers,
                        accent: accent,
                        inactive: scheme.outline.withOpacity(0.3),
                        strokeWidth: stroke,
                        dotRadius: dotSize / 2,
                        shorten:
                            14.0, // total middle reduction between two dots
                        underlap:
                            6.0, // increase underlap so the short connectors still tuck under the dots
                      ),
                    ),
                    // dots on top - position dots at the exact connector centers so
                    // they always align with the painted connectors and move together
                    for (int i = 0; i < 4; i++)
                      Positioned(
                        left: centers[i].dx - (dotSize / 2),
                        top: 0,
                        width: dotSize,
                        height: dotSize,
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              DesignSystem.getBrandGradient(
                                'primary',
                              ).createShader(bounds),
                          blendMode: BlendMode.srcIn,
                          child: _DotStep(
                            filled: (3 - i) <= step,
                            color: Colors.white,
                            size: dotSize,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // labels centered under each dot
              SizedBox(
                width: width,
                height: 56,
                child: Stack(
                  children: List.generate(4, (i) {
                    final labelIndex = 3 - i; // map to logical label
                    const double labelWidth = 84.0;
                    var left = centers[i].dx - (labelWidth / 2);
                    left = left.clamp(0.0, width - labelWidth);
                    return Positioned(
                      left: left,
                      top: 0,
                      width: labelWidth,
                      child: Center(
                        child: Text(
                          labels[labelIndex],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.visible,
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
    this.dotRadius = 0,
    this.shorten = 8.0, // total reduction per segment
    this.underlap =
        2.0, // how much the line hides under the dots (keeps connection feeling)
  });

  final int step;
  final List<Offset> centers;
  final Color accent;
  final Color inactive;
  final double strokeWidth;
  final double dotRadius;

  /// Total amount to reduce the visible line between two dots.
  final double shorten;

  /// Positive value means the line goes slightly under the dot, so it still looks connected.
  final double underlap;

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

    // base edge position (edge of dot, accounting for stroke so it doesn't peek out)
    final edgeGap = dotRadius - (strokeWidth / 2);

    // we want a small underlap under each dot (keeps visual connection)
    final edgeWithUnderlap = (edgeGap - underlap).clamp(0.0, edgeGap);

    for (int i = 0; i < 3; i++) {
      final from = centers[i];
      final to = centers[i + 1];

      final angle = (to - from).direction;

      // start/end near the dot edge, slightly under the dot
      var p1 =
          from +
          Offset(
            math.cos(angle) * edgeWithUnderlap,
            math.sin(angle) * edgeWithUnderlap,
          );
      var p2 =
          to -
          Offset(
            math.cos(angle) * edgeWithUnderlap,
            math.sin(angle) * edgeWithUnderlap,
          );

      // now shorten the visible span in the middle, but keep underlap so it still feels connected
      final halfShorten = shorten / 2;
      final midShift = Offset(
        math.cos(angle) * halfShorten,
        math.sin(angle) * halfShorten,
      );
      p1 = p1 + midShift;
      p2 = p2 - midShift;

      final isActive = i >= (3 - step);
      canvas.drawLine(p1, p2, isActive ? paintActive : paintInactive);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.step != step ||
      old.accent != accent ||
      old.strokeWidth != strokeWidth ||
      old.shorten != shorten ||
      old.underlap != underlap;
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
            '${((order['total'] as num?) ?? 0).toStringAsFixed(2)} SAR',
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
