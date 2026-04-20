import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scheduled_message_models.dart';

class ScheduledMessagesController extends GetxController {
  final messages = <ScheduledMessage>[].obs;
  static const String _prefsKey = 'scheduled_messages_v1';
  
  static const MethodChannel _channel = MethodChannel('replymate/auto_reply');

  @override
  void onInit() {
    super.onInit();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(jsonString);
        messages.value = list.map((e) => ScheduledMessage.fromJson(e)).toList();
        _sortMessages();
      } catch (e) {
        print('Error loading scheduled messages: $e');
      }
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final list = messages.map((e) => e.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(list));
  }

  void _sortMessages() {
    final now = DateTime.now();
    messages.sort((a, b) {
      final aPast = a.scheduledTime.isBefore(now);
      final bPast = b.scheduledTime.isBefore(now);
      
      if (aPast && !bPast) return 1; // b is upcoming, b comes first
      if (!aPast && bPast) return -1; // a is upcoming, a comes first
      
      if (!aPast && !bPast) {
        // Both upcoming: nearest time first
        return a.scheduledTime.compareTo(b.scheduledTime);
      } else {
        // Both past: most recently passed first
        return b.scheduledTime.compareTo(a.scheduledTime);
      }
    });
  }

  Future<void> addMessage(ScheduledMessage msg) async {
    messages.add(msg);
    _sortMessages();
    await _saveMessages();
    await _scheduleNative(msg);
  }

  Future<void> removeMessage(String id) async {
    messages.removeWhere((m) => m.id == id);
    await _saveMessages();
    await _cancelNative(id);
  }

  Future<void> _scheduleNative(ScheduledMessage msg) async {
    try {
      await _channel.invokeMethod('scheduleSms', {
        'id': msg.id,
        'phoneNumber': msg.phoneNumber,
        'message': msg.message,
        'timeMillis': msg.scheduledTime.millisecondsSinceEpoch,
      });
    } on PlatformException catch (e) {
      print("Failed to schedule native SMS: '${e.message}'.");
    }
  }

  Future<void> _cancelNative(String id) async {
    try {
      await _channel.invokeMethod('cancelScheduledSms', {'id': id});
    } on PlatformException catch (e) {
      print("Failed to cancel native SMS: '${e.message}'.");
    }
  }
}
