import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/activity/activity_log.dart';
import '../../core/analytics/activity_analytics_service.dart';
import '../../core/analytics/analytics_filter.dart';
import '../../core/export/activity_log_csv_export.dart';

/// Analytics tab: period filter + CSV export. Metrics come from Hive via the view.
class AnalyticsNavController extends GetxController {
  final Rx<AnalyticsFilter> selectedFilter = AnalyticsFilter.weekly.obs;
  final RxBool isExporting = false.obs;

  static const List<AnalyticsFilter> filters = AnalyticsFilter.values;

  void setFilter(AnalyticsFilter filter) => selectedFilter.value = filter;

  /// Exports [allLogs] rows matching [selectedFilter] as CSV (temp file + share sheet).
  Future<void> exportFilteredLogs(
    BuildContext context,
    List<ActivityLog> allLogs,
  ) async {
    final filter = selectedFilter.value;
    final filtered =
        ActivityAnalyticsService.logsForAnalyticsPeriod(allLogs, filter);
    if (filtered.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }
    isExporting.value = true;
    try {
      await exportData(filtered);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exported successfully')),
      );
    } on ArgumentError catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      isExporting.value = false;
    }
  }
}
