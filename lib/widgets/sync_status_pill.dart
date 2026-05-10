import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/sync_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Listd 2027 · Indigo Edition sync status pill.
///
/// One pill, lives at the bottom of the sidebar drawer. Renders one of
/// four states with a 6 px functional dot
/// (success / warning / error / accent for in-flight) plus a trailing
/// `sync` glyph or a 14 px spinner. Tap fires
/// `syncStateProvider.notifier.syncNow()`.
///
/// Per the indigo spec the pill takes the **full available width** when
/// it's given bounded constraints (sidebar drawer footer) and shrinks
/// to its content otherwise.
class SyncStatusPill extends ConsumerWidget {
  const SyncStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncStateProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();

    final (label, dotColor) = _statusFor(state, scheme);
    final canSync = !state.isSyncing;

    return Tooltip(
      message: _tooltipFor(state),
      child: Material(
        // Lift one stop above the panel surface the pill sits on so
        // it has visible separation. In light: white card on slate-50
        // panel (silhouette unchanged, but the bumped outlineVariant
        // from slate-100 → slate-200 gives the border real contrast).
        // In dark: slate-700 card on slate-900 panel — was slate-800
        // on slate-900 (one stop) and now pops a full stop above the
        // flattened panel/canvas, matching `02_today_dark.png`.
        color: surfaces?.card ?? scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        child: InkWell(
          onTap: canSync
              ? () => ref.read(syncStateProvider.notifier).syncNow()
              : null,
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          child: Container(
            height: AppTheme.controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.controlRadius),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: [
                if (state.isSyncing)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  )
                else
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
                if (!state.isSyncing) ...[
                  const SizedBox(width: 8),
                  Icon(
                    PhosphorIcons.arrowsClockwise(),
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, Color) _statusFor(SyncStateSnapshot state, ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    if (state.isSyncing) {
      return ('Syncing…', scheme.primary);
    }
    if (state.lastError != null) {
      return ('Sync failed', isDark ? AppColors.errorDark : AppColors.error);
    }
    if (state.totalPending > 0) {
      final n = state.totalPending;
      return ('$n pending', isDark ? AppColors.warningDark : AppColors.warning);
    }
    return ('Synced', isDark ? AppColors.successDark : AppColors.success);
  }

  String _tooltipFor(SyncStateSnapshot state) {
    if (state.isSyncing) return 'Sync in progress';
    if (state.lastError != null) {
      return 'Sync failed: ${state.lastError}\nTap to retry.';
    }
    final last = state.lastSyncedAt;
    final lastLabel = last == null
        ? 'Never synced'
        : 'Last synced ${_relative(last)}';
    if (state.totalPending > 0) {
      return '${state.totalPending} unsynced change'
          '${state.totalPending == 1 ? '' : 's'}\n'
          '$lastLabel\nTap to sync now.';
    }
    return '$lastLabel\nTap to sync now.';
  }

  String _relative(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inSeconds < 5) return 'just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
