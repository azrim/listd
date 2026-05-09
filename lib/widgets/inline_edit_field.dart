import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_motion.dart';

/// Listd 2027 · Indigo Edition inline-edit field.
///
/// Per `docs/redesign/2027-indigo/03_components.md` §6 this is the
/// single component that powers task title, notes, list name, and
/// step text. Visual states:
///
/// | State              | Visual                                        |
/// | ------------------ | --------------------------------------------- |
/// | Rest               | text only, 1 px slate-200 hairline underneath |
/// | Hover              | underline thickens to slate-400               |
/// | Focus              | underline becomes 2 px indigo-600             |
/// | Empty placeholder  | italic slate-400, hairline still visible      |
/// | Read-only          | no underline ever                             |
///
/// The hairline at rest is what makes the field discoverable — users
/// can see what's editable without having to click first.
class InlineEditField extends StatefulWidget {
  const InlineEditField({
    super.key,
    required this.controller,
    this.focusNode,
    this.style,
    this.placeholder,
    this.placeholderStyle,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.autofocus = false,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 0,
      vertical: 6,
    ),
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextStyle? style;
  final String? placeholder;
  final TextStyle? placeholderStyle;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final bool autofocus;
  final EdgeInsets contentPadding;

  @override
  State<InlineEditField> createState() => _InlineEditFieldState();
}

class _InlineEditFieldState extends State<InlineEditField> {
  late final FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    } else {
      _focusNode = widget.focusNode!;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focused = _focusNode.hasFocus;

    Color underlineColor;
    double underlineWidth;
    if (widget.readOnly) {
      underlineColor = Colors.transparent;
      underlineWidth = 0;
    } else if (focused) {
      underlineColor = scheme.primary;
      underlineWidth = 2;
    } else if (_hovered) {
      underlineColor = scheme.onSurfaceVariant;
      underlineWidth = 1;
    } else {
      underlineColor = scheme.outlineVariant;
      underlineWidth = 1;
    }

    final defaultStyle =
        widget.style ??
        GoogleFonts.inter(
          fontSize: 15,
          height: 22 / 15,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        );
    final defaultPlaceholderStyle =
        widget.placeholderStyle ??
        defaultStyle.copyWith(
          color: scheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.readOnly
          ? SystemMouseCursors.basic
          : SystemMouseCursors.text,
      child: AnimatedContainer(
        duration: AppMotion.flickDuration,
        curve: AppMotion.flickCurve,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: underlineColor, width: underlineWidth),
          ),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          autofocus: widget.autofocus,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          onEditingComplete: widget.onEditingComplete,
          style: defaultStyle,
          cursorColor: scheme.primary,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: defaultPlaceholderStyle,
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: widget.contentPadding,
          ),
        ),
      ),
    );
  }
}
