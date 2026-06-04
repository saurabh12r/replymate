import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AutoReplyBridge {
  static const MethodChannel _channel = MethodChannel('replymate/auto_reply');

  Future<void> _updateUserStatsDirect(String field, int increment) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final month = now.month;
      final day = now.day;
      final monthStr = month < 10 ? '0$month' : '$month';
      final dayStr = day < 10 ? '0$day' : '$day';
      final dailyId = '${now.year}-$monthStr-$dayStr';
      final monthId = '${now.year}-$monthStr';

      final db = FirebaseFirestore.instance;

      // Update global daily and monthly stats
      final globalDailyRef = db.collection('daily_stats').doc(dailyId);
      final globalMonthlyRef = db.collection('monthly_stats').doc(monthId);

      await globalDailyRef.set({
        'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
        field: FieldValue.increment(increment),
      }, SetOptions(merge: true));

      await globalMonthlyRef.set({
        'year': now.year,
        'month': now.month,
        field: FieldValue.increment(increment),
      }, SetOptions(merge: true));

      final phone = user.phoneNumber;
      final docId = (phone != null && phone.isNotEmpty) ? phone : user.uid;
      final userStatsRef = db.collection('stats').doc(docId);

      // Update cumulative stats on user stats document (not user document directly)
      final cumulativeField = field == 'smsSent'
          ? 'totalSmsSent'
          : 'totalSmsFailed';
      await userStatsRef.set({
        cumulativeField: FieldValue.increment(increment),
        'lastSmsAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Daily stats inside user's stats/daily subcollection
      final userDailyRef = userStatsRef.collection('daily').doc(dailyId);
      await userDailyRef.set({
        field: FieldValue.increment(increment),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Monthly stats inside user's stats/monthly subcollection
      final userMonthlyRef = userStatsRef.collection('monthly').doc(monthId);
      await userMonthlyRef.set({
        field: FieldValue.increment(increment),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Ignore errors - stats are not critical
    }
  }

  Future<void> startCallListener() async {
    await _channel.invokeMethod('startCallListener');
  }

  Future<void> stopCallListener() async {
    await _channel.invokeMethod('stopCallListener');
  }

  Future<void> sendSms({required String phone, required String message}) async {
    await _channel.invokeMethod('sendSms', {
      'phone': phone,
      'message': message,
    });
  }

  Future<void> updateAutoReplyConfig({
    required bool autoReplyEnabled,
    required bool replyOnCallAnswered,
    required bool replyOnMissedCall,
    bool replyOnWhatsappCall = false,
    required bool replyOnBusyCall,
    required bool replyOnRejectedCall,
    required bool replyOnOutgoingAnswered,
    required bool replyOnOutgoingUnanswered,
    required bool useTimeRange,
    required int startMinutes,
    required int endMinutes,
    required String defaultReplyMessage,
  }) async {
    await _channel.invokeMethod('updateAutoReplyConfig', {
      'autoReplyEnabled': autoReplyEnabled,
      'replyOnCallAnswered': replyOnCallAnswered,
      'replyOnMissedCall': replyOnMissedCall,
      'replyOnWhatsappCall': false,
      'replyOnBusyCall': replyOnBusyCall,
      'replyOnRejectedCall': replyOnRejectedCall,
      'replyOnOutgoingAnswered': replyOnOutgoingAnswered,
      'replyOnOutgoingUnanswered': replyOnOutgoingUnanswered,
      'useTimeRange': useTimeRange,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'defaultReplyMessage': defaultReplyMessage,
    });
  }

  Future<Map<String, dynamic>> getAutoReplyConfig() async {
    final data = await _channel.invokeMapMethod<String, dynamic>(
      'getAutoReplyConfig',
    );
    return data ?? <String, dynamic>{};
  }

  /// Keeps native [ContactFilterNativeStore] in sync for background SMS filtering.
  Future<void> syncContactFilterNative({
    required String filterMode,
    required String phonesJson,
  }) async {
    await _channel.invokeMethod('syncContactFilterNative', {
      'filterMode': filterMode,
      'phonesJson': phonesJson,
    });
  }

  /// Checks if the app is currently ignoring battery optimizations.
  Future<bool> isIgnoringBatteryOptimizations() async {
    final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
    return result ?? false;
  }

  /// Opens system battery optimization list (Android 6+).
  Future<void> openBatteryOptimizationSettings() async {
    await _channel.invokeMethod('openBatteryOptimizationSettings');
  }

  /// Requests ignore battery optimizations for this package (may be denied by OEM).
  Future<void> requestIgnoreBatteryOptimizations() async {
    await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
  }

  /// Checks if the app is currently the default SMS app without prompting.
  Future<bool> isDefaultSmsApp() async {
    final result = await _channel.invokeMethod<bool>('isDefaultSmsApp');
    return result ?? false;
  }

  /// Prompts user to set this app as the default SMS app (Android 10+ via RoleManager, older via ACTION_CHANGE_DEFAULT).
  Future<bool> requestDefaultSmsApp() async {
    final result = await _channel.invokeMethod<bool>('requestDefaultSmsApp');
    return result ?? false;
  }

  Future<void> setThrottleEnabled(bool enabled) async {
    await _channel.invokeMethod('setThrottleEnabled', {
      'throttleEnabled': enabled,
    });
  }

  Future<void> setThrottleDuration(int hours) async {
    await _channel.invokeMethod('setThrottleDuration', {
      'throttleDuration': hours,
    });
  }

  // Stats tracking - updates daily/monthly stats in Firestore
  Future<void> incrementSmsSent() async {
    // Try native first, then fallback to direct Dart implementation
    try {
      await _channel.invokeMethod('incrementSmsSent');
    } catch (_) {}
    // Also update directly from Dart for reliability
    await _updateUserStatsDirect('smsSent', 1);
  }

  Future<void> incrementSmsFailed() async {
    try {
      await _channel.invokeMethod('incrementSmsFailed');
    } catch (_) {}
    // Also update directly from Dart for reliability
    await _updateUserStatsDirect('smsFailed', 1);
  }

  Future<void> incrementCallReceived({bool missed = false}) async {
    try {
      await _channel.invokeMethod('incrementCallReceived', {'missed': missed});
    } catch (_) {}
    // Also update user stats directly
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final now = DateTime.now();
        final month = now.month;
        final day = now.day;
        final monthStr = month < 10 ? '0$month' : '$month';
        final dayStr = day < 10 ? '0$day' : '$day';
        final dailyId = '${now.year}-$monthStr-$dayStr';
        final monthId = '${now.year}-$monthStr';
        final db = FirebaseFirestore.instance;

        // Update global daily and monthly stats
        final globalDailyRef = db.collection('daily_stats').doc(dailyId);
        final globalMonthlyRef = db.collection('monthly_stats').doc(monthId);

        await globalDailyRef.set({
          'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
          'callsReceived': FieldValue.increment(1),
          if (missed) 'missedCalls': FieldValue.increment(1),
        }, SetOptions(merge: true));

        await globalMonthlyRef.set({
          'year': now.year,
          'month': now.month,
          'callsReceived': FieldValue.increment(1),
          if (missed) 'missedCalls': FieldValue.increment(1),
        }, SetOptions(merge: true));

        final phone = user.phoneNumber;
        final docId = (phone != null && phone.isNotEmpty) ? phone : user.uid;
        final userStatsRef = db.collection('stats').doc(docId);
        await userStatsRef.set({
          'callsReceived': FieldValue.increment(1),
          if (missed) 'missedCalls': FieldValue.increment(1),
          'lastActivity': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final userDailyRef = userStatsRef.collection('daily').doc(dailyId);
        await userDailyRef.set({
          'callsReceived': FieldValue.increment(1),
          if (missed) 'missedCalls': FieldValue.increment(1),
          'date': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final userMonthlyRef = userStatsRef.collection('monthly').doc(monthId);
        await userMonthlyRef.set({
          'callsReceived': FieldValue.increment(1),
          if (missed) 'missedCalls': FieldValue.increment(1),
          'date': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Future<void> setAutoReplyEnabled(bool enabled) async {
    await _channel.invokeMethod('setAutoReplyEnabled', {
      'autoReplyEnabled': enabled,
    });
  }

  /// Native hard block for background execution (cached in SharedPreferences).
  Future<void> setBlocked(bool value, {int? subscriptionEndMs, int? nextPlanDurationDays}) async {
    await _channel.invokeMethod('setBlocked', {
      'value': value,
      'subscriptionEndMs': subscriptionEndMs,
      'nextPlanDurationDays': nextPlanDurationDays,
    });
  }

  Future<void> setReplyRules({
    required bool replyOnMissedCall,
    required bool replyOnIncomingCall,
    required bool replyOnBusyCall,
    required bool replyOnRejectedCall,
    required bool replyOnOutgoingAnswered,
    required bool replyOnOutgoingUnanswered,
  }) async {
    await _channel.invokeMethod('setReplyRules', {
      'replyOnMissedCall': replyOnMissedCall,
      'replyOnIncomingCall': replyOnIncomingCall,
      'replyOnWhatsappCall': false,
      'replyOnBusyCall': replyOnBusyCall,
      'replyOnRejectedCall': replyOnRejectedCall,
      'replyOnOutgoingAnswered': replyOnOutgoingAnswered,
      'replyOnOutgoingUnanswered': replyOnOutgoingUnanswered,
    });
  }

  Future<void> setCustomMessages({
    required String missedCallMessage,
    required String incomingCallMessage,
    String whatsappCallMessage = '',
    required String busyCallMessage,
    required String rejectedCallMessage,
    required String outgoingAnsweredMessage,
    required String outgoingUnansweredMessage,
  }) async {
    await _channel.invokeMethod('setCustomMessages', {
      'missedCallMessage': missedCallMessage,
      'incomingCallMessage': incomingCallMessage,
      'whatsappCallMessage': whatsappCallMessage,
      'busyCallMessage': busyCallMessage,
      'rejectedCallMessage': rejectedCallMessage,
      'outgoingAnsweredMessage': outgoingAnsweredMessage,
      'outgoingUnansweredMessage': outgoingUnansweredMessage,
    });
  }

  /// Active SIM subscriptions (values are real [subscriptionId]s for storage).
  Future<List<Map<String, dynamic>>> listSubscriptionInfos() async {
    final raw = await _channel.invokeMethod<List<dynamic>>(
      'listSubscriptionInfos',
    );
    return (raw ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();
  }

  Future<int?> getDefaultSmsSubscriptionId() async {
    final raw = await _channel.invokeMethod<dynamic>(
      'getDefaultSmsSubscriptionId',
    );
    if (raw is int) return raw;
    return null;
  }

  Future<String> getStoresJson() async {
    final s = await _channel.invokeMethod<String>('getStoresJson');
    return s ?? '[]';
  }

  Future<void> setStoresJson(String storesJson) async {
    await _channel.invokeMethod('setStoresJson', {'storesJson': storesJson});
  }

  Future<void> setUserId(String? userId) async {
    if (userId != null) {
      await _channel.invokeMethod('setUserId', {'userId': userId});
    }
  }

  Future<String?> getUserId() async {
    final result = await _channel.invokeMethod<String>('getUserId');
    return result;
  }
}
