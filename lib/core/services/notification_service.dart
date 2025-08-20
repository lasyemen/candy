import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

// Top-level background handler required by firebase_messaging
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Keep minimal: initialize Firebase in background isolate
  await Firebase.initializeApp();
  // You can perform background processing here if needed
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FirebaseMessaging? _fm;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Ensure Firebase is initialized before using messaging
    await Firebase.initializeApp();
    // initialize FirebaseMessaging instance after Firebase is ready
    _fm = FirebaseMessaging.instance;

    // Initialize local notifications (for foreground display) - Android only
    final androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(
      initSettings,
      // handle notification tapped when app is in foreground/background
      onDidReceiveNotificationResponse: (response) {
        // TODO: handle navigation on tap using response.payload
      },
    );

    // Ensure Android notification channel exists (important for Android 8+)
    final androidChannel = AndroidNotificationChannel(
      'fcm_default_channel',
      'FCM Messages',
      description: 'FCM push messages',
      importance: Importance.max,
    );

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    // Initialize timezone data for scheduled reminders
    try {
      tzdata.initializeTimeZones();
      final String name = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      print('NotificationService - timezone init failed: $e');
    }

    // Background handler registration
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions and get token
    await _requestPermissions();
    await _registerDeviceToken();

    // Listen for messages while app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // debug log
      print(
        'NotificationService - onMessage received: ${message.messageId} ${message.data}',
      );
      if (message.notification != null) {
        print(
          'NotificationService - notification: ${message.notification!.title} - ${message.notification!.body}',
        );
      }
      _showLocalNotification(message);
    });

    // Handle user tapping a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('NotificationService - onMessageOpenedApp: ${message.data}');
      // TODO: navigate to specific screen using message.data
    });
  }

  Future<void> _requestPermissions() async {
    // For Android 13+ we must request the POST_NOTIFICATIONS runtime permission.
    // Use permission_handler to request and handle the user's choice.
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        if (result.isPermanentlyDenied) {
          // Optionally prompt user to open settings
          print('Notification permission permanently denied');
        }
      }

      // Also request messaging permissions via firebase_messaging API (harmless on Android).
      await (_fm ?? FirebaseMessaging.instance).requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      print('Notification permission request error: $e');
    }
  }

  /// If notifications are blocked, show a dialog prompting the user to open
  /// app settings so they can enable notifications. Call this from any UI
  /// (for example after login or from an in-app settings screen).
  Future<void> promptEnableNotifications(BuildContext context) async {
    final status = await Permission.notification.status;
    if (status.isGranted) return;

    // Show rationale / settings prompt
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'Notifications are disabled for this app. Open settings to enable notifications so you can receive important updates.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await openAppSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _registerDeviceToken() async {
    try {
      final token = await (_fm ?? FirebaseMessaging.instance).getToken();
      if (token == null) return;
      print('NotificationService - FCM token: $token');
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId == null) return; // require authenticated user to save

      final deviceId = await _getOrCreateDeviceId();

      final payload = {
        'customer_id': userId,
        'device_id': deviceId,
        'fcm_token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'last_seen': DateTime.now().toIso8601String(),
      };

      // Upsert into the notification_subscriptions table created in Supabase.
      await SupabaseService.instance.client
          .from('notification_subscriptions')
          .upsert(payload)
          .select();
    } catch (e) {
      // ignore errors for now
      print('NotificationService - failed to register device token: $e');
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'device_id';
    var id = prefs.getString(key);
    if (id != null && id.isNotEmpty) return id;

    // simple unique id: timestamp + random hex
    final rand = Random();
    id =
        '${DateTime.now().millisecondsSinceEpoch}-${rand.nextInt(1 << 32).toRadixString(16)}';
    await prefs.setString(key, id);
    return id;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'fcm_default_channel',
      'FCM Messages',
      channelDescription: 'FCM push messages',
      importance: Importance.max,
      priority: Priority.high,
    );
    // Use a time-based id so multiple notifications don't replace each other.
    final int notifId = DateTime.now().millisecondsSinceEpoch.remainder(
      1 << 31,
    );
    await _local.show(
      notifId,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }

  // SCHEDULED REMINDERS
  tz.TZDateTime _nextInstanceOfHourMinute(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now))
      scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final scheduled = _nextInstanceOfHourMinute(hour, minute);
    await _local.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'fcm_default_channel',
          'Reminders',
          channelDescription: 'Daily reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleHourlyReminder({
    required int id,
    required String title,
    required String body,
    required int minutesInterval,
  }) async {
    // For custom minute intervals we schedule the next occurrence manually
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(Duration(minutes: minutesInterval));
    await _local.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'fcm_default_channel',
          'Reminders',
          channelDescription: 'Periodic reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Do not use matchDateTimeComponents for custom intervals
    );
  }

  Future<void> cancelReminder(int id) => _local.cancel(id);

  Future<void> cancelAllReminders() => _local.cancelAll();
}
