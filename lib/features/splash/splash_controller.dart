import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/local/onboarding_state_service.dart';

/// SplashController
/// Stitch Screen ID: b434f8b18ba444febc349eae4f82895b
class SplashController extends GetxController {
  final OnboardingStateService _onboardingStateService =
      Get.find<OnboardingStateService>();

  Timer? _fallbackTimer;
  bool _navigated = false;

  @override
  void onReady() {
    super.onReady();
    _navigateFromSession();
  }

  void _navigateFromSession() {
    assert(() {
      // Helpful in release-like runs (e.g., profile mode) and debug.
      // In release builds, asserts are stripped.
      // ignore: avoid_print
      print('ReplyMate: splash -> start navigation');
      return true;
    }());

    // Failsafe: never allow indefinite splash/white screen.
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      if (_navigated) return;
      _navigated = true;
      final route = _onboardingStateService.isFirstTimeUser
          ? Routes.permissionsSetup
          : Routes.dashboard;
      Get.offNamed(route);
    });

    // Give Flutter a moment to render first frame, then navigate.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (_navigated) return;
      User? currentUser;
      try {
        currentUser = FirebaseAuth.instance.currentUser;
      } catch (_) {
        currentUser = null;
      }
      if (currentUser == null) {
        _fallbackTimer?.cancel();
        _navigated = true;
        Get.offNamed(Routes.login);
        return;
      }

      final route = _onboardingStateService.isFirstTimeUser
          ? Routes.permissionsSetup
          : Routes.dashboard;
      _fallbackTimer?.cancel();
      _navigated = true;
      Get.offNamed(route);
    });
  }

  @override
  void onClose() {
    _fallbackTimer?.cancel();
    super.onClose();
  }
}
