import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/subscription/subscription_service.dart';
import '../../core/services/permissions/permission_service.dart';

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

  void _go(String route) async {
    _fallbackTimer?.cancel();
    if (_navigated) return;
    _navigated = true;

    if (route == Routes.dashboard) {
      final permService = PermissionService();
      final allGranted = await permService.checkAllPermissions();
      final batteryOptimization = await Permission.ignoreBatteryOptimizations.isGranted;
      if (!allGranted || !batteryOptimization) {
        Get.offNamed(Routes.permissions);
        return;
      }
    }

    Get.offNamed(route);
  }

  @override
  void onClose() {
    _fallbackTimer?.cancel();
    super.onClose();
  }
}
