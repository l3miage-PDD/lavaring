import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String notificationChannelId = 'my_foreground';
const int notificationId = 888;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? timer;
  bool isRunning = false;
  int totalSeconds = 0;
  DateTime? startTime;

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    totalSeconds = prefs.getInt('totalSeconds') ?? 0;
    isRunning = prefs.getBool('isRunning') ?? false;
    final startTimeMillis = prefs.getInt('startTime');
    if (startTimeMillis != null) {
      startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
    }
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalSeconds', totalSeconds);
    await prefs.setBool('isRunning', isRunning);
    if (startTime != null) {
      await prefs.setInt('startTime', startTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('startTime');
    }
  }

  loadState();

  service.on('startTimer').listen((event) {
    if (!isRunning) {
      isRunning = true;
      startTime = DateTime.now();
      saveState();
    }
  });

  service.on('pauseTimer').listen((event) {
    if (isRunning && startTime != null) {
      final elapsed = DateTime.now().difference(startTime!).inSeconds;
      totalSeconds += elapsed;
      isRunning = false;
      startTime = null;
      saveState();
    }
  });

  service.on('resetTimer').listen((event) {
    isRunning = false;
    startTime = null;
    totalSeconds = 0;
    saveState();
  });

  timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (isRunning && startTime != null) {
      final currentSeconds = totalSeconds + DateTime.now().difference(startTime!).inSeconds;

      service.invoke('update', {'seconds': currentSeconds});

      if (currentSeconds >= 60) {
        flutterLocalNotificationsPlugin.show(
          notificationId,
          'Objectif Atteint !',
          'Bravo ! Vous avez atteint votre objectif de 1 minute.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId, 
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: false, // Make the notification dismissible
            ),
          ),
        );
        // Stop the timer
        isRunning = false;
        startTime = null;
        totalSeconds = currentSeconds; // Save the final time
        saveState();
      }
    }
  });
}
