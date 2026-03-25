import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/routes/app_routes.dart';

/// LogoutController
/// Stitch Screen ID: dfdfa5e89eb04a4bb147f643637b46d7
class LogoutController extends GetxController {
  // ── State ───────────────────────────────────────────────────────────────────
  final RxBool isLoggingOut = false.obs;

  // ── User info (passed through or loaded from local state) ──────────────────
  final RxString userName = 'Alex Johnson'.obs;
  final RxString userEmail = 'alex.j@replymate.ai'.obs;

  Future<void> confirmLogout() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;

    // Explicit logout: keep user signed in until this point.
    await FirebaseAuth.instance.signOut();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    isLoggingOut.value = false;
    // Clear entire nav stack and go to Login
    Get.offAllNamed(Routes.login);
  }

  void cancel() => Get.back();
}
