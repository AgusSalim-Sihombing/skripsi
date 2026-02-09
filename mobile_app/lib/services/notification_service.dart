import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _inited = false;
  static const String channelId = 'zone_alerts_v2';

  static Future<void> init({bool requestPermission = false}) async {
    if (_inited) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    const channelId = 'zone_alerts_v2';

    await _plugin.initialize(initSettings);

    final pattern = Int64List.fromList([
      0, // delay
      1500, // getar 1.5 detik
      300, // jeda 0.3 detik
      1500, // getar 1.5 detik
      300,
      1500,
      300,
      2000, // getar 2 detik (bonus)
    ]);
    final channel = AndroidNotificationChannel(
      channelId,
      'Zona Bahaya Alerts',
      description: 'Notifikasi saat masuk zona bahaya',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: pattern,
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImpl?.createNotificationChannel(channel);

    if (requestPermission) {
      await requestPermissionIfNeeded();
    }

    _inited = true;
  }

  /// ✅ Android 13+ cuma akan muncul sekali.
  /// Kalau sudah di-allow / device Android < 13, gak akan muncul prompt lagi (normal).
  static Future<void> requestPermissionIfNeeded() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImpl == null) return;

    final enabled = await androidImpl.areNotificationsEnabled() ?? true;
    if (!enabled) {
      final granted = await androidImpl.requestNotificationsPermission();
      debugPrint("🔔 notif permission granted? $granted");
    }
  }

  static Future<void> showZoneWarning({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_inited) await init();

    final pattern = Int64List.fromList([
      0, // delay
      1500, // getar 1.5 detik
      300, // jeda 0.3 detik
      1500, // getar 1.5 detik
      300,
      1500,
      300,
      2000, // getar 2 detik (bonus)
    ]);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Zona Bahaya Alerts',
      channelDescription: 'Notifikasi saat masuk zona bahaya',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: pattern,
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }
}
