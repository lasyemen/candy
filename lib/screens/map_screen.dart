// lib/screens/map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import '../core/constants/mapbox_constants.dart';
import '../core/constants/design_system.dart';
import '../core/services/customer_session.dart';
import '../core/services/supabase_service.dart';
import '../models/customer.dart';
import '../core/services/geocoding_service.dart';
import '../core/services/android_search_bridge.dart';

class FullMapScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final bool isEditing;
  const FullMapScreen({super.key, this.initialLat, this.initialLng, this.isEditing = false});

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  mb.MapboxMap? _mapboxMap;
  bool _saving = false;
  mb.PointAnnotationManager? _pointAnnotationManager;
  mb.PointAnnotation? _selectedAnnotation;
  mb.Position? _selectedPosition;
  Uint8List? _pinImageBytes;
  // Search state
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  // We’ll hold both searchbox and geocoder results in a common display model
  List<_UiSuggestion> _searchResults = const [];
  bool _searchLoading = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    mb.MapboxOptions.setAccessToken(MapboxConstants.accessToken);
  }

  void _onMapCreated(mb.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    // Prepare annotation manager
    _mapboxMap!.annotations.createPointAnnotationManager().then((manager) {
      _pointAnnotationManager = manager;
    });
    // Ensure camera is centered once the map is ready
    final initLng = widget.initialLng;
    final initLat = widget.initialLat;
    if (initLat != null && initLng != null) {
      // Center on provided coordinates and pre-place a pin
      final pos = mb.Position(initLng, initLat);
      _selectedPosition = pos;
      mapboxMap.setCamera(
        mb.CameraOptions(
          center: mb.Point(coordinates: pos),
          zoom: 16.0,
        ),
      );
      _placePinAt(pos);
    } else {
      mapboxMap.setCamera(
        mb.CameraOptions(
          center: mb.Point(coordinates: mb.Position(46.6753, 24.7136)),
          zoom: 12.0,
        ),
      );
    }

    // Move Mapbox scale bar down so it doesn't overlap the phone app bar
    try {
      final topInset = MediaQuery.of(context).padding.top;
      _mapboxMap?.scaleBar.updateSettings(
        mb.ScaleBarSettings(
          enabled: true,
          position: mb.OrnamentPosition.TOP_LEFT,
          marginTop: topInset + 12,
          marginLeft: 12,
        ),
      );
    } catch (_) {
      // Ignore if ornaments API is unavailable; not critical
    }

  // Ensure location puck is disabled (selection screen only)
    _mapboxMap?.location.updateSettings(
      mb.LocationComponentSettings(
    enabled: false,
    puckBearingEnabled: false,
    pulsingEnabled: false,
    showAccuracyRing: false,
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.surface,
      body: Stack(
        children: [
          mb.MapWidget(
            key: const ValueKey('full_map'),
            cameraOptions: mb.CameraOptions(
              center: mb.Point(
                coordinates: widget.initialLat != null && widget.initialLng != null
                    ? mb.Position(widget.initialLng!, widget.initialLat!)
                    : mb.Position(46.6753, 24.7136),
              ),
              zoom: widget.initialLat != null && widget.initialLng != null ? 16.0 : 10.0,
            ),
            styleUri: MapboxConstants.styleUri,
            onMapCreated: _onMapCreated,
            // Tap anywhere to place/move the pin
            onTapListener: (mb.MapContentGestureContext ctx) async {
              final pos = ctx.point.coordinates;
              _selectedPosition = pos;
              await _placePinAt(pos);
            },
          ),

          // Top bar: title + search in the same line
          Positioned(
            top: 36,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.38),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'تحديد الموقع',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Material(
                      color: Colors.white,
                      elevation: 2,
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.black54),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                focusNode: _searchFocus,
                                textDirection: TextDirection.rtl,
                                decoration: const InputDecoration(
                                  hintText: 'ابحث عن شارع أو مكان...',
                                  border: InputBorder.none,
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            ),
                            if (_searchLoading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            if (_searchLoading) const SizedBox(width: 8),
                            if (_searchCtrl.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: _clearSearch,
                              )
                          ],
                        ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search suggestions dropdown
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 88,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Material(
                  color: Colors.white,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final r = _searchResults[index];
                        return ListTile(
                          dense: true,
                          title: Text(r.title, textDirection: TextDirection.rtl),
                          subtitle: r.subtitle != null
                              ? Text(
                                  r.subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: TextDirection.rtl,
                                )
                              : null,
                          onTap: () => _onSuggestionTap(r),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

          // Note: No centered overlay pin; we use a map annotation anchored to coordinates

          // Save button (bottom full-width, gradient)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
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
                onPressed: _saving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                          strokeWidth: 2.2,
                        ),
                      )
                    : Text(
                        widget.isEditing ? 'تحديث الموقع' : 'حفظ الموقع',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ),

          // Delete address button (visible in edit mode)
          if (widget.isEditing && CustomerSession.instance.isLoggedIn)
            Positioned(
              left: 16,
              bottom: 92,
              child: SafeArea(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  onPressed: _handleDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('حذف العنوان'),
                ),
              ),
            ),

          // No extra buttons; tap anywhere to drop the pin
        ],
      ),
    );
  }

  // Center camera helper removed (not used with tap-to-drop)

  Future<void> _handleSave() async {
    if (_mapboxMap == null) return;
    try {
      setState(() => _saving = true);
      final pos =
          _selectedPosition ??
          (await _mapboxMap!.getCameraState()).center.coordinates;
  final double lat = pos.lat.toDouble();
  final double lng = pos.lng.toDouble();
    // If user is logged in, persist to customers table
      if (CustomerSession.instance.isLoggedIn) {
        // Resolve customer ID; if missing, fetch by phone
        String? id = CustomerSession.instance.currentCustomerId;
        // Fallback 1: Supabase auth user id
        try {
          id ??= SupabaseService.instance.client.auth.currentUser?.id;
        } catch (_) {}
        if (id == null) {
          final phone = CustomerSession.instance.currentCustomerPhone;
          if (phone != null && phone.isNotEmpty) {
            try {
              final row = await SupabaseService.instance.client
                  .from('customers')
                  .select('id')
                  .eq('phone', phone)
                  .maybeSingle();
              if (row != null) id = row['id'] as String;
            } catch (_) {}
          }
        }

        if (id != null) {
          // Try to resolve a readable Arabic address (street, area)
          String? addressAr;
          try {
            addressAr = await GeocodingService.instance
                .reverseGeocode(lat, lng, language: 'ar');
          } catch (_) {
            // Geocoding failure shouldn't block saving location
            addressAr = null;
          }

          // Prefer update by id; if 0 rows, try update by phone; otherwise insert
          final payload = <String, dynamic>{
            'lat': lat,
            'lng': lng,
            'updated_at': DateTime.now().toIso8601String(),
          };
          if (addressAr != null && addressAr.isNotEmpty) {
            payload['address'] = addressAr;
          }

          Map<String, dynamic>? updatedRow;
          try {
            final response = await SupabaseService.instance.client
                .from('customers')
                .update(payload)
                .eq('id', id)
                .select()
                .maybeSingle();
            if (response != null) {
              updatedRow = response;
            } else {
              // Try update by phone as a fallback
              final phone = CustomerSession.instance.currentCustomerPhone;
              if (phone != null && phone.isNotEmpty) {
                final resp2 = await SupabaseService.instance.client
                    .from('customers')
                    .update(payload)
                    .eq('phone', phone)
                    .select()
                    .maybeSingle();
                if (resp2 != null) {
                  updatedRow = resp2;
                }
              }
            }
          } catch (_) {}
          if (updatedRow == null) {
            // Insert (id + payload) as a last resort
            final insertData = {
              'id': id,
              ...payload,
            };
            updatedRow = await SupabaseService.instance.client
                .from('customers')
                .insert(insertData)
                .select()
                .single();
          }

          // Verify persisted values with tolerance
          final savedLat = (updatedRow['lat'] as num?)?.toDouble();
          final savedLng = (updatedRow['lng'] as num?)?.toDouble();
          bool persisted = false;
          if (savedLat != null && savedLng != null) {
            persisted = (savedLat - lat).abs() < 1e-6 && (savedLng - lng).abs() < 1e-6;
          }
          if (!persisted) {
            throw Exception('لم يتم تحديث الموقع في قاعدة البيانات');
          }

          // Update local session model
          final current = CustomerSession.instance.currentCustomer;
          if (current != null) {
            await CustomerSession.instance.setCurrentCustomer(
              Customer(
                id: current.id,
                name: current.name,
                phone: current.phone,
                address: (addressAr != null && addressAr.isNotEmpty)
                    ? addressAr
                    : current.address,
                avatar: current.avatar,
                isActive: current.isActive,
                lastLogin: current.lastLogin,
                totalSpent: current.totalSpent,
                ordersCount: current.ordersCount,
                rating: current.rating,
                lat: lat,
                lng: lng,
                createdAt: current.createdAt,
                updatedAt: DateTime.now(),
              ),
            );
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.isEditing ? 'تم تحديث الموقع بنجاح' : 'تم حفظ الموقع بنجاح',
                ),
              ),
            );
          }
        } else {
          throw Exception('مطلوب تسجيل الدخول لحفظ الموقع');
        }
      } else {
        // Guest user: just inform and return coords
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديد الموقع')),
          );
        }
      }
      if (!mounted) return;
      // Give the user a brief moment to see the snackbar
      await Future.delayed(const Duration(milliseconds: 600));
      Navigator.of(context).pop({'lat': lat, 'lng': lng});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
  ).showSnackBar(SnackBar(content: Text(widget.isEditing ? 'تعذر تحديث الموقع: $e' : 'تعذر حفظ الموقع: $e')));
    }
    finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleDelete() async {
    try {
      final current = CustomerSession.instance.currentCustomer;
      if (current == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مطلوب تسجيل الدخول')), 
        );
        return;
      }
      // Update DB: set address and coords to null
  await SupabaseService.instance.client
          .from('customers')
          .update({
            'address': null,
            'lat': null,
            'lng': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', current.id)
          .select()
          .maybeSingle();

      // Update session model
      await CustomerSession.instance.setCurrentCustomer(
        Customer(
          id: current.id,
          name: current.name,
          phone: current.phone,
          address: null,
          avatar: current.avatar,
          isActive: current.isActive,
          lastLogin: current.lastLogin,
          totalSpent: current.totalSpent,
          ordersCount: current.ordersCount,
          rating: current.rating,
          lat: null,
          lng: null,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
        ),
      );

      // Remove pin from map if shown
      if (_selectedAnnotation != null && _pointAnnotationManager != null) {
        await _pointAnnotationManager!.delete(_selectedAnnotation!);
        _selectedAnnotation = null;
        _selectedPosition = null;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف العنوان')),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pop({'deleted': true});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حذف العنوان: $e')),
      );
    }
  }

  // ignore: unused_element
  Future<void> _placePinAt(mb.Position pos) async {
    if (_mapboxMap == null) return;
    // Ensure we have an annotation manager
    _pointAnnotationManager ??= await _mapboxMap!.annotations
        .createPointAnnotationManager();
    // Load pin image once
    // Remove old annotation
    if (_selectedAnnotation != null) {
      await _pointAnnotationManager!.delete(_selectedAnnotation!);
      _selectedAnnotation = null;
    }
    // Ensure we have pin image bytes (custom drawn red pin)
    _pinImageBytes ??= await _buildRedPinBytes();
    // Create new annotation at the provided position using the custom red pin
  _selectedAnnotation = await _pointAnnotationManager!.create(
      mb.PointAnnotationOptions(
        geometry: mb.Point(coordinates: pos),
        image: _pinImageBytes!,
        iconAnchor: mb.IconAnchor.BOTTOM,
    iconSize: 1.8,
      ),
    );
  }

  Future<Uint8List> _buildRedPinBytes({double size = 128}) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));
    final red = Paint()..color = const Color(0xFFE53935);
    final white = Paint()..color = Colors.white;

    final cx = size / 2;
    final cy = size * 0.38;
    final r = size * 0.22;

    // Draw head
    canvas.drawCircle(Offset(cx, cy), r, red);
    // Draw tail
    final tail = Path()
      ..moveTo(cx, size * 0.92)
      ..lineTo(cx - r * 0.75, cy + r * 0.75)
      ..lineTo(cx + r * 0.75, cy + r * 0.75)
      ..close();
    canvas.drawPath(tail, red);
    // Inner dot
    canvas.drawCircle(Offset(cx, cy), r * 0.45, white);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final q = value.trim();
      if (q.isEmpty) {
        setState(() => _searchResults = const []);
        return;
      }
      setState(() => _searchLoading = true);
      // Use proximity for better local relevance
      double? proxLat;
      double? proxLng;
      try {
        if (_selectedPosition != null) {
          proxLat = _selectedPosition!.lat.toDouble();
          proxLng = _selectedPosition!.lng.toDouble();
        } else if (_mapboxMap != null) {
          final center = (await _mapboxMap!.getCameraState()).center.coordinates;
          proxLat = center.lat.toDouble();
          proxLng = center.lng.toDouble();
        }
      } catch (_) {}
      // Prefer Android native Search SDK if available
      List<_UiSuggestion> ui;
      if (AndroidSearchBridge.isAvailable) {
        final native = await AndroidSearchBridge.suggest(q);
        if (native.isNotEmpty) {
          ui = native
              .map((m) => _UiSuggestion.searchbox(
                    mapboxId: (m['mapboxId'] as String?) ?? (m['id'] as String? ?? ''),
                    title: (m['name'] as String?) ?? '',
                    subtitle: (m['formattedAddress'] as String?),
                  ))
              .toList(growable: false);
        } else {
          // Fallback to Search Box HTTP suggest
          final suggest = await GeocodingService.instance.searchboxSuggest(
            q,
            language: 'ar',
            limit: 8,
            proximityLat: proxLat,
            proximityLng: proxLng,
          );
          if (suggest.isNotEmpty) {
            ui = suggest
                .map((s) => _UiSuggestion.searchbox(mapboxId: s.mapboxId, title: s.name, subtitle: s.description))
                .toList(growable: false);
          } else {
            final results = await GeocodingService.instance.forwardGeocode(
              q,
              language: 'ar',
              limit: 8,
              proximityLat: proxLat,
              proximityLng: proxLng,
            );
            ui = results
                .map((g) => _UiSuggestion.geocoder(title: g.name, subtitle: g.placeName, lat: g.lat, lng: g.lng))
                .toList(growable: false);
          }
        }
      } else {
        // Non-Android: use HTTP Search Box suggest, then geocoder
        final suggest = await GeocodingService.instance.searchboxSuggest(
          q,
          language: 'ar',
          limit: 8,
          proximityLat: proxLat,
          proximityLng: proxLng,
        );
        if (suggest.isNotEmpty) {
          ui = suggest
              .map((s) => _UiSuggestion.searchbox(mapboxId: s.mapboxId, title: s.name, subtitle: s.description))
              .toList(growable: false);
        } else {
          final results = await GeocodingService.instance.forwardGeocode(
            q,
            language: 'ar',
            limit: 8,
            proximityLat: proxLat,
            proximityLng: proxLng,
          );
          ui = results
              .map((g) => _UiSuggestion.geocoder(title: g.name, subtitle: g.placeName, lat: g.lat, lng: g.lng))
              .toList(growable: false);
        }
      }
      if (!mounted) return;
      setState(() {
        _searchResults = ui;
        _searchLoading = false;
      });
    });
  }

  void _clearSearch() {
    setState(() {
      _searchCtrl.clear();
      _searchResults = const [];
    });
  }

  Future<void> _onSuggestionTap(_UiSuggestion s) async {
    _clearSearch();
    if (s.kind == _UiKind.searchbox && s.mapboxId != null) {
      final res = await GeocodingService.instance.searchboxRetrieve(
        s.mapboxId!,
        language: 'ar',
      );
      if (res == null) return;
      final pos = mb.Position(res.lng, res.lat);
      _selectedPosition = pos;
      await _placePinAt(pos);
      await _mapboxMap?.setCamera(mb.CameraOptions(
        center: mb.Point(coordinates: pos),
        zoom: 16.0,
      ));
      return;
    }
    if (s.kind == _UiKind.geocoder && s.lat != null && s.lng != null) {
      final pos = mb.Position(s.lng!, s.lat!);
      _selectedPosition = pos;
      await _placePinAt(pos);
      await _mapboxMap?.setCamera(mb.CameraOptions(
        center: mb.Point(coordinates: pos),
        zoom: 16.0,
      ));
    }
  }

}

enum _UiKind { searchbox, geocoder }

class _UiSuggestion {
  final _UiKind kind;
  final String title;
  final String? subtitle;
  final String? mapboxId;
  final double? lat;
  final double? lng;
  const _UiSuggestion._({
    required this.kind,
    required this.title,
    this.subtitle,
    this.mapboxId,
    this.lat,
    this.lng,
  });
  factory _UiSuggestion.searchbox({
    required String mapboxId,
    required String title,
    String? subtitle,
  }) => _UiSuggestion._(kind: _UiKind.searchbox, mapboxId: mapboxId, title: title, subtitle: subtitle);
  factory _UiSuggestion.geocoder({
    required String title,
    required String subtitle,
    required double lat,
    required double lng,
  }) => _UiSuggestion._(kind: _UiKind.geocoder, title: title, subtitle: subtitle, lat: lat, lng: lng);
}

// (Center pin overlay removed; we use map annotations instead)
