import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plan_model.dart';
import '../models/broker_model.dart';
import '../models/replymet_user.dart';
import '../models/approval_model.dart';
import '../models/activity_log.dart';
import '../models/notification_model.dart';
import '../models/daily_stats.dart';
import '../models/campaign_model.dart';
import '../models/subscription_history_model.dart';
import 'service_providers.dart';
import 'auth_provider.dart';

// ─── PLANS ────────────────────────────────────────────────────────────────────

final plansStreamProvider = StreamProvider<List<PlanModel>>((ref) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).plansStream();
});

final activePlansStreamProvider = StreamProvider<List<PlanModel>>((ref) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).activePlansStream();
});

// ─── BROKERS ──────────────────────────────────────────────────────────────────

final brokersStreamProvider = StreamProvider<List<BrokerModel>>((ref) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).brokersStream();
});

final currentBrokerProvider = StreamProvider<BrokerModel?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null || !user.isBroker) {
        return Stream<BrokerModel?>.value(null);
      }
      return ref.read(firestoreServiceProvider).brokerStream(user.uid);
    },
    loading: () => Stream<BrokerModel?>.value(null),
    error: (e, _) => Stream<BrokerModel?>.value(null),
  );
});

// ─── REPLYMET USERS ───────────────────────────────────────────────────────────

final allUsersStreamProvider = StreamProvider<List<ReplymetUser>>((ref) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).allUsersStream();
});

final userStreamProvider = StreamProvider.family<ReplymetUser?, String>((ref, userId) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).userStream(userId);
});

final subscriptionHistoryProvider = StreamProvider.family<List<SubscriptionHistoryModel>, String>((ref, userId) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).subscriptionHistoryStream(userId);
});

/// Admin-only pending users (no broker assigned)
final adminPendingUsersProvider = StreamProvider<List<ReplymetUser>>((ref) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).adminPendingUsersStream();
});

/// All users associated with a specific broker
final usersByBrokerStreamProvider = StreamProvider.family<List<ReplymetUser>, String>((ref, brokerId) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).usersByBrokerStream(brokerId);
});


/// Broker-specific users
final brokerUsersProvider = StreamProvider<List<ReplymetUser>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null || !user.isBroker) {
        return Stream<List<ReplymetUser>>.value(const <ReplymetUser>[]);
      }
      return ref.read(firestoreServiceProvider).usersByBrokerStream(user.uid);
    },
    loading: () => Stream<List<ReplymetUser>>.value(const <ReplymetUser>[]),
    error: (e, st) => Stream.error(e, st),
  );
});

/// Broker pending users — uses in-memory filter to avoid requiring a composite
/// Firestore index on (brokerId + isApproved). Fetches all broker users and
/// filters client-side: isApproved=false AND not blocked.
final brokerPendingUsersProvider = StreamProvider<List<ReplymetUser>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null || !user.isBroker) {
        return Stream<List<ReplymetUser>>.value(const <ReplymetUser>[]);
      }
      // Fetch all users for this broker, then filter pending in-memory.
      // This avoids the composite index requirement for brokerId+isApproved.
      return ref
          .read(firestoreServiceProvider)
          .usersByBrokerStream(user.uid)
          .map((users) => users
              .where((u) => u.isPending)
              .toList());
    },
    loading: () => Stream<List<ReplymetUser>>.value(const <ReplymetUser>[]),
    error: (e, st) => Stream.error(e, st),
  );
});

// ─── APPROVALS ────────────────────────────────────────────────────────────────

final approvalsStreamProvider = StreamProvider<List<ApprovalModel>>((ref) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).approvalsStream();
});

final brokerApprovalsProvider = StreamProvider<List<ApprovalModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null || !user.isBroker) {
        return Stream<List<ApprovalModel>>.value(const <ApprovalModel>[]);
      }
      return ref.read(firestoreServiceProvider).brokerApprovalsStream(user.uid);
    },
    loading: () => Stream<List<ApprovalModel>>.value(const <ApprovalModel>[]),
    error: (e, _) => Stream<List<ApprovalModel>>.value(const <ApprovalModel>[]),
  );
});

// ─── ACTIVITY LOGS ────────────────────────────────────────────────────────────

final activityLogsProvider = StreamProvider<List<ActivityLog>>((ref) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).activityLogsStream();
});

// ─── ADMIN DASHBOARD STATS ────────────────────────────────────────────────────

/// Admin dashboard stats — real-time from pre-aggregated stats/global document
/// Falls back to computing in-memory if stats/global doesn't exist yet
final adminStatsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  ref.watch(authLoadedProvider);
  final db = FirebaseFirestore.instance;
  return db.collection('stats').doc('global').snapshots().asyncMap((snap) async {
    if (snap.exists && snap.data() != null) {
      final d = snap.data()!;
      return {
        'totalUsers': d['totalUsers'] ?? 0,
        'activeSubscriptions': d['activeUsers'] ?? 0,
        'totalBrokers': d['totalBrokers'] ?? 0,
        'pendingApprovals': d['pendingUsers'] ?? 0,
        'totalRevenue': (d['totalRevenue'] ?? 0).toDouble(),
      };
    }
    // Fallback: compute from collections (used before first Cloud Function run)
    return ref.read(firestoreServiceProvider).getAdminDashboardStats();
  });
});

final monthlyRevenueProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).getMonthlyRevenue();
});

// ─── SEARCH FILTER ────────────────────────────────────────────────────────────

final userSearchQueryProvider = StateProvider<String>((ref) => '');
final userStatusFilterProvider = StateProvider<String?>((ref) => null);

/// Filtered users based on search + status (excluding broker-assigned users)
final filteredUsersProvider = Provider<List<ReplymetUser>>((ref) {
  final allUsers = ref.watch(allUsersStreamProvider).value ?? [];
  final query = ref.watch(userSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(userStatusFilterProvider);

  return allUsers.where((u) {
    // Exclude users associated with a broker
    if (u.brokerId != null && u.brokerId!.isNotEmpty) {
      return false;
    }
    
    final matchesSearch = query.isEmpty ||
        u.name.toLowerCase().contains(query) ||
        u.email.toLowerCase().contains(query) ||
        u.phone.contains(query);
    final matchesStatus = statusFilter == null || u.status == statusFilter;
    return matchesSearch && matchesStatus;
  }).toList();
});

// ─── NOTIFICATIONS ────────────────────────────────────────────────────────────────

final adminNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).notificationsStream('admin');
});

final brokerNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null || !user.isBroker) {
        return Stream<List<AppNotification>>.value(const []);
      }
      return ref.read(firestoreServiceProvider).notificationsStream('broker', targetId: user.uid);
    },
    loading: () => Stream<List<AppNotification>>.value(const []),
    error: (e, _) => Stream<List<AppNotification>>.value(const []),
  );
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final adminNotifs = ref.watch(adminNotificationsProvider).value ?? [];
  final brokerNotifs = ref.watch(brokerNotificationsProvider).value ?? [];
  final user = ref.watch(currentUserProvider).valueOrNull;
  final notifs = user?.isAdmin == true ? adminNotifs : brokerNotifs;
  return notifs.where((n) => !n.isRead).length;
});

// ─── DAILY/MONTHLY STATS ────────────────────────────────────────────────────────────

final dailyStatsProvider = StreamProvider<List<DailyStats>>((ref) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).dailyStatsStream(days: 30);
});

final monthlyStatsProvider = StreamProvider<List<MonthlyStats>>((ref) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).monthlyStatsStream(months: 12);
});

final userStatsProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, userId) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).userStatsStream(userId);
});

final userActivityProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).userActivityStream(userId);
});

final userStatsSummaryProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).getUserStatsSummary(userId);
});

final userTodayStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).getUserTodayStats(userId);
});

final userStatsForDateProvider = FutureProvider.family<Map<String, dynamic>, ({String userId, DateTime date})>((ref, args) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).getUserStatsForDate(args.userId, args.date);
});

final userDailyStatsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).getUserDailyStats(userId);
});

final userMonthlyStatsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).getUserMonthlyStats(userId);
});

// ─── CAMPAIGNS ────────────────────────────────────────────────────────────

final campaignsStreamProvider = StreamProvider<List<CampaignModel>>((ref) {
  ref.watch(authLoadedProvider);
  return ref.watch(firestoreServiceProvider).campaignsStream();
});

final brokerCampaignsProvider = StreamProvider<List<CampaignModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null || !user.isBroker) {
        return Stream<List<CampaignModel>>.value(const <CampaignModel>[]);
      }
      return ref.watch(firestoreServiceProvider).campaignsStream(brokerId: user.uid);
    },
    loading: () => Stream<List<CampaignModel>>.value(const <CampaignModel>[]),
    error: (e, _) => Stream<List<CampaignModel>>.value(const <CampaignModel>[]),
  );
});
