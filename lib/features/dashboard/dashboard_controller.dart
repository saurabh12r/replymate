import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../core/activity/activity_log_service.dart';
import '../../core/services/auto_reply/auto_reply_bridge.dart';
import '../../core/services/auto_reply/auto_reply_event_stream.dart';
import '../../core/services/auto_reply/auto_reply_preferences.dart';
import '../../core/services/auth/user_repository.dart';

/// DashboardController
/// Stitch Screen ID: c9f778dbd8df4d52b55759e3997f2300
class DashboardController extends GetxController {
  DashboardController({
    AutoReplyBridge? autoReplyBridge,
    AutoReplyPreferences? autoReplyPreferences,
    UserRepository? userRepository,
  })  : _autoReplyBridge = autoReplyBridge ?? AutoReplyBridge(),
        _autoReplyPreferences = autoReplyPreferences ?? AutoReplyPreferences(),
        _userRepository = userRepository ?? Get.find<UserRepository>();

  final AutoReplyBridge _autoReplyBridge;
  final AutoReplyPreferences _autoReplyPreferences;
  final UserRepository _userRepository;

  // ── Auto-reply state ───────────────────────────────────────────────────────
  final RxBool autoReplyEnabled = true.obs;
  final RxString status = 'Operational'.obs;

  // ── Active message preview ────────────────────────────────────────────────
  final RxString missedCallMessage =
      "Sorry, I missed your call. I'll call you back.".obs;
  final RxString incomingCallMessage =
      "I'm currently busy, will get back to you soon.".obs;
  final RxString whatsappCallMessage =
      'Sorry, I missed your WhatsApp call.'.obs;
  final RxString busyCallMessage =
      "I'm on another call right now. I'll call you back.".obs;
  final RxString outgoingCallMessage =
      "I'm currently on a call. I'll get back to you soon.".obs;
  final RxBool replyOnMissedCall = true.obs;
  final RxBool replyOnIncomingCall = false.obs;
  final RxBool replyOnWhatsappCall = true.obs;
  final RxBool replyOnBusyCall = false.obs;
  final RxBool replyOnOutgoingCall = false.obs;

  // ── Bottom nav ────────────────────────────────────────────────────────────
  final RxInt selectedNavIndex = 0.obs;

  // ── User greeting ─────────────────────────────────────────────────────────
  final RxString userName = 'User'.obs;

  // ── Native event stream (foreground UI) ─────────────────────────────────
  final RxBool eventChannelListening = false.obs;
  final RxString lastEngineEventLine = ''.obs;
  StreamSubscription<dynamic>? _eventSub;
  Timer? _syncDebounce;
  bool _autoReplyEventStreamAttached = false;

  @override
  void onInit() {
    super.onInit();
    _loadAutoReplyState();
    _attachAutoReplyEventStream();
  }

  @override
  void onReady() {
    super.onReady();
    _loadAutoReplyState();
    ActivityLogService.instance.cleanOldLogs();
  }

  Future<void> _loadAutoReplyState() async {
    try {
      final enabledPref = await _autoReplyPreferences.getAutoReplyEnabled();
      final allowed = await _isAutoReplyAllowedInFirebase();
      final enabled = enabledPref && allowed;
      autoReplyEnabled.value = enabled;
      status.value = enabled ? 'Operational' : 'Paused';

      // If the user got blocked / not approved, force disable native engine too.
      if (enabledPref != enabled) {
        await _autoReplyPreferences.setAutoReplyEnabled(enabled);
        await _autoReplyBridge.setAutoReplyEnabled(enabled);
      }

      replyOnMissedCall.value = await _autoReplyPreferences.getReplyMissedCall();
      replyOnIncomingCall.value =
          await _autoReplyPreferences.getReplyIncomingCall();
      replyOnWhatsappCall.value =
          await _autoReplyPreferences.getReplyWhatsappCall();
      replyOnBusyCall.value = await _autoReplyPreferences.getReplyBusyCall();
      replyOnOutgoingCall.value =
          await _autoReplyPreferences.getReplyOutgoingCall();
      missedCallMessage.value =
          await _autoReplyPreferences.getMissedCallMessage();
      incomingCallMessage.value =
          await _autoReplyPreferences.getIncomingCallMessage();
      whatsappCallMessage.value =
          await _autoReplyPreferences.getWhatsappCallMessage();
      busyCallMessage.value = await _autoReplyPreferences.getBusyCallMessage();
      outgoingCallMessage.value =
          await _autoReplyPreferences.getOutgoingCallMessage();
    } catch (_) {
      // Keep current UI state if bridge read fails.
    }
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

  Future<void> toggleAutoReply() async {
    final nextValue = !autoReplyEnabled.value;

    if (nextValue) {
      final flags = await _getAutoReplyAdminFlagsInFirebase();
      final approved = flags['approved'] == true;
      final blocked = flags['blocked'] == true;
      if (!approved || blocked) {
        await _showContactAdminDialog(approved: approved, blocked: blocked);
        return;
      }
    }

    autoReplyEnabled.value = nextValue;
    status.value = nextValue ? 'Operational' : 'Paused';
    try {
      await _autoReplyPreferences.setAutoReplyEnabled(autoReplyEnabled.value);
      await _autoReplyBridge.setAutoReplyEnabled(autoReplyEnabled.value);
    } catch (_) {
      autoReplyEnabled.value = !nextValue;
      status.value = autoReplyEnabled.value ? 'Operational' : 'Paused';
    }
  }

  void onNavTap(int index) {
    selectedNavIndex.value = index;
  }

  Future<void> refreshDashboard() async {
    await _loadAutoReplyState();
  }

  void _attachAutoReplyEventStream() {
    if (_autoReplyEventStreamAttached) return;
    _autoReplyEventStreamAttached = true;
    _eventSub?.cancel();
    eventChannelListening.value = true;
    _eventSub = AutoReplyEventStream.stream.listen(
      (dynamic raw) {
        if (raw is! Map) return;
        final m = Map<String, dynamic>.from(raw);
        lastEngineEventLine.value = _formatEngineEvent(m);
        _debouncedSyncFromNative();
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  void _debouncedSyncFromNative() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 400), () {
      ActivityLogService.instance.syncPendingFromNative();
    });
  }

  String _formatEngineEvent(Map<String, dynamic> m) {
    final kind = m['kind']?.toString() ?? '';
    final phone = m['phone']?.toString() ?? '';
    final event = m['event']?.toString() ?? '';
    switch (kind) {
      case 'dispatching':
        final preview = m['messagePreview']?.toString() ?? '';
        return 'Sending SMS → $phone ($event) ${preview.isNotEmpty ? '· ${preview.length > 40 ? '${preview.substring(0, 40)}…' : preview}' : ''}';
      case 'throttled':
        return 'Cooldown active · skipped $phone ($event)';
      case 'blocked':
        return 'Blocked: ${m['reason'] ?? 'unknown'} ($event)';
      case 'sms_failed':
        return 'SMS failed · $phone: ${m['error'] ?? ''}';
      default:
        return kind.isEmpty ? 'Event' : kind;
    }
  }

  @override
  void onClose() {
    _syncDebounce?.cancel();
    _eventSub?.cancel();
    _autoReplyEventStreamAttached = false;
    super.onClose();
  }
}
