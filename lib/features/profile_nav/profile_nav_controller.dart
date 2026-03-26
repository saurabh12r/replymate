import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth/user_repository.dart';
import 'user_model.dart';

/// ProfileNavController
/// Stitch Screen ID: 51d28699599a41debb374aff662d7311
class ProfileNavController extends GetxController {
  ProfileNavController({UserRepository? userRepository})
      : _userRepository = userRepository ?? Get.find<UserRepository>();

  final UserRepository _userRepository;

  // ── User info ──────────────────────────────────────────────────────────────
  final RxString userName = 'Loading...'.obs;
  final RxString userRole = ''.obs;
  final RxString phone = 'Loading...'.obs;
  final RxString email = 'Loading...'.obs;
  final RxBool isLoadingProfile = true.obs;
  final RxString profileError = ''.obs;
  final RxBool isLoggedIn = true.obs;
  final RxBool hasProfileData = true.obs;
  final Rxn<UserModel> profile = Rxn<UserModel>();
  StreamSubscription<UserModel?>? _profileSubscription;

  // ── Logout state ───────────────────────────────────────────────────────────
  final RxBool isLoggingOut = false.obs;

  @override
  void onInit() {
    super.onInit();
    _bindProfile();
  }

  Future<void> _bindProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      isLoggedIn.value = false;
      isLoadingProfile.value = false;
      profileError.value = 'Please login to view profile.';
      return;
    }
    isLoggedIn.value = true;
    isLoadingProfile.value = true;
    profileError.value = '';

    try {
      await _userRepository.ensureUserDocumentForUid(
        uid: currentUser.uid,
        phone: currentUser.phoneNumber,
        email: currentUser.email,
      );
    } catch (_) {
      // Continue to stream even if seed migration fails.
    }

    await _profileSubscription?.cancel();
    _profileSubscription = _userRepository.watchUserByUid(currentUser.uid).listen(
      (data) {
        profile.value = data;
        hasProfileData.value = data != null;
        isLoadingProfile.value = false;
        profileError.value = '';
        if (data != null) {
          userName.value = data.name;
          phone.value = data.phone;
          email.value = data.email;
          userRole.value = data.email == 'Not available' ? 'ReplyMate User' : data.email;
        } else {
          userName.value = 'No profile data found';
          phone.value = 'Not available';
          email.value = 'Not available';
          userRole.value = '';
        }
      },
      onError: (_) {
        isLoadingProfile.value = false;
        profileError.value = 'Unable to load profile right now.';
      },
    );
  }

  Future<void> reloadProfile() async {
    await _bindProfile();
  }

  void navigateToSettings() => Get.toNamed(Routes.settings);

  Future<void> confirmLogout() async {
    final result = await Get.dialog<bool>(
      const _LogoutDialog(),
      barrierDismissible: true,
    );
    if (result == true) await _doLogout();
  }

  Future<void> _doLogout() async {
    isLoggingOut.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 800));
    isLoggingOut.value = false;
    // Navigate to the dedicated logout route (handles Firebase sign-out + nav to login)
    Get.offAllNamed(Routes.logout);
  }

  @override
  void onClose() {
    _profileSubscription?.cancel();
    super.onClose();
  }
}

/// Logout confirmation dialog — stateless widget kept in same file for cohesion
class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  static const Color _error = Color(0xFFBA1A1A);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: _error.withAlpha(15), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.logout_rounded, color: _error, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign Out?',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will be logged out and redirected to the login screen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: _onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFFC5C5D4)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, color: _onSurface),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _error,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
