import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth/user_repository.dart';
import '../../core/services/auto_reply/auto_reply_bridge.dart';
import '../../core/services/auto_reply/auto_reply_preferences.dart';
import '../../core/services/permissions/permission_service.dart';
import '../dashboard/dashboard_controller.dart';

/// SettingsController
/// Stitch Screen ID: 85e03ab29e7d4b36b405cd279cd70d9b
///
/// NOTE: All settings are currently in-memory (Rx).
/// Wire up shared_preferences when available for persistence.
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

  // ── Automation toggles ─────────────────────────────────────────────────────
  final RxBool autoReplyEnabled = true.obs;
  final RxBool throttleEnabled = true.obs;

  // ── Reply rules ────────────────────────────────────────────────────────────
  final RxBool replyOnMissedCallOnly = true.obs;
  final RxBool replyOnCall = false.obs;
  final RxBool replyOnWhatsappCall = true.obs;
  final RxBool replyOnBusyCall = false.obs;
  final RxBool replyOnOutgoingCall = false.obs;

  // ── Messages ────────────────────────────────────────────────────────────────
  final TextEditingController missedCallMessageController =
      TextEditingController();
  final TextEditingController incomingCallMessageController =
      TextEditingController();
  final TextEditingController whatsappCallMessageController =
      TextEditingController();
  final TextEditingController busyCallMessageController =
      TextEditingController();
  final TextEditingController outgoingCallMessageController =
      TextEditingController();

  // ── Time range ─────────────────────────────────────────────────────────────
  final RxBool useTimeRange = false.obs;
  final Rx<TimeOfDay> startTime = const TimeOfDay(hour: 9, minute: 0).obs;
  final Rx<TimeOfDay> endTime = const TimeOfDay(hour: 21, minute: 0).obs;

  // ── Save state ─────────────────────────────────────────────────────────────
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
    ever<bool>(replyOnMissedCallOnly, (_) => _persistReplyRules());
    ever<bool>(replyOnCall, (_) => _persistReplyRules());
    ever<bool>(replyOnWhatsappCall, (_) => _persistReplyRules());
    ever<bool>(replyOnBusyCall, (_) => _persistReplyRules());
    ever<bool>(replyOnOutgoingCall, (_) => _persistReplyRules());
    missedCallMessageController.addListener(_persistCustomMessages);
    incomingCallMessageController.addListener(_persistCustomMessages);
    whatsappCallMessageController.addListener(_persistCustomMessages);
    busyCallMessageController.addListener(_persistCustomMessages);
    outgoingCallMessageController.addListener(_persistCustomMessages);
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
      replyOnMissedCallOnly.value =
          await _autoReplyPreferences.getReplyMissedCall();
      replyOnCall.value = await _autoReplyPreferences.getReplyIncomingCall();
      replyOnWhatsappCall.value =
          await _autoReplyPreferences.getReplyWhatsappCall();
      replyOnBusyCall.value = await _autoReplyPreferences.getReplyBusyCall();
      replyOnOutgoingCall.value =
          await _autoReplyPreferences.getReplyOutgoingCall();
      missedCallMessageController.text =
          await _autoReplyPreferences.getMissedCallMessage();
      incomingCallMessageController.text =
          await _autoReplyPreferences.getIncomingCallMessage();
      whatsappCallMessageController.text =
          await _autoReplyPreferences.getWhatsappCallMessage();
      busyCallMessageController.text =
          await _autoReplyPreferences.getBusyCallMessage();
      outgoingCallMessageController.text =
          await _autoReplyPreferences.getOutgoingCallMessage();
    } finally {
      _hydrating = false;
    }

    // Enforce admin approval + not-blocked rule before allowing native replies.
    await _applyAutoReplyApprovalGuard();

    await _persistReplyRules();
    await _persistCustomMessages();
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
      autoReplyEnabled.value = false; // Triggers ever() persistence + native sync.
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

  Future<void> _persistReplyRules() async {
    if (_hydrating) return;
    await _autoReplyPreferences.setReplyMissedCall(replyOnMissedCallOnly.value);
    await _autoReplyPreferences.setReplyIncomingCall(replyOnCall.value);
    await _autoReplyPreferences.setReplyWhatsappCall(replyOnWhatsappCall.value);
    await _autoReplyPreferences.setReplyBusyCall(replyOnBusyCall.value);
    await _autoReplyPreferences.setReplyOutgoingCall(replyOnOutgoingCall.value);
    await _autoReplyBridge.setReplyRules(
      replyOnMissedCall: replyOnMissedCallOnly.value,
      replyOnIncomingCall: replyOnCall.value,
      replyOnWhatsappCall: replyOnWhatsappCall.value,
      replyOnBusyCall: replyOnBusyCall.value,
      replyOnOutgoingCall: replyOnOutgoingCall.value,
    );
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().refreshDashboard();
    }
  }

  Future<void> _persistCustomMessages() async {
    if (_hydrating) return;
    await _autoReplyPreferences
        .setMissedCallMessage(missedCallMessageController.text);
    await _autoReplyPreferences
        .setIncomingCallMessage(incomingCallMessageController.text);
    await _autoReplyPreferences
        .setWhatsappCallMessage(whatsappCallMessageController.text);
    await _autoReplyPreferences
        .setBusyCallMessage(busyCallMessageController.text);
    await _autoReplyPreferences
        .setOutgoingCallMessage(outgoingCallMessageController.text);
    await _autoReplyBridge.setCustomMessages(
      missedCallMessage: missedCallMessageController.text,
      incomingCallMessage: incomingCallMessageController.text,
      whatsappCallMessage: whatsappCallMessageController.text,
      busyCallMessage: busyCallMessageController.text,
      outgoingCallMessage: outgoingCallMessageController.text,
    );
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().refreshDashboard();
    }
  }

  Future<void> pickStartTime(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: startTime.value);
    if (picked != null) startTime.value = picked;
  }

  Future<void> pickEndTime(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: endTime.value);
    if (picked != null) endTime.value = picked;
  }

  String formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> saveSettings() async {
    isSaving.value = true;
    saveSuccess.value = false;
    await _autoReplyPreferences.setAutoReplyEnabled(autoReplyEnabled.value);
    await _autoReplyPreferences.setReplyMissedCall(replyOnMissedCallOnly.value);
    await _autoReplyPreferences.setReplyIncomingCall(replyOnCall.value);
    await _autoReplyPreferences.setReplyWhatsappCall(replyOnWhatsappCall.value);
    await _autoReplyPreferences.setReplyBusyCall(replyOnBusyCall.value);
    await _autoReplyPreferences.setReplyOutgoingCall(replyOnOutgoingCall.value);
    await _autoReplyPreferences
        .setMissedCallMessage(missedCallMessageController.text);
    await _autoReplyPreferences
        .setIncomingCallMessage(incomingCallMessageController.text);
    await _autoReplyPreferences
        .setWhatsappCallMessage(whatsappCallMessageController.text);
    await _autoReplyPreferences
        .setBusyCallMessage(busyCallMessageController.text);
    await _autoReplyPreferences
        .setOutgoingCallMessage(outgoingCallMessageController.text);
    await _autoReplyBridge.setAutoReplyEnabled(autoReplyEnabled.value);
    await _autoReplyBridge.setReplyRules(
      replyOnMissedCall: replyOnMissedCallOnly.value,
      replyOnIncomingCall: replyOnCall.value,
      replyOnWhatsappCall: replyOnWhatsappCall.value,
      replyOnBusyCall: replyOnBusyCall.value,
      replyOnOutgoingCall: replyOnOutgoingCall.value,
    );
    await _autoReplyBridge.setCustomMessages(
      missedCallMessage: missedCallMessageController.text,
      incomingCallMessage: incomingCallMessageController.text,
      whatsappCallMessage: whatsappCallMessageController.text,
      busyCallMessage: busyCallMessageController.text,
      outgoingCallMessage: outgoingCallMessageController.text,
    );
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

  Future<void> requestDefaultSmsRole() async {
    try {
      await _autoReplyBridge.requestDefaultSmsRole();
    } catch (_) {
      // Best-effort: role request is device/OS dependent.
    }
  }

  Future<void> openTestAutoReplyDialog() async {
    final phoneController = TextEditingController();
    await Get.dialog<void>(
      AlertDialog(
        title: const Text('Send test auto reply'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: 'Include country code if needed',
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final p = phoneController.text;
              Get.back<void>();
              sendTestAutoReply(p);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    phoneController.dispose();
  }

  Future<void> sendTestAutoReply(String rawPhone) async {
    final phone = rawPhone.trim();
    if (phone.isEmpty) {
      Get.snackbar(
        'Phone required',
        'Enter a number to send the test SMS.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFBA1A1A),
        colorText: Colors.white,
        borderRadius: 14,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    final msg = missedCallMessageController.text.trim().isNotEmpty
        ? missedCallMessageController.text.trim()
        : 'ReplyMate test auto-reply.';
    try {
      await _autoReplyBridge.sendSms(phone: phone, message: msg);
      Get.snackbar(
        'Test SMS',
        'Message queued to $phone',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF006A6A),
        colorText: Colors.white,
        borderRadius: 14,
        margin: const EdgeInsets.all(16),
      );
    } on PlatformException catch (e) {
      Get.snackbar(
        'SMS failed',
        e.message ?? 'Could not send',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFBA1A1A),
        colorText: Colors.white,
        borderRadius: 14,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void navigateToLogout() => Get.toNamed(Routes.logoutConfirm);

  @override
  void onClose() {
    missedCallMessageController.dispose();
    incomingCallMessageController.dispose();
    whatsappCallMessageController.dispose();
    busyCallMessageController.dispose();
    outgoingCallMessageController.dispose();
    super.onClose();
  }
}
