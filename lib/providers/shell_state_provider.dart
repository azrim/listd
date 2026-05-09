import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Listd 2027 · Indigo Edition shell state.
///
/// `sidebarDrawerOpenProvider` — true when the sidebar is visible.
/// Per the indigo mockups (`docs/redesign/2027-indigo/mockups/`) the
/// sidebar is permanently docked against the left edge on desktop,
/// so this defaults to **`true`**. `Ctrl + \` toggles it for users
/// who want a chrome-free canvas.
final sidebarDrawerOpenProvider = StateProvider<bool>((ref) => true);
