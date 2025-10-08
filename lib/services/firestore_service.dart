
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// Represents a single wear session
class Session {
  final DateTime start;
  final DateTime end;

  Session({required this.start, required this.end});

  Map<String, dynamic> toJson() => {
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(end),
      };
}

// Represents the log for a single tracking day (20:00 to 19:59)
class DailyLog {
  final String date; // YYYY-MM-DD
  int totalSeconds;
  String status; // 'rouge', 'orange', 'vert'
  List<Session> sessions;
  Timestamp lastUpdate;

  DailyLog({
    required this.date,
    this.totalSeconds = 0,
    this.status = 'rouge',
    required this.sessions,
    required this.lastUpdate,
  });

  // Calculates status based on total seconds
  void calculateStatus() {
    double hours = totalSeconds / 3600.0;
    // Goal is 15 hours
    if (hours >= 15) {
      status = 'vert';
    } else if (hours >= 14) {
      status = 'orange';
    } else {
      status = 'rouge';
    }
  }

  Map<String, dynamic> toJson() {
    calculateStatus();
    return {
      'date': date,
      'total_seconds': totalSeconds,
      'status': status,
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'last_update': lastUpdate,
    };
  }
}


class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveDailyLog(String userId, DailyLog log) async {
    if (userId.isEmpty) {
      return;
    }
    DocumentReference docRef =
        _db.collection('users').doc(userId).collection('daily_logs').doc(log.date);

    await docRef.set(log.toJson());
  }

  // Example of how to retrieve a log
  Future<DailyLog?> getDailyLog(String userId, String date) async {
    if (userId.isEmpty) {
      return null;
    }
    DocumentSnapshot doc =
        await _db.collection('users').doc(userId).collection('daily_logs').doc(date).get();

    if (doc.exists) {
      // This part would need a fromJson constructor in DailyLog, which is omitted for brevity
      return null; 
    }
    return null;
  }
}
