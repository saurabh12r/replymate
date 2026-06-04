import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/app_utils.dart';

/// Approval record model (approvals collection)
class ApprovalModel {
  final String approvalId;
  final String userId;
  final String approvedBy; // uid
  final String approvedByRole; // admin or broker
  final String? brokerId;
  final String planId;
  final double amount;
  final double brokerCommission;
  final double adminRevenue;
  final DateTime? approvedAt;

  const ApprovalModel({
    required this.approvalId,
    required this.userId,
    required this.approvedBy,
    required this.approvedByRole,
    this.brokerId,
    required this.planId,
    required this.amount,
    required this.brokerCommission,
    required this.adminRevenue,
    this.approvedAt,
  });

  factory ApprovalModel.fromMap(Map<String, dynamic> map, String id) {
    return ApprovalModel(
      approvalId: id,
      userId: map['userId'] ?? '',
      approvedBy: map['approvedBy'] ?? '',
      approvedByRole: map['approvedByRole'] ?? 'admin',
      brokerId: map['brokerId'],
      planId: map['planId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      brokerCommission: (map['brokerCommission'] ?? 0).toDouble(),
      adminRevenue: (map['adminRevenue'] ?? 0).toDouble(),
      approvedAt: AppUtils.timestampToDate(map['approvedAt']),
    );
  }

  factory ApprovalModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      return ApprovalModel(
        approvalId: doc.id,
        userId: '',
        approvedBy: '',
        approvedByRole: 'admin',
        planId: '',
        amount: 0,
        brokerCommission: 0,
        adminRevenue: 0,
      );
    }
    Map<String, dynamic> mapData;
    if (data is Map<String, dynamic>) {
      mapData = data;
    } else if (data is Map) {
      mapData = Map<String, dynamic>.from(data);
    } else {
      mapData = {};
    }
    return ApprovalModel.fromMap(mapData, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'approvalId': approvalId,
      'userId': userId,
      'approvedBy': approvedBy,
      'approvedByRole': approvedByRole,
      'brokerId': brokerId,
      'planId': planId,
      'amount': amount,
      'brokerCommission': brokerCommission,
      'adminRevenue': adminRevenue,
      'approvedAt': approvedAt ?? FieldValue.serverTimestamp(),
    };
  }
}
