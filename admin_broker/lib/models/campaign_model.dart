import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/app_utils.dart';

class CampaignModel {
  final String id;
  final String senderId;
  final String senderRole;
  final String senderName;
  final String title;
  final String message;
  final String? imageUrl;
  final String targetType;
  final String? planId;
  final int totalTargeted;
  final int successCount;
  final int failureCount;
  final DateTime? createdAt;

  const CampaignModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.targetType,
    this.planId,
    this.totalTargeted = 0,
    this.successCount = 0,
    this.failureCount = 0,
    this.createdAt,
  });

  factory CampaignModel.fromMap(Map<String, dynamic> map, String docId) {
    return CampaignModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      senderRole: map['senderRole'] ?? '',
      senderName: map['senderName'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      imageUrl: map['imageUrl'],
      targetType: map['targetType'] ?? 'all',
      planId: map['planId'],
      totalTargeted: map['totalTargeted'] ?? 0,
      successCount: map['successCount'] ?? 0,
      failureCount: map['failureCount'] ?? 0,
      createdAt: AppUtils.timestampToDate(map['createdAt']),
    );
  }
}
