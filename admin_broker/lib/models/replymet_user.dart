import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/app_utils.dart';
import '../core/constants/app_constants.dart';

/// ReplyMet end-user model — maps to the existing 'users' collection in Firestore.
///
/// Existing fields from ReplyMate app:
///   name, phone, email, isApproved, isBlocked, createdAt, updatedAt
///
/// Admin-added fields (written when admin/broker approves):
///   status, approvedBy, approvedByRole, brokerId, planId,
///   subscriptionStart, subscriptionEnd, totalPaid, brokerCommission, adminRevenue
class ReplymetUser {
  final String uid;
  final String name;
  final String phone;
  final String email;

  // Existing ReplyMate fields
  final bool isApproved;   // Original approval flag from mobile app
  final bool isBlocked;    // Original block flag from mobile app

  // Admin panel status (derived or stored)
  // pending → not yet assigned a plan
  // active  → has valid subscription
  // expired → subscription passed end date
  // suspended → admin/broker blocked
  final String status;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Admin/Broker approval fields
  final String? approvedBy;      // uid of who approved
  final String? approvedByRole;  // 'admin' or 'broker'
  final String? brokerId;        // broker uid if registered via broker code
  final String? planId;

  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final double totalPaid;
  final double brokerCommission;
  final double adminRevenue;
  final double paymentReceived;
  final DateTime? paymentDate;
  final String? paymentStatus;
  final String? nextPlanId;
  final String? nextPlanName;

const ReplymetUser({
    required this.uid,
    required this.name,
    required this.phone,
    this.email = '',
    this.isApproved = false,
    this.isBlocked = false,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
    this.approvedBy,
    this.approvedByRole,
    this.brokerId,
    this.planId,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.totalPaid = 0,
    this.brokerCommission = 0,
    this.adminRevenue = 0,
    this.paymentReceived = 0,
    this.paymentDate,
    this.paymentStatus = 'unpaid',
    this.authUid,
    this.nextPlanId,
    this.nextPlanName,
  });

  final String? authUid;

  factory ReplymetUser.fromMap(Map<String, dynamic> map, String id) {
    // Derive status from existing isApproved/isBlocked fields if 'status' not set
    String status = map['status'] ?? '';
    if (status.isEmpty) {
      if (map['isBlocked'] == true) {
        status = AppConstants.statusSuspended;
      } else if (map['isApproved'] == true) {
        status = AppConstants.statusActive;
      } else {
        status = AppConstants.statusPending;
      }
    }

    return ReplymetUser(
      uid: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      isApproved: map['isApproved'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      status: status,
      createdAt: AppUtils.timestampToDate(map['createdAt']),
      updatedAt: AppUtils.timestampToDate(map['updatedAt']),
      approvedBy: map['approvedBy'],
      approvedByRole: map['approvedByRole'],
      brokerId: map['brokerId'],
      planId: map['planId'],
      subscriptionStart: AppUtils.timestampToDate(map['subscriptionStart']),
      subscriptionEnd: AppUtils.timestampToDate(map['subscriptionEnd']),
      totalPaid: (map['totalPaid'] ?? 0).toDouble(),
      brokerCommission: (map['brokerCommission'] ?? 0).toDouble(),
      adminRevenue: (map['adminRevenue'] ?? 0).toDouble(),
      paymentReceived: (map['paymentReceived'] ?? 0).toDouble(),
      paymentDate: AppUtils.timestampToDate(map['paymentDate']),
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      nextPlanId: map['nextPlanId'],
      nextPlanName: map['nextPlanName'],
    );
  }

  factory ReplymetUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      return ReplymetUser(
        uid: doc.id,
        name: '',
        phone: '',
        email: '',
        status: AppConstants.statusPending,
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
    return ReplymetUser.fromMap(mapData, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'isApproved': isApproved,
      'isBlocked': isBlocked,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'approvedBy': approvedBy,
      'approvedByRole': approvedByRole,
      'brokerId': brokerId,
      'planId': planId,
      'subscriptionStart': subscriptionStart,
      'subscriptionEnd': subscriptionEnd,
      'totalPaid': totalPaid,
      'brokerCommission': brokerCommission,
      'adminRevenue': adminRevenue,
      'paymentReceived': paymentReceived,
      'paymentDate': paymentDate,
      'paymentStatus': paymentStatus,
      'nextPlanId': nextPlanId,
      'nextPlanName': nextPlanName,
    };
  }

  ReplymetUser copyWith({
    String? uid,
    String? name,
    String? phone,
    String? email,
    bool? isApproved,
    bool? isBlocked,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? approvedBy,
    String? approvedByRole,
    String? brokerId,
    String? planId,
    DateTime? subscriptionStart,
    DateTime? subscriptionEnd,
    double? totalPaid,
    double? brokerCommission,
    double? adminRevenue,
    double? paymentReceived,
    DateTime? paymentDate,
    String? paymentStatus,
    String? nextPlanId,
    String? nextPlanName,
  }) {
    return ReplymetUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isApproved: isApproved ?? this.isApproved,
      isBlocked: isBlocked ?? this.isBlocked,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByRole: approvedByRole ?? this.approvedByRole,
      brokerId: brokerId ?? this.brokerId,
      planId: planId ?? this.planId,
      subscriptionStart: subscriptionStart ?? this.subscriptionStart,
      subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
      totalPaid: totalPaid ?? this.totalPaid,
      brokerCommission: brokerCommission ?? this.brokerCommission,
      adminRevenue: adminRevenue ?? this.adminRevenue,
      paymentReceived: paymentReceived ?? this.paymentReceived,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      nextPlanId: nextPlanId ?? this.nextPlanId,
      nextPlanName: nextPlanName ?? this.nextPlanName,
    );
  }

  bool get isPending => status == AppConstants.statusPending;
  bool get isActive => status == AppConstants.statusActive;
  bool get isExpired => status == AppConstants.statusExpired;
  bool get isSuspended => status == AppConstants.statusSuspended;
  bool get hasBroker => brokerId != null && brokerId!.isNotEmpty;
  bool get isExpiringSoon => AppUtils.isExpiringSoon(subscriptionEnd);
  bool get isPaymentPending => paymentStatus == 'unpaid' || paymentStatus == 'partial';
  bool get isPaymentComplete => paymentStatus == 'paid' && paymentReceived >= totalPaid;
  double get pendingPayment => totalPaid - paymentReceived;
}
