import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Hairline text field — 32 px tall, 8 px radius, 1 px border, 2 px
/// accent focus ring (no glow). Despite the legacy name, there is no
/// glass effect; the widget is kept for backward compatibility with
/// existing call sites and now renders the 2026 input from the spec.
class GlassTextField extends StatelessWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      cursorColor: scheme.primary,
      style: GoogleFonts.inter(
        color: scheme.onSurface,
        fontSize: 15,
        height: 22 / 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: scheme.outline,
          fontSize: 15,
          height: 22 / 15,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: scheme.onSurfaceVariant, size: 18)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: scheme.surface,
        isDense: true,
        contentPadding: maxLines > 1
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }
}

/// In the 2026 system this is identical to [GlassTextField] — focus
/// state is communicated by the 2 px accent border, not by a glow.
class FocusedGlassTextField extends StatelessWidget {
  const FocusedGlassTextField({
    super.key,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return GlassTextField(
      controller: controller,
      hint: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      obscureText: obscureText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      maxLines: maxLines,
      autofocus: autofocus,
    );
  }
}
