import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

/// Listd 2027 · Indigo Edition modal-overlay shell.
///
/// The same visual frame that [CommandPalette] uses, factored out so
/// every overlay-style picker in the app reads as the same surface
/// pattern: centered 540 × ≤480 px panel on `surfaces.panel`, 16 px
/// radius, `outlineVariant` border, `shadowMd`, with a header / body
/// / footer triptych. ESC dismisses.
///
/// Each picker (Due / Reminder / Repeat / Tags) supplies the title,
/// header icon, body, and optional footer hint or actions. The shell
/// owns the chrome — radius, surface, border, shadow, ESC, sizing —
/// so individual pickers stay focused on their own job.
///
/// Use [showSheetShell] to open one as a dialog. The dialog uses a
/// dimmed scrim like [CommandPalette]'s.
class SheetShell extends StatelessWidget {
  const SheetShell({
    super.key,
    required this.title,
    required this.icon,
    required this.body,
    this.headerActions,
    this.footer,
    this.width = 540,
    this.maxHeight = 480,
  });

  /// Title shown next to [icon] in the header (e.g. "Due date").
  final String title;

  /// Phosphor icon glyph rendered in the header at 18 px.
  final IconData icon;

  /// Picker body — fills the middle slot between header and footer.
  /// Wrap scrollable content in a `Flexible` so it can shrink under
  /// [maxHeight].
  final Widget body;

  /// Optional trailing widgets in the header row (e.g. a clear /
  /// reset icon button). They sit flush with the right edge.
  final List<Widget>? headerActions;

  /// Optional bottom slot — keyboard-shortcut hint and/or action
  /// buttons. Sits below a 1 px outlineVariant divider.
  final Widget? footer;

  /// Fixed width. The default (540) matches [CommandPalette].
  final double width;

  /// Max content height. The shell contracts to fit smaller bodies
  /// and scrolls when the body asks for more.
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();
    final cardBg = surfaces?.panel ?? scheme.surface;

    return Center(
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Material(
            color: cardBg,
            elevation: 0,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: scheme.outline, width: 1),
                boxShadow: [surfaces?.shadowMd ?? const BoxShadow()],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              height: 22 / 16,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        if (headerActions != null) ...headerActions!,
                      ],
                    ),
                  ),
                  Container(height: 1, color: scheme.outline),
                  Flexible(child: body),
                  if (footer != null) ...[
                    Container(height: 1, color: scheme.outline),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quiet trailing-hint footer — matches the [CommandPalette]'s
/// "↑↓ navigate · ↵ open · Esc close" line. Pickers without a
/// keyboard contract should pass plain action buttons instead.
class SheetShellHintFooter extends StatelessWidget {
  const SheetShellHintFooter({super.key, required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 16 / 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action-row footer — left-aligned destructive / neutral, right-
/// aligned cancel + confirm. Used by Repeat ("Don't repeat" /
/// Cancel / Save) and Tags (Cancel / Save).
class SheetShellActionFooter extends StatelessWidget {
  const SheetShellActionFooter({
    super.key,
    this.leading,
    this.trailing = const <Widget>[],
  });

  /// Optional left-aligned action (typically destructive — "Don't
  /// repeat", "Clear due date", etc.).
  final Widget? leading;

  /// Right-aligned actions, rendered with 8 px gaps between them.
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (leading != null) {
      children.add(leading!);
    }
    children.add(const Spacer());
    for (var i = 0; i < trailing.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 8));
      children.add(trailing[i]);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(children: children),
    );
  }
}

/// Opens a [SheetShell]-wrapped picker as a dialog. The scrim and
/// dismissibility match [CommandPalette]'s overlay so the visual
/// language is consistent across every modal in the app.
///
/// The [builder] is invoked inside an Esc-handling Shortcuts block —
/// pressing Escape will pop the dialog with `null`.
Future<T?> showSheetShell<T>(
  BuildContext context,
  Widget Function(BuildContext) builder, {
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      return Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.escape): _SheetEscIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _SheetEscIntent: CallbackAction<_SheetEscIntent>(
              onInvoke: (_) {
                Navigator.of(ctx).pop();
                return null;
              },
            ),
          },
          child: Focus(autofocus: true, child: builder(ctx)),
        ),
      );
    },
  );
}

class _SheetEscIntent extends Intent {
  const _SheetEscIntent();
}

/// Tiny convenience for the most common header trailing action — a
/// quiet "clear" icon button (e.g. on the Due picker).
class SheetShellClearButton extends StatelessWidget {
  const SheetShellClearButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Clear',
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(PhosphorIcons.x(), size: 16),
      visualDensity: VisualDensity.compact,
      color: scheme.onSurfaceVariant,
    );
  }
}
