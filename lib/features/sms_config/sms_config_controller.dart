import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auto_reply/auto_reply_bridge.dart';

/// SmsConfigController
/// Stitch Screen ID: 53c349aca01c48a582c0b153cecb49d2
class SmsConfigController extends GetxController {
  SmsConfigController({AutoReplyBridge? autoReplyBridge})
      : _autoReplyBridge = autoReplyBridge ?? AutoReplyBridge();

  final AutoReplyBridge _autoReplyBridge;

  // ── Message ────────────────────────────────────────────────────────────────
  final messageController = TextEditingController();
  final RxString defaultReplyMessage = ''.obs;
  final RxString charCount = '0/160'.obs;

  // ── Toggles ────────────────────────────────────────────────────────────────
  final RxBool autoReplyEnabled = true.obs;
  final RxBool replyOnCall = false.obs;
  final RxBool replyOnMissedCall = true.obs;
  final RxBool replyOnWhatsappCall = true.obs;
  final RxBool replyOnBusyCall = false.obs;
  final RxBool replyOnRejectedCall = false.obs;
  final RxBool replyOnOutgoingAnswered = false.obs;
  final RxBool replyOnOutgoingUnanswered = false.obs;

  // ── Time range ─────────────────────────────────────────────────────────────
  final Rx<TimeOfDay> startTime = const TimeOfDay(hour: 9, minute: 0).obs;
  final Rx<TimeOfDay> endTime = const TimeOfDay(hour: 21, minute: 0).obs;
  final RxBool useTimeRange = false.obs;

  // ── Template messages ──────────────────────────────────────────────────────
  static const List<String> templates = [
    "In a meeting, will call you back at 3 PM.",
    "Driving right now. I'll check my messages soon.",
    "Hi there! Received your message. Talk soon!",
  ];

  // ── Loading ────────────────────────────────────────────────────────────────
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    messageController.addListener(_onMessageChanged);
    _loadConfig();
  }

  void _onMessageChanged() {
    final text = messageController.text;
    defaultReplyMessage.value = text;
    charCount.value = '${text.length}/160';
  }

  void applyTemplate(String template) {
    messageController.text = template;
    messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: template.length),
    );
  }

  Future<void> pickStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: startTime.value,
    );
    if (picked != null) startTime.value = picked;
  }

  Future<void> pickEndTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: endTime.value,
    );
    if (picked != null) endTime.value = picked;
  }

  String formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  int _timeToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
  TimeOfDay _minutesToTime(int minutes) =>
      TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60);

  Future<void> _loadConfig() async {
    messageController.text = templates[0];
    _onMessageChanged();
    try {
      final config = await _autoReplyBridge.getAutoReplyConfig();
      autoReplyEnabled.value = config['autoReplyEnabled'] as bool? ?? true;
      replyOnCall.value = config['replyOnCallAnswered'] as bool? ?? false;
      replyOnMissedCall.value = config['replyOnMissedCall'] as bool? ?? true;
      replyOnWhatsappCall.value = config['replyOnWhatsappCall'] as bool? ?? true;
      replyOnBusyCall.value = config['replyOnBusyCall'] as bool? ?? false;
      replyOnRejectedCall.value = config['replyOnRejectedCall'] as bool? ?? false;
      replyOnOutgoingAnswered.value = config['replyOnOutgoingAnswered'] as bool? ?? false;
      replyOnOutgoingUnanswered.value = config['replyOnOutgoingUnanswered'] as bool? ?? false;
      useTimeRange.value = config['useTimeRange'] as bool? ?? false;
      startTime.value = _minutesToTime(config['startMinutes'] as int? ?? 540);
      endTime.value = _minutesToTime(config['endMinutes'] as int? ?? 1260);
      final message = (config['defaultReplyMessage'] as String?)?.trim();
      if (message != null && message.isNotEmpty) {
        messageController.text = message;
        _onMessageChanged();
      }
    } catch (_) {
      errorMessage.value = 'Unable to load auto-reply settings.';
    }
  }

  Future<void> saveAndContinue() async {
    if (defaultReplyMessage.value.trim().isEmpty) return;
    isSaving.value = true;
    errorMessage.value = '';
    try {
      await _autoReplyBridge.updateAutoReplyConfig(
        autoReplyEnabled: autoReplyEnabled.value,
        replyOnCallAnswered: replyOnCall.value,
        replyOnMissedCall: replyOnMissedCall.value,
        replyOnWhatsappCall: replyOnWhatsappCall.value,
        replyOnBusyCall: replyOnBusyCall.value,
        replyOnRejectedCall: replyOnRejectedCall.value,
        replyOnOutgoingAnswered: replyOnOutgoingAnswered.value,
        replyOnOutgoingUnanswered: replyOnOutgoingUnanswered.value,
        useTimeRange: useTimeRange.value,
        startMinutes: _timeToMinutes(startTime.value),
        endMinutes: _timeToMinutes(endTime.value),
        defaultReplyMessage: defaultReplyMessage.value.trim(),
      );
      if (autoReplyEnabled.value) {
        await _autoReplyBridge.startCallListener();
      } else {
        await _autoReplyBridge.stopCallListener();
      }
      Get.offAllNamed(Routes.dashboard);
    } catch (_) {
      errorMessage.value = 'Unable to save settings. Please try again.';
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
