import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/routes/app_routes.dart';

/// PermissionErrorController
/// Stitch Screen ID: 18951caf69644594bfd89849c34b3150
class PermissionErrorController extends GetxController {
  final RxBool isOpeningSettings = false.obs;

  /// Retry → go back to Permissions Setup (clean stack replacement)
  void retry() {
    Get.offNamed(Routes.permissionsSetup);
  }

  /// Open device App Settings so user can manually grant permissions
  Future<void> openSettings() async {
    isOpeningSettings.value = true;
    await openAppSettings();
    isOpeningSettings.value = false;
  }
}
