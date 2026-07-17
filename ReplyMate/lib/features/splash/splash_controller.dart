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

      final route = await SubscriptionService.instance.determineRouteForCurrentSession();
      _go(route);
    });
  }

  void _go(String route) {
    _fallbackTimer?.cancel();
    if (_navigated) return;
    _navigated = true;

    // Permission setup is only part of the first-time login flow (handled after
    // OTP verification). Returning users with an existing session go straight to
    // their resolved route — we no longer force the permissions screen on every
    // launch. Missing permissions can still be re-granted from Settings.
    Get.offNamed(route);
  }

  @override
  void onClose() {
    _fallbackTimer?.cancel();
    super.onClose();
  }
}
