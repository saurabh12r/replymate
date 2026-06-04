import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/app_utils.dart';

class DailyStats {
  final String id;
  final DateTime date;
  final int smsSent;
  final int smsFailed;
  final int callsReceived;
  final int missedCalls;
  final int incomingCalls;
  final int outgoingCalls;
  final int newUsers;
  final int renewedUsers;
  final int expiredUsers;
  final DateTime? createdAt;

  const DailyStats({
    required this.id,
    required this.date,
    this.smsSent = 0,
    this.smsFailed = 0,
    this.callsReceived = 0,
    this.missedCalls = 0,
    this.incomingCalls = 0,
    this.outgoingCalls = 0,
    this.newUsers = 0,
    this.renewedUsers = 0,
    this.expiredUsers = 0,
    this.createdAt,
  });

  factory DailyStats.fromMap(Map<String, dynamic> map, String id) {
    return DailyStats(
      id: id,
      date: AppUtils.timestampToDate(map['date']) ?? DateTime.now(),
      smsSent: map['smsSent'] ?? 0,
      smsFailed: map['smsFailed'] ?? 0,
      callsReceived: map['callsReceived'] ?? 0,
      missedCalls: map['missedCalls'] ?? 0,
      incomingCalls: map['incomingCalls'] ?? 0,
      outgoingCalls: map['outgoingCalls'] ?? 0,
      newUsers: map['newUsers'] ?? 0,
      renewedUsers: map['renewedUsers'] ?? 0,
      expiredUsers: map['expiredUsers'] ?? 0,
      createdAt: AppUtils.timestampToDate(map['createdAt']),
    );
  }

  factory DailyStats.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return DailyStats(id: doc.id, date: DateTime.now());
    }
    return DailyStats.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'smsSent': smsSent,
      'smsFailed': smsFailed,
      'callsReceived': callsReceived,
      'missedCalls': missedCalls,
      'incomingCalls': incomingCalls,
      'outgoingCalls': outgoingCalls,
      'newUsers': newUsers,
      'renewedUsers': renewedUsers,
      'expiredUsers': expiredUsers,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  int get totalSms => smsSent + smsFailed;
  double get successRate => totalSms > 0 ? (smsSent / totalSms) * 100 : 0;
}

class MonthlyStats {
  final String id;
  final int year;
  final int month;
  final int smsSent;
  final int smsFailed;
  final int callsReceived;
  final int missedCalls;
  final int newUsers;
  final int renewedUsers;
  final int totalRevenue;
  final DateTime? createdAt;

  const MonthlyStats({
    required this.id,
    required this.year,
    required this.month,
    this.smsSent = 0,
    this.smsFailed = 0,
    this.callsReceived = 0,
    this.missedCalls = 0,
    this.newUsers = 0,
    this.renewedUsers = 0,
    this.totalRevenue = 0,
    this.createdAt,
  });

  factory MonthlyStats.fromMap(Map<String, dynamic> map, String id) {
    return MonthlyStats(
      id: id,
      year: map['year'] ?? DateTime.now().year,
      month: map['month'] ?? DateTime.now().month,
      smsSent: map['smsSent'] ?? 0,
      smsFailed: map['smsFailed'] ?? 0,
      callsReceived: map['callsReceived'] ?? 0,
      missedCalls: map['missedCalls'] ?? 0,
      newUsers: map['newUsers'] ?? 0,
      renewedUsers: map['renewedUsers'] ?? 0,
      totalRevenue: map['totalRevenue'] ?? 0,
      createdAt: AppUtils.timestampToDate(map['createdAt']),
    );
  }

  factory MonthlyStats.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return MonthlyStats(id: doc.id, year: DateTime.now().year, month: DateTime.now().month);
    }
    return MonthlyStats.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'month': month,
      'smsSent': smsSent,
      'smsFailed': smsFailed,
      'callsReceived': callsReceived,
      'missedCalls': missedCalls,
      'newUsers': newUsers,
      'renewedUsers': renewedUsers,
      'totalRevenue': totalRevenue,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  int get totalSms => smsSent + smsFailed;
  double get successRate => totalSms > 0 ? (smsSent / totalSms) * 100 : 0;
  
  String get monthName {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}