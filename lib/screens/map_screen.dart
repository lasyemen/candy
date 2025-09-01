// lib/screens/map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:geolocator/geolocator.dart';
import '../core/constants/mapbox_constants.dart';
import '../core/constants/design_system.dart';
import '../core/services/customer_session.dart';
import '../core/services/supabase_service.dart';
import '../models/customer.dart';

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
  bool _locating = false;
  bool _saving = false;
  mb.PointAnnotationManager? _pointAnnotationManager;
  mb.PointAnnotation? _selectedAnnotation;
  mb.Position? _selectedPosition;
  Uint8List? _pinImageBytes;

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
  void dispose() {
    super.dispose();
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
          ),

          // Title overlay (top-center), semi-transparent grey container
          Positioned(
            top: 36,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
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
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Note: No centered overlay pin; we use a map annotation anchored to coordinates

      // Locate-me button (bottom-right, above save)
          Positioned(
            right: 16,
            bottom: 92, // save button (52) + 24 margin + 16 gap
            child: SafeArea(
              child: _LocateButton(
        locating: _locating,
        onPressed: _handleLocateOnce,
              ),
            ),
          ),

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
        ],
      ),
    );
  }

  Future<void> _handleLocateOnce() async {
    if (_mapboxMap == null) return;
    setState(() => _locating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        await Geolocator.openAppSettings();
        throw Exception('تم رفض إذن الموقع');
      }

      // Ensure device location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        throw Exception('خدمة الموقع غير مفعلة');
      }

      // One-shot current position, center map only (no puck)
  final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
        ),
      );
  // Update selected position and place a red pin annotation at user's location
  _selectedPosition = mb.Position(pos.longitude, pos.latitude);
  await _placePinAt(_selectedPosition!);
  await _centerCamera(pos.longitude, pos.latitude, zoom: 16.0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تعذّر تحديد الموقع: $e')));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _centerCamera(double lng, double lat, {double? zoom}) async {
    if (_mapboxMap == null) return;
    await _mapboxMap!.setCamera(
      mb.CameraOptions(
        center: mb.Point(coordinates: mb.Position(lng, lat)),
        zoom: zoom,
      ),
    );
  }

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
        final id = CustomerSession.instance.currentCustomerId;
        if (id != null) {
          await SupabaseService.instance.updateData(
            'customers',
            id,
            {
              'lat': lat,
              'lng': lng,
              'updated_at': DateTime.now().toIso8601String(),
            },
          );
          // Verify persisted values
          final updatedRow =
              await SupabaseService.instance.fetchById('customers', id);
          final savedLat = (updatedRow?['lat'] as num?)?.toDouble();
          final savedLng = (updatedRow?['lng'] as num?)?.toDouble();
          final persisted = savedLat == lat && savedLng == lng;
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
                address: current.address,
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
        SnackBar(content: Text(widget.isEditing ? 'تم تحديث الموقع بنجاح' : 'تم حفظ الموقع بنجاح')),
            );
          }
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
        iconSize: 1.4,
      ),
    );
  }

  Future<Uint8List> _buildRedPinBytes({double size = 96}) async {
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
}

class _LocateButton extends StatelessWidget {
  final bool locating;
  final VoidCallback onPressed;
  const _LocateButton({required this.locating, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: locating ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: locating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.my_location,
                  size: 22,
                  color: Colors.black87,
                ),
        ),
      ),
    );
  }
}

// (Center pin overlay removed; we use map annotations instead)
