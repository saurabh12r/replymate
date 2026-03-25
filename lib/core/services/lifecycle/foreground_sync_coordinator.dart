import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../activity/activity_log_service.dart';
import '../../contact_filter/contact_filter_preferences.dart';
import '../../contact_filter/contact_filter_sms_policy.dart';
import '../../../features/contact_filter/contact_filter_controller.dart';
import '../../../features/dashboard/dashboard_controller.dart';

/// Centralizes foreground-safe work on app resume: activity log import, policy
/// hydration, and lightweight GetX controller refresh. Does not start Android
/// services (those remain system-driven); avoids duplicate overlapping syncs.
class ForegroundSyncCoordinator {
  ForegroundSyncCoordinator._();

  static final ForegroundSyncCoordinator instance = ForegroundSyncCoordinator._();

  Timer? _resumeDebounce;
  bool _syncInFlight = false;

  void dispose() {
    _resumeDebounce?.cancel();
    _resumeDebounce = null;
  }

  void onAppLifecycleChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleForegroundSync();
    }
  }

  void _scheduleForegroundSync() {
    _resumeDebounce?.cancel();
    _resumeDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_runForegroundSync());
    });
  }

  Future<void> _runForegroundSync() async {
    if (_syncInFlight) return;
    _syncInFlight = true;
    try {
      await Future<void>.delayed(Duration.zero);

      await _safe(() async {
        await ActivityLogService.instance.syncPendingFromNative();
      });
      await _safe(() async {
        await ActivityLogService.instance.cleanOldLogs();
      });
      await _safe(() async {
        await ContactFilterSmsPolicy.instance.hydrate();
      });
      await _safe(() async {
        await ContactFilterPreferences().syncToNative();
      });

      await _refreshControllersSafely();

      if (kDebugMode) {
        debugPrint('ReplyMate: foreground sync completed');
      }
    } finally {
      _syncInFlight = false;
    }
  }

  Future<void> _safe(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ReplyMate: foreground sync step failed: $e\n$st');
      }
    }
  }

  Future<void> _refreshControllersSafely() async {
    try {
      if (Get.isRegistered<DashboardController>()) {
        await Get.find<DashboardController>().refreshDashboard();
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ReplyMate: refresh DashboardController: $e\n$st');
      }
    }
    try {
      if (Get.isRegistered<ContactFilterController>()) {
        await Get.find<ContactFilterController>().syncPolicyFromDisk();
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ReplyMate: refresh ContactFilterController: $e\n$st');
      }
    }
  }
}
