import 'package:get/get.dart';
import '../dashboard/dashboard_controller.dart';

/// DashboardNavController
/// Stitch Screen ID: 8838ec89e7394356ae1cdd9b72e02d8b
///
/// Owns the bottom nav index only.
/// Each tab's own controller (DashboardController, etc.) is registered separately.
class DashboardNavController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void onNavTap(int index) {
    selectedIndex.value = index;
  }

  // Ensure DashboardController is available for the Home tab
  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController());
    }
  }
}
