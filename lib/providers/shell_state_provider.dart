import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Listd 2027 P5 shell state.
///
/// `sidebarDrawerOpenProvider` — true when the hidden sidebar drawer
/// is summoned. Toggled by:
///
///  * Hover within 8 px of the left edge for 200 ms (sets `true`).
///  * Mouse leaving the drawer area (debounced; sets `false`).
///  * `Ctrl + \` keyboard shortcut (toggles).
///  * `Escape` (sets `false`).
final sidebarDrawerOpenProvider = StateProvider<bool>((ref) => false);
