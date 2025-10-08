
import 'dart:async';
import 'dart:ui';
import 'dart:developer' as developer; 

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

const String notificationChannelId = 'my_foreground';
const int notificationId = 888;
const int goalInHours = 15;
const int goalInSeconds = goalInHours * 3600;
const int resetHour = 20; // 8 PM

// Helper function outside of onStart
DateTime getTrackingDate(DateTime dateTime) {
  if (dateTime.hour >= resetHour) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  } else {
    return DateTime(dateTime.year, dateTime.month, dateTime.day)
        .subtract(const Duration(days: 1));
  }
}

String getTrackingDateString(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  developer.log('Background service started.', name: 'background_service');

  final notificationService = NotificationService();
  await notificationService.init();
  final firestoreService = FirestoreService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String userId = '';
  bool isRunning = false;
  DateTime? sessionStartTime;
  int dailyTotalSeconds = 0;
  List<Session> sessions = [];
  bool goalReachedNotified = false;
  DateTime currentTrackingDate = getTrackingDate(DateTime.now());

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('trackingDate', getTrackingDateString(currentTrackingDate));
    await prefs.setInt('dailyTotalSeconds', dailyTotalSeconds);
    await prefs.setBool('isRunning', isRunning);
    await prefs.setBool('goalReachedNotified', goalReachedNotified);
    if (sessionStartTime != null) {
      await prefs.setInt('sessionStartTime', sessionStartTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('sessionStartTime');
    }
  }

  Future<void> resetDailyState(SharedPreferences prefs, {bool saveToFirestore = true}) async {
    if (saveToFirestore && userId.isNotEmpty) {
      final log = DailyLog(
        date: getTrackingDateString(currentTrackingDate),
        totalSeconds: dailyTotalSeconds,
        sessions: sessions,
        lastUpdate: Timestamp.now(),
      );
      await firestoreService.saveDailyLog(userId, log);
      await notificationService.show(1, 'Journée terminée', 'Total: ${(dailyTotalSeconds / 3600).toStringAsFixed(2)}h');
    }

    isRunning = false;
    sessionStartTime = null;
    dailyTotalSeconds = 0;
    goalReachedNotified = false;
    sessions = [];
    currentTrackingDate = getTrackingDate(DateTime.now());

    await saveState();
  }

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    final savedDate = prefs.getString('trackingDate');

    if (savedDate == getTrackingDateString(currentTrackingDate)) {
      dailyTotalSeconds = prefs.getInt('dailyTotalSeconds') ?? 0;
      isRunning = prefs.getBool('isRunning') ?? false;
      goalReachedNotified = prefs.getBool('goalReachedNotified') ?? false;
      final startTimeMillis = prefs.getInt('sessionStartTime');
      if (startTimeMillis != null) {
        sessionStartTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
      }
    } else {
      await resetDailyState(prefs, saveToFirestore: true);
    }
    developer.log(
      'State loaded: isRunning=$isRunning, userId=$userId, dailyTotalSeconds=$dailyTotalSeconds',
      name: 'background_service',
    );
  }

  // --- Service Listeners ---
  service.on('set_user').listen((event) {
    developer.log('Received "set_user" event.', name: 'background_service');
    if (event != null && event['userId'] != null) {
      userId = event['userId'];
      loadState(); // Load state for the new user
    }
  });

  service.on('get_status').listen((event) {
     developer.log('Received "get_status" event.', name: 'background_service');
    int currentSeconds = dailyTotalSeconds;
    if (isRunning && sessionStartTime != null) {
      currentSeconds += DateTime.now().difference(sessionStartTime!).inSeconds;
    }
    service.invoke('update', {
      'seconds': currentSeconds,
      'isRunning': isRunning,
    });
  });

  service.on('startTimer').listen((event) async {
    developer.log(
      'Received "startTimer" event. Current isRunning state: $isRunning',
      name: 'background_service',
    );
    final now = DateTime.now();
    if (getTrackingDate(now) != currentTrackingDate) {
      developer.log('Date has changed, resetting daily state.', name: 'background_service');
      final prefs = await SharedPreferences.getInstance();
      await resetDailyState(prefs);
    }

    if (!isRunning) {
      developer.log('Timer is not running. Starting it now.', name: 'background_service');
      isRunning = true;
      sessionStartTime = now;
      await saveState();
       developer.log('New state saved: isRunning=$isRunning', name: 'background_service');
    } else {
       developer.log('Timer is already running. Ignoring "startTimer" event.', name: 'background_service');
    }
  });

  service.on('pauseTimer').listen((event) async {
     developer.log(
      'Received "pauseTimer" event. Current isRunning state: $isRunning',
      name: 'background_service',
    );
    if (isRunning && sessionStartTime != null) {
      final sessionEnd = DateTime.now();
      final session = Session(start: sessionStartTime!, end: sessionEnd);
      sessions.add(session);

      dailyTotalSeconds += sessionEnd.difference(sessionStartTime!).inSeconds;
      isRunning = false;
      sessionStartTime = null;
      await saveState();
       developer.log('Timer paused. State saved: isRunning=$isRunning', name: 'background_service');

      final log = DailyLog(
        date: getTrackingDateString(currentTrackingDate),
        totalSeconds: dailyTotalSeconds,
        sessions: sessions,
        lastUpdate: Timestamp.now(),
      );
      await firestoreService.saveDailyLog(userId, log);
    } else {
        developer.log('Timer is not running. Ignoring "pauseTimer" event.', name: 'background_service');
    }
  });

  // --- Main Loop ---
  await loadState();

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    final now = DateTime.now();

    if (now.hour == resetHour && now.minute == 0 && getTrackingDate(now) != currentTrackingDate) {
        final prefs = await SharedPreferences.getInstance();
        await resetDailyState(prefs);
        return;
    }

    if (isRunning && sessionStartTime != null) {
      final currentTotal = dailyTotalSeconds + now.difference(sessionStartTime!).inSeconds;
      final remaining = goalInSeconds - currentTotal;
      final h = (remaining / 3600).floor();
      final m = ((remaining % 3600) / 60).floor();
      final s = remaining % 60;

      await flutterLocalNotificationsPlugin.show(
          notificationId,
          'Lava Ring - Actif',
          remaining > 0 ? 'Objectif dans: ${h}h ${m}m ${s}s' : 'Objectif atteint !',
          const NotificationDetails(
              android: AndroidNotificationDetails(notificationChannelId, 'LAVA RING TIMER',
                  icon: 'ic_notification_ring', ongoing: true, priority: Priority.high, importance: Importance.max)));

      service.invoke('update', {'seconds': currentTotal, 'isRunning': isRunning});

      if (currentTotal >= goalInSeconds && !goalReachedNotified) {
        await notificationService.show(123, '🎯 Objectif journalier atteint !', 'Bravo! Vous avez porté l\'anneau pendant $goalInHours heures.');
        goalReachedNotified = true;
        await saveState();
      }
    } else {
       await flutterLocalNotificationsPlugin.show(
          notificationId,
          'Lava Ring',
          'Le minuteur est en pause ou arrêté.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId, 'LAVA RING TIMER',
              icon: 'ic_notification_ring', ongoing: true,
            ),
          ));
      service.invoke('update', {'seconds': dailyTotalSeconds, 'isRunning': false});
    }
  });
}
