import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/design_system.dart';
import '../core/constants/mapbox_constants.dart';
import '../core/services/supabase_service.dart';

class LiveOrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final double? userLat;
  final double? userLng;
  const LiveOrderTrackingScreen({
    super.key,
    required this.orderId,
    this.userLat,
    this.userLng,
  });

  @override
  State<LiveOrderTrackingScreen> createState() =>
      _LiveOrderTrackingScreenState();
}

class _LiveOrderTrackingScreenState extends State<LiveOrderTrackingScreen> {
  mb.MapboxMap? _map;
  mb.PointAnnotationManager? _annManager;
  mb.PointAnnotation? _driverAnn;
  // ignore: unused_field
  mb.PointAnnotation? _userAnn;
  Uint8List? _driverIcon;
  Uint8List? _userIcon;

  RealtimeChannel? _channel;
  Timer? _pollTimer;
  double? _driverLat, _driverLng;

  @override
  void initState() {
    super.initState();
    mb.MapboxOptions.setAccessToken(MapboxConstants.accessToken);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _onMapCreated(mb.MapboxMap map) async {
    _map = map;
    _annManager = await map.annotations.createPointAnnotationManager();
    _driverIcon ??= await _buildDriverIcon();
    _userIcon ??= await _buildUserIcon();

    // Add user destination pin if provided
    if (widget.userLat != null && widget.userLng != null) {
      _userAnn = await _annManager!.create(
        mb.PointAnnotationOptions(
          geometry: mb.Point(
            coordinates: mb.Position(widget.userLng!, widget.userLat!),
          ),
          image: _userIcon!,
          iconAnchor: mb.IconAnchor.BOTTOM,
          iconSize: 1.2,
        ),
      );
    }

    // Style ornaments: move scale bar below system bar
    try {
      final inset = MediaQuery.of(context).padding.top;
      await _map?.scaleBar.updateSettings(
        mb.ScaleBarSettings(
          enabled: true,
          position: mb.OrnamentPosition.TOP_LEFT,
          marginTop: inset + 12,
          marginLeft: 12,
        ),
      );
    } catch (_) {}

    await _loadInitialDriver();
    _subscribeRealtime();
    _startPollingFallback();
  }

  Future<void> _loadInitialDriver() async {
    try {
      final res = await SupabaseService.instance.client
          .from('driver_locations')
          .select('lat,lng,heading,updated_at')
          .eq('order_id', widget.orderId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (res != null) {
        final lat = (res['lat'] as num).toDouble();
        final lng = (res['lng'] as num).toDouble();
        final heading = (res['heading'] as num?)?.toDouble();
        await _updateDriver(
          lat,
          lng,
          heading: heading,
          centerCamera: true,
          zoom: 14.5,
        );
      }
    } catch (_) {
      // ignore — table may not exist yet
    }
  }

  void _subscribeRealtime() {
    try {
      final client = SupabaseService.instance.client;
      _channel =
          client.channel('public:driver_locations:order:${widget.orderId}')
            ..onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'driver_locations',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'order_id',
                value: widget.orderId,
              ),
              callback: (payload) {
                final row = payload.newRecord;
                _handleRealtimeRow(row);
              },
            )
            ..onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'driver_locations',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'order_id',
                value: widget.orderId,
              ),
              callback: (payload) {
                final row = payload.newRecord;
                _handleRealtimeRow(row);
              },
            )
            ..subscribe();
    } catch (_) {
      // ignore — fallback polling will handle updates
    }
  }

  void _startPollingFallback() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      try {
        final res = await SupabaseService.instance.client
            .from('driver_locations')
            .select('lat,lng,heading,updated_at')
            .eq('order_id', widget.orderId)
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (res != null) {
          _handleRealtimeRow(res);
        }
      } catch (_) {}
    });
  }

  Future<void> _handleRealtimeRow(Map<String, dynamic> row) async {
    try {
      final lat = (row['lat'] as num?)?.toDouble();
      final lng = (row['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      final heading = (row['heading'] as num?)?.toDouble();
      await _updateDriver(lat, lng, heading: heading);
    } catch (_) {}
  }

  Future<void> _updateDriver(
    double lat,
    double lng, {
    double? heading,
    bool centerCamera = true,
    double? zoom,
  }) async {
    if (_map == null || _annManager == null) return;
    if (_driverIcon == null) _driverIcon = await _buildDriverIcon();

    // Save for recenter button
    _driverLat = lat;
    _driverLng = lng;

    // Recreate driver annotation (simple & compatible across SDK versions)
    if (_driverAnn != null) {
      try {
        await _annManager!.delete(_driverAnn!);
      } catch (_) {}
      _driverAnn = null;
    }
    _driverAnn = await _annManager!.create(
      mb.PointAnnotationOptions(
        geometry: mb.Point(coordinates: mb.Position(lng, lat)),
        image: _driverIcon!,
        iconAnchor: mb.IconAnchor.CENTER,
        iconSize: 1.0,
        iconRotate: heading,
      ),
    );

    if (centerCamera) {
      await _map!.setCamera(
        mb.CameraOptions(
          center: mb.Point(coordinates: mb.Position(lng, lat)),
          zoom: zoom,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.surface,
      body: Stack(
        children: [
          mb.MapWidget(
            key: const ValueKey('live_order_tracking_map'),
            cameraOptions: mb.CameraOptions(
              center: mb.Point(coordinates: mb.Position(46.6753, 24.7136)),
              zoom: 12.0,
            ),
            styleUri: MapboxConstants.styleUri,
            onMapCreated: _onMapCreated,
          ),

          // Title overlay
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
                    'تتبُّع السائق',
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

          // Back button
          Positioned(
            top: 36,
            left: 16,
            child: SafeArea(
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_back, size: 20),
                  ),
                ),
              ),
            ),
          ),

          // Recenter button
          Positioned(
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    if (_driverLat != null && _driverLng != null) {
                      await _map?.setCamera(
                        mb.CameraOptions(
                          center: mb.Point(
                            coordinates: mb.Position(_driverLng!, _driverLat!),
                          ),
                          zoom: 15.0,
                        ),
                      );
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.center_focus_strong, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simple blue driver marker (circle with arrow)
  Future<Uint8List> _buildDriverIcon({double size = 72}) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));
    final blue = Paint()..color = const Color(0xFF1976D2);
    final white = Paint()..color = Colors.white;
    final cx = size / 2;
    final cy = size / 2;
    final r = size * 0.28;
    canvas.drawCircle(Offset(cx, cy), r, blue);
    final arrow = Path()
      ..moveTo(cx, cy - r * 0.9)
      ..lineTo(cx - r * 0.45, cy + r * 0.5)
      ..lineTo(cx + r * 0.45, cy + r * 0.5)
      ..close();
    canvas.drawPath(arrow, white);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  // Grey user pin
  Future<Uint8List> _buildUserIcon({double size = 88}) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));
    final grey = Paint()..color = const Color(0xFF616161);
    final white = Paint()..color = Colors.white;
    final cx = size / 2;
    final cy = size * 0.38;
    final r = size * 0.22;
    canvas.drawCircle(Offset(cx, cy), r, grey);
    final tail = Path()
      ..moveTo(cx, size * 0.92)
      ..lineTo(cx - r * 0.75, cy + r * 0.75)
      ..lineTo(cx + r * 0.75, cy + r * 0.75)
      ..close();
    canvas.drawPath(tail, grey);
    canvas.drawCircle(Offset(cx, cy), r * 0.45, white);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }
}
