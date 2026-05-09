# 06 · Migration plan

A concrete file-by-file path from current `azrim/listd@main` to the
indigo system. Designed so the **next** PR is mechanical and minimally
risky.

## Strategy

Three small PRs in sequence, not one big one:

1. **PR A · Tokens.** Replace `app_colors.dart`, add
   `app_motion.dart`, update `app_theme.dart`. Zero widget code touched.
   The whole app turns indigo overnight (warm tokens still resolve
   via the back-compat aliases CLAUDE.md mentions). Visual diff is the
   regression-test target.
2. **PR B · Surface fixes.** Top bar, sidebar, calendar track, settings
   drawer. Each surface is a self-contained widget so each can be
   reviewed independently within the PR.
3. **PR C · Inline editor + empty states.** TaskCard expanded view,
   inline-editable field, empty-state component. This is the
   highest-judgment PR; it intentionally goes last so the rest of the
   app is already on the new tokens.

## PR A — Tokens (mechanical)

### `lib/theme/app_colors.dart`

Replace the entire file. New structure:

```dart
class AppColors {
  AppColors._();

  // Indigo scale (primary)
  static const Color indigo50  = Color(0xFFF0F1FF);
  static const Color indigo100 = Color(0xFFE0E2FF);
  static const Color indigo200 = Color(0xFFC2C5FF);
  static const Color indigo300 = Color(0xFFA0A2FA);
  static const Color indigo400 = Color(0xFF7376F8);
  static const Color indigo500 = Color(0xFF5A52E8);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo700 = Color(0xFF4338CA);
  static const Color indigo800 = Color(0xFF3730A3);
  static const Color indigo900 = Color(0xFF312E81);
  static const Color indigo950 = Color(0xFF1E1B4B);

  // Slate scale (neutrals — cool, indigo-tinted)
  static const Color slate50  = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF0B1224);

  // Amber (single co-accent — stars only)
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);

  // Functional (state-pill dots only)
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFF87171);

  // ── Light scheme ────────────────────────────────────────
  static final ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: indigo600,
    onPrimary: Colors.white,
    primaryContainer: indigo50,
    onPrimaryContainer: indigo700,
    secondary: amber400,
    onSecondary: indigo950,
    secondaryContainer: Color(0xFFFEF3C7),
    onSecondaryContainer: Color(0xFF78350F),
    tertiary: slate500,
    onTertiary: Colors.white,
    tertiaryContainer: slate100,
    onTertiaryContainer: slate700,
    error: error,
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Colors.white,
    onSurface: slate900,
    onSurfaceVariant: slate500,
    outline: slate200,
    outlineVariant: slate100,
    shadow: Color(0xFF0F172A),
    scrim: Color(0xFF0F172A),
    inverseSurface: slate900,
    onInverseSurface: slate50,
    inversePrimary: indigo300,
  );

  static final ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: indigo400,
    onPrimary: indigo950,
    primaryContainer: Color.fromRGBO(49, 46, 129, 0.4), // indigo900 @ 40%
    onPrimaryContainer: indigo200,
    secondary: amber300,
    onSecondary: indigo950,
    secondaryContainer: Color(0xFF422006),
    onSecondaryContainer: Color(0xFFFCD34D),
    tertiary: slate400,
    onTertiary: slate950,
    tertiaryContainer: slate800,
    onTertiaryContainer: slate200,
    error: errorDark,
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFF991B1B),
    onErrorContainer: Color(0xFFFECACA),
    surface: slate900,
    onSurface: slate50,
    onSurfaceVariant: slate400,
    outline: slate700,
    outlineVariant: slate800,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: slate50,
    onInverseSurface: slate900,
    inversePrimary: indigo700,
  );
}
```

The deprecated names (`flame`, `flameSoft`, `oat`, `oatSoft`, etc.)
ship as **deprecated aliases** in this PR pointing at indigo
equivalents:

```dart
@Deprecated('Use ColorScheme.primary')
static const Color flame = indigo600;
@Deprecated('Use ColorScheme.primaryContainer')
static const Color flameSoft = indigo50;
@Deprecated('Use ColorScheme.tertiary')
static const Color oat = slate500;
@Deprecated('Use ColorScheme.surfaceContainerHigh')
static const Color oatSoft = slate100;
```

Linter will flag every call site; PR B/C clean them up.

### `lib/theme/app_theme.dart`

- `controlRadius`: `12` → `10`
- `cardRadius`: `16` → `14`
- Everything else stays the same; the new scheme drives the visual.

### Add `lib/theme/app_motion.dart`

See the implementation block in `04_motion.md`. Move the existing
`spring.dart` body inside this file and re-export so existing imports
break loudly (or alias for one PR cycle).

### Add `lib/theme/app_density.dart`

```dart
enum DensityMode { cozy, compact }

class AppDensity {
  AppDensity._();

  static double rowTask(DensityMode m) => m == DensityMode.cozy ? 56 : 44;
  static double rowNav(DensityMode m) => m == DensityMode.cozy ? 36 : 32;
  static double control(DensityMode m) => m == DensityMode.cozy ? 36 : 32;
  static double gapList(DensityMode m) => m == DensityMode.cozy ? 12 : 8;
  static double gapSections(DensityMode m) => m == DensityMode.cozy ? 16 : 12;
  static EdgeInsets canvasPadding(DensityMode m) =>
      m == DensityMode.cozy
          ? const EdgeInsets.symmetric(horizontal: 32, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
}
```

Wire to a Riverpod provider (`densityModeProvider`) seeded from
`shared_preferences`. The toggle in Settings → Appearance writes back.

### `lib/theme/gradients.dart` (`AppBackplate`)

Update the four backplate stops:

```dart
static const Color ambientLightStartTopLeft = Color(0xFFE0E2FF); // indigo100
static const Color ambientLightStartBottomRight = Color(0xFFF0ABFC); // pink-300, very faint
static const Color ambientDarkStartTopLeft = Color(0xFF312E81); // indigo900
static const Color ambientDarkStartBottomRight = Color(0xFF1E293B); // slate800
```

Keep the time-of-day drift logic.

## PR B — Surfaces

| Touch | File | Change |
| --- | --- | --- |
| Top bar | `lib/widgets/top_bar.dart` | Drop "Listd" pill; show active page title; avatar moves right |
| Sidebar | `lib/widgets/sidebar_drawer.dart` | Drop account block; drop bottom Sign-out; drop one of the two sync pills |
| Sync pill | `lib/widgets/sync_status_pill.dart` | Single instance only — sidebar bottom, full width |
| Calendar | `lib/widgets/calendar_strip.dart` | Replace cell grid with horizontal date track |
| Settings | `lib/widgets/settings_overlay.dart` | Modal → side drawer (right). Remove BackdropFilter. |
| List header | `lib/widgets/task_list_panel.dart` | Add caption above name; H1 22 px; progress bar |

CI gates after PR B:

```bash
grep -R 'BackdropFilter' lib/   # → 0
grep -R 'AppGradients\b' lib/   # → 0
```

## PR C — Editor + empty states

| Touch | File | Change |
| --- | --- | --- |
| Task card | `lib/widgets/task_card.dart` | New collapsed/expanded styling; progress bar; deleted styling |
| Inline edit | new `lib/widgets/inline_edit_field.dart` | hairline-rest / 2-px-focus underline component |
| Step row | `lib/widgets/task_step_row.dart` | Use inline-edit field; drag handle hover-reveal |
| Empty state | new `lib/widgets/empty_state.dart` | One component; per-surface props |
| Capture | `lib/widgets/capture_sheet.dart` | AI-suggestion slot reservation |

Final CI gates:

```bash
flutter analyze --fatal-infos
dart format --output=none --set-exit-if-changed .
flutter test
grep -R 'flameSoft\|oat\|warmCream' lib/   # → 0 (no deprecated tokens left)
```

## Asset additions

- `assets/fonts/Inter-Variable.ttf` (replace static cuts)
- `assets/fonts/Newsreader-Variable.ttf` (replace static cuts)
- No new icons — Phosphor already covers the entire surface.

## Things explicitly *not* changing

- Sync engine, Drift schema, Riverpod state shape: untouched.
- Routing structure: untouched.
- The existing right-click context menu (PR #22): visual update only.
- Density-bar work (PR #23): we re-use; this redesign formalizes the modes as `DensityMode` enum.
- The ambient `AppBackplate` widget: tokens shift, gradient logic stays.
