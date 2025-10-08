import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';

const String notificationChannelId = 'my_foreground';
const int notificationId = 888;
const int goalInSeconds = 60;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.init();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? timer;
  bool isRunning = false;
  int totalSeconds = 0;
  DateTime? startTime;
  bool goalReachedNotified = false;

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    totalSeconds = prefs.getInt('totalSeconds') ?? 0;
    isRunning = prefs.getBool('isRunning') ?? false;
    goalReachedNotified = prefs.getBool('goalReachedNotified') ?? false;
    final startTimeMillis = prefs.getInt('startTime');
    if (startTimeMillis != null) {
      startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
    }
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalSeconds', totalSeconds);
    await prefs.setBool('isRunning', isRunning);
    await prefs.setBool('goalReachedNotified', goalReachedNotified);
    if (startTime != null) {
      await prefs.setInt('startTime', startTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('startTime');
    }
  }

  loadState();

  service.on('get_status').listen((event) {
    int currentSeconds = totalSeconds;
    if (isRunning && startTime != null) {
      currentSeconds += DateTime.now().difference(startTime!).inSeconds;
    }
    service.invoke('update', {
      'seconds': currentSeconds,
      'isRunning': isRunning,
    });
  });

  service.on('startTimer').listen((event) {
    if (!isRunning) {
      isRunning = true;
      startTime = DateTime.now();
      if (totalSeconds >= goalInSeconds) {
        totalSeconds = 0;
        goalReachedNotified = false;
      }
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
    goalReachedNotified = false;
    saveState();
  });

  service.on('stopService').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });

  timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (isRunning && startTime != null) {
      final currentSeconds = totalSeconds + DateTime.now().difference(startTime!).inSeconds;
      final remaining = goalInSeconds - currentSeconds;
      final minutes = (remaining / 60).floor();
      final seconds = remaining % 60;

      flutterLocalNotificationsPlugin.show(
        notificationId,
        'Lava Ring - Actif',
        'Objectif dans: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            'LAVA RING TIMER',
            icon: 'ic_notification_ring', // Updated icon
            ongoing: true,
            priority: Priority.high,
            importance: Importance.max,
          ),
        ),
      );

      service.invoke('update', {'seconds': currentSeconds, 'isRunning': isRunning});

      if (currentSeconds >= goalInSeconds && !goalReachedNotified) {
        await notificationService.show(
          123, 
          'Objectif Atteint !',
          'Bravo ! Vous avez atteint votre objectif de 1 minute.',
        );

        isRunning = false;
        startTime = null;
        totalSeconds = currentSeconds;
        goalReachedNotified = true;
        saveState();
        
        flutterLocalNotificationsPlugin.show(
          notificationId,
          'Objectif Atteint !',
          'Minuteur terminé.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'LAVA RING TIMER',
              icon: 'ic_notification_ring', // Updated icon
              ongoing: false,
            ),
          ),
        );
      }
    } else {
       flutterLocalNotificationsPlugin.show(
          notificationId,
          'Lava Ring',
          'Le minuteur est en pause ou arrêté.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'LAVA RING TIMER',
              icon: 'ic_notification_ring', // Updated icon
              ongoing: true,
            ),
          ),
        );
    }
  });
}
