import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../core/services/auth/phone_auth_service.dart';
import '../../core/services/auth/user_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/local/onboarding_state_service.dart';

/// LoginController
/// Stitch Screen ID: f6417a644f80448193ad7d306fe4de25
class LoginController extends GetxController {
  LoginController({
    UserRepository? userRepository,
    PhoneAuthService? phoneAuthService,
  })  : _userRepository = userRepository ?? Get.find<UserRepository>(),
        _phoneAuthService = phoneAuthService ?? Get.find<PhoneAuthService>();

  final UserRepository _userRepository;
  final PhoneAuthService _phoneAuthService;
  final OnboardingStateService _onboardingStateService = Get.find<OnboardingStateService>();

  final phoneController = TextEditingController();

  final RxString phoneNumber = ''.obs;
  final RxBool isValid = false.obs;
  final RxBool isLoading = false.obs;
  final RxString countryCode = '+91'.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    final value = phoneController.text.trim();
    phoneNumber.value = value;
    errorMessage.value = '';
    isValid.value = value.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(value);
  }

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

  Future<void> sendOtp() async {
    final fullPhone = '${countryCode.value}${phoneNumber.value}';
    await _phoneAuthService.sendOtp(
      phoneNumber: fullPhone,
      onCodeSent: (verificationId) {
        Get.toNamed(
          Routes.otp,
          arguments: {
            'phone': fullPhone,
            'countryCode': countryCode.value,
            'verificationId': verificationId,
          },
        );
      },
      onVerificationCompleted: (_) {
        final route = _onboardingStateService.isFirstTimeUser
            ? Routes.permissionsSetup
            : Routes.dashboard;
        Get.offAllNamed(route);
      },
      onFailed: (message) {
        errorMessage.value = message;
      },
    );
  }

  Future<void> loginUser() async {
    if (!isValid.value) {
      errorMessage.value = 'Please enter a valid 10-digit phone number';
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    final fullPhone = '${countryCode.value}${phoneNumber.value}';
    try {
      final user = await _userRepository.getUserByPhone(fullPhone);
      if (user == null) {
        errorMessage.value = 'User not registered';
        return;
      }

      if ((user['isBlocked'] as bool?) == true) {
        Get.dialog(
          AlertDialog(
            title: const Text('Access denied'),
            content: const Text('User is blocked by admin'),
            actions: [
              TextButton(
                onPressed: Get.back,
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      if ((user['isApproved'] as bool?) != true) {
        Get.dialog(
          AlertDialog(
            title: const Text('Approval pending'),
            content: const Text('Admin not approved yet'),
            actions: [
              TextButton(
                onPressed: Get.back,
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      await sendOtp();
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'Failed to send OTP';
    } catch (_) {
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login() => loginUser();

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }
}
