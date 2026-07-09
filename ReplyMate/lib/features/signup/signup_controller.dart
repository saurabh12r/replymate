import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../core/services/auth/user_repository.dart';
import '../../core/services/subscription/subscription_service.dart';

/// SignupController with broker code support
class SignupController extends GetxController {
  SignupController({UserRepository? userRepository})
    : _userRepository = userRepository ?? Get.find<UserRepository>();

  final UserRepository _userRepository;

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final brokerCodeController = TextEditingController(); // ← NEW

  final RxString countryCode = '+91'.obs;
  final RxBool isLoading = false.obs;
  final RxBool isFormValid = false.obs;

  final RxString fullNameError = ''.obs;
  final RxString phoneError = ''.obs;
  final RxString emailError = ''.obs;
  final RxString brokerCodeError = ''.obs; // ← NEW
  final RxBool isBrokerCodeValid = false.obs; // ← NEW — green check when valid
  final RxBool isValidatingCode = false.obs; // ← NEW — loading indicator

  // Resolved brokerId after validation (null if no code entered)
  String? _resolvedBrokerId;

  @override
  void onInit() {
    super.onInit();
    fullNameController.addListener(_validateLive);
    phoneController.addListener(_validateLive);
    emailController.addListener(_validateLive);
    brokerCodeController.addListener(_onBrokerCodeChanged); // ← NEW
  }

  void _validateLive() {
    fullNameError.value = '';
    phoneError.value = '';
    emailError.value = '';
    isFormValid.value = _computeIsValid();
  }

  // Debounce timer for broker code validation
  Worker? _brokerDebounce;

  void _onBrokerCodeChanged() {
    brokerCodeError.value = '';
    isBrokerCodeValid.value = false;
    _resolvedBrokerId = null;
    isFormValid.value = _computeIsValid();

    final code = brokerCodeController.text.trim();
    if (code.isEmpty) return;

    // Debounce: wait 800ms after user stops typing before hitting Firestore
    _brokerDebounce?.call();
    _brokerDebounce = debounce(
      Duration.zero.obs,
      (_) {},
      time: const Duration(milliseconds: 800),
    );

    Future.delayed(const Duration(milliseconds: 800), () async {
      if (brokerCodeController.text.trim() != code) return; // stale
      await _validateBrokerCode(code);
    });
  }

  Future<void> _validateBrokerCode(String code) async {
    isValidatingCode.value = true;
    try {
      final brokerId = await SubscriptionService.instance.validateBrokerCode(
        code,
      );
      if (brokerId != null) {
        _resolvedBrokerId = brokerId;
        isBrokerCodeValid.value = true;
        brokerCodeError.value = '';
      } else {
        _resolvedBrokerId = null;
        isBrokerCodeValid.value = false;
        brokerCodeError.value = 'Invalid or inactive broker code';
      }
    } catch (e) {
      _resolvedBrokerId = null;
      isBrokerCodeValid.value = false;
      if (e.toString().contains('Broker limit reached')) {
        brokerCodeError.value = "Broker's user limit has been reached";
      } else {
        brokerCodeError.value = 'Could not verify broker code';
      }
    } finally {
      isValidatingCode.value = false;
      isFormValid.value = _computeIsValid();
    }
  }

  bool _computeIsValid() {
    final fullName = fullNameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final code = brokerCodeController.text.trim();

    final isPhoneValid = RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
    final isEmailValid =
        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

    // Broker code: if entered, must be validated; if empty, OK (optional)
    final isBrokerOk = code.isEmpty || isBrokerCodeValid.value;

    return fullName.length >= 2 && isPhoneValid && isEmailValid && isBrokerOk;
  }

  bool _validateAndSetErrors() {
    final fullName = fullNameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final code = brokerCodeController.text.trim();
    var valid = true;

    fullNameError.value = '';
    phoneError.value = '';
    emailError.value = '';
    brokerCodeError.value = '';

    if (fullName.isEmpty || fullName.length < 2) {
      fullNameError.value = fullName.isEmpty
          ? 'Please enter your full name'
          : 'Full name must be at least 2 characters';
      valid = false;
    }

    if (phone.isEmpty) {
      phoneError.value = 'Please enter your phone number';
      valid = false;
    } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      phoneError.value = 'Please enter a valid 10-digit phone number';
      valid = false;
    }

    if (email.isEmpty) {
      emailError.value = 'Please enter your email address';
      valid = false;
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      emailError.value = 'Please enter a valid email address';
      valid = false;
    }

    if (code.isNotEmpty && !isBrokerCodeValid.value) {
      brokerCodeError.value = 'Please enter a valid broker code or leave empty';
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
        brokerId: _resolvedBrokerId,
        brokerCode: brokerCodeController.text.trim().isEmpty
            ? null
            : brokerCodeController.text.trim().toUpperCase(),
      );

      await Get.dialog(
        AlertDialog(
          title: const Text('Registration successful'),
          content: Text(
            _resolvedBrokerId != null
                ? 'Registration successful! Your broker will review and activate your account shortly.'
                : 'Registration successful! Wait for admin approval before logging in.',
          ),
          actions: [TextButton(onPressed: Get.back, child: const Text('OK'))],
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
    brokerCodeController.dispose();
    super.onClose();
  }
}
