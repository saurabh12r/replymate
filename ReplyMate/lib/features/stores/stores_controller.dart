import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/auto_reply/auto_reply_bridge.dart';
import '../../core/stores/reply_store_models.dart';
import '../dashboard/dashboard_controller.dart';

class StoresController extends GetxController {
  StoresController({AutoReplyBridge? bridge})
    : _bridge = bridge ?? AutoReplyBridge();

  final AutoReplyBridge _bridge;

  final RxList<ReplyStore> stores = <ReplyStore>[].obs;
  final RxList<Map<String, dynamic>> subscriptionInfos =
      <Map<String, dynamic>>[].obs;
  final RxBool loading = false.obs;

  static String generateId() =>
      '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999999)}';

  static ReplyStore createEmptyStore({String name = 'New business'}) {
    final ids = List<String>.generate(7, (_) => generateId());
    const missed = "Sorry, I missed your call. I'll call you back.";
    const incoming =
        "Thanks for calling! I'm currently busy, will get back to you soon.";
    const wa = 'Sorry, I missed your WhatsApp call.';
    const busy = "I'm on another call right now. I'll call you back.";
    const rejected =
        "Sorry, I can't take your call right now. I'll get back to you shortly.";
    const outAns = "Thanks for picking up! Just following up via SMS as well.";
    const outUnans =
        "I tried calling you but couldn't reach you. Please call me back when free.";

    final templates = <ReplyTemplate>[
      ReplyTemplate(id: ids[0], text: missed),
      ReplyTemplate(id: ids[1], text: incoming),
      ReplyTemplate(id: ids[2], text: wa),
      ReplyTemplate(id: ids[3], text: busy),
      ReplyTemplate(id: ids[4], text: rejected),
      ReplyTemplate(id: ids[5], text: outAns),
      ReplyTemplate(id: ids[6], text: outUnans),
    ];

    return ReplyStore(
      id: generateId(),
      name: name,
      subscriptionId: null,
      active: false,
      replyMissedCall: true,
      replyIncomingCall: false,
      replyWhatsappCall: true,
      replyBusyCall: false,
      replyRejectedCall: false,
      replyOutgoingAnswered: false,
      replyOutgoingUnanswered: false,
      enableDaysSetup: false,
      selectedDays: [],
      vacationMode: false,
      vacationMessage: '',
      templates: templates,
      eventTemplateIds: {
        ReplyStoreEventKeys.missedCall: ids[0],
        ReplyStoreEventKeys.incomingCall: ids[1],
        ReplyStoreEventKeys.missedWhatsapp: ids[2],
        ReplyStoreEventKeys.busyCall: ids[3],
        ReplyStoreEventKeys.rejectedCall: ids[4],
        ReplyStoreEventKeys.outgoingAnswered: ids[5],
        ReplyStoreEventKeys.outgoingUnanswered: ids[6],
      },
    );
  }

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() async {
    loading.value = true;
    try {
      subscriptionInfos.value = await _bridge.listSubscriptionInfos();
      final raw = await _bridge.getStoresJson();
      stores.assignAll(parseReplyStoresJson(raw));
    } finally {
      loading.value = false;
    }
  }

  Future<void> saveAll(
    List<ReplyStore> next, {
    String? reassignedFromStoreName,
    bool useSimMovedMessage = false,
  }) async {
    await _bridge.setStoresJson(encodeReplyStoresJson(next));
    stores.assignAll(parseReplyStoresJson(await _bridge.getStoresJson()));
    if (reassignedFromStoreName != null && reassignedFromStoreName.isNotEmpty) {
      Get.snackbar(
        'SIM reassigned',
        useSimMovedMessage
            ? 'SIM moved to this business'
            : 'This SIM was linked to “$reassignedFromStoreName”. It’s now linked here.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    }
    _refreshDashboardIfRegistered();
  }

  void _refreshDashboardIfRegistered() {
    if (!Get.isRegistered<DashboardController>()) return;
    unawaited(Get.find<DashboardController>().refreshDashboard());
  }

  /// When assigning [subscriptionId] to [storeId], clears that subscription from other stores.
  void applySubscriptionAndSave(String storeId, int? subscriptionId) {
    String? conflictName;
    final updated = stores.map((s) {
      if (s.id == storeId) {
        return s.copyWith(
          subscriptionId: subscriptionId,
          clearSubscriptionId: subscriptionId == null,
          active: subscriptionId == null ? false : s.active,
        );
      }
      if (subscriptionId != null && s.subscriptionId == subscriptionId) {
        conflictName = s.name;
        return s.copyWith(clearSubscriptionId: true, active: false);
      }
      return s;
    }).toList();
    saveAll(updated, reassignedFromStoreName: conflictName);
  }

  /// Subscription rows sorted by [simSlotIndex] for stable SIM 1 / SIM 2 ordering.
  List<Map<String, dynamic>> get orderedSubscriptionInfos {
    final list = List<Map<String, dynamic>>.from(subscriptionInfos);
    list.sort((a, b) {
      final ia = a['simSlotIndex'];
      final ib = b['simSlotIndex'];
      final na = ia is int ? ia : 0;
      final nb = ib is int ? ib : 0;
      return na.compareTo(nb);
    });
    return list;
  }

  /// Turns a business off; keeps [subscriptionId] for reuse.
  Future<void> deactivateStore(String storeId) async {
    final next = stores
        .map((s) => s.id == storeId ? s.copyWith(active: false) : s)
        .toList();
    await saveAll(next);
  }

  /// Sets [active] without changing SIM; use when enabling and SIM is already set.
  Future<void> setStoreActive(String storeId, bool active) async {
    final next = stores
        .map((s) => s.id == storeId ? s.copyWith(active: active) : s)
        .toList();
    await saveAll(next);
  }

  /// Sets [vacationMode] for a store quickly.
  Future<void> toggleVacationMode(String storeId, bool vacationMode) async {
    final next = stores
        .map(
          (s) => s.id == storeId ? s.copyWith(vacationMode: vacationMode) : s,
        )
        .toList();
    await saveAll(next);
  }

  /// Sets [vacationMessage] for a store quickly.
  Future<void> setVacationMessage(
    String storeId,
    String vacationMessage,
  ) async {
    final next = stores
        .map(
          (s) => s.id == storeId
              ? s.copyWith(vacationMessage: vacationMessage)
              : s,
        )
        .toList();
    await saveAll(next);
  }

  /// Assigns [subscriptionId] to [storeId], sets active, clears that SIM from other stores.
  Future<void> activateStoreWithSubscription(
    String storeId,
    int subscriptionId,
  ) async {
    String? conflictName;
    final updated = stores.map((s) {
      if (s.id == storeId) {
        return s.copyWith(
          subscriptionId: subscriptionId,
          clearSubscriptionId: false,
          active: true,
        );
      }
      if (s.subscriptionId == subscriptionId) {
        conflictName = s.name;
        return s.copyWith(clearSubscriptionId: true, active: false);
      }
      return s;
    }).toList();
    await saveAll(
      updated,
      reassignedFromStoreName: conflictName,
      useSimMovedMessage: (conflictName?.isNotEmpty ?? false),
    );
  }

  /// Slot label "SIM 1" / "SIM 2" for a [subscriptionId], if present in [subscriptionInfos].
  String simSlotLabelForSubscription(int subscriptionId) {
    for (final info in orderedSubscriptionInfos) {
      if (info['subscriptionId'] == subscriptionId) {
        final slot = info['simSlotIndex'];
        if (slot is int) return 'SIM ${slot + 1}';
        break;
      }
    }
    return 'SIM';
  }

  Future<void> deleteStore(String id) async {
    final next = stores.where((s) => s.id != id).toList();
    await saveAll(next);
  }

  String formatSimLabel(Map<String, dynamic> info) {
    final slot = info['simSlotIndex'];
    final name = info['displayName']?.toString() ?? '';
    final sub = info['subscriptionId'];
    final slotLabel = slot is int ? 'SIM ${slot + 1}' : 'SIM';
    if (name.isNotEmpty) return '$slotLabel · $name';
    return '$slotLabel (#$sub)';
  }
}
