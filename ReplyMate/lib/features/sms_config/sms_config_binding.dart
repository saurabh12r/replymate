import 'package:get/get.dart';
import 'sms_config_controller.dart';

class SmsConfigBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SmsConfigController>(SmsConfigController());
  }
}
