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
    required bool replyOnWhatsappCall,
    required bool replyOnBusyCall,
    required bool replyOnOutgoingCall,
    required bool useTimeRange,
    required int startMinutes,
    required int endMinutes,
    required String defaultReplyMessage,
  }) async {
    await _channel.invokeMethod('updateAutoReplyConfig', {
      'autoReplyEnabled': autoReplyEnabled,
      'replyOnCallAnswered': replyOnCallAnswered,
      'replyOnMissedCall': replyOnMissedCall,
      'replyOnWhatsappCall': replyOnWhatsappCall,
      'replyOnBusyCall': replyOnBusyCall,
      'replyOnOutgoingCall': replyOnOutgoingCall,
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

  /// Prompts user to set this app as the default SMS app (Android 10+ via RoleManager).
  Future<void> requestDefaultSmsRole() async {
    await _channel.invokeMethod('requestDefaultSmsRole');
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

  Future<void> setReplyRules({
    required bool replyOnMissedCall,
    required bool replyOnIncomingCall,
    required bool replyOnWhatsappCall,
    required bool replyOnBusyCall,
    required bool replyOnOutgoingCall,
  }) async {
    await _channel.invokeMethod('setReplyRules', {
      'replyOnMissedCall': replyOnMissedCall,
      'replyOnIncomingCall': replyOnIncomingCall,
      'replyOnWhatsappCall': replyOnWhatsappCall,
      'replyOnBusyCall': replyOnBusyCall,
      'replyOnOutgoingCall': replyOnOutgoingCall,
    });
  }

  Future<void> setCustomMessages({
    required String missedCallMessage,
    required String incomingCallMessage,
    required String whatsappCallMessage,
    required String busyCallMessage,
    required String outgoingCallMessage,
  }) async {
    await _channel.invokeMethod('setCustomMessages', {
      'missedCallMessage': missedCallMessage,
      'incomingCallMessage': incomingCallMessage,
      'whatsappCallMessage': whatsappCallMessage,
      'busyCallMessage': busyCallMessage,
      'outgoingCallMessage': outgoingCallMessage,
    });
  }
}
