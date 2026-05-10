import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

/// Listd 2027 P6 undo toast.
///
/// Lives at the bottom-center of the canvas. 6 s auto-dismiss.
/// Covers destructive actions: delete task, complete task,
/// list-delete. Reads from `undoToastProvider`. Pushers post a
/// `UndoToastPayload` and supply an `onUndo` callback.

class UndoToastPayload {
  const UndoToastPayload({
    required this.message,
    required this.onUndo,
    this.duration = const Duration(seconds: 6),
    this.showUndoButton = true,
  });

  final String message;
  final FutureOr<void> Function() onUndo;
  final Duration duration;

  /// When false, the toast renders the message + dismiss button only,
  /// no Undo TextButton. Used for delete-task in v1 because real
  /// undelete needs `clearDeletedAt` on TaskDao which doesn't exist
  /// yet — the toast still acknowledges the delete, just without
  /// promising a reversal we can't deliver.
  final bool showUndoButton;
}

class UndoToastNotifier extends StateNotifier<UndoToastPayload?> {
  UndoToastNotifier() : super(null);
  Timer? _timer;

  void show(UndoToastPayload payload) {
    _timer?.cancel();
    state = payload;
    _timer = Timer(payload.duration, dismiss);
  }

  void dismiss() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }

  Future<void> undo() async {
    final p = state;
    if (p == null) return;
    dismiss();
    await p.onUndo();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final undoToastProvider =
    StateNotifierProvider<UndoToastNotifier, UndoToastPayload?>(
      (ref) => UndoToastNotifier(),
    );

class UndoToast extends ConsumerWidget {
  const UndoToast({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = ref.watch(undoToastProvider);
    if (payload == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Material(
          color: surfaces?.panel ?? scheme.surface,
          elevation: 0,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant, width: 1),
              boxShadow: [surfaces?.shadowMd ?? const BoxShadow()],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIcons.arrowCounterClockwise(),
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  payload.message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 18 / 13,
                    color: scheme.onSurface,
                  ),
                ),
                if (payload.showUndoButton) ...[
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () =>
                        ref.read(undoToastProvider.notifier).undo(),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text('Undo'),
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Dismiss',
                  icon: Icon(PhosphorIcons.x(), size: 14),
                  color: scheme.onSurfaceVariant,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () =>
                      ref.read(undoToastProvider.notifier).dismiss(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
