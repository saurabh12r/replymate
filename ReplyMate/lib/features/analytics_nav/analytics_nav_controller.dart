import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/activity/activity_log.dart';
import '../../core/activity/activity_log_service.dart';
import '../../core/analytics/analytics_filter.dart';
import '../../core/export/activity_log_csv_export.dart';
import '../../core/activity/activity_date_utils.dart';
import '../../core/activity/event_type.dart';

/// Analytics tab: period filter + CSV export. Metrics come from Hive via the view.
class AnalyticsNavController extends GetxController {
  final Rx<AnalyticsFilter> selectedFilter = AnalyticsFilter.weekly.obs;
  final RxBool isExporting = false.obs;

  static const List<AnalyticsFilter> filters = AnalyticsFilter.values;

  // Custom interactive filters
  final Rxn<DateTimeRange> customDateRange = Rxn<DateTimeRange>();
  final RxString callFilter = 'All'.obs; // 'All', 'All Calls', 'Incoming', 'Outgoing', 'Missed'
  final RxString messageFilter = 'All'.obs; // 'All', 'Standard', 'Scheduled', 'Vacation'
  final RxString statusFilter = 'All'.obs; // 'All', 'Sent', 'Failed'

  void setFilter(AnalyticsFilter filter) {
    selectedFilter.value = filter;
    customDateRange.value = null; // Clear custom range if preset is tapped
  }

  void resetFilters() {
    customDateRange.value = null;
    callFilter.value = 'All';
    messageFilter.value = 'All';
    statusFilter.value = 'All';
  }

  Future<void> selectCustomDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: customDateRange.value ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cs = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: cs.primary,
                    onPrimary: cs.onPrimary,
                    surface: cs.surfaceContainerHigh,
                    onSurface: cs.onSurface,
                  )
                : ColorScheme.light(
                    primary: cs.primary,
                    onPrimary: cs.onPrimary,
                    surface: cs.surface,
                    onSurface: cs.onSurface,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      customDateRange.value = picked;
    }
  }

  List<ActivityLog> applyFilters(List<ActivityLog> logs) {
    return logs.where((log) {
      // 1. Date Filter
      if (customDateRange.value != null) {
        final start = DateTime(
          customDateRange.value!.start.year,
          customDateRange.value!.start.month,
          customDateRange.value!.start.day,
        );
        final end = DateTime(
          customDateRange.value!.end.year,
          customDateRange.value!.end.month,
          customDateRange.value!.end.day,
          23, 59, 59, 999,
        );
        if (log.timestamp.isBefore(start) || log.timestamp.isAfter(end)) {
          return false;
        }
      } else {
        final filter = selectedFilter.value;
        switch (filter) {
          case AnalyticsFilter.daily:
            if (!isToday(log.timestamp)) return false;
            break;
          case AnalyticsFilter.weekly:
            if (!isWithin7Days(log.timestamp)) return false;
            break;
          case AnalyticsFilter.monthly:
            if (!isWithin30Days(log.timestamp)) return false;
            break;
        }
      }

      final isSms = log.type == EventType.scheduledSms || log.isVacation;
      final isCall = !isSms;

      // 2. Call Filter
      if (callFilter.value != 'All') {
        if (isSms) return false;
        if (callFilter.value == 'Incoming' && log.type != EventType.incomingCall) {
          return false;
        }
        if (callFilter.value == 'Outgoing' &&
            log.type != EventType.outgoingAnswered &&
            log.type != EventType.outgoingUnanswered) {
          return false;
        }
        if (callFilter.value == 'Missed' && log.type != EventType.missedCall) {
          return false;
        }
      }

      // 3. Message Filter
      if (messageFilter.value != 'All') {
        if (isCall) return false;
        if (messageFilter.value == 'Scheduled' && log.type != EventType.scheduledSms) {
          return false;
        }
        if (messageFilter.value == 'Vacation' && !log.isVacation) {
          return false;
        }
        if (messageFilter.value == 'Standard' && (log.type == EventType.scheduledSms || log.isVacation)) {
          return false;
        }
      }

      // 4. Status Filter
      if (statusFilter.value != 'All') {
        final isSuccess = log.replied;
        if (statusFilter.value == 'Sent' && !isSuccess) return false;
        if (statusFilter.value == 'Failed' && isSuccess) return false;
      }

      return true;
    }).toList();
  }

  /// Exports [filteredLogs] rows matching active filters as CSV (temp file + share sheet).
  Future<void> exportFilteredLogs(
    BuildContext context,
    List<ActivityLog> filteredLogs,
  ) async {
    if (filteredLogs.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }
    isExporting.value = true;
    try {
      final fileName = await exportData(filteredLogs);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Saved to Downloads: $fileName'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
          duration: const Duration(seconds: 5),
        ),
      );
    } on ArgumentError catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> syncLogs() async {
    isExporting.value = true;
    try {
      await ActivityLogService.instance.syncPendingFromNative();
      Get.snackbar(
        'Success',
        'Activity logs synced from background service',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withAlpha(200),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Sync failed: $e');
    } finally {
      isExporting.value = false;
    }
  }
}
