import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/services/auth/phone_auth_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/permissions/permission_service.dart';
import '../../core/services/auto_reply/auto_reply_bridge.dart';
import '../../core/contact_filter/contact_filter_phone_normalize.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/auth/user_repository.dart';
import '../../core/services/subscription/subscription_service.dart';

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

  void _navigatePostLogin() async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    await Permission.phone.request();

    final isSimMatched = await _checkSimMatch(phoneNumber);

    Get.back(); // close loader

    if (!isSimMatched) {
      Get.snackbar(
        'SIM Error',
        'SIM is not in the same phone',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      Get.offAllNamed(Routes.login);
      return;
    }

    final permService = PermissionService();
    final allGranted = await permService.checkAllPermissions();
    final batteryOptimization = await Permission.ignoreBatteryOptimizations.isGranted;
    if (!allGranted || !batteryOptimization) {
      Get.offAllNamed(Routes.permissions);
    } else {
      final route = await SubscriptionService.instance.determineRouteForCurrentSession();
      Get.offAllNamed(route);
    }
  }

  Future<bool> _checkSimMatch(String loginPhone) async {
    try {
      final bridge = AutoReplyBridge();
      final sims = await bridge.listSubscriptionInfos();
      if (sims.isEmpty) {
        return false;
      }

      final cleanLoginPhone = contactFilterNormalizeRawToCanonical(loginPhone);
      if (cleanLoginPhone.isEmpty) return false;

      final useSuffix = cleanLoginPhone.length >= 10;
      final loginMatchString = useSuffix
          ? cleanLoginPhone.substring(cleanLoginPhone.length - 10)
          : cleanLoginPhone;

      final allEmpty = sims.every((sim) => (sim['number'] as String? ?? '').trim().isEmpty);
      if (allEmpty) {
        return true;
      }

      for (final sim in sims) {
        final number = sim['number'] as String? ?? '';
        if (number.isNotEmpty) {
          final cleanSim = contactFilterNormalizeRawToCanonical(number);
          final simMatchString = (useSuffix && cleanSim.length >= 10)
              ? cleanSim.substring(cleanSim.length - 10)
              : cleanSim;
          if (simMatchString == loginMatchString) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return true;
    }
  }
}
