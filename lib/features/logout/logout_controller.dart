import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth/user_repository.dart';

/// LogoutController
/// Stitch Screen ID: dfdfa5e89eb04a4bb147f643637b46d7
class LogoutController extends GetxController {
  LogoutController({UserRepository? userRepository})
      : _userRepository = userRepository ?? Get.find<UserRepository>();

  final UserRepository _userRepository;

  // ── State ───────────────────────────────────────────────────────────────────
  final RxBool isLoggingOut = false.obs;

  // ── User info loaded from Firebase ─────────────────────────────────────────
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = await _userRepository.getUserByPhone(user.phoneNumber ?? '');
    if (data != null) {
      userName.value = (data['name'] as String?) ?? 'User';
      userEmail.value = (data['email'] as String?) ?? user.phoneNumber ?? '';
    } else {
      userName.value = user.displayName ?? 'User';
      userEmail.value = user.phoneNumber ?? '';
    }
  }

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
