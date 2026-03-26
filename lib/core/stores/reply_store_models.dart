import 'dart:convert';

/// Must match [com.replymate.reply_mate.autoreply.StoreEventKeys] on Android.
class ReplyStoreEventKeys {
  static const missedCall = 'missed_call';
  static const incomingCall = 'incoming_call';
  static const missedWhatsapp = 'missed_whatsapp';
  static const busyCall = 'busy_call';
  static const outgoingCall = 'outgoing_call';

  static const all = <String>[
    missedCall,
    incomingCall,
    missedWhatsapp,
    busyCall,
    outgoingCall,
  ];

  static String label(String key) {
    switch (key) {
      case missedCall:
        return 'Missed call';
      case incomingCall:
        return 'Incoming call';
      case missedWhatsapp:
        return 'WhatsApp missed call';
      case busyCall:
        return 'Busy (call waiting)';
      case outgoingCall:
        return 'Outgoing call';
      default:
        return key;
    }
  }
}

class ReplyTemplate {
  ReplyTemplate({required this.id, required this.text});

  final String id;
  final String text;

  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  static ReplyTemplate fromJson(Map<String, dynamic> m) {
    return ReplyTemplate(
      id: m['id']?.toString() ?? '',
      text: m['text']?.toString() ?? '',
    );
  }
}

class ReplyStore {
  ReplyStore({
    required this.id,
    required this.name,
    this.subscriptionId,
    required this.active,
    required this.replyMissedCall,
    required this.replyIncomingCall,
    required this.replyWhatsappCall,
    required this.replyBusyCall,
    required this.replyOutgoingCall,
    required this.templates,
    required this.eventTemplateIds,
  });

  final String id;
  final String name;
  final int? subscriptionId;
  final bool active;
  final bool replyMissedCall;
  final bool replyIncomingCall;
  final bool replyWhatsappCall;
  final bool replyBusyCall;
  final bool replyOutgoingCall;
  final List<ReplyTemplate> templates;
  final Map<String, String> eventTemplateIds;

  bool toggleForKey(String eventKey) {
    switch (eventKey) {
      case ReplyStoreEventKeys.missedCall:
        return replyMissedCall;
      case ReplyStoreEventKeys.incomingCall:
        return replyIncomingCall;
      case ReplyStoreEventKeys.missedWhatsapp:
        return replyWhatsappCall;
      case ReplyStoreEventKeys.busyCall:
        return replyBusyCall;
      case ReplyStoreEventKeys.outgoingCall:
        return replyOutgoingCall;
      default:
        return false;
    }
  }

  String? messageForEventKey(String eventKey) {
    final tid = eventTemplateIds[eventKey];
    if (tid == null || tid.isEmpty) return null;
    for (final t in templates) {
      if (t.id == tid) {
        final s = t.text.trim();
        return s.isEmpty ? null : s;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subscriptionId': subscriptionId,
      'active': active,
      'replyMissedCall': replyMissedCall,
      'replyIncomingCall': replyIncomingCall,
      'replyWhatsappCall': replyWhatsappCall,
      'replyBusyCall': replyBusyCall,
      'replyOutgoingCall': replyOutgoingCall,
      'templates': templates.map((t) => t.toJson()).toList(),
      'eventTemplateIds': eventTemplateIds,
    };
  }

  static ReplyStore fromJson(Map<String, dynamic> m) {
    final templatesRaw = m['templates'];
    final templates = <ReplyTemplate>[];
    if (templatesRaw is List) {
      for (final e in templatesRaw) {
        if (e is Map<String, dynamic>) {
          templates.add(ReplyTemplate.fromJson(e));
        }
      }
    }
    final em = m['eventTemplateIds'];
    final eventMap = <String, String>{};
    if (em is Map) {
      em.forEach((k, v) {
        eventMap[k.toString()] = v.toString();
      });
    }
    int? sub;
    if (m.containsKey('subscriptionId') && m['subscriptionId'] != null) {
      final v = m['subscriptionId'];
      if (v is int) {
        sub = v;
      } else if (v is num) {
        sub = v.toInt();
      }
    }
    return ReplyStore(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? 'Business',
      subscriptionId: sub,
      active: m['active'] == true,
      replyMissedCall: m['replyMissedCall'] == true,
      replyIncomingCall: m['replyIncomingCall'] == true,
      replyWhatsappCall: m['replyWhatsappCall'] == true,
      replyBusyCall: m['replyBusyCall'] == true,
      replyOutgoingCall: m['replyOutgoingCall'] == true,
      templates: templates,
      eventTemplateIds: eventMap,
    );
  }

  ReplyStore copyWith({
    String? id,
    String? name,
    int? subscriptionId,
    bool? clearSubscriptionId,
    bool? active,
    bool? replyMissedCall,
    bool? replyIncomingCall,
    bool? replyWhatsappCall,
    bool? replyBusyCall,
    bool? replyOutgoingCall,
    List<ReplyTemplate>? templates,
    Map<String, String>? eventTemplateIds,
  }) {
    return ReplyStore(
      id: id ?? this.id,
      name: name ?? this.name,
      subscriptionId: clearSubscriptionId == true ? null : (subscriptionId ?? this.subscriptionId),
      active: active ?? this.active,
      replyMissedCall: replyMissedCall ?? this.replyMissedCall,
      replyIncomingCall: replyIncomingCall ?? this.replyIncomingCall,
      replyWhatsappCall: replyWhatsappCall ?? this.replyWhatsappCall,
      replyBusyCall: replyBusyCall ?? this.replyBusyCall,
      replyOutgoingCall: replyOutgoingCall ?? this.replyOutgoingCall,
      templates: templates ?? this.templates,
      eventTemplateIds: eventTemplateIds ?? this.eventTemplateIds,
    );
  }
}

List<ReplyStore> parseReplyStoresJson(String raw) {
  if (raw.trim().isEmpty) return [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => ReplyStore.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } catch (_) {
    return [];
  }
}

String encodeReplyStoresJson(List<ReplyStore> stores) {
  return jsonEncode(stores.map((s) => s.toJson()).toList());
}

ReplyStore? findStoreForSubscription(List<ReplyStore> stores, int subscriptionId) {
  for (final s in stores) {
    if (s.subscriptionId == subscriptionId) return s;
  }
  return null;
}
