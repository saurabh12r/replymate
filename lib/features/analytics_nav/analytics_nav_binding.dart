import 'package:get/get.dart';
import 'analytics_nav_controller.dart';

class AnalyticsNavBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AnalyticsNavController>(AnalyticsNavController());
  }
}
