import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../auto_reply/auto_reply_bridge.dart';
import '../auth/user_repository.dart';
import 'subscription_service.dart';

class SubscriptionSyncService extends GetxService {
  final AutoReplyBridge _bridge = AutoReplyBridge();
  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  StreamSubscription? _subscriptionSub;
  String? _phone;

  @override
  void onInit() {
    super.onInit();
    _startListening();
  }

  Future<void> _startListening() async {
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) {
        String? docId = current.phoneNumber;
        if (docId == null || docId.isEmpty) {
          final repo = Get.find<UserRepository>();
          docId = await repo.getUserPhoneByUid(current.uid);
        }

        if (docId != null && docId.isNotEmpty) {
          try {
            await _bridge.setUserId(docId);
          } catch (_) {}
          _syncForDocId(docId);
        }
      }
    } catch (_) {}

    try {
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user == null) {
          _stopListening();
          return;
        }

        String? docId = user.phoneNumber;
        if (docId == null || docId.isEmpty) {
          final repo = Get.find<UserRepository>();
          docId = await repo.getUserPhoneByUid(user.uid);
        }

        if (docId != null && docId.isNotEmpty) {
          try {
            await _bridge.setUserId(docId);
          } catch (_) {}
          _syncForDocId(docId);
        }
      });
    } catch (_) {}
  }

  void _syncForDocId(String docId) {
    if (_phone == docId) return;
    _phone = docId;

    _subscriptionService.startWatching(docId);

    _subscriptionSub?.cancel();
    _subscriptionSub = _subscriptionService.stream.listen((info) async {
      final shouldBeActive = info.status == SubscriptionStatus.active;
      final subEndMs = info.subscriptionEnd?.millisecondsSinceEpoch;
      await _syncToNative(shouldBeActive, subEndMs: subEndMs, nextPlanDurationDays: info.nextPlanDurationDays);
      
      if (info.status == SubscriptionStatus.expired) {
        if (Get.currentRoute != '/subscription-expired') {
          Get.offAllNamed('/subscription-expired');
        }
      } else if (info.status == SubscriptionStatus.blocked) {
        if (Get.currentRoute != '/suspended') {
          Get.offAllNamed('/suspended');
        }
      }
    });
  }

  Future<void> _syncToNative(bool shouldBeActive, {int? subEndMs, int? nextPlanDurationDays}) async {
    try {
      await _bridge.setBlocked(!shouldBeActive, subscriptionEndMs: subEndMs, nextPlanDurationDays: nextPlanDurationDays);
    } catch (_) {}
  }

  void _stopListening() {
    _subscriptionSub?.cancel();
    _subscriptionSub = null;
    _phone = null;
  }

  @override
  void onClose() {
    _subscriptionSub?.cancel();
    super.onClose();
  }
}
