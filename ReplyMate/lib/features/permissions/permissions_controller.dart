import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/permissions/permission_service.dart';
import '../../core/services/subscription/subscription_service.dart';

class PermissionsController extends GetxController with WidgetsBindingObserver {
  final PermissionService _service = PermissionService();

  final smsGranted = false.obs;
  final callLogsGranted = false.obs;
  final contactsGranted = false.obs;
  final notificationsGranted = false.obs;
  final batteryOptimizationGranted = false.obs;

  Timer? _realtimeTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    refreshStatuses();
    // Periodically poll permission state in the foreground to update UI instantly
    _realtimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      refreshStatuses();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshStatuses();
    }
  }

  Future<void> refreshStatuses() async {
    smsGranted.value = await _service.isGranted(AppPermissionType.sms);
    callLogsGranted.value = await _service.isGranted(AppPermissionType.callLogs);
    contactsGranted.value = await _service.isGranted(AppPermissionType.contacts);
    notificationsGranted.value = await _service.isGranted(AppPermissionType.notifications);
    batteryOptimizationGranted.value = await Permission.ignoreBatteryOptimizations.isGranted;
  }

  Future<void> requestPermission(AppPermissionType type) async {
    await _service.request(type);
    await refreshStatuses();
  }

  Future<void> requestBatteryOptimization() async {
    await Permission.ignoreBatteryOptimizations.request();
    await refreshStatuses();
  }

  bool get areAllPermissionsGranted {
    return smsGranted.value &&
        callLogsGranted.value &&
        contactsGranted.value &&
        notificationsGranted.value &&
        batteryOptimizationGranted.value;
  }

  void goToDashboard() async {
    final route = await SubscriptionService.instance.determineRouteForCurrentSession();
    Get.offAllNamed(route);
  }

  @override
  void onClose() {
    _realtimeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
