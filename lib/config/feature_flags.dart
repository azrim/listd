/// Feature flags for the Listd 2027 redesign.
///
/// These are compile-time constants — Dart's tree-shaker drops the
/// inactive branch entirely when the flag is `false` so there's no
/// runtime cost to keeping legacy code around behind a flag.
///
/// Flags graduate from `false` → `true` as each phase lands and ship
/// for one release before the dead code is deleted.
class FeatureFlags {
  FeatureFlags._();

  /// 2027 P3: render the warm, rounded TaskCard with inline expand
  /// instead of the legacy 44 px `_TaskRow` + 360 px inspector pane.
  ///
  /// When `true`:
  ///  - HomeScreen renders 2 columns (sidebar + list); inspector is
  ///    not mounted.
  ///  - TaskListPanel uses TaskCard for every row.
  ///  - Tapping a card expands it inline; one card is expanded at a
  ///    time, controlled by `expandedTaskIdProvider`.
  static const bool use2027Cards = true;
}
