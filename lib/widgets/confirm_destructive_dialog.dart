import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'sheet_shell.dart';

/// Listd 2027 destructive-action confirmation dialog.
///
/// Wraps a [SheetShell] so it shares the same overlay shell language
/// as the Due / Reminder / Repeat / Tags pickers. Used to gate any
/// irreversible action (delete task, delete list, complete-all) so
/// the user has to acknowledge before the mutation fires.
///
/// Returns `true` if the user clicks the destructive confirm button,
/// `false` (or `null` → coalesced to `false` by [showConfirmDestructiveDialog])
/// if they cancel or dismiss with Esc / scrim tap.
class ConfirmDestructiveDialog extends StatelessWidget {
  const ConfirmDestructiveDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.icon,
  });

  /// Header title — e.g. "Delete this task?".
  final String title;

  /// Body line — e.g. the task title or list name. Rendered in
  /// `onSurfaceVariant` so it reads as the *thing being acted on*,
  /// not as primary content.
  final String body;

  /// Label on the destructive confirm button (e.g. "Delete").
  final String confirmLabel;

  /// Optional Phosphor icon for the header. Defaults to a trash glyph.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SheetShell(
      title: title,
      icon: icon ?? PhosphorIcons.trash(),
      maxHeight: 200,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Text(
          body,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 20 / 14,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
      footer: SheetShellActionFooter(
        trailing: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          // Destructive button — `error` foreground per the
          // `mockups/png/10_components_overview.png` SECONDARY & GHOST
          // group ("Delete" rendered in red). This is the same color
          // the sync pill uses for "Sync failed — tap to retry", so
          // the visual cue for "this is destructive" is consistent.
          TextButton(
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

/// Convenience opener — returns `true` if the user confirmed,
/// `false` for cancel / Esc / scrim dismiss.
Future<bool> showConfirmDestructiveDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  IconData? icon,
}) async {
  final result = await showSheetShell<bool>(
    context,
    (ctx) => ConfirmDestructiveDialog(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      icon: icon,
    ),
  );
  return result ?? false;
}
