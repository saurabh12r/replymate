import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes/app_routes.dart';
import 'login_controller.dart';

/// Login View
/// Stitch Screen ID: f6417a644f80448193ad7d306fe4de25
/// Project: auto (14054579236203393248)
class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colorScheme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      'Welcome back',
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your phone number to login securely',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Phone Number',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPhoneInput(colorScheme),
                    const SizedBox(height: 8),
                    Obx(() {
                      if (controller.errorMessage.isEmpty)
                        return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          controller.errorMessage.value,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorScheme.error,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 28),
                    _buildSendOtpButton(colorScheme),
                    const SizedBox(height: 18),
                    _buildSignupLink(colorScheme),
                    const SizedBox(height: 32),
                    _buildTermsText(colorScheme),
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

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A2980),
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(31),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(51), width: 1),
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'ReplyMate',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput(ColorScheme colorScheme) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 1.2),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: controller.onCountryCodeTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(15),
                ),
                border: Border(
                  right: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1.2,
                  ),
                ),
              ),
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
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller.phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: '98765 43210',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: colorScheme.onSurfaceVariant.withAlpha(128),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendOtpButton(ColorScheme colorScheme) {
    return Obx(() {
      final enabled = controller.isValid.value && !controller.isLoading.value;
      return GestureDetector(
        onTap: enabled ? controller.loginUser : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    colors: [colorScheme.primary, colorScheme.primaryContainer],
                  )
                : null,
            color: enabled ? null : colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(51),
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
                    'Login',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildTermsText(ColorScheme colorScheme) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
          height: 1.6,
        ),
        children: [
          const TextSpan(text: 'By clicking "Send OTP", you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Widget _buildSignupLink(ColorScheme colorScheme) {
    return Align(
      child: GestureDetector(
        onTap: () => Get.toNamed(Routes.signup),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
            children: [
              const TextSpan(text: "Don't have an account? "),
              TextSpan(
                text: 'Sign Up',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: colorScheme.primary,
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
