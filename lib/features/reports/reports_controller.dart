import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';

/// Message classification item model
class MessageCategory {
  const MessageCategory({
    required this.label,
    required this.count,
    required this.fraction,
    required this.color,
    required this.subtitle,
  });

  final String label;
  final int count;
  final double fraction;
  final Color color;
  final String subtitle;
}

/// ReportsController
/// Stitch Screen ID: c69c1fd624e8483b9e12bc7a94f6a823
class ReportsController extends GetxController {
  // ── Summary KPIs ───────────────────────────────────────────────────────────
  final RxInt totalMessages = 2840.obs;
  final RxString responseRate = '94.2%'.obs;

  // ── Period selector ────────────────────────────────────────────────────────
  final RxString selectedPeriod = 'Weekly'.obs;
  final List<String> periods = ['Daily', 'Weekly', 'Monthly'];

  // ── Message categories ─────────────────────────────────────────────────────
  final RxList<MessageCategory> categories = <MessageCategory>[].obs;

  // ── Automated insight ──────────────────────────────────────────────────────
  final RxString insightText = ''.obs;

  // ── Call breakdown ─────────────────────────────────────────────────────────
  final RxInt totalCalls = 128.obs;
  final RxInt missedCalls = 37.obs;
  final RxInt whatsappCalls = 14.obs;
  final RxInt autoRepliesSent = 89.obs;

  // ── Export state ───────────────────────────────────────────────────────────
  final RxBool isExporting = false.obs;

  @override
  void onReady() {
    super.onReady();
    _loadData();
  }

  void setPeriod(String period) {
    selectedPeriod.value = period;
    _loadData();
  }

  void _loadData() {
    switch (selectedPeriod.value) {
      case 'Daily':
        totalMessages.value = 205;
        responseRate.value = '97.0%';
        categories.assignAll([
          const MessageCategory(
            label: 'Customer Support',
            count: 42,
            fraction: 0.21,
            color: Color(0xFF24389C),
            subtitle: '42 handled today',
          ),
          const MessageCategory(
            label: 'Marketing Inquiries',
            count: 98,
            fraction: 0.48,
            color: Color(0xFF006A6A),
            subtitle: '98 handled today',
          ),
          const MessageCategory(
            label: 'General Chat',
            count: 65,
            fraction: 0.32,
            color: Color(0xFF25D366),
            subtitle: '65 handled today',
          ),
        ]);
        insightText.value =
            'Response volume is on track for today. Marketing inquiries remain the highest category.';
        break;

      case 'Weekly':
        totalMessages.value = 2840;
        responseRate.value = '94.2%';
        categories.assignAll([
          const MessageCategory(
            label: 'Customer Support',
            count: 420,
            fraction: 0.15,
            color: Color(0xFF24389C),
            subtitle: '420 handled this week',
          ),
          const MessageCategory(
            label: 'Marketing Inquiries',
            count: 1120,
            fraction: 0.40,
            color: Color(0xFF006A6A),
            subtitle: '1,120 handled this week',
          ),
          const MessageCategory(
            label: 'General Chat',
            count: 1300,
            fraction: 0.45,
            color: Color(0xFF25D366),
            subtitle: '1,300 handled this week',
          ),
        ]);
        insightText.value =
            'High volume detected in Marketing Inquiries. Consider updating your automation triggers for faster response times in this category.';
        break;

      case 'Monthly':
        totalMessages.value = 11200;
        responseRate.value = '92.8%';
        categories.assignAll([
          const MessageCategory(
            label: 'Customer Support',
            count: 1680,
            fraction: 0.15,
            color: Color(0xFF24389C),
            subtitle: '1,680 handled this month',
          ),
          const MessageCategory(
            label: 'Marketing Inquiries',
            count: 4480,
            fraction: 0.40,
            color: Color(0xFF006A6A),
            subtitle: '4,480 handled this month',
          ),
          const MessageCategory(
            label: 'General Chat',
            count: 5040,
            fraction: 0.45,
            color: Color(0xFF25D366),
            subtitle: '5,040 handled this month',
          ),
        ]);
        insightText.value =
            'Monthly performance is strong. Response rate slightly decreased — review failed deliveries to identify patterns.';
        break;
    }
  }

  Future<void> exportReport() async {
    isExporting.value = true;
    await Future<void>.delayed(const Duration(seconds: 1));
    isExporting.value = false;
    Get.toNamed(Routes.exportReports);
  }

  String formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
