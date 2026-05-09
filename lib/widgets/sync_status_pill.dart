import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/sync_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Compact sync status pill — 32 px tall, hairline border, sized to
/// its content (it must work both in the 2027 top bar `Row` — where
/// the parent constraint is unbounded — and in the legacy sidebar
/// column — where the pill simply takes its natural width).
///
/// Renders one of four states with a 6 px functional dot
/// (success / warning / error / accent for in-flight) plus a
/// trailing `sync` glyph or a 14 px spinner. Tap fires
/// `syncStateProvider.notifier.syncNow()`.
class SyncStatusPill extends ConsumerWidget {
  const SyncStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncStateProvider);
    final scheme = Theme.of(context).colorScheme;

    final (label, dotColor) = _statusFor(state, scheme);
    final canSync = !state.isSyncing;

    return Tooltip(
      message: _tooltipFor(state),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        child: InkWell(
          onTap: canSync
              ? () => ref.read(syncStateProvider.notifier).syncNow()
              : null,
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          child: Container(
            height: AppTheme.controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.controlRadius),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(width: 8),
                Flexible(
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
                const SizedBox(width: 8),
                if (!state.isSyncing)
                  Icon(Icons.sync, size: 14, color: scheme.onSurfaceVariant),
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
