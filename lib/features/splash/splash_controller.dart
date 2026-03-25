import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/local/onboarding_state_service.dart';

/// SplashController
/// Stitch Screen ID: b434f8b18ba444febc349eae4f82895b
class SplashController extends GetxController {
  final OnboardingStateService _onboardingStateService =
      Get.find<OnboardingStateService>();

  @override
  void onReady() {
    super.onReady();
    _navigateFromSession();
  }

  void _navigateFromSession() {
    Future.delayed(const Duration(seconds: 3), () {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.offNamed(Routes.login);
        return;
      }

      final route = _onboardingStateService.isFirstTimeUser
          ? Routes.permissionsSetup
          : Routes.dashboard;
      Get.offNamed(route);
    });
  }
}
