import 'package:get/get.dart';
import '../../core/services/auth/phone_auth_service.dart';
import 'otp_controller.dart';

class OtpBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PhoneAuthService>()) {
      Get.put<PhoneAuthService>(PhoneAuthService(), permanent: true);
    }
    Get.put<OtpController>(OtpController());
  }
}
