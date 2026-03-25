import 'package:get/get.dart';
import '../../core/services/auth/user_repository.dart';
import 'signup_controller.dart';

class SignupBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<UserRepository>()) {
      Get.put<UserRepository>(UserRepository(), permanent: true);
    }
    Get.lazyPut<SignupController>(() => SignupController());
  }
}
