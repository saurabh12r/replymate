import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/subscription/subscription_service.dart';

/// SplashController — gates app entry based on subscription status
class SplashController extends GetxController {
  Timer? _fallbackTimer;
  bool _navigated = false;

  @override
  void onReady() {
    super.onReady();
    _navigateFromSession();
  }

  void _navigateFromSession() {
    // Failsafe: never allow indefinite splash/white screen.
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(const Duration(seconds: 6), () {
      if (_navigated) return;
      _navigated = true;
      Get.offNamed(Routes.dashboard);
    });

    Future.delayed(const Duration(milliseconds: 700), () async {
      if (_navigated) return;

      User? currentUser;
      try {
        currentUser = FirebaseAuth.instance.currentUser;
      } catch (_) {
        currentUser = null;
      }

      if (currentUser == null) {
        _go(Routes.login);
        return;
      }

      // ── Check subscription status before routing ──────────────────────────
      final phone = currentUser.phoneNumber; // e.g. '+919022902102'
      final info = await SubscriptionService.instance.getOnce(
        currentUser.uid,
        phone: phone,
      );

      switch (info.status) {
        case SubscriptionStatus.active:
          // Start real-time watcher for the session
          SubscriptionService.instance.startWatching(
            currentUser.uid,
            phone: phone,
          );
          _go(Routes.dashboard);
          break;

        case SubscriptionStatus.pending:
          SubscriptionService.instance.startWatching(
            currentUser.uid,
            phone: phone,
          );
          _go(Routes.pendingApproval);
          break;

        case SubscriptionStatus.expired:
          _go(Routes.subscriptionExpired);
          break;

        case SubscriptionStatus.blocked:
          _go(Routes.accountBlocked);
          break;

        case SubscriptionStatus.unknown:
        case SubscriptionStatus.loading:
          // No user doc yet (new user?) — send to dashboard, let dashboard handle
          SubscriptionService.instance.startWatching(
            currentUser.uid,
            phone: phone,
          );
          _go(Routes.dashboard);
          break;
      }
    });
  }

  void _go(String route) {
    _fallbackTimer?.cancel();
    if (_navigated) return;
    _navigated = true;
    Get.offNamed(route);
  }

  @override
  void onClose() {
    _fallbackTimer?.cancel();
    super.onClose();
  }
}
