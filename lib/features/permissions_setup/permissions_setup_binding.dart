import 'package:get/get.dart';
import 'permissions_setup_controller.dart';

class PermissionsSetupBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<PermissionsSetupController>(PermissionsSetupController());
  }
}
