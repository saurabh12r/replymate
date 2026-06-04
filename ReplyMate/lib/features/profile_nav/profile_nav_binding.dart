import 'package:get/get.dart';
import 'profile_nav_controller.dart';
import '../../core/services/auth/user_repository.dart';

class ProfileNavBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<UserRepository>()) {
      Get.put<UserRepository>(UserRepository(), permanent: true);
    }
    Get.put<ProfileNavController>(ProfileNavController());
  }
}
