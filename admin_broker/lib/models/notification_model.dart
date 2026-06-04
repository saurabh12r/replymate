import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/app_utils.dart';

enum NotificationType {
  newUserRegistered,
  subscriptionExpiringSoon,
  subscriptionExpired,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String? userId;
  final String? userName;
  final String? userPhone;
  final String targetRole;
  final String? targetId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.userId,
    this.userName,
    this.userPhone,
    required this.targetRole,
    this.targetId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.newUserRegistered,
      ),
      userId: data['userId'],
      userName: data['userName'],
      userPhone: data['userPhone'],
      targetRole: data['targetRole'] ?? '',
      targetId: data['targetId'],
      isRead: data['isRead'] ?? false,
      createdAt: AppUtils.timestampToDate(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type.name,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'targetRole': targetRole,
      'targetId': targetId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    String? userId,
    String? userName,
    String? userPhone,
    String? targetRole,
    String? targetId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      targetRole: targetRole ?? this.targetRole,
      targetId: targetId ?? this.targetId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}