import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// One row in a [ListdContextMenu].
///
/// `icon` is the leading glyph; `label` is the row text; `shortcut`
/// renders a quiet trailing hint (e.g. `Ctrl+\`) for muscle-memory
/// reinforcement. Set `destructive: true` for delete-style rows — they
/// render in scheme.error and tint on hover.
///
/// `enabled: false` greys the row and skips it during keyboard nav.
class ListdContextMenuItem {
  const ListdContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.shortcut,
    this.destructive = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? shortcut;
  final bool destructive;
  final bool enabled;
}

/// Visual divider in a [ListdContextMenu]. Rendered as a 1 px
/// `outlineVariant` hairline with 4 px breathing room.
///
/// Pass it inside the items list alongside [ListdContextMenuItem].
class ListdContextMenuDivider {
  const ListdContextMenuDivider();
}

/// Pop the Listd 2027 context menu at [globalPosition].
///
/// Mounts an opaque modal route so the first click outside dismisses
/// it without triggering the underlying widget. The menu clamps inside
/// the viewport: if there isn't room below the click, it flips above;
/// if there isn't room to the right, it flips left.
///
/// `items` may contain `ListdContextMenuItem` and
/// `ListdContextMenuDivider` instances in any order.
Future<void> showListdContextMenu(
  BuildContext context,
  Offset globalPosition,
  List<Object> items,
) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 80),
      reverseTransitionDuration: const Duration(milliseconds: 60),
      pageBuilder: (ctx, _, _) =>
          _ContextMenuOverlay(globalPosition: globalPosition, items: items),
      transitionsBuilder: (ctx, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    ),
  );
}

class _ContextMenuOverlay extends StatefulWidget {
  const _ContextMenuOverlay({
    required this.globalPosition,
    required this.items,
  });

  final Offset globalPosition;
  final List<Object> items;

  @override
  State<_ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<_ContextMenuOverlay> {
  static const double _menuWidth = 220;
  static const double _viewportPadding = 8;

  final FocusNode _focusNode = FocusNode();
  int _focusedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Indices of selectable rows (skipping dividers + disabled items) so
  // arrow-key nav lands on something usable.
  List<int> get _navigableIndices {
    final out = <int>[];
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      if (item is ListdContextMenuItem && item.enabled) out.add(i);
    }
    return out;
  }

  void _moveFocus(int delta) {
    final nav = _navigableIndices;
    if (nav.isEmpty) return;
    final currentNavIdx = nav.indexOf(_focusedIndex);
    final nextNavIdx = currentNavIdx == -1
        ? (delta > 0 ? 0 : nav.length - 1)
        : (currentNavIdx + delta) % nav.length;
    setState(() => _focusedIndex = nav[(nextNavIdx + nav.length) % nav.length]);
  }

  void _activateFocused() {
    if (_focusedIndex < 0 || _focusedIndex >= widget.items.length) return;
    final item = widget.items[_focusedIndex];
    if (item is! ListdContextMenuItem || !item.enabled) return;
    Navigator.of(context).pop();
    // Defer so the route is fully gone before the callback runs — most
    // callbacks open another overlay (date picker, etc.) and we don't
    // want them stacking on top of this menu's pop animation.
    WidgetsBinding.instance.addPostFrameCallback((_) => item.onTap());
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveFocus(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveFocus(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _activateFocused();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();
    final media = MediaQuery.of(context).size;

    // Estimate menu height so we can flip it above the click point if
    // needed. 36 px per row + 1 px per divider + 8 px vertical padding.
    final estimatedHeight =
        widget.items.fold<double>(8, (sum, item) {
          if (item is ListdContextMenuDivider) return sum + 9;
          return sum + 36;
        }) +
        8;

    var x = widget.globalPosition.dx;
    var y = widget.globalPosition.dy;

    if (x + _menuWidth + _viewportPadding > media.width) {
      x = media.width - _menuWidth - _viewportPadding;
    }
    if (x < _viewportPadding) x = _viewportPadding;

    if (y + estimatedHeight + _viewportPadding > media.height) {
      y = media.height - estimatedHeight - _viewportPadding;
    }
    if (y < _viewportPadding) y = _viewportPadding;

    return Stack(
      children: [
        Positioned(
          left: x,
          top: y,
          width: _menuWidth,
          child: Focus(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _onKey,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: surfaces?.panel ?? scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant, width: 1),
                  boxShadow: [
                    surfaces?.shadowLg ??
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < widget.items.length; i++)
                      if (widget.items[i] is ListdContextMenuDivider)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            height: 1,
                            color: scheme.outlineVariant,
                          ),
                        )
                      else
                        _ContextMenuRow(
                          item: widget.items[i] as ListdContextMenuItem,
                          focused: _focusedIndex == i,
                          onHover: (h) {
                            if (h) setState(() => _focusedIndex = i);
                          },
                          onTap: () {
                            final item =
                                widget.items[i] as ListdContextMenuItem;
                            if (!item.enabled) return;
                            Navigator.of(context).pop();
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => item.onTap(),
                            );
                          },
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContextMenuRow extends StatelessWidget {
  const _ContextMenuRow({
    required this.item,
    required this.focused,
    required this.onHover,
    required this.onTap,
  });

  final ListdContextMenuItem item;
  final bool focused;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final disabled = !item.enabled;
    final fg = disabled
        ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
        : item.destructive
        ? scheme.error
        : scheme.onSurface;
    final hoverFill = item.destructive
        ? scheme.error.withValues(alpha: 0.08)
        : scheme.surfaceContainerHighest;
    final fill = focused ? hoverFill : Colors.transparent;

    return MouseRegion(
      cursor: disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) {
        if (!disabled) onHover(true);
      },
      onExit: (_) => onHover(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 16, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (item.shortcut != null) ...[
                const SizedBox(width: 12),
                Text(
                  item.shortcut!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 16 / 11,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
