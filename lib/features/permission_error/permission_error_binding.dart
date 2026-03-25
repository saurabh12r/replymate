import 'package:get/get.dart';
import 'permission_error_controller.dart';

class PermissionErrorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PermissionErrorController>(() => PermissionErrorController());
  }
}
