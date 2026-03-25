import 'package:get/get.dart';
import 'splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Use Get.put (not lazyPut) so SplashController is eagerly instantiated
    // and onReady() fires even though the view has no reactive bindings.
    Get.put<SplashController>(SplashController());
  }
}
