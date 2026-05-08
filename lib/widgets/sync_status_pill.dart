import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/sync_provider.dart';

/// Compact status pill that shows the current sync state plus a manual
/// "sync now" button. Designed to slot into the sidebar footer.
///
/// States:
///   - **Synced** (green dot, no error, 0 pending)
///   - **Syncing…** (spinner)
///   - **N pending** (amber dot, has uncommitted local edits)
///   - **Sync failed** (red dot, lastError set)
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
        color: Colors.transparent,
        child: InkWell(
          onTap: canSync
              ? () => ref.read(syncStateProvider.notifier).syncNow()
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.outlineVariant),
              color: scheme.surfaceContainerLow,
            ),
            child: Row(
              children: [
                if (state.isSyncing)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  )
                else
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!state.isSyncing)
                  Icon(Icons.sync, size: 16, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, Color) _statusFor(SyncStateSnapshot state, ColorScheme scheme) {
    if (state.isSyncing) {
      return ('Syncing…', scheme.primary);
    }
    if (state.lastError != null) {
      return ('Sync failed — tap to retry', scheme.error);
    }
    if (state.totalPending > 0) {
      final n = state.totalPending;
      return ('$n pending — tap to sync', const Color(0xFFF59E0B));
    }
    return ('Synced', const Color(0xFF22C55E));
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
