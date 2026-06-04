import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/local/onboarding_state_service.dart';

/// NotificationGuideController
/// Stitch Screen ID: 7d3dca8e4eb24eebb6c32371bbab60a2
class NotificationGuideController extends GetxController {
  final RxBool isOpeningSettings = false.obs;
  final RxBool isLoading = false.obs;
  final OnboardingStateService _onboardingStateService =
      Get.find<OnboardingStateService>();

  /// Open device notification settings
  Future<void> openNotificationSettings() async {
    isOpeningSettings.value = true;
    await openAppSettings();
    isOpeningSettings.value = false;
  }

  /// Complete onboarding and go to Home
  Future<void> onContinue() async {
    isLoading.value = true;
    await _onboardingStateService.markOnboardingComplete();
    isLoading.value = false;
    Get.offAllNamed(Routes.dashboard);
  }
}
