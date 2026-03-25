import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/permissions/permission_service.dart';

/// PermissionsSetupController
/// Stitch Screen ID: 342e2e75ebff4d13a2d9cc153f73f614
///
class PermissionsSetupController extends GetxController
    with WidgetsBindingObserver {
  PermissionsSetupController({PermissionService? permissionService})
      : _permissionService = permissionService ?? PermissionService();

  final PermissionService _permissionService;

  // ── Per-permission reactive status ────────────────────────────────────────
  final RxBool isSmsGranted = false.obs;
  final RxBool isCallLogsGranted = false.obs;
  final RxBool isNotificationGranted = false.obs;
  final RxBool isContactsGranted = false.obs;
  final RxBool isNotificationListenerGranted = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<AppPermissionType?> permanentlyDeniedPermission =
      Rx<AppPermissionType?>(null);

  bool get allGranted =>
      isSmsGranted.value &&
      isCallLogsGranted.value &&
      isNotificationGranted.value &&
      isContactsGranted.value &&
      isNotificationListenerGranted.value;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    refreshPermissionState();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshPermissionState();
    }
  }

  Future<bool> checkAllPermissions() => _permissionService.checkAllPermissions();

  // ── Individual "Allow" taps ───────────────────────────────────────────────
  Future<void> requestSms() async {
    await _requestPermission(AppPermissionType.sms);
  }

  Future<void> requestCallLogs() async {
    await _requestPermission(AppPermissionType.callLogs);
  }

  Future<void> requestNotification() async {
    await _requestPermission(AppPermissionType.notifications);
  }

  Future<void> requestContacts() async {
    await _requestPermission(AppPermissionType.contacts);
  }

  Future<void> requestNotificationListener() async {
    await _requestPermission(AppPermissionType.notificationListener);
  }

  Future<void> openAppSettingsForPermanentlyDenied() async {
    await openAppSettings();
  }

  Future<void> refreshPermissionState() async {
    isSmsGranted.value = await _permissionService.isGranted(AppPermissionType.sms);
    isCallLogsGranted.value =
        await _permissionService.isGranted(AppPermissionType.callLogs);
    isNotificationGranted.value =
        await _permissionService.isGranted(AppPermissionType.notifications);
    isContactsGranted.value =
        await _permissionService.isGranted(AppPermissionType.contacts);
    isNotificationListenerGranted.value =
        await _permissionService.isGranted(AppPermissionType.notificationListener);
  }

  Future<void> requestAllPermissions() async {
    await requestSms();
    await requestCallLogs();
    await requestNotification();
    await requestContacts();
    await requestNotificationListener();
  }

  // ── Continue — requests/checks permissions and navigates forward ──────────
  Future<void> onContinue() async {
    isLoading.value = true;
    errorMessage.value = '';
    await refreshPermissionState();
    final granted = await checkAllPermissions();
    isLoading.value = false;
    if (granted) {
      Get.offNamed(Routes.notificationGuide);
    } else {
      errorMessage.value =
          'Some required permissions are still denied. Please grant all permissions to continue.';
      Get.offNamed(Routes.permissionError);
    }
  }

  Future<void> _requestPermission(AppPermissionType permissionType) async {
    errorMessage.value = '';
    permanentlyDeniedPermission.value = null;
    final status = await _permissionService.request(permissionType);
    await refreshPermissionState();

    if (status.isGranted) {
      return;
    }

    if (status.isPermanentlyDenied ||
        await _permissionService.isPermanentlyDenied(permissionType)) {
      permanentlyDeniedPermission.value = permissionType;
      errorMessage.value =
          'Permission is permanently denied. Please open app settings to grant it.';
      return;
    }

    errorMessage.value =
        'Permission denied. Please retry and allow access to continue.';
  }
}
