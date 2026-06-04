import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription states for ReplyMate users
enum SubscriptionStatus {
  loading,
  pending, // registered, isApproved=false, isBlocked=false
  active, // isApproved=true, subscription not expired
  expired, // isApproved=false, subscriptionEnd in the past
  blocked, // isBlocked=true
  unknown,
}

class SubscriptionInfo {
  final SubscriptionStatus status;
  final String planName;
  final DateTime? subscriptionEnd;
  final String? brokerId;
  final String? brokerCode;
  final bool isApproved;
  final bool isBlocked;
  final String? nextPlanId;
  final String? nextPlanName;
  final int? nextPlanDurationDays;

  const SubscriptionInfo({
    required this.status,
    this.planName = '',
    this.subscriptionEnd,
    this.brokerId,
    this.brokerCode,
    this.isApproved = false,
    this.isBlocked = false,
    this.nextPlanId,
    this.nextPlanName,
    this.nextPlanDurationDays,
  });

  static const loading = SubscriptionInfo(status: SubscriptionStatus.loading);
  static const unknown = SubscriptionInfo(status: SubscriptionStatus.unknown);

  int get daysRemaining {
    if (subscriptionEnd == null) return 0;
    final diff = subscriptionEnd!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isExpiringSoon => daysRemaining <= 7 && daysRemaining > 0;

  String get statusLabel {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.pending:
        return 'Pending Approval';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.blocked:
        return 'Suspended';
      default:
        return 'Unknown';
    }
  }

  String get expiryLabel {
    if (subscriptionEnd == null) return 'No plan assigned';
    final days = daysRemaining;
    if (days == 0) return 'Expires today';
    if (days < 0) return 'Expired';
    return '$days days remaining';
  }

  factory SubscriptionInfo.fromMap(Map<String, dynamic> data) {
    final isApproved = data['isApproved'] == true;
    final isBlocked = data['isBlocked'] == true;

    DateTime? subEnd;
    final rawEnd = data['subscriptionEnd'];
    if (rawEnd is Timestamp) subEnd = rawEnd.toDate();

    SubscriptionStatus status;
    if (isBlocked) {
      status = SubscriptionStatus.blocked;
    } else if (!isApproved) {
      status = SubscriptionStatus.pending;
    } else if (subEnd != null && subEnd.isBefore(DateTime.now())) {
      status = SubscriptionStatus.expired;
    } else {
      status = SubscriptionStatus.active;
    }

    return SubscriptionInfo(
      status: status,
      planName: (data['planName'] as String?)?.trim().isNotEmpty == true
          ? data['planName'] as String
          : (data['planId'] as String? ?? ''),
      subscriptionEnd: subEnd,
      brokerId: data['brokerId'],
      brokerCode: data['brokerCode'],
      isApproved: isApproved,
      isBlocked: isBlocked,
      nextPlanId: data['nextPlanId'] as String?,
      nextPlanName: data['nextPlanName'] as String?,
      nextPlanDurationDays: data['nextPlanDurationDays'] as int?,
    );
  }
}

/// Service that watches the current user's subscription in real-time.
/// This is the single source of truth for access control in the app.
class SubscriptionService {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _sub;
  final _controller = StreamController<SubscriptionInfo>.broadcast();

  /// Last known subscription info — used to seed new StreamBuilder subscribers
  /// so they always have a value instead of showing 'unknown' on first frame.
  SubscriptionInfo? _lastInfo;

  /// Stream that immediately replays the last known value to new subscribers.
  Stream<SubscriptionInfo> get stream async* {
    if (_lastInfo != null) yield _lastInfo!;
    yield* _controller.stream;
  }

  /// Start watching — call after user logs in.
  /// Pass [phone] (e.g. '+919022902102') to watch the phone-keyed doc;
  /// falls back to uid if phone is not provided.
  void startWatching(String uid, {String? phone}) {
    final docId = (phone != null && phone.trim().isNotEmpty)
        ? phone.trim()
        : uid;
    _sub?.cancel();
    _sub = _db
        .collection('users')
        .doc(docId)
        .snapshots()
        .listen(
          (snap) {
            if (!snap.exists || snap.data() == null) {
              _emit(SubscriptionInfo.unknown);
              return;
            }
            final info = SubscriptionInfo.fromMap(snap.data()!);

            // If subscription has expired but isApproved is still true,
            // write the expiry update (handles cases Cloud Function hasn't run yet)
            if (info.status == SubscriptionStatus.expired && info.isApproved) {
              _db
                  .collection('users')
                  .doc(docId)
                  .update({
                    'isApproved': false,
                    'status': 'expired',
                    'updatedAt': FieldValue.serverTimestamp(),
                  })
                  .catchError((_) {});
            }

            _emit(info);
          },
          onError: (_) {
            _emit(SubscriptionInfo.unknown);
          },
        );
  }

  void _emit(SubscriptionInfo info) {
    _lastInfo = info;
    _controller.add(info);
  }

  /// Stop watching — call on logout
  void stopWatching() {
    _sub?.cancel();
    _sub = null;
  }

  /// One-shot check (for splash screen).
  /// Pass [phone] to look up the phone-keyed doc first.
  Future<SubscriptionInfo> getOnce(String uid, {String? phone}) async {
    final docId = (phone != null && phone.trim().isNotEmpty)
        ? phone.trim()
        : uid;
    try {
      final snap = await _db.collection('users').doc(docId).get();
      if (!snap.exists || snap.data() == null) return SubscriptionInfo.unknown;
      return SubscriptionInfo.fromMap(snap.data()!);
    } catch (_) {
      return SubscriptionInfo.unknown;
    }
  }

  /// Validate a broker code — returns brokerId if valid, null otherwise
  Future<String?> validateBrokerCode(String code) async {
    if (code.trim().isEmpty) return null;
    final snap = await _db
        .collection('brokers')
        .where('brokerCode', isEqualTo: code.trim().toUpperCase())
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    
    final doc = snap.docs.first;
    final data = doc.data();
    final maxUsers = data['maxUsers'] ?? 0;
    final totalUsers = data['totalUsers'] ?? 0;
    if (maxUsers > 0 && totalUsers >= maxUsers) {
      throw Exception('Broker limit reached');
    }
    
    return doc.id;
  }

  /// Fetch broker details by brokerId
  Future<BrokerInfo?> getBrokerInfo(String brokerId) async {
    try {
      final snap = await _db.collection('brokers').doc(brokerId).get();
      if (!snap.exists || snap.data() == null) return null;
      return BrokerInfo.fromMap(snap.id, snap.data()!);
    } catch (_) {
      return null;
    }
  }

  /// Fetch admin settings - returns support email
  Future<AdminSettings?> getAdminSettings() async {
    try {
      final snap = await _db.collection('settings').doc('admin').get();
      if (!snap.exists || snap.data() == null) return null;
      return AdminSettings.fromMap(snap.data()!);
    } catch (_) {
      return null;
    }
  }
}

class AdminSettings {
  final String? supportEmail;
  final String? supportPhone;

  const AdminSettings({this.supportEmail, this.supportPhone});

  factory AdminSettings.fromMap(Map<String, dynamic> data) {
    return AdminSettings(
      supportEmail: data['supportEmail'] as String?,
      supportPhone: data['supportPhone'] as String?,
    );
  }
}

class BrokerInfo {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String brokerCode;

  const BrokerInfo({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    required this.brokerCode,
  });

  factory BrokerInfo.fromMap(String id, Map<String, dynamic> data) {
    return BrokerInfo(
      id: id,
      name: (data['name'] as String?)?.trim() ?? 'Unknown Broker',
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      brokerCode: (data['brokerCode'] as String?) ?? '',
    );
  }
}
