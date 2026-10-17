import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Phone notifications for new OHS notifications (hazard alerts, reviews, permit decisions…) found by the
/// once-a-minute check while the app is open or in the background. Push delivery when the app is closed needs
/// Firebase Cloud Messaging on the server (see README).
class LocalAlerts {
  LocalAlerts._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'ohs_alerts',
    'OHS notifications',
    channelDescription: 'Hazard alerts, reviews, decisions and other notifications from the OHS platform',
    importance: Importance.high,
    priority: Priority.high,
  );

  static Future<void> init() async {
    if (_ready || kIsWeb) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      // Android 13+ asks the user once.
      await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {
      // Not supported on this platform (e.g. desktop in development): the in-app badge still works.
    }
  }

  static Future<void> show(String title, String body) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(android: _channel, iOS: DarwinNotificationDetails()),
      );
    } catch (_) {}
  }
}
