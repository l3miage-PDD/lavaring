import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class TimerProvider with ChangeNotifier {
  int _totalSeconds = 0;
  bool _isRunning = false;
  bool _goalReached = false;

  int get totalSeconds => _totalSeconds;
  bool get isRunning => _isRunning;
  bool get goalReached => _goalReached;

  TimerProvider() {
    FlutterBackgroundService().on('update').listen((data) {
      if (data != null) {
        final seconds = data['seconds'] as int? ?? 0;
        _totalSeconds = seconds;

        if (seconds >= 60 && !_goalReached) {
          _goalReached = true;
        }

        notifyListeners();
      }
    });
  }

  void startTimer() {
    FlutterBackgroundService().invoke('startTimer');
    _isRunning = true;
    notifyListeners();
  }

  void pauseTimer() {
    FlutterBackgroundService().invoke('pauseTimer');
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    FlutterBackgroundService().invoke('resetTimer');
    _totalSeconds = 0;
    _isRunning = false;
    _goalReached = false;
    notifyListeners();
  }

  void acknowledgeGoal() {
    _goalReached = false;
    notifyListeners();
  }
}
