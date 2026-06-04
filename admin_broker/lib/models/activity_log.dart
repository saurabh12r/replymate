import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/app_utils.dart';

/// Activity log entry model (activity_logs collection)
class ActivityLog {
  final String logId;
  final String action;
  final String performedBy; // uid
  final String performedByRole;
  final String? targetId; // user/broker/plan uid
  final String? targetType; // 'user', 'broker', 'plan'
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;

  const ActivityLog({
    required this.logId,
    required this.action,
    required this.performedBy,
    required this.performedByRole,
    this.targetId,
    this.targetType,
    this.metadata,
    this.createdAt,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> map, String id) {
    Map<String, dynamic>? metadata;
    if (map['metadata'] != null) {
      metadata = Map<String, dynamic>.from(map['metadata']);
    }
    return ActivityLog(
      logId: id,
      action: map['action']?.toString() ?? '',
      performedBy: map['performedBy']?.toString() ?? '',
      performedByRole: map['performedByRole']?.toString() ?? '',
      targetId: map['targetId']?.toString(),
      targetType: map['targetType']?.toString(),
      metadata: metadata,
      createdAt: AppUtils.timestampToDate(map['createdAt']),
    );
  }

  factory ActivityLog.fromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      return ActivityLog(
        logId: doc.id,
        action: '',
        performedBy: '',
        performedByRole: '',
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
    return ActivityLog.fromMap(mapData, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'action': action,
      'performedBy': performedBy,
      'performedByRole': performedByRole,
      'targetId': targetId,
      'targetType': targetType,
      'metadata': metadata,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
