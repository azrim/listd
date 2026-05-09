import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/overlays_provider.dart';
import '../providers/shell_state_provider.dart';
import '../theme/spring.dart';
import 'capture_sheet.dart';
import 'command_palette.dart';
import 'sidebar_drawer.dart';
import 'top_bar.dart';
import 'undo_toast.dart';

/// Listd 2027 app shell.
///
/// Wraps every screen with:
///
///  * `TopBar` (40 px).
///  * Hover-edge detector on the left 8 px (200 ms dwell opens the
///    drawer).
///  * Hidden `SidebarDrawer` overlayed via a `Stack` with a slide-
///    in transition driven by `ListdSpring.standard`.
///  * `Ctrl + \` toggles the drawer; `Escape` closes it.
///  * The wrapped child shifts 32 px to the right when the drawer is
///    open so the eye doesn't have to fight a covered canvas.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const Duration _hoverDwell = Duration(milliseconds: 200);
  static const double _edgeThreshold = 8;
  static const double _canvasShift = 32;

  Timer? _hoverTimer;
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
    _hoverTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleOpen() {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(_hoverDwell, () {
      if (!mounted) return;
      ref.read(sidebarDrawerOpenProvider.notifier).state = true;
    });
  }

  void _cancelOpen() {
    _hoverTimer?.cancel();
  }

  KeyEventResult _onKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.backslash) {
      ref.read(sidebarDrawerOpenProvider.notifier).update((v) => !v);
      return KeyEventResult.handled;
    }
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyK) {
      // Toggle the command palette. Closing the capture sheet first
      // means Ctrl+K is always a one-shot route to a known overlay.
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
      // Close overlays first; only fall through to the drawer if no
      // overlay was open.
      if (ref.read(commandPaletteOpenProvider)) {
        ref.read(commandPaletteOpenProvider.notifier).state = false;
        return KeyEventResult.handled;
      }
      if (ref.read(captureSheetOpenProvider)) {
        ref.read(captureSheetOpenProvider.notifier).state = false;
        return KeyEventResult.handled;
      }
      if (ref.read(sidebarDrawerOpenProvider)) {
        ref.read(sidebarDrawerOpenProvider.notifier).state = false;
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = ref.watch(sidebarDrawerOpenProvider);
    final captureOpen = ref.watch(captureSheetOpenProvider);
    final paletteOpen = ref.watch(commandPaletteOpenProvider);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Stack(
        children: [
          // Main canvas — top bar + child. Slide right by 32 px when
          // the drawer is open so the visible work area gets out of
          // the drawer's way.
          AnimatedPositioned(
            duration: ListdSpring.duration,
            curve: ListdSpring.curve,
            left: isOpen ? SidebarDrawer.width + _canvasShift : 0,
            right: isOpen ? -(SidebarDrawer.width + _canvasShift) + 0 : 0,
            top: 0,
            bottom: 0,
            child: Column(
              children: [
                const TopBar(),
                Expanded(child: widget.child),
              ],
            ),
          ),

          // Hover-edge detector on the left 8 px. Doesn't render
          // anything visible — just listens for mouse hover and
          // schedules `sidebarDrawerOpenProvider = true` after 200 ms.
          if (!isOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _edgeThreshold,
              child: MouseRegion(
                opaque: false,
                onEnter: (_) => _scheduleOpen(),
                onExit: (_) => _cancelOpen(),
              ),
            ),

          // Tap-outside backdrop: closes the drawer when the user
          // clicks anywhere outside it. Behind the drawer in the
          // stack so the drawer's own gestures still win.
          if (isOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () =>
                    ref.read(sidebarDrawerOpenProvider.notifier).state = false,
              ),
            ),

          // The drawer itself slides in from -width → 0.
          AnimatedPositioned(
            duration: ListdSpring.duration,
            curve: ListdSpring.curve,
            top: 0,
            bottom: 0,
            left: isOpen ? 0 : -SidebarDrawer.width,
            child: const SidebarDrawer(),
          ),

          // Bottom-center undo toast — always mounted so the
          // notifier can show without a route hop.
          const Positioned.fill(
            child: IgnorePointer(ignoring: false, child: UndoToast()),
          ),

          // P6 overlays. Backdrop scrim + dialog are mounted only when
          // open. Backdrop closes on tap.
          if (paletteOpen) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    ref.read(commandPaletteOpenProvider.notifier).state = false,
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
        ],
      ),
    );
  }
}
