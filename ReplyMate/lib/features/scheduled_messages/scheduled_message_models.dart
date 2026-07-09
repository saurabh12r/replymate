class ScheduledMessage {
  final String id;
  final String title;
  final List<String> phoneNumbers;
  final String message;
  final DateTime scheduledTime;
  final bool isSent;

  ScheduledMessage({
    required this.id,
    required this.title,
    required this.phoneNumbers,
    required this.message,
    required this.scheduledTime,
    this.isSent = false,
  });

  ScheduledMessage copyWith({
    String? id,
    String? title,
    List<String>? phoneNumbers,
    String? message,
    DateTime? scheduledTime,
    bool? isSent,
  }) {
    return ScheduledMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      message: message ?? this.message,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isSent: isSent ?? this.isSent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'phoneNumbers': phoneNumbers,
      'message': message,
      'scheduledTime': scheduledTime.toIso8601String(),
      'isSent': isSent,
    };
  }

  factory ScheduledMessage.fromJson(Map<String, dynamic> json) {
    return ScheduledMessage(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      phoneNumbers: List<String>.from(json['phoneNumbers'] ?? []),
      message: json['message'] ?? '',
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      isSent: json['isSent'] ?? false,
    );
  }
}
