import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp_controller.dart';

/// OTP Verification View
/// Stitch Screen ID: 57e63680f2bb41daa9a7b0c10941fd6d
/// Project: auto (14054579236203393248)
///
/// Design (from Stitch):
///  - Indigo gradient header with back button + ReplyMate logo
///  - Title: "Verify Identity"
///  - Subtitle: "We've sent a 6-digit code to phone"
///  - 6 individual OTP digit boxes (auto-focus, auto-move, focus highlight)
///  - 30s resend timer + "Resend OTP" tappable link
///  - Full-width "Verify OTP" gradient button
///  - "Having trouble?" tonal card at bottom
class OtpView extends GetView<OtpController> {
  const OtpView({super.key});

  // ── Design tokens ─────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF24389C);
  static const Color _primaryContainer = Color(0xFF3F51B5);
  static const Color _surface = Color(0xFFF8F9FA);
  static const Color _surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _outlineVariant = Color(0xFFC5C5D4);
  static const Color _secondary = Color(0xFF006A6A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      'Verify Identity',
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _onSurfaceVariant,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: "We've sent a 6-digit code to "),
                          TextSpan(
                            text: controller.phoneNumber.isNotEmpty
                                ? controller.phoneNumber
                                : '+91 98765 43210',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _onSurface,
                            ),
                          ),
                          const TextSpan(text: '. Please enter it below.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    _buildOtpBoxes(),
                    const SizedBox(height: 10),
                    Obx(() {
                      if (controller.errorMessage.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          controller.errorMessage.value,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFBA1A1A),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    _buildResendRow(),
                    const SizedBox(height: 32),
                    _buildVerifyButton(),
                    const SizedBox(height: 28),
                    _buildTroubleCard(),
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
            onPressed: controller.goBack,
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

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        OtpController.otpLength,
        (i) => _OtpBox(
          controller: controller.boxes[i],
          focusNode: controller.focusNodes[i],
          onChanged: (v) => controller.onBoxChanged(v, i),
          onKey: (e) => controller.onKeyEvent(e, i),
        ),
      ),
    );
  }

  Widget _buildResendRow() {
    return Obx(
      () => Row(
        children: [
          Text(
            "Didn't receive the code? ",
            style: GoogleFonts.inter(fontSize: 13, color: _onSurfaceVariant),
          ),
          if (!controller.canResend.value)
            Text(
              'Resend in ${controller.resendSeconds.value}s',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            GestureDetector(
              onTap: controller.resendOtp,
              child: Text(
                'Resend OTP',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Obx(() {
      final hasSession = controller.hasVerificationId.value;
      final enabled =
          hasSession && controller.isValid.value && !controller.isLoading.value;
      return GestureDetector(
        onTap: enabled ? controller.verifyOtp : null,
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
            color: enabled ? null : _outlineVariant,
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
                    hasSession ? 'Verify OTP' : 'Sending OTP…',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: enabled ? Colors.white : _onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildTroubleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _secondary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              size: 20,
              color: _secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Having trouble?',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check your spam folder or try another verification method. Secure login is our priority.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single OTP digit box ──────────────────────────────────────────────────────
class _OtpBox extends StatefulWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKey,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKey;

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  static const Color _primary = Color(0xFF24389C);
  static const Color _surfaceLowest = Color(0xFFFFFFFF);
  static const Color _outlineVariant = Color(0xFFC5C5D4);
  static const Color _onSurface = Color(0xFF191C1D);

  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: widget.onKey,
      child: SizedBox(
        width: 48,
        height: 56,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _surfaceLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focused ? _primary : _outlineVariant,
              width: _focused ? 2.0 : 1.2,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: _primary.withAlpha(31),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: widget.onChanged,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _onSurface,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}
