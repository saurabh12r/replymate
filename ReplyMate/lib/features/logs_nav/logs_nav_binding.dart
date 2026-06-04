import 'package:get/get.dart';
import 'logs_nav_controller.dart';

class LogsNavBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<LogsNavController>(LogsNavController());
  }
}
