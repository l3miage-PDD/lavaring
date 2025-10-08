import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification_ring'); // Updated icon

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    final status = await Permission.notification.request();
    if (status.isDenied) {
      // You can show a dialog to the user explaining why the permission is needed.
    }
  }

  Future<void> show(int id, String title, String body) async {
    if (!_isInitialized) {
      await init();
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'goal_notification_channel',
      'Objectifs Atteints',
      channelDescription: 'Notifications pour les objectifs de temps atteints',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: 'ic_notification_ring', // Ensure this is also updated
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
    );
  }
}
