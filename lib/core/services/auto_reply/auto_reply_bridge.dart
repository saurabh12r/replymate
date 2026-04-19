import 'package:flutter/services.dart';

class AutoReplyBridge {
  static const MethodChannel _channel = MethodChannel('replymate/auto_reply');

  Future<void> startCallListener() async {
    await _channel.invokeMethod('startCallListener');
  }

  Future<void> stopCallListener() async {
    await _channel.invokeMethod('stopCallListener');
  }

  Future<void> sendSms({
    required String phone,
    required String message,
  }) async {
    await _channel.invokeMethod('sendSms', {
      'phone': phone,
      'message': message,
    });
  }

  Future<void> updateAutoReplyConfig({
    required bool autoReplyEnabled,
    required bool replyOnCallAnswered,
    required bool replyOnMissedCall,
    bool replyOnWhatsappCall = false,
    required bool replyOnBusyCall,
    required bool replyOnRejectedCall,
    required bool replyOnOutgoingAnswered,
    required bool replyOnOutgoingUnanswered,
    required bool useTimeRange,
    required int startMinutes,
    required int endMinutes,
    required String defaultReplyMessage,
  }) async {
    await _channel.invokeMethod('updateAutoReplyConfig', {
      'autoReplyEnabled': autoReplyEnabled,
      'replyOnCallAnswered': replyOnCallAnswered,
      'replyOnMissedCall': replyOnMissedCall,
      'replyOnWhatsappCall': false,
      'replyOnBusyCall': replyOnBusyCall,
      'replyOnRejectedCall': replyOnRejectedCall,
      'replyOnOutgoingAnswered': replyOnOutgoingAnswered,
      'replyOnOutgoingUnanswered': replyOnOutgoingUnanswered,
      'useTimeRange': useTimeRange,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'defaultReplyMessage': defaultReplyMessage,
    });
  }

  Future<Map<String, dynamic>> getAutoReplyConfig() async {
    final data =
        await _channel.invokeMapMethod<String, dynamic>('getAutoReplyConfig');
    return data ?? <String, dynamic>{};
  }

  /// Keeps native [ContactFilterNativeStore] in sync for background SMS filtering.
  Future<void> syncContactFilterNative({
    required String filterMode,
    required String phonesJson,
  }) async {
    await _channel.invokeMethod('syncContactFilterNative', {
      'filterMode': filterMode,
      'phonesJson': phonesJson,
    });
  }

  /// Opens system battery optimization list (Android 6+).
  Future<void> openBatteryOptimizationSettings() async {
    await _channel.invokeMethod('openBatteryOptimizationSettings');
  }

  /// Requests ignore battery optimizations for this package (may be denied by OEM).
  Future<void> requestIgnoreBatteryOptimizations() async {
    await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
  }

  /// Checks if the app is currently the default SMS app without prompting.
  Future<bool> isDefaultSmsApp() async {
    final result = await _channel.invokeMethod<bool>('isDefaultSmsApp');
    return result ?? false;
  }

  /// Prompts user to set this app as the default SMS app (Android 10+ via RoleManager, older via ACTION_CHANGE_DEFAULT).
  Future<bool> requestDefaultSmsApp() async {
    final result = await _channel.invokeMethod<bool>('requestDefaultSmsApp');
    return result ?? false;
  }

  Future<void> setThrottleEnabled(bool enabled) async {
    await _channel.invokeMethod('setThrottleEnabled', {
      'throttleEnabled': enabled,
    });
  }

  Future<void> setAutoReplyEnabled(bool enabled) async {
    await _channel.invokeMethod('setAutoReplyEnabled', {
      'autoReplyEnabled': enabled,
    });
  }

  /// Native hard block for background execution (cached in SharedPreferences).
  Future<void> setBlocked(bool value) async {
    await _channel.invokeMethod('setBlocked', {
      'value': value,
    });
  }

  Future<void> setReplyRules({
    required bool replyOnMissedCall,
    required bool replyOnIncomingCall,
    required bool replyOnBusyCall,
    required bool replyOnRejectedCall,
    required bool replyOnOutgoingAnswered,
    required bool replyOnOutgoingUnanswered,
  }) async {
    await _channel.invokeMethod('setReplyRules', {
      'replyOnMissedCall': replyOnMissedCall,
      'replyOnIncomingCall': replyOnIncomingCall,
      'replyOnWhatsappCall': false,
      'replyOnBusyCall': replyOnBusyCall,
      'replyOnRejectedCall': replyOnRejectedCall,
      'replyOnOutgoingAnswered': replyOnOutgoingAnswered,
      'replyOnOutgoingUnanswered': replyOnOutgoingUnanswered,
    });
  }

  Future<void> setCustomMessages({
    required String missedCallMessage,
    required String incomingCallMessage,
    String whatsappCallMessage = '',
    required String busyCallMessage,
    required String rejectedCallMessage,
    required String outgoingAnsweredMessage,
    required String outgoingUnansweredMessage,
  }) async {
    await _channel.invokeMethod('setCustomMessages', {
      'missedCallMessage': missedCallMessage,
      'incomingCallMessage': incomingCallMessage,
      'whatsappCallMessage': whatsappCallMessage,
      'busyCallMessage': busyCallMessage,
      'rejectedCallMessage': rejectedCallMessage,
      'outgoingAnsweredMessage': outgoingAnsweredMessage,
      'outgoingUnansweredMessage': outgoingUnansweredMessage,
    });
  }

  /// Active SIM subscriptions (values are real [subscriptionId]s for storage).
  Future<List<Map<String, dynamic>>> listSubscriptionInfos() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('listSubscriptionInfos');
    return (raw ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();
  }

  Future<int?> getDefaultSmsSubscriptionId() async {
    final raw = await _channel.invokeMethod<dynamic>('getDefaultSmsSubscriptionId');
    if (raw is int) return raw;
    return null;
  }

  Future<String> getStoresJson() async {
    final s = await _channel.invokeMethod<String>('getStoresJson');
    return s ?? '[]';
  }

  Future<void> setStoresJson(String storesJson) async {
    await _channel.invokeMethod('setStoresJson', {'storesJson': storesJson});
  }
}
