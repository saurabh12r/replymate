import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';


/// SplashController
/// Stitch Screen ID: b434f8b18ba444febc349eae4f82895b
class SplashController extends GetxController {


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
      Get.offNamed(Routes.dashboard);
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

      _fallbackTimer?.cancel();
      _navigated = true;
      Get.offNamed(Routes.dashboard);
    });
  }

  @override
  void onClose() {
    _fallbackTimer?.cancel();
    super.onClose();
  }
}
