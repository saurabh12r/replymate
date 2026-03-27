import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import 'signup_controller.dart';
import 'widgets/auth_text_field.dart';

/// Signup View
/// Stitch Screen ID: CUSTOM_SIGNUP_01
class SignupView extends GetView<SignupController> {
  const SignupView({super.key});
  static const Color _primary = Color(0xFF24389C);
  static const Color _primaryContainer = Color(0xFF3F51B5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    Text(
                      'Create Account',
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign up to get started',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildLabel('Full Name'),
                    const SizedBox(height: 8),
                    AuthTextField(
                      controller: controller.fullNameController,
                      hintText: 'Enter your full name',
                      keyboardType: TextInputType.name,
                    ),
                    _buildError(controller.fullNameError),
                    const SizedBox(height: 14),
                    _buildLabel('Phone Number'),
                    const SizedBox(height: 8),
                    AuthTextField(
                      controller: controller.phoneController,
                      hintText: '98765 43210',
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      prefix: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius:
                              const BorderRadius.horizontal(left: Radius.circular(15)),
                          border: const Border(
                            right: BorderSide(
                              color: AppTheme.outlineVariant,
                              width: 1.2,
                            ),
                          ),
                        ),
                        child: GestureDetector(
                          onTap: controller.onCountryCodeTap,
                          child: Obx(
                            () => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 6),
                                Text(
                                  controller.countryCode.value,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildError(controller.phoneError),
                    const SizedBox(height: 14),
                    _buildLabel('Email (Optional)'),
                    const SizedBox(height: 8),
                    AuthTextField(
                      controller: controller.emailController,
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildError(controller.emailError),
                    const SizedBox(height: 16),
                    _buildPolicyConsent(),
                    const SizedBox(height: 20),
                    _buildSignupButton(),
                    const SizedBox(height: 20),
                    _buildLoginLink(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2980), _primary, _primaryContainer],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: controller.goToLogin,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(31),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(51), width: 1),
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'ReplyMate',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.onSurface,
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _buildError(RxString message) {
    return Obx(() {
      if (message.value.isEmpty) return const SizedBox(height: 2);
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          message.value,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.error,
          ),
        ),
      );
    });
  }

  Widget _buildPolicyConsent() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.5),
        children: [
          const TextSpan(text: 'By registering, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: _primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrl(
                    Uri.parse('https://replymate.app/terms'),
                    mode: LaunchMode.externalApplication,
                  ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: _primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrl(
                    Uri.parse('https://replymate.app/privacy'),
                    mode: LaunchMode.externalApplication,
                  ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Widget _buildSignupButton() {
    return Obx(() {
      final enabled = controller.isFormValid.value && !controller.isLoading.value;
      return GestureDetector(
        onTap: enabled ? controller.signup : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [_primary, _primaryContainer],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: enabled ? null : AppTheme.outlineVariant,
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: _primary.withAlpha(51),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: controller.isLoading.value
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Register',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: enabled ? Colors.white : AppTheme.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildLoginLink() {
    return Align(
      child: GestureDetector(
        onTap: controller.goToLogin,
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
            ),
            children: [
              const TextSpan(text: 'Already have an account? '),
              TextSpan(
                text: 'Login',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
