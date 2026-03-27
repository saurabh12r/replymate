import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth/user_repository.dart';
import '../../core/services/auto_reply/auto_reply_bridge.dart';
import '../../core/services/auto_reply/auto_reply_preferences.dart';
import '../../core/services/permissions/permission_service.dart';
import '../dashboard/dashboard_controller.dart';

/// Global settings: master auto-reply, throttle, permissions.
/// Per-SIM rules and messages live under **Businesses** (native store registry).
class SettingsController extends GetxController {
  SettingsController({
    AutoReplyBridge? autoReplyBridge,
    AutoReplyPreferences? autoReplyPreferences,
    UserRepository? userRepository,
  })  : _autoReplyBridge = autoReplyBridge ?? AutoReplyBridge(),
        _autoReplyPreferences = autoReplyPreferences ?? AutoReplyPreferences(),
        _userRepository = userRepository ?? Get.find<UserRepository>();

  final AutoReplyBridge _autoReplyBridge;
  final AutoReplyPreferences _autoReplyPreferences;
  final UserRepository _userRepository;
  final PermissionService _permissionService = PermissionService();
  bool _hydrating = false;

  final RxBool permSmsGranted = false.obs;
  final RxBool permPhoneCallLogsGranted = false.obs;
  final RxBool permPostNotificationsGranted = false.obs;
  final RxBool permNotificationListenerGranted = false.obs;

  final RxBool autoReplyEnabled = true.obs;
  final RxBool throttleEnabled = true.obs;

  final RxBool isSaving = false.obs;
  final RxBool saveSuccess = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPersistedRules();
    ever<bool>(autoReplyEnabled, (value) async {
      if (_hydrating) return;
      await _autoReplyPreferences.setAutoReplyEnabled(value);
      await _autoReplyBridge.setAutoReplyEnabled(value);
    });
    ever<bool>(throttleEnabled, (value) async {
      if (_hydrating) return;
      await _autoReplyPreferences.setThrottleEnabled(value);
      await _autoReplyBridge.setThrottleEnabled(value);
    });
    refreshPermissionStatus();
  }

  Future<void> refreshPermissionStatus() async {
    permSmsGranted.value =
        await _permissionService.isGranted(AppPermissionType.sms);
    permPhoneCallLogsGranted.value =
        await _permissionService.isGranted(AppPermissionType.callLogs);
    permPostNotificationsGranted.value =
        await _permissionService.isGranted(AppPermissionType.notifications);
    permNotificationListenerGranted.value = await _permissionService
        .isGranted(AppPermissionType.notificationListener);
  }

  Future<void> _loadPersistedRules() async {
    _hydrating = true;
    try {
      autoReplyEnabled.value = await _autoReplyPreferences.getAutoReplyEnabled();
      throttleEnabled.value = await _autoReplyPreferences.getThrottleEnabled();
    } finally {
      _hydrating = false;
    }
    await _applyAutoReplyApprovalGuard();
  }

  Future<bool> _isAutoReplyAllowedInFirebase() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final phone = currentUser?.phoneNumber;
    if (phone == null || phone.isEmpty) return false;

    final data = await _userRepository.getUserByPhone(phone);
    final approved = (data?['isApproved'] as bool?) == true;
    final blocked = (data?['isBlocked'] as bool?) == true;
    return approved && !blocked;
  }

  Future<void> _applyAutoReplyApprovalGuard() async {
    final allowed = await _isAutoReplyAllowedInFirebase();
    if (!allowed && autoReplyEnabled.value) {
      autoReplyEnabled.value = false;
    }
  }

  Future<void> trySetAutoReplyEnabled(bool enabled) async {
    if (enabled) {
      final flags = await _getAutoReplyAdminFlagsInFirebase();
      final approved = flags['approved'] == true;
      final blocked = flags['blocked'] == true;

      if (!approved || blocked) {
        autoReplyEnabled.value = false;
        await _showContactAdminDialog(approved: approved, blocked: blocked);
        return;
      }
    }

    autoReplyEnabled.value = enabled;
  }

  Future<Map<String, bool>> _getAutoReplyAdminFlagsInFirebase() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final phone = currentUser?.phoneNumber;
    if (phone == null || phone.isEmpty) {
      return {'approved': false, 'blocked': false};
    }

    final data = await _userRepository.getUserByPhone(phone);
    final approved = (data?['isApproved'] as bool?) == true;
    final blocked = (data?['isBlocked'] as bool?) == true;
    return {'approved': approved, 'blocked': blocked};
  }

  Future<void> _showContactAdminDialog({
    required bool approved,
    required bool blocked,
  }) async {
    final body = blocked
        ? 'You have been blocked. Please contact admin.'
        : 'Your auto-reply access is not approved yet. Please contact admin.';

    await Get.dialog<void>(
      AlertDialog(
        title: const Text('Contact admin'),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Future<void> saveSettings() async {
    isSaving.value = true;
    saveSuccess.value = false;
    await _autoReplyPreferences.setAutoReplyEnabled(autoReplyEnabled.value);
    await _autoReplyPreferences.setThrottleEnabled(throttleEnabled.value);
    await _autoReplyBridge.setAutoReplyEnabled(autoReplyEnabled.value);
    await _autoReplyBridge.setThrottleEnabled(throttleEnabled.value);
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().refreshDashboard();
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    isSaving.value = false;
    saveSuccess.value = true;
    Get.snackbar(
      '✅ Settings Saved',
      'Your preferences have been updated',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF006A6A),
      colorText: Colors.white,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> recheckPermissions() async {
    await refreshPermissionStatus();
    if (!permSmsGranted.value) {
      await _permissionService.request(AppPermissionType.sms);
    }
    if (!permPhoneCallLogsGranted.value) {
      await _permissionService.request(AppPermissionType.callLogs);
    }
    if (!permPostNotificationsGranted.value) {
      await _permissionService.request(AppPermissionType.notifications);
    }
    if (!permNotificationListenerGranted.value) {
      await _permissionService.request(AppPermissionType.notificationListener);
    }
    await refreshPermissionStatus();
    final ok = permSmsGranted.value &&
        permPhoneCallLogsGranted.value &&
        permPostNotificationsGranted.value &&
        permNotificationListenerGranted.value;
    Get.snackbar(
      'Permissions',
      ok
          ? 'Required access looks good.'
          : 'Some items still need approval — see status below.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          ok ? const Color(0xFF006A6A) : const Color(0xFF24389C),
      colorText: Colors.white,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
    );
  }

  void navigateToLogout() => Get.toNamed(Routes.logoutConfirm);

  Future<void> confirmDeleteAccount() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. '
          'This action cannot be undone.\n\n'
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFBA1A1A),
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _userRepository.deleteUserByUid(user.uid);
        await user.delete();
      }
      Get.offAllNamed(Routes.login);
      Get.snackbar(
        'Account Deleted',
        'Your account and data have been removed.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF006A6A),
        colorText: Colors.white,
        borderRadius: 14,
        margin: const EdgeInsets.all(16),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        Get.snackbar(
          'Re-authentication Required',
          'Please sign out, sign back in, and try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFBA1A1A),
          colorText: Colors.white,
          borderRadius: 14,
          margin: const EdgeInsets.all(16),
        );
      } else {
        rethrow;
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Unable to delete account. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFBA1A1A),
        colorText: Colors.white,
        borderRadius: 14,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}
