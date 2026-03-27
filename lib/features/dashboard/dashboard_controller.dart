import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../core/activity/activity_log_service.dart';
import '../../core/services/auto_reply/auto_reply_bridge.dart';
import '../../core/services/auto_reply/auto_reply_event_stream.dart';
import '../../core/services/auto_reply/auto_reply_preferences.dart';
import '../../core/services/auth/user_repository.dart';
import '../../core/stores/reply_store_models.dart';

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

  /// Shown on dashboard instead of per-message preview (default SMS / first active store).
  final RxString activeBusinessName = ''.obs;

  // ── Active message preview (still loaded for any legacy use) ───────────────
  final RxString missedCallMessage =
      "Sorry, I missed your call. I'll call you back.".obs;
  final RxString incomingCallMessage =
      "I'm currently busy, will get back to you soon.".obs;
  final RxString whatsappCallMessage =
      'Sorry, I missed your WhatsApp call.'.obs;
  final RxString busyCallMessage =
      "I'm on another call right now. I'll call you back.".obs;
  final RxString rejectedCallMessage =
      "Sorry, I can't take your call right now. I'll get back to you shortly.".obs;
  final RxString outgoingAnsweredMessage =
      "Thanks for picking up! Just following up via SMS as well.".obs;
  final RxString outgoingUnansweredMessage =
      "I tried calling you but couldn't reach you. Please call me back when free.".obs;
  final RxBool replyOnMissedCall = true.obs;
  final RxBool replyOnIncomingCall = false.obs;
  final RxBool replyOnWhatsappCall = true.obs;
  final RxBool replyOnBusyCall = false.obs;
  final RxBool replyOnRejectedCall = false.obs;
  final RxBool replyOnOutgoingAnswered = false.obs;
  final RxBool replyOnOutgoingUnanswered = false.obs;

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
    unawaited(_cleanOldLogsSafe());
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

      final raw = await _autoReplyBridge.getStoresJson();
      final stores = parseReplyStoresJson(raw);
      final subId = await _autoReplyBridge.getDefaultSmsSubscriptionId();
      ReplyStore? store;
      if (subId != null) {
        final match = findStoreForSubscription(stores, subId);
        if (match != null && _isBusinessActiveOnLine(match)) {
          store = match;
        }
      }
      if (store == null) {
        for (final s in stores) {
          if (_isBusinessActiveOnLine(s)) {
            store = s;
            break;
          }
        }
      }
      if (store != null) {
        _applyStorePreview(store);
      } else {
        _clearStorePreview();
      }
    } catch (_) {
      // Keep current UI state if bridge read fails.
    }
  }

  Future<void> _cleanOldLogsSafe() async {
    try {
      await ActivityLogService.instance.cleanOldLogs();
    } catch (_) {}
  }

  /// Matches Businesses screen: ON + SIM selected.
  static bool _isBusinessActiveOnLine(ReplyStore s) =>
      s.active && s.subscriptionId != null;

  void _applyStorePreview(ReplyStore store) {
    activeBusinessName.value = store.name;
    replyOnMissedCall.value = store.replyMissedCall;
    replyOnIncomingCall.value = store.replyIncomingCall;
    replyOnWhatsappCall.value = store.replyWhatsappCall;
    replyOnBusyCall.value = store.replyBusyCall;
    replyOnRejectedCall.value = store.replyRejectedCall;
    replyOnOutgoingAnswered.value = store.replyOutgoingAnswered;
    replyOnOutgoingUnanswered.value = store.replyOutgoingUnanswered;
    missedCallMessage.value =
        store.messageForEventKey(ReplyStoreEventKeys.missedCall) ?? '—';
    incomingCallMessage.value =
        store.messageForEventKey(ReplyStoreEventKeys.incomingCall) ?? '—';
    whatsappCallMessage.value =
        store.messageForEventKey(ReplyStoreEventKeys.missedWhatsapp) ?? '—';
    busyCallMessage.value =
        store.messageForEventKey(ReplyStoreEventKeys.busyCall) ?? '—';
    rejectedCallMessage.value =
        store.messageForEventKey(ReplyStoreEventKeys.rejectedCall) ?? '—';
    outgoingAnsweredMessage.value =
        store.messageForEventKey(ReplyStoreEventKeys.outgoingAnswered) ?? '—';
    outgoingUnansweredMessage.value =
        store.messageForEventKey(ReplyStoreEventKeys.outgoingUnanswered) ?? '—';
  }

  void _clearStorePreview() {
    activeBusinessName.value = '';
    replyOnMissedCall.value = false;
    replyOnIncomingCall.value = false;
    replyOnWhatsappCall.value = false;
    replyOnBusyCall.value = false;
    replyOnRejectedCall.value = false;
    replyOnOutgoingAnswered.value = false;
    replyOnOutgoingUnanswered.value = false;
    const dash = '—';
    missedCallMessage.value = dash;
    incomingCallMessage.value = dash;
    whatsappCallMessage.value = dash;
    busyCallMessage.value = dash;
    rejectedCallMessage.value = dash;
    outgoingAnsweredMessage.value = dash;
    outgoingUnansweredMessage.value = dash;
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
