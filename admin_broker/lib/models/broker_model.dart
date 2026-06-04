import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/app_utils.dart';

/// Broker model (brokers collection)
class BrokerModel {
  final String brokerId;
  final String name;
  final String email;
  final String phone;
  final String brokerCode;
  final double commissionPercent;
  final double walletBalance;
  final int totalUsers;
  final double totalRevenue;
  final DateTime? createdAt;
  final bool isActive;
  final double totalPendingPayment;
  final double totalPaidToAdmin;
  final double totalAdminRevenue;
  final int maxUsers;

  const BrokerModel({
    required this.brokerId,
    required this.name,
    required this.email,
    required this.phone,
    required this.brokerCode,
    required this.commissionPercent,
    this.walletBalance = 0,
    this.totalUsers = 0,
    this.totalRevenue = 0,
    this.createdAt,
    this.isActive = true,
    this.totalPendingPayment = 0,
    this.totalPaidToAdmin = 0,
    this.totalAdminRevenue = 0,
    this.maxUsers = 0,
  });

  factory BrokerModel.fromMap(Map<String, dynamic> map, String id) {
    return BrokerModel(
      brokerId: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      brokerCode: map['brokerCode'] ?? '',
      commissionPercent: (map['commissionPercent'] ?? 0).toDouble(),
      walletBalance: (map['walletBalance'] ?? 0).toDouble(),
      totalUsers: map['totalUsers'] ?? 0,
      totalRevenue: (map['totalRevenue'] ?? 0).toDouble(),
      createdAt: AppUtils.timestampToDate(map['createdAt']),
      isActive: map['isActive'] ?? true,
      totalPendingPayment: (map['totalPendingPayment'] ?? 0).toDouble(),
      totalPaidToAdmin: (map['totalPaidToAdmin'] ?? 0).toDouble(),
      totalAdminRevenue: (map['totalAdminRevenue'] ?? 0).toDouble(),
      maxUsers: map['maxUsers'] ?? 0,
    );
  }

  factory BrokerModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      return BrokerModel(
        brokerId: doc.id,
        name: '',
        email: '',
        phone: '',
        brokerCode: '',
        commissionPercent: 0,
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
    return BrokerModel.fromMap(mapData, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'brokerId': brokerId,
      'name': name,
      'email': email,
      'phone': phone,
      'brokerCode': brokerCode,
      'commissionPercent': commissionPercent,
      'walletBalance': walletBalance,
      'totalUsers': totalUsers,
      'totalRevenue': totalRevenue,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'isActive': isActive,
      'totalPendingPayment': totalPendingPayment,
      'totalPaidToAdmin': totalPaidToAdmin,
      'totalAdminRevenue': totalAdminRevenue,
      'maxUsers': maxUsers,
    };
  }

  BrokerModel copyWith({
    String? brokerId,
    String? name,
    String? email,
    String? phone,
    String? brokerCode,
    double? commissionPercent,
    double? walletBalance,
    int? totalUsers,
    double? totalRevenue,
    DateTime? createdAt,
    bool? isActive,
    double? totalPendingPayment,
    double? totalPaidToAdmin,
    double? totalAdminRevenue,
    int? maxUsers,
  }) {
    return BrokerModel(
      brokerId: brokerId ?? this.brokerId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      brokerCode: brokerCode ?? this.brokerCode,
      commissionPercent: commissionPercent ?? this.commissionPercent,
      walletBalance: walletBalance ?? this.walletBalance,
      totalUsers: totalUsers ?? this.totalUsers,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      totalPendingPayment: totalPendingPayment ?? this.totalPendingPayment,
      totalPaidToAdmin: totalPaidToAdmin ?? this.totalPaidToAdmin,
      totalAdminRevenue: totalAdminRevenue ?? this.totalAdminRevenue,
      maxUsers: maxUsers ?? this.maxUsers,
    );
  }
}
