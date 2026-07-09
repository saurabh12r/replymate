import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../auto_reply/auto_reply_bridge.dart';
import '../auth/user_repository.dart';
import 'subscription_service.dart';
import '../../notifications/push_notification.dart';
import '../../notifications/push_notification_service.dart';

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
      
      _checkAndSendNotifications(docId, info);

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

  Future<void> _checkAndSendNotifications(String docId, SubscriptionInfo info) async {
    if (info.status == SubscriptionStatus.loading || info.status == SubscriptionStatus.unknown) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      final isApprovedKey = 'sub_is_approved_$docId';
      final planNameKey = 'sub_plan_name_$docId';
      final statusKey = 'sub_status_$docId';
      final nextPlanNameKey = 'sub_next_plan_name_$docId';

      final wasApproved = prefs.getBool(isApprovedKey);
      final previousPlanName = prefs.getString(planNameKey);
      final previousStatusStr = prefs.getString(statusKey);
      final previousNextPlanName = prefs.getString(nextPlanNameKey);

      // 1) Account Activation Notification:
      if (wasApproved == null) {
        await prefs.setBool(isApprovedKey, info.isApproved);
      } else if (!wasApproved && info.isApproved) {
        await prefs.setBool(isApprovedKey, true);
        
        final notification = PushNotification(
          id: const Uuid().v4(),
          title: 'Account Activated',
          body: 'Your ReplyMate account has been successfully approved and activated.',
          timestamp: DateTime.now(),
          isRead: false,
          type: 'account_activation',
        );
        await PushNotificationService.instance.addNotification(notification);
        
        Get.snackbar(
          'Account Activated',
          'Your account has been successfully approved and activated.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF1A2980).withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else if (wasApproved && !info.isApproved) {
        await prefs.setBool(isApprovedKey, false);
      }

      // 2) Plan Activation Notification:
      if (info.status == SubscriptionStatus.active) {
        bool shouldNotifyPlan = false;
        if (previousStatusStr != null && previousStatusStr != SubscriptionStatus.active.name) {
          shouldNotifyPlan = true;
        } else if (previousPlanName != null && previousPlanName != info.planName) {
          shouldNotifyPlan = true;
        }
        
        if (shouldNotifyPlan) {
          final planDisplayName = info.planName.isNotEmpty ? info.planName : 'Default';
          final notification = PushNotification(
            id: const Uuid().v4(),
            title: 'Plan Activated',
            body: 'Your subscription to the "$planDisplayName" plan is now active.',
            timestamp: DateTime.now(),
            isRead: false,
            type: 'plan_activation',
          );
          await PushNotificationService.instance.addNotification(notification);
          
          Get.snackbar(
            'Plan Activated',
            'Your subscription to the "$planDisplayName" plan is now active.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
      }

      // 3) Plan Expired Notification:
      if (info.status == SubscriptionStatus.expired && previousStatusStr != null && previousStatusStr != SubscriptionStatus.expired.name) {
        final planDisplayName = info.planName.isNotEmpty ? info.planName : 'Default';
        final notification = PushNotification(
          id: const Uuid().v4(),
          title: 'Plan Expired',
          body: 'Your subscription to the "$planDisplayName" plan has expired.',
          timestamp: DateTime.now(),
          isRead: false,
          type: 'plan_expired',
        );
        await PushNotificationService.instance.addNotification(notification);
        
        Get.snackbar(
          'Plan Expired',
          'Your subscription to the "$planDisplayName" plan has expired.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }

      // 4) Plan Scheduled / Next Plan Override Notification:
      if (info.status == SubscriptionStatus.scheduled && previousStatusStr != null && previousStatusStr != SubscriptionStatus.scheduled.name) {
        final planDisplayName = info.planName.isNotEmpty ? info.planName : 'Default';
        final dateStr = info.subscriptionStart != null 
            ? DateFormat('dd MMM yyyy').format(info.subscriptionStart!.toLocal())
            : 'soon';
        final notification = PushNotification(
          id: const Uuid().v4(),
          title: 'New Plan Scheduled',
          body: 'Your upcoming "$planDisplayName" plan is scheduled to activate on $dateStr.',
          timestamp: DateTime.now(),
          isRead: false,
          type: 'plan_scheduled',
        );
        await PushNotificationService.instance.addNotification(notification);
        
        Get.snackbar(
          'Plan Scheduled',
          'Your upcoming "$planDisplayName" plan is scheduled to activate on $dateStr.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else if (info.nextPlanName != null && info.nextPlanName!.isNotEmpty && previousNextPlanName != null && info.nextPlanName != previousNextPlanName) {
        final notification = PushNotification(
          id: const Uuid().v4(),
          title: 'Upcoming Plan Updated',
          body: 'Your next plan has been set to "${info.nextPlanName}".',
          timestamp: DateTime.now(),
          isRead: false,
          type: 'next_plan_updated',
        );
        await PushNotificationService.instance.addNotification(notification);
        
        Get.snackbar(
          'Upcoming Plan Updated',
          'Your next plan has been set to "${info.nextPlanName}".',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blue.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }

      // 5) Account Blocked/Suspended Notification:
      if (info.status == SubscriptionStatus.blocked && previousStatusStr != null && previousStatusStr != SubscriptionStatus.blocked.name) {
        final notification = PushNotification(
          id: const Uuid().v4(),
          title: 'Account Suspended',
          body: 'Your account has been suspended by the admin.',
          timestamp: DateTime.now(),
          isRead: false,
          type: 'account_suspended',
        );
        await PushNotificationService.instance.addNotification(notification);
        
        Get.snackbar(
          'Account Suspended',
          'Your account has been suspended by the admin.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }

      await prefs.setString(planNameKey, info.planName);
      await prefs.setString(statusKey, info.status.name);
      if (info.nextPlanName != null) {
        await prefs.setString(nextPlanNameKey, info.nextPlanName!);
      } else {
        await prefs.remove(nextPlanNameKey);
      }
    } catch (_) {}
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
