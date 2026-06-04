import 'package:get/get.dart';
import 'notification_guide_controller.dart';

class NotificationGuideBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<NotificationGuideController>(NotificationGuideController());
  }
}
