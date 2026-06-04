import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ExportController
/// Stitch Screen ID: 89e50d2e95d24c19b3a75220080b3f0e
class ExportController extends GetxController {
  // ── Format selection ───────────────────────────────────────────────────────
  final RxString selectedFormat = 'PDF'.obs;
  final List<Map<String, dynamic>> formats = [
    {
      'label': 'PDF',
      'icon': Icons.picture_as_pdf_rounded,
      'desc': 'Best for sharing & printing',
    },
    {
      'label': 'CSV',
      'icon': Icons.table_chart_rounded,
      'desc': 'Raw data for spreadsheets',
    },
    {
      'label': 'Excel',
      'icon': Icons.grid_on_rounded,
      'desc': 'Rich formatting with charts',
    },
  ];

  // ── Timeframe selection ────────────────────────────────────────────────────
  final RxString selectedTimeframe = 'This Week'.obs;
  final List<String> timeframes = [
    'Today',
    'This Week',
    'This Month',
    'Last 3 Months',
    'Custom Range',
  ];

  // ── Include options (checkboxes) ───────────────────────────────────────────
  final RxBool includeCharts = true.obs;
  final RxBool includeRawData = true.obs;
  final RxBool includeCallBreakdown = false.obs;
  final RxBool includeInsights = true.obs;

  // ── Report preview info ────────────────────────────────────────────────────
  final RxInt repliesCount = 1248.obs;
  final RxInt widgetsCount = 14.obs;
  final RxString lastSaved = 'Last report saved 2 mins ago'.obs;
  final RxBool isReady = true.obs;

  // ── Export state ───────────────────────────────────────────────────────────
  final RxBool isExporting = false.obs;
  final RxBool exportSuccess = false.obs;

  // ── Custom date range ──────────────────────────────────────────────────────
  final Rx<DateTime> startDate = DateTime.now()
      .subtract(const Duration(days: 7))
      .obs;
  final Rx<DateTime> endDate = DateTime.now().obs;

  bool get showCustomRange => selectedTimeframe.value == 'Custom Range';

  void selectFormat(String format) => selectedFormat.value = format;

  void selectTimeframe(String tf) => selectedTimeframe.value = tf;

  Future<void> pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate.value,
      firstDate: DateTime(2024),
      lastDate: endDate.value,
    );
    if (picked != null) startDate.value = picked;
  }

  Future<void> pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate.value,
      firstDate: startDate.value,
      lastDate: DateTime.now(),
    );
    if (picked != null) endDate.value = picked;
  }

  String formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> generateExport() async {
    if (isExporting.value) return;
    isExporting.value = true;
    exportSuccess.value = false;

    // Simulate export processing
    await Future<void>.delayed(const Duration(milliseconds: 1800));

    isExporting.value = false;
    exportSuccess.value = true;
    lastSaved.value = 'Last report saved just now';

    Get.snackbar(
      '✅ Export Successful',
      'Your ${selectedFormat.value} report has been saved',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF006A6A),
      colorText: Colors.white,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
}
