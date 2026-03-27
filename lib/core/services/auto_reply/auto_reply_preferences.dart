import 'package:shared_preferences/shared_preferences.dart';

class AutoReplyPreferences {
  static const String _keyAutoReplyEnabled = 'auto_reply_enabled';
  static const String _keyReplyMissedCall = 'reply_missed_call';
  static const String _keyReplyIncomingCall = 'reply_incoming_call';
  static const String _keyReplyWhatsappCall = 'reply_whatsapp_call';
  static const String _keyReplyBusyCall = 'reply_busy_call';
  static const String _keyReplyRejectedCall = 'reply_rejected_call';
  static const String _keyReplyOutgoingAnswered = 'reply_outgoing_answered';
  static const String _keyReplyOutgoingUnanswered = 'reply_outgoing_unanswered';
  static const String _keyMsgMissedCall = 'msg_missed_call';
  static const String _keyMsgIncomingCall = 'msg_incoming_call';
  static const String _keyMsgWhatsappCall = 'msg_whatsapp_call';
  static const String _keyMsgBusyCall = 'msg_busy_call';
  static const String _keyMsgRejectedCall = 'msg_rejected_call';
  static const String _keyMsgOutgoingAnswered = 'msg_outgoing_answered';
  static const String _keyMsgOutgoingUnanswered = 'msg_outgoing_unanswered';
  static const String _keyThrottleEnabled = 'throttle_enabled';

  static const String _defaultMissedCallMessage =
      "Sorry, I missed your call. I'll call you back.";
  static const String _defaultIncomingCallMessage =
      "Thanks for calling! I'm currently busy, will get back to you soon.";
  static const String _defaultWhatsappCallMessage =
      'Sorry, I missed your WhatsApp call.';
  static const String _defaultBusyCallMessage =
      "I'm on another call right now. I'll call you back.";
  static const String _defaultRejectedCallMessage =
      "Sorry, I can't take your call right now. I'll get back to you shortly.";
  static const String _defaultOutgoingAnsweredMessage =
      "Thanks for picking up! Just following up via SMS as well.";
  static const String _defaultOutgoingUnansweredMessage =
      "I tried calling you but couldn't reach you. Please call me back when free.";
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

  Future<bool> getReplyRejectedCall() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReplyRejectedCall) ?? false;
  }

  Future<void> setReplyRejectedCall(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReplyRejectedCall, value);
  }

  Future<bool> getReplyOutgoingAnswered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReplyOutgoingAnswered) ?? false;
  }

  Future<void> setReplyOutgoingAnswered(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReplyOutgoingAnswered, value);
  }

  Future<bool> getReplyOutgoingUnanswered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReplyOutgoingUnanswered) ?? false;
  }

  Future<void> setReplyOutgoingUnanswered(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReplyOutgoingUnanswered, value);
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

  Future<String> getRejectedCallMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyMsgRejectedCall)?.trim();
    return (value == null || value.isEmpty) ? _defaultRejectedCallMessage : value;
  }

  Future<void> setRejectedCallMessage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = value.trim().isEmpty ? _defaultRejectedCallMessage : value.trim();
    await prefs.setString(_keyMsgRejectedCall, normalized);
  }

  Future<String> getOutgoingAnsweredMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyMsgOutgoingAnswered)?.trim();
    return (value == null || value.isEmpty)
        ? _defaultOutgoingAnsweredMessage
        : value;
  }

  Future<void> setOutgoingAnsweredMessage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized =
        value.trim().isEmpty ? _defaultOutgoingAnsweredMessage : value.trim();
    await prefs.setString(_keyMsgOutgoingAnswered, normalized);
  }

  Future<String> getOutgoingUnansweredMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyMsgOutgoingUnanswered)?.trim();
    return (value == null || value.isEmpty)
        ? _defaultOutgoingUnansweredMessage
        : value;
  }

  Future<void> setOutgoingUnansweredMessage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized =
        value.trim().isEmpty ? _defaultOutgoingUnansweredMessage : value.trim();
    await prefs.setString(_keyMsgOutgoingUnanswered, normalized);
  }
}
