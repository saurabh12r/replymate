import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    required this.hintText,
    super.key,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.inputFormatters,
    this.prefix,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant, width: 1.2),
      ),
      child: Row(
        children: [
          if (prefix != null) prefix!,
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              maxLength: maxLength,
              inputFormatters: inputFormatters,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppTheme.onSurfaceVariant.withAlpha(128),
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
}
