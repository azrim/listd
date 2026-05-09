import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Listd 2027 P6 overlay state.
///
/// `captureSheetOpenProvider` — true when the Ctrl + N capture sheet
/// is mounted.
/// `commandPaletteOpenProvider` — true when the Ctrl + K palette is
/// mounted.
///
/// Only one is shown at a time; opening one closes the other.
final captureSheetOpenProvider = StateProvider<bool>((ref) => false);
final commandPaletteOpenProvider = StateProvider<bool>((ref) => false);

/// `settingsOverlayOpenProvider` — true when the 560 × 640 settings
/// modal is mounted on top of the canvas (the only blurred backdrop
/// in the codebase).
final settingsOverlayOpenProvider = StateProvider<bool>((ref) => false);
