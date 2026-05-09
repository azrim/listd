import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/overlays_provider.dart';
import '../providers/task_lists_provider.dart';
import '../theme/app_theme.dart';

/// Listd 2027 P6 command palette.
///
/// Opens via Ctrl + K. Search-driven launcher for navigation:
/// smart buckets, user lists, settings. Targets <100 ms perceived
/// open — pure widget, single TextField, ListView.builder over a
/// pre-computed list. No async work on open.
class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _controller.addListener(() {
      setState(() {
        _selectedIndex = 0;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _close() {
    ref.read(commandPaletteOpenProvider.notifier).state = false;
  }

  void _activate(_PaletteItem item) {
    final router = GoRouter.of(context);
    _close();
    if (item.route == '/settings') {
      // Settings is an overlay, not a route — open it directly.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(settingsOverlayOpenProvider.notifier).state = true;
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go(item.route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<ListdSurfaces>();
    final cardBg = surfaces?.panel ?? scheme.surface;

    final lists = ref.watch(taskListsNotifierProvider).valueOrNull ?? const [];
    final all = <_PaletteItem>[
      _PaletteItem(
        icon: PhosphorIcons.sun(),
        label: 'Today',
        route: '/today',
        section: 'Smart',
      ),
      _PaletteItem(
        icon: PhosphorIcons.tray(),
        label: 'Inbox',
        route: '/inbox',
        section: 'Smart',
      ),
      _PaletteItem(
        icon: PhosphorIcons.star(),
        label: 'Important',
        route: '/important',
        section: 'Smart',
      ),
      _PaletteItem(
        icon: PhosphorIcons.calendar(),
        label: 'Planned',
        route: '/planned',
        section: 'Smart',
      ),
      _PaletteItem(
        icon: PhosphorIcons.listChecks(),
        label: 'All Tasks',
        route: '/all',
        section: 'Smart',
      ),
      for (final l in lists)
        _PaletteItem(
          icon: PhosphorIcons.bookmark(),
          label: l.title,
          route: '/list/${l.id}',
          section: 'Lists',
        ),
      _PaletteItem(
        icon: PhosphorIcons.gearSix(),
        label: 'Settings',
        route: '/settings',
        section: 'System',
      ),
      _PaletteItem(
        icon: PhosphorIcons.folder(),
        label: 'Manage folders',
        route: '/folders',
        section: 'System',
      ),
    ];

    final query = _controller.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? all
        : all
              .where((i) => i.label.toLowerCase().contains(query))
              .toList(growable: false);

    if (_selectedIndex >= filtered.length) {
      _selectedIndex = filtered.isEmpty ? 0 : filtered.length - 1;
    }

    return Center(
      child: SizedBox(
        width: 540,
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Material(
            color: cardBg,
            elevation: 0,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 480),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant, width: 1),
                boxShadow: [surfaces?.shadowMd ?? const BoxShadow()],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.magnifyingGlass(),
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Shortcuts(
                            shortcuts: const {
                              SingleActivator(LogicalKeyboardKey.escape):
                                  _PaletteCloseIntent(),
                              SingleActivator(LogicalKeyboardKey.arrowDown):
                                  _PaletteDownIntent(),
                              SingleActivator(LogicalKeyboardKey.arrowUp):
                                  _PaletteUpIntent(),
                              SingleActivator(LogicalKeyboardKey.enter):
                                  _PaletteActivateIntent(),
                            },
                            child: Actions(
                              actions: <Type, Action<Intent>>{
                                _PaletteCloseIntent:
                                    CallbackAction<_PaletteCloseIntent>(
                                      onInvoke: (_) => _close(),
                                    ),
                                _PaletteDownIntent:
                                    CallbackAction<_PaletteDownIntent>(
                                      onInvoke: (_) {
                                        if (filtered.isEmpty) return null;
                                        setState(() {
                                          _selectedIndex =
                                              (_selectedIndex + 1) %
                                              filtered.length;
                                        });
                                        return null;
                                      },
                                    ),
                                _PaletteUpIntent:
                                    CallbackAction<_PaletteUpIntent>(
                                      onInvoke: (_) {
                                        if (filtered.isEmpty) return null;
                                        setState(() {
                                          _selectedIndex =
                                              (_selectedIndex -
                                                  1 +
                                                  filtered.length) %
                                              filtered.length;
                                        });
                                        return null;
                                      },
                                    ),
                                _PaletteActivateIntent:
                                    CallbackAction<_PaletteActivateIntent>(
                                      onInvoke: (_) {
                                        if (filtered.isEmpty) return null;
                                        _activate(filtered[_selectedIndex]);
                                        return null;
                                      },
                                    ),
                              },
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  height: 22 / 16,
                                  fontWeight: FontWeight.w500,
                                  color: scheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Jump to anything…',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 16,
                                    height: 22 / 16,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: scheme.outlineVariant),
                  Flexible(
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'No matches',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final isSelected = index == _selectedIndex;
                              return _PaletteRow(
                                item: item,
                                selected: isSelected,
                                onTap: () => _activate(item),
                                onHover: () {
                                  if (_selectedIndex != index) {
                                    setState(() {
                                      _selectedIndex = index;
                                    });
                                  }
                                },
                              );
                            },
                          ),
                  ),
                  Container(height: 1, color: scheme.outlineVariant),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '↑↓ navigate · ↵ open · Esc close',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 16 / 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteCloseIntent extends Intent {
  const _PaletteCloseIntent();
}

class _PaletteDownIntent extends Intent {
  const _PaletteDownIntent();
}

class _PaletteUpIntent extends Intent {
  const _PaletteUpIntent();
}

class _PaletteActivateIntent extends Intent {
  const _PaletteActivateIntent();
}

class _PaletteItem {
  const _PaletteItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.section,
  });

  final IconData icon;
  final String label;
  final String route;
  final String section;
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onHover,
  });

  final _PaletteItem item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onHover;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onHover: (_) => onHover(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 16,
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ),
              Text(
                item.section,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 14 / 11,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
