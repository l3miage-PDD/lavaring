
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';

class TimerProvider with ChangeNotifier {
  int _totalSeconds = 0;
  bool _isRunning = false;
  final FlutterBackgroundService _service = FlutterBackgroundService();

  int get totalSeconds => _totalSeconds;
  bool get isRunning => _isRunning;

  TimerProvider() {
    _service.on('update').listen((data) {
      if (data != null) {
        _totalSeconds = data['seconds'] ?? 0;
        _isRunning = data['isRunning'] ?? false;
        notifyListeners();
      }
    });
  } 

  void startTimer() {
     _service.invoke('startTimer');
  }

  void pauseTimer() {
     _service.invoke('pauseTimer');
  }

  void getStatus() {
     _service.invoke('get_status');
  }

}
