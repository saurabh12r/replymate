import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/replymet_user.dart';
import '../models/plan_model.dart';
import '../models/broker_model.dart';
import '../models/approval_model.dart';
import '../models/activity_log.dart';
import '../models/notification_model.dart';
import '../models/daily_stats.dart';
import '../models/campaign_model.dart';
import '../models/subscription_history_model.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_utils.dart';

/// Main Firestore service for all CRUD operations
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── PLANS ───────────────────────────────────────────────────────────────

  Stream<List<PlanModel>> plansStream() {
    return _db
        .collection(AppConstants.plansCollection)
        .snapshots()
        .map((s) => s.docs.map(PlanModel.fromDoc).toList());
  }

  Stream<List<PlanModel>> activePlansStream() {
    return _db
        .collection(AppConstants.plansCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(PlanModel.fromDoc).toList());
  }

  Future<void> createPlan(PlanModel plan) async {
    await _db
        .collection(AppConstants.plansCollection)
        .doc(plan.planId)
        .set({...plan.toMap(), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updatePlan(PlanModel plan) async {
    await _db
        .collection(AppConstants.plansCollection)
        .doc(plan.planId)
        .set({...plan.toMap(), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  Future<void> deletePlan(String planId) async {
    await _db.collection(AppConstants.plansCollection).doc(planId).delete();
  }

  // ─── BROKERS ─────────────────────────────────────────────────────────────

  Stream<List<BrokerModel>> brokersStream() {
    return _db
        .collection(AppConstants.brokersCollection)
        .snapshots()
        .map((s) => s.docs.map(BrokerModel.fromDoc).toList());
  }

  Future<BrokerModel?> getBroker(String brokerId) async {
    final doc = await _db
        .collection(AppConstants.brokersCollection)
        .doc(brokerId)
        .get();
    if (!doc.exists) return null;
    return BrokerModel.fromDoc(doc);
  }

  Stream<BrokerModel?> brokerStream(String brokerId) {
    return _db
        .collection(AppConstants.brokersCollection)
        .doc(brokerId)
        .snapshots()
        .map((doc) => doc.exists ? BrokerModel.fromDoc(doc) : null);
  }

  Future<void> createBroker(BrokerModel broker) async {
    await _db
        .collection(AppConstants.brokersCollection)
        .doc(broker.brokerId)
        .set({...broker.toMap(), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateBroker(BrokerModel broker) async {
    await _db
        .collection(AppConstants.brokersCollection)
        .doc(broker.brokerId)
        .update(broker.toMap());
  }

  Future<void> toggleBrokerStatus(String brokerId, bool isActive) async {
    await _db
        .collection(AppConstants.brokersCollection)
        .doc(brokerId)
        .update({'isActive': isActive});
  }

  Future<void> deleteBroker(String brokerId) async {
    await _db
        .collection(AppConstants.brokersCollection)
        .doc(brokerId)
        .delete();
  }

  // ─── REPLYMET USERS (the actual 'users' collection) ───────────────────────

  /// All users — handles both UID-based and phone-based documents
  Stream<List<ReplymetUser>> allUsersStream() {
    return _db
        .collection(AppConstants.replymetUsersCollection)
        .snapshots()
        .map((s) {
      final list = s.docs.map(ReplymetUser.fromDoc).toList();
      // Sort in-memory: newest first (handles mixed createdAt types)
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Stream<ReplymetUser?> userStream(String userId) {
    final decodedUserId = Uri.decodeComponent(userId);
    return _db
        .collection(AppConstants.replymetUsersCollection)
        .doc(decodedUserId)
        .snapshots()
        .map((doc) => doc.exists ? ReplymetUser.fromDoc(doc) : null);
  }

  Stream<List<SubscriptionHistoryModel>> subscriptionHistoryStream(String userId) {
    final decodedUserId = Uri.decodeComponent(userId);
    return _db
        .collection(AppConstants.replymetUsersCollection)
        .doc(decodedUserId)
        .collection('subscription_history')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(SubscriptionHistoryModel.fromDoc).toList());
  }

  /// Pending users — catches both those with status='pending' AND
  /// legacy users with isApproved=false (no status field yet)
  Stream<List<ReplymetUser>> allUsersWithDerivedStatusStream() {
    return allUsersStream();
  }

  /// Pending users for admin: isApproved=false AND not blocked AND no brokerId.
  /// Fetches all users and filters in-memory to handle legacy docs missing isApproved field.
  Stream<List<ReplymetUser>> adminPendingUsersStream() {
    return _db
        .collection(AppConstants.replymetUsersCollection)
        .snapshots()
        .map((s) {
      return s.docs
          .map(ReplymetUser.fromDoc)
          .where((u) => u.isPending && !u.hasBroker)
          .toList()
        ..sort((a, b) {
          final aTime = a.createdAt ?? DateTime(2000);
          final bTime = b.createdAt ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });
    });
  }

  /// Pending users for a specific broker: isApproved=false AND brokerId matches.
  /// Fetches all broker users and filters in-memory to handle legacy docs missing isApproved.
  Stream<List<ReplymetUser>> pendingUsersByBrokerStream(String brokerId) {
    return _db
        .collection(AppConstants.replymetUsersCollection)
        .where('brokerId', isEqualTo: brokerId)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map(ReplymetUser.fromDoc)
          .where((u) => u.isPending)
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// All users for a specific broker
  Stream<List<ReplymetUser>> usersByBrokerStream(String brokerId) {
    return _db
        .collection(AppConstants.replymetUsersCollection)
        .where('brokerId', isEqualTo: brokerId)
        .snapshots()
        .map((s) {
      final list = s.docs.map(ReplymetUser.fromDoc).toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Approve a user and assign subscription — atomically updates all related docs
  Future<void> approveUser({
    required String userId,
    required String approvedBy,
    required String approvedByRole,
    String? brokerId,
    required PlanModel plan,
    required DateTime startDate,
    required double brokerCommission,
    required double adminRevenue,
  }) async {
    if (brokerId != null && brokerId.isNotEmpty) {
      final brokerDoc = await _db.collection(AppConstants.brokersCollection).doc(brokerId).get();
      if (brokerDoc.exists) {
        final data = brokerDoc.data() ?? {};
        final maxUsers = data['maxUsers'] ?? 0;
        final totalUsers = data['totalUsers'] ?? 0;
        if (maxUsers > 0 && totalUsers >= maxUsers) {
          throw Exception('Broker has reached their limit of $maxUsers users.');
        }
      }
    }

    final endDate = AppUtils.calculateEndDate(startDate, plan.durationDays);
    final batch = _db.batch();

    // Check if user was already approved to decide whether to increment totalUsers
    final userDoc = await _db.collection(AppConstants.replymetUsersCollection).doc(userId).get();
    final wasApproved = userDoc.exists && (userDoc.data()?['isApproved'] ?? false) == true;

    // CHECK FOR OVERRIDE WITHIN 24 HOURS
    final approvalsSnap = await _db.collection(AppConstants.approvalsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('approvedAt', descending: true)
        .limit(1)
        .get();

    double oldAmount = 0.0;
    double oldCommission = 0.0;
    double oldAdminRevenue = 0.0;
    String? oldBrokerId;
    String? oldApprovedByRole;
    DocumentReference? oldApprovalRef;
    bool shouldDeduct = false;

    if (approvalsSnap.docs.isNotEmpty) {
      final doc = approvalsSnap.docs.first;
      final oldApproval = ApprovalModel.fromMap(doc.data(), doc.id);
      final approvedAt = oldApproval.approvedAt;
      if (approvedAt != null) {
        final diff = DateTime.now().difference(approvedAt);
        if (diff.inHours < 24) {
          shouldDeduct = true;
          oldAmount = oldApproval.amount;
          oldCommission = oldApproval.brokerCommission;
          oldAdminRevenue = oldApproval.adminRevenue;
          oldBrokerId = oldApproval.brokerId;
          oldApprovedByRole = oldApproval.approvedByRole;
          oldApprovalRef = doc.reference;
        }
      }
    }

    if (shouldDeduct) {
      batch.delete(oldApprovalRef!);
      if (oldApprovedByRole == 'broker' && oldBrokerId != null && oldBrokerId.isNotEmpty) {
        final oldBrokerRef = _db.collection(AppConstants.brokersCollection).doc(oldBrokerId);
        batch.update(oldBrokerRef, {
          'totalRevenue': FieldValue.increment(-oldAmount),
          'walletBalance': FieldValue.increment(-oldCommission),
          'totalAdminRevenue': FieldValue.increment(-oldAdminRevenue),
          'totalPendingPayment': FieldValue.increment(-oldAdminRevenue),
        });
      }
    }

    // 1. Update replymet user — sync isApproved/isBlocked for mobile app compatibility
    final userRef = _db.collection(AppConstants.replymetUsersCollection).doc(userId);
    batch.update(userRef, {
      'status': AppConstants.statusActive,
      'isApproved': true,      // ← ReplyMate mobile reads this to allow auto-reply
      'isBlocked': false,
      'approvedBy': approvedBy,
      'approvedByRole': approvedByRole,
      'brokerId': brokerId,
      'planId': plan.planId,
      'planName': plan.name,   // ← Mobile app reads this for display
      'subscriptionStart': Timestamp.fromDate(startDate),
      'subscriptionEnd': Timestamp.fromDate(endDate),
      'totalPaid': plan.price,
      'brokerCommission': shouldDeduct && oldApprovedByRole == 'broker' ? brokerCommission - oldCommission : brokerCommission,
      'adminRevenue': shouldDeduct ? adminRevenue - oldAdminRevenue : adminRevenue,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Create approval record
    final approvalId = AppUtils.generateId();
    final approvalRef = _db.collection(AppConstants.approvalsCollection).doc(approvalId);
    batch.set(approvalRef, ApprovalModel(
      approvalId: approvalId,
      userId: userId,
      approvedBy: approvedBy,
      approvedByRole: approvedByRole,
      brokerId: brokerId,
      planId: plan.planId,
      amount: plan.price,
      brokerCommission: brokerCommission,
      adminRevenue: adminRevenue,
      approvedAt: DateTime.now(),
    ).toMap());

    // 2b. Log subscription history
    final historyRef = userRef.collection('subscription_history').doc();
    batch.set(historyRef, {
      'planId': plan.planId,
      'planName': plan.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': AppConstants.statusActive,
      'amount': plan.price,
      'action': 'approved',
      'performedBy': approvedBy,
      'performedByRole': approvedByRole,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Update broker stats if broker approval
    if (brokerId != null && brokerId.isNotEmpty) {
      final brokerRef = _db.collection(AppConstants.brokersCollection).doc(brokerId);
      batch.update(brokerRef, {
        if (!wasApproved) 'totalUsers': FieldValue.increment(1),
        'totalRevenue': FieldValue.increment(plan.price),
        'walletBalance': FieldValue.increment(brokerCommission),
        'totalAdminRevenue': FieldValue.increment(adminRevenue),
        'totalPendingPayment': FieldValue.increment(adminRevenue),
      });
    }

    await batch.commit();

    // Create notifications for new user approval
    await _createApprovalNotification(userId, brokerId);
  }

  Future<void> _createApprovalNotification(String userId, String? brokerId) async {
    final userDoc = await _db.collection(AppConstants.replymetUsersCollection).doc(userId).get();
    if (!userDoc.exists) return;
    
    final user = ReplymetUser.fromDoc(userDoc);
    final notificationId = AppUtils.generateId();

    if (brokerId != null && brokerId.isNotEmpty) {
      await createNotification(AppNotification(
        id: notificationId,
        title: 'New User Approved',
        message: '${user.name} (${user.phone}) has been approved with a plan.',
        type: NotificationType.newUserRegistered,
        userId: user.uid,
        userName: user.name,
        userPhone: user.phone,
        targetRole: 'broker',
        targetId: brokerId,
        createdAt: DateTime.now(),
      ));
    }

    await createNotification(AppNotification(
      id: '${notificationId}_admin',
      title: 'New User Approved',
      message: '${user.name} (${user.phone}) has been approved${brokerId != null ? ' via broker' : ''}.',
      type: NotificationType.newUserRegistered,
      userId: user.uid,
      userName: user.name,
      userPhone: user.phone,
      targetRole: 'admin',
      createdAt: DateTime.now(),
    ));
  }

  /// Update user status — syncs isApproved/isBlocked for ReplyMate mobile app
  Future<void> updateUserStatus(String userId, String status, {String performedBy = 'portal', String performedByRole = 'portal'}) async {
    final userRef = _db.collection(AppConstants.replymetUsersCollection).doc(userId);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;
    final userData = userDoc.data() ?? {};

    final Map<String, dynamic> update = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    // Critical: mobile app checks isApproved && !isBlocked to allow auto-reply
    if (status == AppConstants.statusActive) {
      update['isApproved'] = true;
      update['isBlocked'] = false;
    } else if (status == AppConstants.statusSuspended) {
      update['isApproved'] = false;
      update['isBlocked'] = true;  // ← shows "You have been blocked" in mobile app
    } else if (status == AppConstants.statusExpired) {
      update['isApproved'] = false;
      update['isBlocked'] = false;
    }

    final batch = _db.batch();
    batch.update(userRef, update);

    final historyRef = userRef.collection('subscription_history').doc();
    batch.set(historyRef, {
      'planId': userData['planId'] ?? '',
      'planName': userData['planName'] ?? 'None',
      'startDate': userData['subscriptionStart'],
      'endDate': userData['subscriptionEnd'],
      'status': status,
      'amount': (userData['totalPaid'] ?? 0.0).toDouble(),
      'action': status == AppConstants.statusSuspended
          ? 'suspended'
          : (status == AppConstants.statusActive ? 'activated' : 'expired'),
      'performedBy': performedBy,
      'performedByRole': performedByRole,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Delete/Remove user plan and reset subscription status
  Future<void> removeUserPlan(String userId, {required String performedBy, required String performedByRole}) async {
    final userRef = _db.collection(AppConstants.replymetUsersCollection).doc(userId);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;

    final data = userDoc.data() ?? {};
    final brokerId = data['brokerId'] as String?;
    final isApproved = data['isApproved'] as bool? ?? false;

    final batch = _db.batch();

    batch.update(userRef, {
      'status': AppConstants.statusPending,
      'isApproved': false,
      'approvedBy': FieldValue.delete(),
      'approvedByRole': FieldValue.delete(),
      'planId': FieldValue.delete(),
      'planName': FieldValue.delete(),
      'subscriptionStart': FieldValue.delete(),
      'subscriptionEnd': FieldValue.delete(),
      'totalPaid': 0.0,
      'brokerCommission': 0.0,
      'adminRevenue': 0.0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Reset broker totalUsers if the user was approved
    if (brokerId != null && brokerId.isNotEmpty && isApproved) {
      final brokerRef = _db.collection(AppConstants.brokersCollection).doc(brokerId);
      batch.update(brokerRef, {
        'totalUsers': FieldValue.increment(-1),
      });
    }

    // Log subscription history for plan removal
    final historyRef = userRef.collection('subscription_history').doc();
    batch.set(historyRef, {
      'planId': data['planId'] ?? '',
      'planName': data['planName'] ?? 'None',
      'startDate': data['subscriptionStart'],
      'endDate': data['subscriptionEnd'],
      'status': AppConstants.statusPending,
      'amount': (data['totalPaid'] ?? 0.0).toDouble(),
      'action': 'plan_removed',
      'performedBy': performedBy,
      'performedByRole': performedByRole,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Delete/Remove user queued plan
  Future<void> removeQueuePlan(
    String userId, {
    required String performedBy,
    required String performedByRole,
  }) async {
    final userRef = _db.collection(AppConstants.replymetUsersCollection).doc(userId);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;

    final data = userDoc.data() ?? {};
    final nextPlanId = data['nextPlanId'] as String?;
    final brokerId = data['brokerId'] as String?;

    if (nextPlanId == null || nextPlanId.isEmpty) return;

    final batch = _db.batch();

    // Revert broker stats if broker exists
    if (brokerId != null && brokerId.isNotEmpty) {
      // Fetch plan to get price
      final planDoc = await _db.collection(AppConstants.plansCollection).doc(nextPlanId).get();
      final brokerDoc = await _db.collection(AppConstants.brokersCollection).doc(brokerId).get();
      if (planDoc.exists && brokerDoc.exists) {
        final planPrice = (planDoc.data()?['price'] ?? 0.0).toDouble();
        final commissionPercent = (brokerDoc.data()?['commissionPercent'] ?? 0.0).toDouble();
        final brokerCommission = planPrice * commissionPercent / 100;
        final adminRevenue = planPrice - brokerCommission;

        batch.update(_db.collection(AppConstants.brokersCollection).doc(brokerId), {
          'totalRevenue': FieldValue.increment(-planPrice),
          'walletBalance': FieldValue.increment(-brokerCommission),
          'totalAdminRevenue': FieldValue.increment(-adminRevenue),
        });
      }
    }

    batch.update(userRef, {
      'nextPlanId': FieldValue.delete(),
      'nextPlanName': FieldValue.delete(),
      'nextPlanDurationDays': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log subscription history for queue plan removal
    final historyRef = userRef.collection('subscription_history').doc();
    batch.set(historyRef, {
      'planId': nextPlanId,
      'planName': data['nextPlanName'] ?? 'None',
      'startDate': null,
      'endDate': null,
      'status': 'queued_removed',
      'amount': 0.0,
      'action': 'queue_removed',
      'performedBy': performedBy,
      'performedByRole': performedByRole,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Move user from broker to admin (direct management)
  Future<void> moveUserToAdmin(String userId) async {
    final userDoc = await _db.collection(AppConstants.replymetUsersCollection).doc(userId).get();
    if (!userDoc.exists) return;

    final data = userDoc.data();
    final brokerId = data?['brokerId'] as String?;
    final isApproved = data?['isApproved'] as bool? ?? false;

    final Map<String, dynamic> update = {
      'brokerId': FieldValue.delete(),
      'brokerCode': FieldValue.delete(),
      'brokerCommission': 0.0,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();
    batch.update(_db.collection(AppConstants.replymetUsersCollection).doc(userId), update);

    if (brokerId != null && brokerId.isNotEmpty && isApproved) {
      final brokerRef = _db.collection(AppConstants.brokersCollection).doc(brokerId);
      batch.update(brokerRef, {
        'totalUsers': FieldValue.increment(-1),
      });
    }

    await batch.commit();
  }

  /// Assign a user to a broker (from Direct Admin or another broker)
  Future<void> assignUserToBroker(String userId, String brokerId) async {
    final userDoc = await _db.collection(AppConstants.replymetUsersCollection).doc(userId).get();
    if (!userDoc.exists) return;

    final user = ReplymetUser.fromDoc(userDoc);
    final oldBrokerId = user.brokerId;
    final isApproved = user.isApproved;

    // Fetch new broker to get brokerCode and check limits
    final brokerDoc = await _db.collection(AppConstants.brokersCollection).doc(brokerId).get();
    if (!brokerDoc.exists) {
      throw Exception('Broker not found');
    }
    final brokerData = brokerDoc.data() ?? {};
    final brokerCode = brokerData['brokerCode'] as String? ?? '';
    final maxUsers = brokerData['maxUsers'] as int? ?? 0;
    final totalUsers = brokerData['totalUsers'] as int? ?? 0;

    // If active/approved, check maxUsers limit on new broker
    if (isApproved && maxUsers > 0 && totalUsers >= maxUsers) {
      throw Exception('Broker has reached their limit of $maxUsers users.');
    }

    final batch = _db.batch();

    // 1. Update user with new brokerId and brokerCode
    batch.update(_db.collection(AppConstants.replymetUsersCollection).doc(userId), {
      'brokerId': brokerId,
      'brokerCode': brokerCode,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Decrement old broker count if it existed and user was approved
    if (oldBrokerId != null && oldBrokerId.isNotEmpty && isApproved) {
      batch.update(_db.collection(AppConstants.brokersCollection).doc(oldBrokerId), {
        'totalUsers': FieldValue.increment(-1),
      });
    }

    // 3. Increment new broker count if user is approved
    if (isApproved) {
      batch.update(_db.collection(AppConstants.brokersCollection).doc(brokerId), {
        'totalUsers': FieldValue.increment(1),
      });
    }

    await batch.commit();
  }

  /// Assign/renew a plan for an existing user (including expired users)
  Future<void> assignPlanToUser({
    required String userId,
    required String approvedBy,
    required String approvedByRole,
    required PlanModel plan,
    String? brokerId,
    required double brokerCommission,
    required double adminRevenue,
    DateTime? startDate,
  }) async {
    final finalStartDate = startDate ?? DateTime.now();
    final endDate = AppUtils.calculateEndDate(finalStartDate, plan.durationDays);
    final batch = _db.batch();

    // CHECK FOR OVERRIDE WITHIN 24 HOURS
    final approvalsSnap = await _db.collection(AppConstants.approvalsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('approvedAt', descending: true)
        .limit(1)
        .get();

    double oldAmount = 0.0;
    double oldCommission = 0.0;
    double oldAdminRevenue = 0.0;
    String? oldBrokerId;
    String? oldApprovedByRole;
    DocumentReference? oldApprovalRef;
    bool shouldDeduct = false;

    if (approvalsSnap.docs.isNotEmpty) {
      final doc = approvalsSnap.docs.first;
      final oldApproval = ApprovalModel.fromMap(doc.data(), doc.id);
      final approvedAt = oldApproval.approvedAt;
      if (approvedAt != null) {
        final diff = DateTime.now().difference(approvedAt);
        if (diff.inHours < 24) {
          shouldDeduct = true;
          oldAmount = oldApproval.amount;
          oldCommission = oldApproval.brokerCommission;
          oldAdminRevenue = oldApproval.adminRevenue;
          oldBrokerId = oldApproval.brokerId;
          oldApprovedByRole = oldApproval.approvedByRole;
          oldApprovalRef = doc.reference;
        }
      }
    }

    if (shouldDeduct) {
      batch.delete(oldApprovalRef!);
      if (oldApprovedByRole == 'broker' && oldBrokerId != null && oldBrokerId.isNotEmpty) {
        final oldBrokerRef = _db.collection(AppConstants.brokersCollection).doc(oldBrokerId);
        batch.update(oldBrokerRef, {
          'totalRevenue': FieldValue.increment(-oldAmount),
          'walletBalance': FieldValue.increment(-oldCommission),
          'totalAdminRevenue': FieldValue.increment(-oldAdminRevenue),
          'totalPendingPayment': FieldValue.increment(-oldAdminRevenue),
        });
      }
    }

    final userRef = _db.collection(AppConstants.replymetUsersCollection).doc(userId);
    batch.update(userRef, {
      'status': AppConstants.statusActive,
      'isApproved': true,
      'isBlocked': false,
      'planId': plan.planId,
      'planName': plan.name,
      'subscriptionStart': Timestamp.fromDate(finalStartDate),
      'subscriptionEnd': Timestamp.fromDate(endDate),
      'totalPaid': plan.price,
      'brokerCommission': FieldValue.increment(shouldDeduct && oldApprovedByRole == 'broker' ? brokerCommission - oldCommission : brokerCommission),
      'adminRevenue': FieldValue.increment(shouldDeduct ? adminRevenue - oldAdminRevenue : adminRevenue),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final approvalId = AppUtils.generateId();
    final approvalRef = _db.collection(AppConstants.approvalsCollection).doc(approvalId);
    batch.set(approvalRef, ApprovalModel(
      approvalId: approvalId,
      userId: userId,
      approvedBy: approvedBy,
      approvedByRole: approvedByRole,
      brokerId: brokerId,
      planId: plan.planId,
      amount: plan.price,
      brokerCommission: brokerCommission,
      adminRevenue: adminRevenue,
      approvedAt: DateTime.now(),
    ).toMap());

    final historyRef = userRef.collection('subscription_history').doc();
    batch.set(historyRef, {
      'planId': plan.planId,
      'planName': plan.name,
      'startDate': Timestamp.fromDate(finalStartDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': AppConstants.statusActive,
      'amount': plan.price,
      'action': 'assigned',
      'performedBy': approvedBy,
      'performedByRole': approvedByRole,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (brokerId != null && brokerId.isNotEmpty) {
      final brokerRef = _db.collection(AppConstants.brokersCollection).doc(brokerId);
      batch.update(brokerRef, {
        'totalRevenue': FieldValue.increment(plan.price),
        'walletBalance': FieldValue.increment(brokerCommission),
        'totalAdminRevenue': FieldValue.increment(adminRevenue),
      });
    }

    await batch.commit();
  }

  /// Queue a future plan that will activate when the current plan expires
  Future<void> queueNextPlanForUser({
    required String userId,
    required String approvedBy,
    required String approvedByRole,
    required PlanModel plan,
    String? brokerId,
    required double brokerCommission,
    required double adminRevenue,
    DateTime? startDate,
  }) async {
    final batch = _db.batch();

    final userRef = _db.collection(AppConstants.replymetUsersCollection).doc(userId);

    Timestamp? nextPlanStartTimestamp;
    Timestamp? nextPlanEndTimestamp;
    if (startDate != null) {
      nextPlanStartTimestamp = Timestamp.fromDate(startDate);
      final endDate = AppUtils.calculateEndDate(startDate, plan.durationDays);
      nextPlanEndTimestamp = Timestamp.fromDate(endDate);
    }

    batch.update(userRef, {
      'nextPlanId': plan.planId,
      'nextPlanName': plan.name,
      'nextPlanDurationDays': plan.durationDays,
      'nextPlanStartDate': nextPlanStartTimestamp,
      'nextPlanEndDate': nextPlanEndTimestamp,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final historyRef = userRef.collection('subscription_history').doc();
    batch.set(historyRef, {
      'planId': plan.planId,
      'planName': plan.name,
      'startDate': nextPlanStartTimestamp,
      'endDate': nextPlanEndTimestamp,
      'status': 'queued',
      'amount': plan.price,
      'action': 'queued',
      'performedBy': approvedBy,
      'performedByRole': approvedByRole,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final approvalId = AppUtils.generateId();
    final approvalRef = _db.collection(AppConstants.approvalsCollection).doc(approvalId);
    batch.set(approvalRef, ApprovalModel(
      approvalId: approvalId,
      userId: userId,
      approvedBy: approvedBy,
      approvedByRole: approvedByRole,
      brokerId: brokerId,
      planId: plan.planId,
      amount: plan.price,
      brokerCommission: brokerCommission,
      adminRevenue: adminRevenue,
      approvedAt: DateTime.now(),
    ).toMap());

    if (brokerId != null && brokerId.isNotEmpty) {
      final brokerRef = _db.collection(AppConstants.brokersCollection).doc(brokerId);
      batch.update(brokerRef, {
        'totalRevenue': FieldValue.increment(plan.price),
        'walletBalance': FieldValue.increment(brokerCommission),
        'totalAdminRevenue': FieldValue.increment(adminRevenue),
      });
    }

    await batch.commit();
  }

  /// Update payment for a user
  Future<void> updatePayment({
    required String userId,
    required double amount,
    required bool isFullPayment,
  }) async {
    final userDoc = await _db.collection(AppConstants.replymetUsersCollection).doc(userId).get();
    if (!userDoc.exists) return;
    
    final currentReceived = (userDoc.data()?['paymentReceived'] ?? 0).toDouble();
    final totalAmount = (userDoc.data()?['totalPaid'] ?? 0).toDouble();
    final newReceived = currentReceived + amount;
    
    String status = 'partial';
    if (isFullPayment || newReceived >= totalAmount) {
      status = 'paid';
    }
    
    await _db.collection(AppConstants.replymetUsersCollection).doc(userId).update({
      'paymentReceived': newReceived,
      'paymentStatus': status,
      'paymentDate': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Record payment from broker to admin (admin receives money from broker)
  Future<void> recordBrokerPayment({
    required String brokerId,
    required double amount,
    required String receivedBy,
  }) async {
    final brokerDoc = await _db.collection(AppConstants.brokersCollection).doc(brokerId).get();
    if (!brokerDoc.exists) return;

    final currentPaid = (brokerDoc.data()?['totalPaidToAdmin'] ?? 0).toDouble();
    final pending = (brokerDoc.data()?['totalPendingPayment'] ?? 0).toDouble();
    final newPaid = currentPaid + amount;
    final newPending = (pending - amount).clamp(0, double.infinity);

    await _db.collection(AppConstants.brokersCollection).doc(brokerId).update({
      'totalPaidToAdmin': newPaid,
      'totalPendingPayment': newPending,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await logActivity(ActivityLog(
      logId: AppUtils.generateId(),
      action: 'Received ₹${amount.toStringAsFixed(2)} from broker',
      performedBy: receivedBy,
      performedByRole: 'admin',
      targetId: brokerId,
      targetType: 'broker_payment',
      createdAt: DateTime.now(),
    ));
  }

  /// Auto-expire subscriptions that have passed end date
  Future<int> expireOverdueSubscriptions() async {
    final snap = await _db
        .collection(AppConstants.replymetUsersCollection)
        .where('isApproved', isEqualTo: true)
        .where('subscriptionEnd', isLessThan: Timestamp.fromDate(DateTime.now()))
        .get();

    if (snap.docs.isEmpty) return 0;

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'status': AppConstants.statusExpired,
        'isApproved': false,   // ← disables auto-reply in mobile app
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final historyRef = doc.reference.collection('subscription_history').doc();
      final data = doc.data();
      batch.set(historyRef, {
        'planId': data['planId'] ?? '',
        'planName': data['planName'] ?? 'None',
        'startDate': data['subscriptionStart'],
        'endDate': data['subscriptionEnd'],
        'status': AppConstants.statusExpired,
        'amount': (data['totalPaid'] ?? 0.0).toDouble(),
        'action': 'expired',
        'performedBy': 'system',
        'performedByRole': 'system',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return snap.docs.length;
  }

  // ─── APPROVALS ────────────────────────────────────────────────────────────

  Stream<List<ApprovalModel>> approvalsStream() {
    return _db
        .collection(AppConstants.approvalsCollection)
        .orderBy('approvedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(ApprovalModel.fromDoc).toList());
  }

  Stream<List<ApprovalModel>> brokerApprovalsStream(String brokerId) {
    return _db
        .collection(AppConstants.approvalsCollection)
        .where('brokerId', isEqualTo: brokerId)
        .snapshots()
        .map((s) {
      final list = s.docs.map(ApprovalModel.fromDoc).toList();
      list.sort((a, b) {
        final aTime = a.approvedAt;
        final bTime = b.approvedAt;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // descending
      });
      return list;
    });
  }

  // ─── ACTIVITY LOGS ────────────────────────────────────────────────────────

  Future<void> logActivity(ActivityLog log) async {
    await _db
        .collection(AppConstants.logsCollection)
        .doc(log.logId)
        .set({...log.toMap(), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<ApprovalModel?> getLatestApprovalForUser(String userId) async {
    final snap = await _db.collection(AppConstants.approvalsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('approvedAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return ApprovalModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  Stream<List<ActivityLog>> activityLogsStream({int limit = 50}) {
    return _db
        .collection(AppConstants.logsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(ActivityLog.fromDoc).toList());
  }

  // ─── ANALYTICS ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMonthlyRevenue() async {
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    final snap = await _db
        .collection(AppConstants.approvalsCollection)
        .where('approvedAt', isGreaterThan: Timestamp.fromDate(sixMonthsAgo))
        .orderBy('approvedAt')
        .get();

    final Map<String, double> monthlyData = {};
    for (final doc in snap.docs) {
      final approval = ApprovalModel.fromDoc(doc);
      if (approval.approvedAt != null) {
        final key = '${approval.approvedAt!.year}-${approval.approvedAt!.month.toString().padLeft(2, '0')}';
        monthlyData[key] = (monthlyData[key] ?? 0) + approval.adminRevenue;
      }
    }
    return monthlyData.entries
        .map((e) => {'month': e.key, 'revenue': e.value})
        .toList();
  }

  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    // Fetch all users in-memory (small dataset) to handle derived status
    final allUsersSnap = await _db
        .collection(AppConstants.replymetUsersCollection)
        .get();
    final allUsers = allUsersSnap.docs.map(ReplymetUser.fromDoc).toList();

    final totalUsers = allUsers.length;
    final activeUsers = allUsers.where((u) => u.isActive).length;
    final pendingUsers = allUsers.where((u) => u.isPending && !u.hasBroker).length;

    final brokersSnap = await _db.collection(AppConstants.brokersCollection).count().get();

    // Total admin revenue from approvals
    final revenueSnap = await _db.collection(AppConstants.approvalsCollection).get();
    double totalRevenue = 0;
    for (final doc in revenueSnap.docs) {
      totalRevenue += (doc.data()['adminRevenue'] ?? 0).toDouble();
    }

    return {
      'totalUsers': totalUsers,
      'activeSubscriptions': activeUsers,
      'totalBrokers': brokersSnap.count ?? 0,
      'pendingApprovals': pendingUsers,
      'totalRevenue': totalRevenue,
    };
  }

  // ─── NOTIFICATIONS ─────────────────────────────────────────────────────────

  Stream<List<AppNotification>> notificationsStream(String targetRole, {String? targetId}) {
    Query query = _db.collection('notifications').where('targetRole', isEqualTo: targetRole);
    if (targetId != null) {
      query = query.where('targetId', isEqualTo: targetId);
    }
    return query.snapshots().map(
      (s) {
        final list = s.docs.map((doc) {
          final data = doc.data();
          return AppNotification.fromMap(doc.id, data as Map<String, dynamic>);
        }).toList();
        list.sort((a, b) {
          final aTime = a.createdAt;
          final bTime = b.createdAt;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // descending order (newest first)
        });
        return list;
      },
    );
  }

  Future<void> createNotification(AppNotification notification) async {
    await _db.collection('notifications').doc(notification.id).set(notification.toMap());
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllNotificationsRead(String targetRole, {String? targetId}) async {
    final query = _db.collection('notifications')
        .where('targetRole', isEqualTo: targetRole)
        .where('isRead', isEqualTo: false);
    
    final snapshot = await query.get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }

  // Create notification for new user registration
  Future<void> notifyNewUserRegistration(ReplymetUser user) async {
    final notificationId = AppUtils.generateId();

    if (user.brokerId != null && user.brokerId!.isNotEmpty) {
      await createNotification(AppNotification(
        id: notificationId,
        title: 'New User Registered',
        message: '${user.name} (${user.phone}) registered via your broker code.',
        type: NotificationType.newUserRegistered,
        userId: user.uid,
        userName: user.name,
        userPhone: user.phone,
        targetRole: 'broker',
        targetId: user.brokerId,
        createdAt: DateTime.now(),
      ));
    }

    await createNotification(AppNotification(
      id: '${notificationId}_admin',
      title: 'New User Registered',
      message: '${user.name} (${user.phone}) has registered${user.brokerId != null ? ' via broker' : ''}.',
      type: NotificationType.newUserRegistered,
      userId: user.uid,
      userName: user.name,
      userPhone: user.phone,
      targetRole: 'admin',
      createdAt: DateTime.now(),
    ));
  }

  // Create notification for expiring subscriptions (called by scheduled job)
  Future<void> notifyExpiringSubscriptions() async {
    final oneDayFromNow = DateTime.now().add(const Duration(days: 1));
    final usersSnap = await _db.collection(AppConstants.replymetUsersCollection)
        .where('subscriptionEnd', isLessThanOrEqualTo: Timestamp.fromDate(oneDayFromNow))
        .where('subscriptionEnd', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .where('status', isEqualTo: 'active')
        .get();

    for (final userDoc in usersSnap.docs) {
      final user = ReplymetUser.fromDoc(userDoc);
      
      // Only notify if there is no queue plan
      if (user.nextPlanId != null && user.nextPlanId!.isNotEmpty) {
        continue;
      }
      
      final diff = user.subscriptionEnd!.difference(DateTime.now());
      final hoursLeft = diff.inHours;
      final timeStr = hoursLeft > 24 ? '${diff.inDays} day(s)' : '$hoursLeft hour(s)';

      // 1. Notify Broker
      if (user.brokerId != null && user.brokerId!.isNotEmpty) {
        await createNotification(AppNotification(
          id: AppUtils.generateId(),
          title: 'Subscription Expiring Soon',
          message: '${user.name}\'s subscription expires in $timeStr.',
          type: NotificationType.subscriptionExpiringSoon,
          userId: user.uid,
          userName: user.name,
          userPhone: user.phone,
          targetRole: 'broker',
          targetId: user.brokerId!,
          createdAt: DateTime.now(),
        ));
      }

      // 2. Notify Admin
      await createNotification(AppNotification(
        id: AppUtils.generateId(),
        title: 'Subscription Expiring Soon',
        message: '${user.name}\'s subscription expires in $timeStr.',
        type: NotificationType.subscriptionExpiringSoon,
        userId: user.uid,
        userName: user.name,
        userPhone: user.phone,
        targetRole: 'admin',
        createdAt: DateTime.now(),
      ));

      // 3. Notify User
      await createNotification(AppNotification(
        id: AppUtils.generateId(),
        title: 'Subscription Expiring Soon',
        message: 'Your subscription expires in $timeStr. Please renew your plan.',
        type: NotificationType.subscriptionExpiringSoon,
        userId: user.uid,
        userName: user.name,
        userPhone: user.phone,
        targetRole: 'user',
        targetId: user.uid,
        createdAt: DateTime.now(),
      ));
    }
  }

  // Create notification for expired subscriptions
  Future<void> notifyExpiredSubscriptions() async {
    final now = DateTime.now();
    final usersSnap = await _db.collection(AppConstants.replymetUsersCollection)
        .where('subscriptionEnd', isLessThan: Timestamp.fromDate(now))
        .where('status', isEqualTo: 'active')
        .get();

    for (final userDoc in usersSnap.docs) {
      final user = ReplymetUser.fromDoc(userDoc);
      
      if (user.brokerId != null) {
        await createNotification(AppNotification(
          id: AppUtils.generateId(),
          title: 'Subscription Expired',
          message: '${user.name}\'s subscription has expired.',
          type: NotificationType.subscriptionExpired,
          userId: user.uid,
          userName: user.name,
          userPhone: user.phone,
          targetRole: 'broker',
          targetId: user.brokerId,
          createdAt: DateTime.now(),
        ));
      }

      await createNotification(AppNotification(
        id: AppUtils.generateId(),
        title: 'Subscription Expired',
        message: '${user.name}\'s subscription has expired.',
        type: NotificationType.subscriptionExpired,
        userId: user.uid,
        userName: user.name,
        userPhone: user.phone,
        targetRole: 'admin',
        createdAt: DateTime.now(),
      ));
    }
  }

  /// Delete a user permanently
  Future<void> deleteUser(String userId) async {
    final userDoc = await _db.collection(AppConstants.replymetUsersCollection).doc(userId).get();
    if (!userDoc.exists) return;

    final data = userDoc.data();
    final brokerId = data?['brokerId'] as String?;
    final isApproved = data?['isApproved'] as bool? ?? false;

    final batch = _db.batch();
    batch.delete(_db.collection(AppConstants.replymetUsersCollection).doc(userId));

    if (brokerId != null && brokerId.isNotEmpty && isApproved) {
      final brokerRef = _db.collection(AppConstants.brokersCollection).doc(brokerId);
      batch.update(brokerRef, {
        'totalUsers': FieldValue.increment(-1),
      });
    }

    await batch.commit();
  }

  // ─── DAILY STATS ────────────────────────────────────────────────────────────

  String _getDateId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getMonthId(int year, int month) {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  Future<void> incrementSmsSent({String? brokerId}) async {
    final now = DateTime.now();
    final dailyId = _getDateId(now);
    final batch = _db.batch();

    final dailyRef = _db.collection(AppConstants.dailyStatsCollection).doc(dailyId);
    batch.set(dailyRef, {
      'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
      'smsSent': FieldValue.increment(1),
    }, SetOptions(merge: true));

    final monthId = _getMonthId(now.year, now.month);
    final monthlyRef = _db.collection(AppConstants.monthlyStatsCollection).doc(monthId);
    batch.set(monthlyRef, {
      'year': now.year,
      'month': now.month,
      'smsSent': FieldValue.increment(1),
    }, SetOptions(merge: true));

    if (brokerId != null) {
      final brokerRef = _db.collection(AppConstants.brokersCollection).doc(brokerId);
      batch.update(brokerRef, {
        'totalRevenue': FieldValue.increment(1),
      });
    }

    await batch.commit();
  }

  Future<void> incrementSmsFailed() async {
    final now = DateTime.now();
    final dailyId = _getDateId(now);
    final batch = _db.batch();

    final dailyRef = _db.collection(AppConstants.dailyStatsCollection).doc(dailyId);
    batch.set(dailyRef, {
      'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
      'smsFailed': FieldValue.increment(1),
    }, SetOptions(merge: true));

    final monthId = _getMonthId(now.year, now.month);
    final monthlyRef = _db.collection(AppConstants.monthlyStatsCollection).doc(monthId);
    batch.set(monthlyRef, {
      'year': now.year,
      'month': now.month,
      'smsFailed': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> incrementCallReceived({bool missed = false}) async {
    final now = DateTime.now();
    final dailyId = _getDateId(now);
    final batch = _db.batch();

    final dailyRef = _db.collection(AppConstants.dailyStatsCollection).doc(dailyId);
    batch.set(dailyRef, {
      'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
      'callsReceived': FieldValue.increment(1),
      if (missed) 'missedCalls': FieldValue.increment(1),
    }, SetOptions(merge: true));

    final monthId = _getMonthId(now.year, now.month);
    final monthlyRef = _db.collection(AppConstants.monthlyStatsCollection).doc(monthId);
    batch.set(monthlyRef, {
      'year': now.year,
      'month': now.month,
      'callsReceived': FieldValue.increment(1),
      if (missed) 'missedCalls': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> incrementNewUser({bool renewed = false}) async {
    final now = DateTime.now();
    final dailyId = _getDateId(now);
    final batch = _db.batch();

    final dailyRef = _db.collection(AppConstants.dailyStatsCollection).doc(dailyId);
    batch.set(dailyRef, {
      'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
      renewed ? 'renewedUsers' : 'newUsers': FieldValue.increment(1),
    }, SetOptions(merge: true));

    final monthId = _getMonthId(now.year, now.month);
    final monthlyRef = _db.collection(AppConstants.monthlyStatsCollection).doc(monthId);
    batch.set(monthlyRef, {
      'year': now.year,
      'month': now.month,
      renewed ? 'renewedUsers' : 'newUsers': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> incrementExpiredUser() async {
    final now = DateTime.now();
    final dailyId = _getDateId(now);

    await _db.collection(AppConstants.dailyStatsCollection).doc(dailyId).set({
      'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
      'expiredUsers': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // Get aggregated daily stats — reads from global daily_stats collection
  // and from each user's stats/{uid}/daily/{dateId} subcollection.
  Stream<List<DailyStats>> dailyStatsStream({int days = 30}) {
    final now = DateTime.now();
    // Stream the global daily_stats collection for real-time updates
    return _db
        .collection(AppConstants.dailyStatsCollection)
        .snapshots()
        .asyncMap((globalSnap) async {
      final Map<String, Map<String, int>> globalData = {};
      for (final doc in globalSnap.docs) {
        final d = doc.data();
        globalData[doc.id] = {
          'smsSent': (d['smsSent'] ?? 0) as int,
          'smsFailed': (d['smsFailed'] ?? 0) as int,
          'callsReceived': (d['callsReceived'] ?? 0) as int,
          'missedCalls': (d['missedCalls'] ?? 0) as int,
          'incomingCalls': (d['incomingCalls'] ?? 0) as int,
          'outgoingCalls': (d['outgoingCalls'] ?? 0) as int,
          'scheduledSmsSent': (d['scheduledSmsSent'] ?? 0) as int,
          'scheduledSmsFailed': (d['scheduledSmsFailed'] ?? 0) as int,
          'vacationSent': (d['vacationSent'] ?? 0) as int,
          'vacationFailed': (d['vacationFailed'] ?? 0) as int,
          'newUsers': (d['newUsers'] ?? 0) as int,
          'renewedUsers': (d['renewedUsers'] ?? 0) as int,
          'expiredUsers': (d['expiredUsers'] ?? 0) as int,
        };
      }

      final List<DailyStats> results = [];
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateId = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final g = globalData[dateId] ?? {};
        results.add(DailyStats(
          id: dateId,
          date: date,
          smsSent: g['smsSent'] ?? 0,
          smsFailed: g['smsFailed'] ?? 0,
          callsReceived: g['callsReceived'] ?? 0,
          missedCalls: g['missedCalls'] ?? 0,
          incomingCalls: g['incomingCalls'] ?? 0,
          outgoingCalls: g['outgoingCalls'] ?? 0,
          scheduledSmsSent: g['scheduledSmsSent'] ?? 0,
          scheduledSmsFailed: g['scheduledSmsFailed'] ?? 0,
          vacationSent: g['vacationSent'] ?? 0,
          vacationFailed: g['vacationFailed'] ?? 0,
          newUsers: g['newUsers'] ?? 0,
          renewedUsers: g['renewedUsers'] ?? 0,
          expiredUsers: g['expiredUsers'] ?? 0,
          createdAt: date,
        ));
      }
      return results;
    });
  }

  // Get aggregated monthly stats — reads from global monthly_stats collection.
  Stream<List<MonthlyStats>> monthlyStatsStream({int months = 12}) {
    return _db
        .collection(AppConstants.monthlyStatsCollection)
        .snapshots()
        .asyncMap((globalSnap) async {
      final now = DateTime.now();
      final Map<String, Map<String, dynamic>> globalData = {};
      for (final doc in globalSnap.docs) {
        final d = doc.data();
        globalData[doc.id] = d;
      }

      final List<MonthlyStats> results = [];
      for (int i = 0; i < months; i++) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthId = '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';
        final g = globalData[monthId] ?? {};
        results.add(MonthlyStats(
          id: monthId,
          year: monthDate.year,
          month: monthDate.month,
          smsSent: (g['smsSent'] ?? 0) as int,
          smsFailed: (g['smsFailed'] ?? 0) as int,
          callsReceived: (g['callsReceived'] ?? 0) as int,
          missedCalls: (g['missedCalls'] ?? 0) as int,
          newUsers: (g['newUsers'] ?? 0) as int,
          renewedUsers: (g['renewedUsers'] ?? 0) as int,
          totalRevenue: 0,
          createdAt: monthDate,
        ));
      }
      return results;
    });
  }

  // ─── USER STATS ─────────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>> userStatsStream(String userId) {
    return _db
        .collection(AppConstants.userStatsCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return {
              'smsSent': 0,
              'smsFailed': 0,
              'callsReceived': 0,
              'missedCalls': 0,
              'totalSpent': 0.0,
              'subscriptionStart': null,
              'subscriptionEnd': null,
            };
          }
          return doc.data() ?? {};
        });
  }

  Stream<List<Map<String, dynamic>>> userActivityStream(String userId) {
    return _db
        .collection('user_activities')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<Map<String, dynamic>> getUserStatsSummary(String userId) async {
    final decodedUserId = Uri.decodeComponent(userId);

    // Read plan info from the users collection
    final userDoc = await _db
        .collection(AppConstants.replymetUsersCollection)
        .doc(decodedUserId)
        .get();
    final userData = userDoc.data() ?? {};
    final planName = userData['planName'] ?? 'None';
    final subscriptionStart = userData['subscriptionStart'];
    final subscriptionEnd = userData['subscriptionEnd'];

    // Read cumulative SMS counters from stats/{uid}
    final statsDoc = await _db.collection('stats').doc(decodedUserId).get();
    final statsData = statsDoc.data() ?? {};
    final totalSmsSent = (statsData['totalSmsSent'] ?? 0) as int;
    final totalSmsFailed = (statsData['totalSmsFailed'] ?? 0) as int;
    final lastSmsAt = statsData['lastSmsAt'];
    final lastActiveAt = statsData['lastActiveAt'];

    return {
      'totalSms': totalSmsSent + totalSmsFailed,
      'smsSent': totalSmsSent,
      'smsFailed': totalSmsFailed,
      'lastSmsAt': lastSmsAt,
      'lastActiveAt': lastActiveAt,
      'totalSpent': 0.0,
      'subscriptionDays': 0,
      'currentPlan': planName,
      'subscriptionStart': subscriptionStart,
      'subscriptionEnd': subscriptionEnd,
      'status': userData['status'] ?? 'Unknown',
    };
  }

  // Get user's daily stats from stats/{uid}/daily/{dateId} subcollection
  Future<List<Map<String, dynamic>>> getUserDailyStats(String userId, {int days = 30}) async {
    final decodedUserId = Uri.decodeComponent(userId);
    final now = DateTime.now();

    // Fetch all daily docs for this user in one query
    final snap = await _db
        .collection('stats')
        .doc(decodedUserId)
        .collection('daily')
        .orderBy(FieldPath.documentId, descending: true)
        .limit(days)
        .get();

    final Map<String, Map<String, dynamic>> docMap = {
      for (final d in snap.docs) d.id: d.data()
    };

    final List<Map<String, dynamic>> results = [];
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateId = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final d = docMap[dateId] ?? {};
      results.add({
        'date': dateId,
        'smsSent': (d['smsSent'] ?? 0) as int,
        'smsFailed': (d['smsFailed'] ?? 0) as int,
        'callsReceived': (d['callsReceived'] ?? 0) as int,
        'missedCalls': (d['missedCalls'] ?? 0) as int,
      });
    }
    return results;
  }

  // Get a specific day's stats for a user from stats/{uid}/daily/{dateId}
  Future<Map<String, dynamic>> getUserStatsForDate(String userId, DateTime date) async {
    final decodedUserId = Uri.decodeComponent(userId);
    final dateId = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final doc = await _db
          .collection('stats')
          .doc(decodedUserId)
          .collection('daily')
          .doc(dateId)
          .get();
      final data = doc.data() ?? {};
      return {
        'smsSent': (data['smsSent'] ?? 0) as int,
        'smsFailed': (data['smsFailed'] ?? 0) as int,
        'callsReceived': (data['callsReceived'] ?? 0) as int,
        'missedCalls': (data['missedCalls'] ?? 0) as int,
      };
    } catch (e) {
      return {'smsSent': 0, 'smsFailed': 0, 'callsReceived': 0, 'missedCalls': 0};
    }
  }

  // Get today's stats for a user from stats/{uid}/daily/{todayId}
  Future<Map<String, dynamic>> getUserTodayStats(String userId) async {
    return getUserStatsForDate(userId, DateTime.now());
  }

  // Get a user's monthly stats from stats/{uid}/monthly/{monthId}
  Future<List<Map<String, dynamic>>> getUserMonthlyStats(String userId, {int months = 12}) async {
    final decodedUserId = Uri.decodeComponent(userId);
    final now = DateTime.now();

    final snap = await _db
        .collection('stats')
        .doc(decodedUserId)
        .collection('monthly')
        .orderBy(FieldPath.documentId, descending: true)
        .limit(months)
        .get();

    final Map<String, Map<String, dynamic>> docMap = {
      for (final d in snap.docs) d.id: d.data()
    };

    final List<Map<String, dynamic>> results = [];
    for (int i = 0; i < months; i++) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthId = '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';
      final d = docMap[monthId] ?? {};
      results.add({
        'monthId': monthId,
        'year': monthDate.year,
        'month': monthDate.month,
        'smsSent': (d['smsSent'] ?? 0) as int,
        'smsFailed': (d['smsFailed'] ?? 0) as int,
        'callsReceived': (d['callsReceived'] ?? 0) as int,
        'missedCalls': (d['missedCalls'] ?? 0) as int,
      });
    }
    return results;
  }

  // ─── CAMPAIGNS ──────────────────────────────────────────────────────────────

  Stream<List<CampaignModel>> campaignsStream({String? brokerId}) {
    Query query = _db.collection('campaigns').orderBy('createdAt', descending: true);
    if (brokerId != null) {
      query = query.where('senderId', isEqualTo: brokerId);
    }
    return query.snapshots().map((s) => s.docs.map((d) => CampaignModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList());
  }
}
