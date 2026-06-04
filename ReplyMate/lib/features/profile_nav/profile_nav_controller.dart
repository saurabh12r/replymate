import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
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
    _loadSavedTheme();
    _syncAuthUid();
  }

  Future<void> _syncAuthUid() async {
    final phoneVal = phone.value;
    if (phoneVal.isEmpty || phoneVal == 'Not available') return;
    try {
      await _userRepository.updateUserProfile(userId: phoneVal);
    } catch (_) {}
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('theme_mode');
    if (idx != null) {
      final saved = ThemeMode.values[idx.clamp(0, ThemeMode.values.length - 1)];
      themeMode.value = saved;
      // Apply it in case the OS resolved a different value at startup.
      Get.changeThemeMode(saved);
    }
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

    // User docs are stored by phone number as doc ID (e.g. users/+919022902102).
    // watchUserByPhone uses the phone; fall back to UID for legacy/UID-keyed docs.
    final phoneNumber = currentUser.phoneNumber;
    await _profileSubscription?.cancel();

    final stream = (phoneNumber != null && phoneNumber.isNotEmpty)
        ? _userRepository.watchUserByPhone(phoneNumber).map((data) {
            if (data == null) return null;
            return UserModel.fromMap(data);
          })
        : _userRepository.watchUserByUid(currentUser.uid);

    _profileSubscription = stream.listen(
      (data) {
        profile.value = data;
        hasProfileData.value = data != null;
        isLoadingProfile.value = false;
        profileError.value = '';
        if (data != null) {
          userName.value = data.name;
          phone.value = data.phone;
          email.value = data.email;
          userRole.value = data.email.isNotEmpty
              ? data.email
              : 'ReplyMate User';
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

  Future<void> editProfile() async {
    final result = await Get.dialog<Map<String, String>>(
      _EditProfileDialog(
        currentName: userName.value,
        currentEmail: email.value,
      ),
    );
    if (result != null) {
      await _updateProfile(result['name']!, result['email']);
    }
  }

  Future<void> _updateProfile(String name, String? email) async {
    try {
      final userPhone = phone.value;
      if (userPhone.isEmpty || userPhone == 'Not available') return;

      await _userRepository.updateUserProfile(
        userId: userPhone,
        name: name,
        email: email,
      );
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

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

  // ── Theme ──────────────────────────────────────────────────────────────────
  // Default: follow the OS. Cycles: system → light → dark → system.
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  /// Whether the current effective theme is dark (used for the toggle label).
  bool get isDarkMode => Get.isDarkMode;

  @override
  void onClose() {
    _profileSubscription?.cancel();
    super.onClose();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    SharedPreferences.getInstance().then(
      (p) => p.setInt('theme_mode', mode.index),
    );
  }

  void toggleTheme() {
    final next = switch (themeMode.value) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    setThemeMode(next);
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
              decoration: BoxDecoration(
                color: _error.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
              ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFFC5C5D4)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        color: _onSurface,
                      ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

class _EditProfileDialog extends StatefulWidget {
  final String currentName;
  final String currentEmail;

  const _EditProfileDialog({
    required this.currentName,
    required this.currentEmail,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF24389C).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF24389C),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Name',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Email',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF24389C),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(color: Colors.white),
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

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Error',
        'Name cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    setState(() => _isLoading = true);
    Get.back(result: {'name': name, 'email': _emailController.text.trim()});
  }
}
