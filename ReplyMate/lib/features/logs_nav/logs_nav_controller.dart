import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/activity/activity_log_filters.dart';
import '../../core/activity/activity_log_service.dart';
import '../../core/activity/filter_type.dart';
import '../../core/activity/log_filter_type.dart';
import '../../core/export/activity_log_csv_export.dart';

/// Logs tab: date + call-type filters and search. Data from Hive via [ValueListenableBuilder].
class LogsNavController extends GetxController {
  final Rx<LogFilterType> selectedDateFilter = LogFilterType.all.obs;
  final Rx<FilterType> selectedFilter = FilterType.all.obs;

  final RxString searchQuery = ''.obs;
  final RxBool showSearch = false.obs;

  void setDateFilter(LogFilterType filter) => selectedDateFilter.value = filter;

  void setFilter(FilterType filter) => selectedFilter.value = filter;

  void toggleSearch() => showSearch.toggle();

  void onSearchChanged(String q) => searchQuery.value = q;

  void clearSearch() {
    searchQuery.value = '';
    showSearch.value = false;
  }

  @override
  void onReady() {
    super.onReady();
    ActivityLogService.instance.cleanOldLogs();
    ActivityLogService.instance.resolveMissingContactNames();
  }

  /// Exports the current list (date + type + search filters) as CSV.
  Future<void> exportFilteredLogs(BuildContext context) async {
    final box = ActivityLogService.instance.box;
    final sorted = box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final logs = applyActivityLogFilters(
      sortedDesc: sorted,
      dateFilter: selectedDateFilter.value,
      typeFilter: selectedFilter.value,
      queryNormalized: searchQuery.value,
    );
    if (logs.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logs match current filters')),
      );
      return;
    }
    try {
      await exportData(logs);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported ${logs.length} row(s)')));
    } on ArgumentError catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nothing to export')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}
