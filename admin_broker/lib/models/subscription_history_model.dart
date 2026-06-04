import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/app_utils.dart';

class SubscriptionHistoryModel {
  final String id;
  final String planId;
  final String planName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final double amount;
  final String action;
  final String performedBy;
  final String performedByRole;
  final DateTime createdAt;

  const SubscriptionHistoryModel({
    required this.id,
    required this.planId,
    required this.planName,
    this.startDate,
    this.endDate,
    required this.status,
    required this.amount,
    required this.action,
    required this.performedBy,
    required this.performedByRole,
    required this.createdAt,
  });

  factory SubscriptionHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionHistoryModel(
      id: id,
      planId: map['planId'] ?? '',
      planName: map['planName'] ?? '',
      startDate: AppUtils.timestampToDate(map['startDate']),
      endDate: AppUtils.timestampToDate(map['endDate']),
      status: map['status'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      action: map['action'] ?? '',
      performedBy: map['performedBy'] ?? '',
      performedByRole: map['performedByRole'] ?? '',
      createdAt: AppUtils.timestampToDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  factory SubscriptionHistoryModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    Map<String, dynamic> mapData;
    if (data is Map<String, dynamic>) {
      mapData = data;
    } else if (data is Map) {
      mapData = Map<String, dynamic>.from(data);
    } else {
      mapData = {};
    }
    return SubscriptionHistoryModel.fromMap(mapData, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'planName': planName,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'status': status,
      'amount': amount,
      'action': action,
      'performedBy': performedBy,
      'performedByRole': performedByRole,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
