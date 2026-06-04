import 'package:get/get.dart';
import '../../core/services/auth/user_repository.dart';
import '../dashboard/dashboard_controller.dart';
import '../logs_nav/logs_nav_controller.dart';
import '../analytics_nav/analytics_nav_controller.dart';
import '../profile_nav/profile_nav_controller.dart';
import '../contact_filter/contact_filter_controller.dart';
import 'dashboard_nav_controller.dart';

class DashboardNavBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<UserRepository>()) {
      Get.put<UserRepository>(UserRepository(), permanent: true);
    }
    Get.put<DashboardController>(DashboardController());
    Get.put<LogsNavController>(LogsNavController());
    Get.put<AnalyticsNavController>(AnalyticsNavController());
    Get.put<ProfileNavController>(ProfileNavController());
    Get.put<ContactFilterController>(ContactFilterController());
    Get.put<DashboardNavController>(DashboardNavController());
  }
}
