import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/overlays_provider.dart';
import '../providers/shell_state_provider.dart';
import '../theme/app_theme.dart';
import '../theme/spring.dart';
import 'capture_sheet.dart';
import 'command_palette.dart';
import 'settings_overlay.dart';
import 'sidebar_drawer.dart';
import 'top_bar.dart';
import 'undo_toast.dart';

/// Listd 2027 · Indigo Edition app shell.
///
/// The mockups (`docs/redesign/2027-indigo/mockups/01_today_light.png`,
/// `03_list_view_light.png` …) show two **floating rounded panels** on
/// the indigo `AppBackplate` — a 240 px sidebar card and a wider canvas
/// card — separated by an 8 px gutter, with 16 px gutters around the
/// outer edges so the backplate shows through. The top bar (panel
/// toggle + page title + Search · ⌘K + avatar) lives **inside** the
/// canvas card, not above the whole shell.
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

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();

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
            // Outer 16 px gutters around both panels so the indigo
            // backplate shows through at every edge — exactly the
            // layering shown in `03_list_view_light.png`.
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sidebar: 240 px slate-soft floating panel with
                  // 20 px corners and a soft shadow. Animates to
                  // width 0 (with an 8 px gap shrink) when toggled.
                  AnimatedSize(
                    duration: ListdSpring.duration,
                    curve: ListdSpring.curve,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: sidebarOpen ? SidebarDrawer.width : 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color:
                                surfaces?.panel ?? scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              surfaces?.shadowSm ?? const BoxShadow(),
                            ],
                            border: Border.all(
                              color: scheme.outlineVariant,
                              width: 1,
                            ),
                          ),
                          child: const SidebarDrawer(),
                        ),
                      ),
                    ),
                  ),

                  // 8 px gutter between the two panels — backplate
                  // shows through here.
                  SizedBox(width: sidebarOpen ? 16 : 0),

                  // Canvas: white floating panel with 20 px corners,
                  // soft shadow, and the top bar living inside it
                  // (panel toggle on the left, page title beside it,
                  // Search · ⌘K + avatar on the right).
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [surfaces?.shadowSm ?? const BoxShadow()],
                          border: Border.all(
                            color: scheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const TopBar(),
                            Expanded(child: widget.child),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
