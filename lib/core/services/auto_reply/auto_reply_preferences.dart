import 'package:shared_preferences/shared_preferences.dart';

class AutoReplyPreferences {
  static const String _keyAutoReplyEnabled = 'auto_reply_enabled';
  static const String _keyReplyMissedCall = 'reply_missed_call';
  static const String _keyReplyIncomingCall = 'reply_incoming_call';
  static const String _keyReplyWhatsappCall = 'reply_whatsapp_call';
  static const String _keyReplyBusyCall = 'reply_busy_call';
  static const String _keyReplyOutgoingCall = 'reply_outgoing_call';
  static const String _keyMsgMissedCall = 'msg_missed_call';
  static const String _keyMsgIncomingCall = 'msg_incoming_call';
  static const String _keyMsgWhatsappCall = 'msg_whatsapp_call';
  static const String _keyMsgBusyCall = 'msg_busy_call';
  static const String _keyMsgOutgoingCall = 'msg_outgoing_call';
  static const String _keyThrottleEnabled = 'throttle_enabled';

  static const String _defaultMissedCallMessage =
      "Sorry, I missed your call. I'll call you back.";
  static const String _defaultIncomingCallMessage =
      "I'm currently busy, will get back to you soon.";
  static const String _defaultWhatsappCallMessage =
      'Sorry, I missed your WhatsApp call.';
  static const String _defaultBusyCallMessage =
      "I'm on another call right now. I'll call you back.";
  static const String _defaultOutgoingCallMessage =
      "I'm currently on a call. I'll get back to you soon.";
  static const bool _defaultThrottleEnabled = true;

  Future<bool> getAutoReplyEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoReplyEnabled) ?? true;
  }

  Future<void> setAutoReplyEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoReplyEnabled, value);
  }

  Future<bool> getReplyMissedCall() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReplyMissedCall) ?? true;
  }

  Future<void> setReplyMissedCall(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReplyMissedCall, value);
  }

  Future<bool> getReplyIncomingCall() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReplyIncomingCall) ?? false;
  }

  Future<void> setReplyIncomingCall(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReplyIncomingCall, value);
  }

  Future<bool> getReplyWhatsappCall() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReplyWhatsappCall) ?? true;
  }

  Future<void> setReplyWhatsappCall(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReplyWhatsappCall, value);
  }

  Future<bool> getReplyBusyCall() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReplyBusyCall) ?? false;
  }

  Future<void> setReplyBusyCall(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReplyBusyCall, value);
  }

  Future<bool> getReplyOutgoingCall() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReplyOutgoingCall) ?? false;
  }

  Future<void> setReplyOutgoingCall(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReplyOutgoingCall, value);
  }

  Future<bool> getThrottleEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyThrottleEnabled) ?? _defaultThrottleEnabled;
  }

  Future<void> setThrottleEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyThrottleEnabled, value);
  }

  Future<String> getMissedCallMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyMsgMissedCall)?.trim();
    return (value == null || value.isEmpty) ? _defaultMissedCallMessage : value;
  }

  Future<void> setMissedCallMessage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = value.trim().isEmpty ? _defaultMissedCallMessage : value.trim();
    await prefs.setString(_keyMsgMissedCall, normalized);
  }

  Future<String> getIncomingCallMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyMsgIncomingCall)?.trim();
    return (value == null || value.isEmpty) ? _defaultIncomingCallMessage : value;
  }

  Future<void> setIncomingCallMessage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized =
        value.trim().isEmpty ? _defaultIncomingCallMessage : value.trim();
    await prefs.setString(_keyMsgIncomingCall, normalized);
  }

  Future<String> getWhatsappCallMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyMsgWhatsappCall)?.trim();
    return (value == null || value.isEmpty) ? _defaultWhatsappCallMessage : value;
  }

  Future<void> setWhatsappCallMessage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized =
        value.trim().isEmpty ? _defaultWhatsappCallMessage : value.trim();
    await prefs.setString(_keyMsgWhatsappCall, normalized);
  }

  Future<String> getBusyCallMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyMsgBusyCall)?.trim();
    return (value == null || value.isEmpty) ? _defaultBusyCallMessage : value;
  }

  Future<void> setBusyCallMessage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = value.trim().isEmpty ? _defaultBusyCallMessage : value.trim();
    await prefs.setString(_keyMsgBusyCall, normalized);
  }

  Future<String> getOutgoingCallMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyMsgOutgoingCall)?.trim();
    return (value == null || value.isEmpty)
        ? _defaultOutgoingCallMessage
        : value;
  }

  Future<void> setOutgoingCallMessage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized =
        value.trim().isEmpty ? _defaultOutgoingCallMessage : value.trim();
    await prefs.setString(_keyMsgOutgoingCall, normalized);
  }
}
