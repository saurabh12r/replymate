import 'package:flutter/material.dart';

class UserStats {
  final String odlId;
  final int smsSent;
  final int smsFailed;
  final int callsReceived;
  final int missedCalls;
  final double totalSpent;
  final int subscriptionDays;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final String? currentPlan;
  final String? status;

  const UserStats({
    required this.odlId,
    this.smsSent = 0,
    this.smsFailed = 0,
    this.callsReceived = 0,
    this.missedCalls = 0,
    this.totalSpent = 0.0,
    this.subscriptionDays = 0,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.currentPlan,
    this.status,
  });

  factory UserStats.fromMap(String id, Map<String, dynamic> map) {
    return UserStats(
      odlId: id,
      smsSent: map['smsSent'] ?? 0,
      smsFailed: map['smsFailed'] ?? 0,
      callsReceived: map['callsReceived'] ?? 0,
      missedCalls: map['missedCalls'] ?? 0,
      totalSpent: (map['totalSpent'] ?? 0).toDouble(),
      subscriptionDays: map['subscriptionDays'] ?? 0,
      subscriptionStart: map['subscriptionStart'] != null 
          ? DateTime.tryParse(map['subscriptionStart'].toString()) 
          : null,
      subscriptionEnd: map['subscriptionEnd'] != null 
          ? DateTime.tryParse(map['subscriptionEnd'].toString()) 
          : null,
      currentPlan: map['currentPlan'],
      status: map['status'],
    );
  }

  int get totalSms => smsSent + smsFailed;
  double get successRate => totalSms > 0 ? (smsSent / totalSms) * 100 : 0;
}

class UserActivity {
  final String id;
  final String type;
  final String description;
  final DateTime timestamp;
  final bool success;

  const UserActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    this.success = true,
  });

  factory UserActivity.fromMap(String id, Map<String, dynamic> map) {
    return UserActivity(
      id: id,
      type: map['type'] ?? 'unknown',
      description: map['description'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      success: map['success'] ?? true,
    );
  }

  IconData get icon {
    switch (type) {
      case 'sms_sent':
        return Icons.send_rounded;
      case 'sms_failed':
        return Icons.error_outline_rounded;
      case 'call_received':
        return Icons.phone_rounded;
      case 'call_missed':
        return Icons.call_missed_rounded;
      case 'subscription_started':
        return Icons.play_arrow_rounded;
      case 'subscription_renewed':
        return Icons.refresh_rounded;
      case 'subscription_expired':
        return Icons.timer_off_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color get color {
    switch (type) {
      case 'sms_sent':
      case 'call_received':
      case 'subscription_started':
      case 'subscription_renewed':
        return const Color(0xFF2E7D32);
      case 'sms_failed':
      case 'call_missed':
      case 'subscription_expired':
        return const Color(0xFFBA1A1A);
      default:
        return const Color(0xFF24389C);
    }
  }
}

class Color {
  final int value;
  const Color(this.value);
}