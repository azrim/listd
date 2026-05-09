import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/overlays_provider.dart';
import '../providers/shell_state_provider.dart';
import '../theme/spring.dart';
import 'capture_sheet.dart';
import 'command_palette.dart';
import 'settings_overlay.dart';
import 'sidebar_drawer.dart';
import 'top_bar.dart';
import 'undo_toast.dart';

/// Listd 2027 · Indigo Edition app shell.
///
/// The mockups (`docs/redesign/2027-indigo/mockups/01_today_light.png`
/// and friends) show the sidebar permanently docked against the left
/// edge — no hover-edge detector, no overlay scrim. The canvas sits
/// to its right and renders its own headline / capture row / cards.
///
///  * Sidebar (240 px, always visible on desktop) + canvas (Expanded).
///  * `Ctrl + \` toggles the sidebar visibility (still useful on
///    narrow screens) — by default `sidebarDrawerOpenProvider` is
///    seeded `true` and the canvas shrinks to the available width.
///  * `Ctrl + K` opens the command palette, `Ctrl + N` the capture
///    sheet, `Escape` closes the topmost open overlay.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final FocusNode _focusNode = FocusNode(skipTraversal: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.backslash) {
      ref.read(sidebarDrawerOpenProvider.notifier).update((v) => !v);
      return KeyEventResult.handled;
    }
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyK) {
      ref.read(captureSheetOpenProvider.notifier).state = false;
      ref.read(commandPaletteOpenProvider.notifier).update((v) => !v);
      return KeyEventResult.handled;
    }
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyN) {
      ref.read(commandPaletteOpenProvider.notifier).state = false;
      ref.read(captureSheetOpenProvider.notifier).update((v) => !v);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (ref.read(settingsOverlayOpenProvider)) {
        ref.read(settingsOverlayOpenProvider.notifier).state = false;
        return KeyEventResult.handled;
      }
      if (ref.read(commandPaletteOpenProvider)) {
        ref.read(commandPaletteOpenProvider.notifier).state = false;
        return KeyEventResult.handled;
      }
      if (ref.read(captureSheetOpenProvider)) {
        ref.read(captureSheetOpenProvider.notifier).state = false;
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final sidebarOpen = ref.watch(sidebarDrawerOpenProvider);
    final captureOpen = ref.watch(captureSheetOpenProvider);
    final paletteOpen = ref.watch(commandPaletteOpenProvider);
    final settingsOpen = ref.watch(settingsOverlayOpenProvider);

    // Wrap the shell in a Material so descendant Text widgets
    // inherit a DefaultTextStyle (otherwise Flutter renders the
    // amber double-underline debug warning over labels like SMART /
    // LISTS / Search · Ctrl+K).
    return Material(
      type: MaterialType.transparency,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Stack(
          children: [
            Row(
              children: [
                AnimatedSize(
                  duration: ListdSpring.duration,
                  curve: ListdSpring.curve,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: sidebarOpen ? SidebarDrawer.width : 0,
                    child: const ClipRect(child: SidebarDrawer()),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const TopBar(),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ],
            ),

            // Bottom-center undo toast — always mounted so the
            // notifier can show without a route hop.
            const Positioned.fill(
              child: IgnorePointer(ignoring: false, child: UndoToast()),
            ),

            if (paletteOpen) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      ref.read(commandPaletteOpenProvider.notifier).state =
                          false,
                  child: Container(color: Colors.black.withValues(alpha: 0.18)),
                ),
              ),
              const Positioned.fill(child: CommandPalette()),
            ],
            if (captureOpen) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      ref.read(captureSheetOpenProvider.notifier).state = false,
                  child: Container(color: Colors.black.withValues(alpha: 0.18)),
                ),
              ),
              const Positioned.fill(child: CaptureSheet()),
            ],

            // 2027 indigo settings drawer — slides in from the right
            // edge with a flat 40 % slate scrim. No blur anywhere in
            // the tree (see CI gate in docs/redesign/2027-indigo).
            if (settingsOpen)
              Positioned.fill(
                child: SettingsOverlay(
                  onClose: () =>
                      ref.read(settingsOverlayOpenProvider.notifier).state =
                          false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
