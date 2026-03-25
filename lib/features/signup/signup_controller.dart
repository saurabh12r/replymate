import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../core/services/auth/user_repository.dart';

/// SignupController
/// Stitch Screen ID: CUSTOM_SIGNUP_01
class SignupController extends GetxController {
  SignupController({UserRepository? userRepository})
      : _userRepository = userRepository ?? Get.find<UserRepository>();

  final UserRepository _userRepository;

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final RxString countryCode = '+91'.obs;
  final RxBool isLoading = false.obs;
  final RxBool isFormValid = false.obs;

  final RxString fullNameError = ''.obs;
  final RxString phoneError = ''.obs;
  final RxString emailError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fullNameController.addListener(_validateLive);
    phoneController.addListener(_validateLive);
    emailController.addListener(_validateLive);
  }

  void _validateLive() {
    fullNameError.value = '';
    phoneError.value = '';
    emailError.value = '';
    isFormValid.value = _computeIsValid();
  }

  bool _computeIsValid() {
    final fullName = fullNameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final isPhoneValid = RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
    final isEmailValid =
        email.isEmpty || RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

    return fullName.length >= 2 && isPhoneValid && isEmailValid;
  }

  bool _validateAndSetErrors() {
    final fullName = fullNameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    var valid = true;

    fullNameError.value = '';
    phoneError.value = '';
    emailError.value = '';

    if (fullName.isEmpty) {
      fullNameError.value = 'Please enter your full name';
      valid = false;
    } else if (fullName.length < 2) {
      fullNameError.value = 'Full name must be at least 2 characters';
      valid = false;
    }

    if (phone.isEmpty) {
      phoneError.value = 'Please enter your phone number';
      valid = false;
    } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      phoneError.value = 'Please enter a valid 10-digit phone number';
      valid = false;
    }

    if (email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      emailError.value = 'Please enter a valid email address';
      valid = false;
    }

    isFormValid.value = valid;
    return valid;
  }

  Future<void> registerUser() async {
    if (!_validateAndSetErrors()) return;

    isLoading.value = true;
    final fullPhone = '${countryCode.value}${phoneController.text.trim()}';
    try {
      await _userRepository.registerUser(
        name: fullNameController.text.trim(),
        phone: fullPhone,
        email: emailController.text.trim(),
      );

      await Get.dialog(
        AlertDialog(
          title: const Text('Registration successful'),
          content: const Text('Registration successful. Wait for admin approval.'),
          actions: [
            TextButton(
              onPressed: Get.back,
              child: const Text('OK'),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      Get.back();
    } on FirebaseException catch (e) {
      final msg = e.message ?? '';
      final isDuplicate = msg.toLowerCase().contains('already registered');
      Get.snackbar(
        isDuplicate ? 'Already registered' : 'Signup failed',
        isDuplicate
            ? 'This phone number is already registered. Please login.'
            : 'Unable to register right now. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        'Signup failed',
        'Unable to register right now. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signup() => registerUser();

  void goToLogin() => Get.back();

  void onCountryCodeTap() {
    final codes = ['+91', '+1', '+44', '+61', '+971'];
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: codes
                .map(
                  (code) => ListTile(
                    title: Text(code),
                    onTap: () {
                      countryCode.value = code;
                      Get.back();
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
