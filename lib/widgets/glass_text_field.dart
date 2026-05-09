import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Text field — 36 px tall, 12 px radius, warm fill, 2 px flame focus
/// ring (no glow). The legacy "Glass" name is kept as an alias only;
/// internally the field already reads from `Theme.of(context)` so it
/// picks up the 2027 tokens automatically.
///
/// New code should use a plain `TextField` with the global theme.
// Deprecated — alias only. New code should use TextField with the global theme.
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

/// Identical to [GlassTextField] — focus state is communicated by the
/// 2 px flame border, not by a glow.
// Deprecated — alias only. New code should use TextField with the global theme.
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
