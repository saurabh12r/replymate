import 'package:get/get.dart';
import '../../core/services/auth/phone_auth_service.dart';
import '../../core/services/auth/user_repository.dart';
import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<UserRepository>()) {
      Get.put<UserRepository>(UserRepository(), permanent: true);
    }
    if (!Get.isRegistered<PhoneAuthService>()) {
      Get.put<PhoneAuthService>(PhoneAuthService(), permanent: true);
    }
    Get.lazyPut<LoginController>(() => LoginController());
  }
}
