import 'package:get/get.dart';
import 'logout_controller.dart';

class LogoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<LogoutController>(LogoutController());
  }
}
