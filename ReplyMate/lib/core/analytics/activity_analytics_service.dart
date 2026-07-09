import 'package:flutter/material.dart';
import '../activity/activity_date_utils.dart';
import '../activity/activity_log.dart';
import '../activity/event_type.dart';
import 'analytics_filter.dart';

/// Fixed response goal denominator for the KPI card (e.g. 205/250).
const int kAnalyticsResponseGoalTarget = 250;

/// One bar bucket for "Replies over time" (local time-of-day).
class AnalyticsTimeBucket {
  const AnalyticsTimeBucket({required this.label, required this.count});

  final String label;
  final int count;

  double get value => count.toDouble();
}

/// Immutable snapshot from a single pass over [ActivityLog] rows.
class ActivityAnalyticsSnapshot {
  const ActivityAnalyticsSnapshot({
    required this.logsInPeriod,
    required this.replySentCount,
    required this.replyFailedCount,
    required this.efficiencyPercent,
    required this.hasEfficiencyDenominator,
    required this.totalCalls,
    required this.missedCalls,
    required this.whatsappCalls,
    required this.repliesSent,
    required this.barBuckets,
    required this.whatsappChannelEvents,
    required this.smsDirectReplies,
    required this.scheduledSent,
    required this.vacationSent,
  });

  /// Rows matching the selected period filter.
  final int logsInPeriod;

  /// Logs with [ActivityLog.replied] == true (maps to "replySent").
  final int replySentCount;

  /// Logs with [ActivityLog.replied] == false (maps to "replyFailed" for efficiency).
  final int replyFailedCount;

  /// (replySent / (replySent + replyFailed)) x 100, or 0 if no denominator.
  final double efficiencyPercent;

  final bool hasEfficiencyDenominator;

  final int totalCalls;
  final int missedCalls;
  final int whatsappCalls;
  final int repliesSent;

  final List<AnalyticsTimeBucket> barBuckets;

  /// All WhatsApp call events (for "Top Channels").
  final int whatsappChannelEvents;

  /// Replies sent via phone/SMS path (incoming + missed with replied).
  final int smsDirectReplies;

  final int scheduledSent;
  final int vacationSent;

  bool get hasLogsInPeriod => logsInPeriod > 0;
}

/// Builds [ActivityAnalyticsSnapshot] from Hive-backed logs in one O(n) pass.
class ActivityAnalyticsService {
  ActivityAnalyticsService._();

  static const List<String> _slotLabels = [
    '6am',
    '9am',
    '12pm',
    '3pm',
    '6pm',
    '9pm',
  ];

  /// Local hour -> bucket 0..5 (3h windows; last bucket is 9pm-6am).
  static int _timeSlotIndex(DateTime utc) {
    final h = utc.toLocal().hour;
    if (h >= 6 && h < 9) return 0;
    if (h >= 9 && h < 12) return 1;
    if (h >= 12 && h < 15) return 2;
    if (h >= 15 && h < 18) return 3;
    if (h >= 18 && h < 21) return 4;
    return 5;
  }

  static bool _inFilter(DateTime timestamp, AnalyticsFilter filter) {
    switch (filter) {
      case AnalyticsFilter.daily:
        return isToday(timestamp);
      case AnalyticsFilter.monthly:
        return isWithin30Days(timestamp);
      case AnalyticsFilter.weekly:
        return isWithin7Days(timestamp);
    }
  }

  /// Logs in filtered range, newest first (for export).
  static List<ActivityLog> logsForAnalyticsPeriod(
    Iterable<ActivityLog> logs,
    AnalyticsFilter filter, {
    DateTimeRange? customRange,
    String callFilter = 'All',
    String messageFilter = 'All',
    String statusFilter = 'All',
  }) {
    final out = <ActivityLog>[];
    for (final log in logs) {
      // 1. Date Filter
      if (customRange != null) {
        final start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
        final end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59, 999);
        if (log.timestamp.isBefore(start) || log.timestamp.isAfter(end)) {
          continue;
        }
      } else {
        if (!_inFilter(log.timestamp, filter)) {
          continue;
        }
      }

      final isSms = log.type == EventType.scheduledSms || log.isVacation;
      final isCall = !isSms;

      // 2. Call Filter
      if (callFilter != 'All') {
        if (isSms) {
          continue;
        }
        if (callFilter == 'Incoming' && log.type != EventType.incomingCall) {
          continue;
        }
        if (callFilter == 'Outgoing' &&
            log.type != EventType.outgoingAnswered &&
            log.type != EventType.outgoingUnanswered) {
          continue;
        }
        if (callFilter == 'Missed' && log.type != EventType.missedCall) {
          continue;
        }
      }

      // 3. Message Filter
      if (messageFilter != 'All') {
        if (isCall) {
          continue;
        }
        if (messageFilter == 'Scheduled' && log.type != EventType.scheduledSms) {
          continue;
        }
        if (messageFilter == 'Vacation' && !log.isVacation) {
          continue;
        }
        if (messageFilter == 'Standard' && (log.type == EventType.scheduledSms || log.isVacation)) {
          continue;
        }
      }

      // 4. Status Filter
      if (statusFilter != 'All') {
        final isSuccess = log.replied;
        if (statusFilter == 'Sent' && !isSuccess) {
          continue;
        }
        if (statusFilter == 'Failed' && isSuccess) {
          continue;
        }
      }

      out.add(log);
    }
    out.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return out;
  }

  /// Single pass: period filter + call stats + reply buckets (replied only).
  static ActivityAnalyticsSnapshot compute(
    Iterable<ActivityLog> logs,
    AnalyticsFilter filter, {
    DateTimeRange? customRange,
    String callFilter = 'All',
    String messageFilter = 'All',
    String statusFilter = 'All',
  }) {
    var logsInPeriod = 0;
    var incoming = 0;
    var missed = 0;
    var wa = 0;
    var busy = 0;
    var rejected = 0;
    var outAns = 0;
    var outUnans = 0;
    var repliedYes = 0;
    var repliedNo = 0;
    var smsReplies = 0;
    var scheduledSent = 0;
    var vacationSent = 0;
    final buckets = List<int>.filled(6, 0);

    for (final log in logs) {
      // 1. Date Filter
      if (customRange != null) {
        final start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
        final end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59, 999);
        if (log.timestamp.isBefore(start) || log.timestamp.isAfter(end)) {
          continue;
        }
      } else {
        if (!_inFilter(log.timestamp, filter)) {
          continue;
        }
      }

      final isSms = log.type == EventType.scheduledSms || log.isVacation;
      final isCall = !isSms;

      // 2. Call Filter
      if (callFilter != 'All') {
        if (isSms) {
          continue;
        }
        if (callFilter == 'Incoming' && log.type != EventType.incomingCall) {
          continue;
        }
        if (callFilter == 'Outgoing' &&
            log.type != EventType.outgoingAnswered &&
            log.type != EventType.outgoingUnanswered) {
          continue;
        }
        if (callFilter == 'Missed' && log.type != EventType.missedCall) {
          continue;
        }
      }

      // 3. Message Filter
      if (messageFilter != 'All') {
        if (isCall) {
          continue;
        }
        if (messageFilter == 'Scheduled' && log.type != EventType.scheduledSms) {
          continue;
        }
        if (messageFilter == 'Vacation' && !log.isVacation) {
          continue;
        }
        if (messageFilter == 'Standard' && (log.type == EventType.scheduledSms || log.isVacation)) {
          continue;
        }
      }

      // 4. Status Filter
      if (statusFilter != 'All') {
        final isSuccess = log.replied;
        if (statusFilter == 'Sent' && !isSuccess) {
          continue;
        }
        if (statusFilter == 'Failed' && isSuccess) {
          continue;
        }
      }

      logsInPeriod++;

      switch (log.type) {
        case EventType.incomingCall:
          incoming++;
          break;
        case EventType.missedCall:
          missed++;
          break;
        case EventType.whatsappCall:
          wa++;
          break;
        case EventType.busyCall:
          busy++;
          break;
        case EventType.rejectedCall:
          rejected++;
          break;
        case EventType.outgoingAnswered:
          outAns++;
          break;
        case EventType.outgoingUnanswered:
          outUnans++;
          break;
        case EventType.scheduledSms:
          break;
      }

      if (log.type == EventType.scheduledSms) {
        if (log.replied) {
          scheduledSent++;
        }
      } else {
        if (log.replied) {
          repliedYes++;
          buckets[_timeSlotIndex(log.timestamp)]++;
          if (log.type != EventType.whatsappCall) {
            smsReplies++;
          }
          if (log.isVacation) {
            vacationSent++;
          }
        } else {
          repliedNo++;
        }
      }
    }

    final denom = repliedYes + repliedNo;
    final eff = denom > 0 ? 100.0 * repliedYes / denom : 0.0;

    final barList = List<AnalyticsTimeBucket>.generate(
      6,
      (i) => AnalyticsTimeBucket(label: _slotLabels[i], count: buckets[i]),
    );

    return ActivityAnalyticsSnapshot(
      logsInPeriod: logsInPeriod,
      replySentCount: repliedYes,
      replyFailedCount: repliedNo,
      efficiencyPercent: eff,
      hasEfficiencyDenominator: denom > 0,
      totalCalls: incoming + missed + wa + busy + rejected + outAns + outUnans,
      missedCalls: missed,
      whatsappCalls: wa,
      repliesSent: repliedYes,
      barBuckets: barList,
      whatsappChannelEvents: wa,
      smsDirectReplies: smsReplies,
      scheduledSent: scheduledSent,
      vacationSent: vacationSent,
    );
  }
}

/// Cross-period reply stats (all-time + rolling windows) in one pass.
class ActivityLogInsights {
  const ActivityLogInsights({
    required this.totalRepliesSentAllTime,
    required this.repliesToday,
    required this.repliesLast7Days,
    required this.mostContactedNumber,
    required this.mostContactedReplyCount,
  });

  final int totalRepliesSentAllTime;
  final int repliesToday;
  final int repliesLast7Days;
  final String mostContactedNumber;
  final int mostContactedReplyCount;

  static ActivityLogInsights compute(Iterable<ActivityLog> logs) {
    var total = 0;
    var today = 0;
    var week = 0;
    final counts = <String, int>{};
    for (final log in logs) {
      if (!log.replied) continue;
      total++;
      if (isToday(log.timestamp)) today++;
      if (isWithin7Days(log.timestamp)) week++;
      final p = log.phoneNumber.trim();
      if (p.isNotEmpty) {
        counts[p] = (counts[p] ?? 0) + 1;
      }
    }
    var topPhone = '—';
    var topCount = 0;
    counts.forEach((k, v) {
      if (v > topCount) {
        topCount = v;
        topPhone = k;
      }
    });
    return ActivityLogInsights(
      totalRepliesSentAllTime: total,
      repliesToday: today,
      repliesLast7Days: week,
      mostContactedNumber: topPhone,
      mostContactedReplyCount: topCount,
    );
  }
}
