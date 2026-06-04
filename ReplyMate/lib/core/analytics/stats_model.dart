import 'package:cloud_firestore/cloud_firestore.dart';

class DailyStatsModel {
  final String dateId; // e.g. 2023-10-10
  final int smsSent;
  final int smsFailed;
  final int callsReceived;
  final int missedCalls;
  final DateTime? updatedAt;
  final DateTime? date;

  DailyStatsModel({
    required this.dateId,
    this.smsSent = 0,
    this.smsFailed = 0,
    this.callsReceived = 0,
    this.missedCalls = 0,
    this.updatedAt,
    this.date,
  });

  factory DailyStatsModel.fromMap(Map<String, dynamic> map, String docId) {
    return DailyStatsModel(
      dateId: docId,
      smsSent: map['smsSent'] ?? 0,
      smsFailed: map['smsFailed'] ?? 0,
      callsReceived: map['callsReceived'] ?? 0,
      missedCalls: map['missedCalls'] ?? 0,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      date: (map['date'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'smsSent': smsSent,
      'smsFailed': smsFailed,
      'callsReceived': callsReceived,
      'missedCalls': missedCalls,
      'updatedAt': FieldValue.serverTimestamp(),
      if (date != null) 'date': Timestamp.fromDate(date!),
    };
  }
}

class MonthlyStatsModel {
  final String monthId; // e.g. 2023-10
  final int smsSent;
  final int smsFailed;
  final int callsReceived;
  final int missedCalls;
  final DateTime? updatedAt;
  final int? year;
  final int? month;

  MonthlyStatsModel({
    required this.monthId,
    this.smsSent = 0,
    this.smsFailed = 0,
    this.callsReceived = 0,
    this.missedCalls = 0,
    this.updatedAt,
    this.year,
    this.month,
  });

  factory MonthlyStatsModel.fromMap(Map<String, dynamic> map, String docId) {
    return MonthlyStatsModel(
      monthId: docId,
      smsSent: map['smsSent'] ?? 0,
      smsFailed: map['smsFailed'] ?? 0,
      callsReceived: map['callsReceived'] ?? 0,
      missedCalls: map['missedCalls'] ?? 0,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      year: map['year'],
      month: map['month'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'smsSent': smsSent,
      'smsFailed': smsFailed,
      'callsReceived': callsReceived,
      'missedCalls': missedCalls,
      'updatedAt': FieldValue.serverTimestamp(),
      if (year != null) 'year': year,
      if (month != null) 'month': month,
    };
  }
}
