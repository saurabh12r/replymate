import 'dart:convert';

class ScheduledMessage {
  final String id;
  final String phoneNumber;
  final String message;
  final DateTime scheduledTime;
  final bool isSent;

  ScheduledMessage({
    required this.id,
    required this.phoneNumber,
    required this.message,
    required this.scheduledTime,
    this.isSent = false,
  });

  ScheduledMessage copyWith({
    String? id,
    String? phoneNumber,
    String? message,
    DateTime? scheduledTime,
    bool? isSent,
  }) {
    return ScheduledMessage(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      message: message ?? this.message,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isSent: isSent ?? this.isSent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'message': message,
      'scheduledTime': scheduledTime.toIso8601String(),
      'isSent': isSent,
    };
  }

  factory ScheduledMessage.fromJson(Map<String, dynamic> json) {
    return ScheduledMessage(
      id: json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      message: json['message'] ?? '',
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      isSent: json['isSent'] ?? false,
    );
  }
}
