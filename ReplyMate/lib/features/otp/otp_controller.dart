import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/services/auth/phone_auth_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth/user_repository.dart';

/// OtpController
/// Stitch Screen ID: 57e63680f2bb41daa9a7b0c10941fd6d
class OtpController extends GetxController {
  OtpController({PhoneAuthService? phoneAuthService})
    : _phoneAuthService = phoneAuthService ?? Get.find<PhoneAuthService>();

  final PhoneAuthService _phoneAuthService;

  // ── Arguments from Login ──────────────────────────────────────────────────
  late final String phoneNumber;
  String countryCode = '+91';
  String verificationId = '';
  final RxBool hasVerificationId = false.obs;

  // ── OTP input (4 boxes) ───────────────────────────────────────────────────
  static const int otpLength = 4;
  final List<TextEditingController> boxes = List.generate(
    otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(
    otpLength,
    (_) => FocusNode(),
  );

  // ── Reactive state ────────────────────────────────────────────────────────
  final RxString otp = ''.obs;
  final RxBool isValid = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // ── Resend timer ──────────────────────────────────────────────────────────
  final RxInt resendSeconds = 30.obs;
  final RxBool canResend = false.obs;
  Timer? _resendTimer;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    phoneNumber = args?['phone'] ?? '';
    countryCode = args?['countryCode'] ?? '+91';
    verificationId = args?['verificationId'] ?? '';
    hasVerificationId.value = verificationId.isNotEmpty;
    _startResendTimer();
  }

  void setVerificationId(String id) {
    if (id.trim().isEmpty) return;
    verificationId = id.trim();
    hasVerificationId.value = true;
  }

  @override
  void onReady() {
    super.onReady();
    Future.microtask(() => focusNodes[0].requestFocus());
  }

  @override
  void onClose() {
    for (final c in boxes) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.onClose();
  }

  // ── Input logic ───────────────────────────────────────────────────────────
  void onBoxChanged(String value, int index) {
    errorMessage.value = '';
    if (value.isEmpty) {
      if (index > 0) focusNodes[index - 1].requestFocus();
    } else {
      if (index < otpLength - 1) {
        focusNodes[index + 1].requestFocus();
      } else {
        focusNodes[index].unfocus();
      }
    }
    _updateOtp();
  }

  void onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        boxes[index].text.isEmpty &&
        index > 0) {
      focusNodes[index - 1].requestFocus();
      boxes[index - 1].clear();
      _updateOtp();
    }
  }

  void _updateOtp() {
    otp.value = boxes.map((c) => c.text).join();
    isValid.value =
        otp.value.length == otpLength && RegExp('^\\d{$otpLength}\$').hasMatch(otp.value);
  }

  // ── Verify ────────────────────────────────────────────────────────────────
  Future<void> verifyOtp() async {
    if (!isValid.value) {
      errorMessage.value = 'Please enter the complete 6-digit code';
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _phoneAuthService.verifyOtp(
        verificationId: verificationId,
        code: otp.value,
        phoneNumber: phoneNumber,
      );
      try {
        await Get.find<UserRepository>().updateFcmToken(phoneNumber);
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
      }
      _navigatePostLogin();
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'Invalid OTP. Please try again.';
    } catch (_) {
      errorMessage.value = 'Verification failed. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Resend ────────────────────────────────────────────────────────────────
  void resendOtp() {
    if (!canResend.value) return;
    _clearBoxes();
    canResend.value = false;
    resendSeconds.value = 30;
    _startResendTimer();
    Future.microtask(() => focusNodes[0].requestFocus());
    _resendOtpFromFirebase();
  }

  Future<void> _resendOtpFromFirebase() async {
    try {
      await _phoneAuthService.sendOtp(
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        onCodeSent: (newVerificationId) {
          setVerificationId(newVerificationId);
        },
        onFailed: (message) {
          errorMessage.value = message;
        },
      );
    } catch (_) {
      // sendOtp reports failures via onFailed; this guards against unexpected errors.
      errorMessage.value = 'Unable to resend OTP. Please try again.';
    }
  }

  void _clearBoxes() {
    for (final c in boxes) {
      c.clear();
    }
    _updateOtp();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendSeconds.value <= 1) {
        t.cancel();
        canResend.value = true;
        resendSeconds.value = 0;
      } else {
        resendSeconds.value--;
      }
    });
  }

  // ── Back navigation ───────────────────────────────────────────────────────
  void goBack() => Get.back();

  void _navigatePostLogin() {
    Get.offAllNamed(Routes.dashboard);
  }
}
