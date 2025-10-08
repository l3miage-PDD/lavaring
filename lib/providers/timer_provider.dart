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
    final service = FlutterBackgroundService();

    // Listen for UI updates from the service
    service.on('update').listen((data) {
      if (data != null) {
        _totalSeconds = data['seconds'] as int? ?? _totalSeconds;
        _isRunning = data['isRunning'] as bool? ?? _isRunning;

        if (_totalSeconds >= 60 && !_goalReached) {
          _goalReached = true;
        }

        notifyListeners();
      }
    });

    // Request initial state from the service
    service.invoke('get_status');
  }

  void startTimer() {
    FlutterBackgroundService().invoke('startTimer');
    _isRunning = true;
    _goalReached = false; // Reset goal when starting
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
