import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/shell_state_provider.dart';
import 'app_logo.dart';
import 'sync_status_pill.dart';

/// Listd 2027 top bar.
///
/// 40 px tall, sits above every screen that renders inside `AppShell`.
/// Holds (left → right):
///
///  * Drawer toggle (8 px from the left edge).
///  * Workspace identity ("Listd" + serif glyph).
///  * Spacer.
///  * `SyncStatusPill` (reads the same `syncStateProvider` as the
///    legacy sidebar so the two views stay in sync without separate
///    state).
///  * Avatar (initials chip; tap opens the profile menu — wired in
///    P7).
class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOpen = ref.watch(sidebarDrawerOpenProvider);
    final auth = ref.watch(authNotifierProvider);
    final email = auth is AuthAuthenticated ? auth.session.user.email : null;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: isOpen ? 'Close sidebar' : 'Open sidebar (Ctrl + \\)',
            icon: Icon(
              isOpen
                  ? PhosphorIcons.sidebar(PhosphorIconsStyle.fill)
                  : PhosphorIcons.sidebar(),
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            onPressed: () =>
                ref.read(sidebarDrawerOpenProvider.notifier).update((v) => !v),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 4),
          const AppLogo(size: 18),
          const SizedBox(width: 8),
          Text(
            'Listd',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 18 / 14,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          const SyncStatusPill(),
          const SizedBox(width: 8),
          _Avatar(email: email),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = (email == null || email!.isEmpty)
        ? '?'
        : email!.substring(0, 1).toUpperCase();

    return Tooltip(
      message: email ?? 'Not signed in',
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: GoogleFonts.inter(
            fontSize: 12,
            height: 1.0,
            fontWeight: FontWeight.w600,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}
