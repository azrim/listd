# Project Overview

Listd is a native Flutter to-do app for Linux desktop (cross-platform). Local-first
storage with background Supabase sync. Riverpod for state, Drift (SQLite) as the
UI source of truth, Supabase for auth + cloud, go_router for navigation.

> Backend is Supabase. Auth is Supabase OAuth via Google (identity only).
> Design language is the **2027 · Indigo Edition** — cool indigo + slate
> neutrals, amber-only stars, single typeface family pair (Inter + Newsreader),
> Phosphor icons, three motion calibrations on a single spring (settle / flick
> / breathe), no glassmorphism. See "Design System" below and the canonical
> spec under `docs/redesign/2027-indigo/`.

# Architecture

```
lib/
├── main.dart                        # App entry — Supabase init + AppBackplate wrap
├── config/
│   └── app_config.dart              # --dart-define wrapper (Supabase URL/anon, Google client ID, redirect URL)
├── models/                          # Domain models (Task, TaskList, TaskStep, RepeatConfig, …)
├── data/
│   └── database/                    # Drift local SQLite — source of truth for the UI
│       ├── daos/                    # Data Access Objects (with watch streams + pending-count queries)
│       └── tables/                  # Table definitions (sync_status, deleted_at on every row)
├── providers/                       # Riverpod state (UI watches Drift via these)
├── router/                          # go_router configuration
├── services/
│   ├── auth/
│   │   ├── google_auth_service.dart # Delegates to Supabase signInWithOAuth
│   │   ├── token_manager.dart       # Thin wrapper — Supabase manages tokens
│   │   └── secure_storage_service.dart # Stub — Supabase handles storage
│   ├── supabase/
│   │   └── supabase_client_service.dart # SupabaseClientService + supabaseClientProvider
│   ├── tasks/
│   │   └── supabase_tasks_provider.dart # ITaskProvider impl via Supabase
│   └── sync/
│       └── task_sync_service.dart   # Drift ↔ Supabase background sync (debounced push + pull)
├── screens/                         # Screens — Today, List, Inbox, Settings drawer, Auth
├── widgets/
│   ├── app_shell.dart               # Top bar + side drawer + overlay mounts
│   ├── top_bar.dart                 # 40 px bar — drawer toggle + active page title
│   ├── sidebar_drawer.dart          # 280 px overlay drawer, Ctrl+\ toggles, sync pill in footer
│   ├── task_card.dart               # Expand-in-place card with InlineEditField + steps progress bar
│   ├── task_list_panel.dart         # List header + capture input + TaskCard list
│   ├── command_palette.dart         # Ctrl+K palette
│   ├── capture_sheet.dart           # Ctrl+N quick capture (reserves AI suggestion slot)
│   ├── calendar_strip.dart          # Horizontal date track on Today
│   ├── settings_overlay.dart        # 560 px side drawer — opaque, no BackdropFilter
│   ├── undo_toast.dart              # 6 s undo for delete/complete/list-delete
│   ├── inline_edit_field.dart       # Hairline-rest / 2 px-focus underline editor
│   ├── empty_state.dart             # Single reusable empty-state component
│   └── sync_status_pill.dart        # Synced / Syncing… / N pending / Sync failed
└── theme/
    ├── app_theme.dart               # ThemeData (light + dark) + 3 ThemeExtensions
    ├── app_colors.dart              # AppColors tokens (indigo + slate + amber)
    ├── app_motion.dart              # ListdMotion — settle / flick / breathe calibrations
    ├── app_density.dart             # DensityMode (cozy / compact)
    ├── gradients.dart               # AppBackplate widget (the only allowed gradient)
    └── spring.dart                  # ListdSpring — single canonical spring physics
```

Data flow: **UI ← Drift streams ← DAOs ← TaskSyncService ← Supabase**.
Mutations write Drift first (`syncStatus = created/updated/deleted`), then
`TaskSyncService.scheduleSync()` pushes them to Supabase in the background.

# Design System (2027 · Indigo Edition)

**Aesthetic:** quiet, focused, layered. Surfaces stack like islands on an
ambient indigo-tinted backplate. One vibrant accent (indigo-600 in light /
indigo-400 in dark), amber reserved entirely for stars, slate neutrals
everywhere else. Hierarchy is carried by **type, weight, and surface depth** —
not bright color. The full canonical spec lives in
`docs/redesign/2027-indigo/` (00–06).

**Allowed**:

- One ambient backplate (`AppBackplate`).
- Layered surfaces: ambient → canvas → panel → card → chip.
- Soft slate-tinted shadows (`shadowSm/Md/Lg` from `ListdSurfaces`).
- One spring with three calibrations (`AppMotion.settle / flick / breathe`).

**Forbidden**:

- Hardcoded colors outside `lib/theme/app_colors.dart`.
- Gradients other than `AppBackplate` (CI gate `grep -R 'AppGradients' lib/` → 0).
- BackdropFilter anywhere (CI gate `grep -R 'BackdropFilter' lib/` → 0; the
  settings drawer uses an opaque scrim, not a blur).
- Material icons. Use `phosphor_flutter` everywhere.
- Manrope, Space Grotesk, or any typeface other than Inter / Newsreader.
- Multiple springs / curves. There is one spring with three calibrations.
- Deprecated 2027-warm tokens (`flameSoft`, `oat`, `oatSoft`, `warmCream`).
  CI gate: `grep -R 'flameSoft\|oat\|warmCream' lib/` → 0.

## Surface stack

| Token       | Light       | Dark        | Use                                          |
| ----------- | ----------- | ----------- | -------------------------------------------- |
| `ambient`   | `#F8FAFC`   | `#020617`   | Backplate behind everything (`AppBackplate`) |
| `canvas`    | `#FFFFFF`   | `#0F172A`   | Page background — 16 px radius "island"      |
| `panel`     | `#F8FAFC`   | `#0F172A`   | Sidebar drawer, settings drawer              |
| `card`      | `#FFFFFF`   | `#1E293B`   | Task card — 12 px radius                     |
| `chip`      | `#F1F5F9`   | `#334155`   | Tag / chip / pill — 999 px radius            |

## Color tokens

| Token              | Light       | Dark        | Use                            |
| ------------------ | ----------- | ----------- | ------------------------------ |
| `indigo` (primary) | `#4F46E5`   | `#7376F8`   | Selection, focus ring, primary |
| `indigoSoft`       | `#EEF2FF`   | `#1E1B4B`   | Selected row fill, today cell  |
| `amber` (star)     | `#FBBF24`   | `#FCD34D`   | Star fill / star glyph only    |
| `text-primary`     | `#0F172A`   | `#F8FAFC`   | Titles, body                   |
| `text-secondary`   | `#64748B`   | `#94A3B8`   | Meta, captions                 |
| `text-tertiary`    | `#94A3B8`   | `#64748B`   | Placeholder, disabled          |
| `border`           | `#E2E8F0`   | `#334155`   | 1 px hairlines                 |
| `divider`          | `#F1F5F9`   | `#1E293B`   | List separators                |

| Functional | Light       | Dark        | Use                       |
| ---------- | ----------- | ----------- | ------------------------- |
| `success`  | `#10B981`   | `#34D399`   | "Synced" pill dot only    |
| `warning`  | `#F59E0B`   | `#FBBF24`   | "N pending" pill dot only |
| `error`    | `#EF4444`   | `#F87171`   | "Sync failed" pill dot only |

Functional colors are scoped to **6 px state-pill dots only**. They never appear
on type, selection, or backgrounds.

## Type ramp

Two faces, weights 400 / 500 / 600 / 700. Newsreader appears in only three
places: Today headline, empty states, About quote.

| Role            | Family     | Size | Line | Weight | Tracking |
| --------------- | ---------- | ---- | ---- | ------ | -------- |
| Display Serif   | Newsreader | 36   | 44   | 500    | -0.02 em |
| H1              | Inter      | 24   | 32   | 700    | -0.02 em |
| H2              | Inter      | 18   | 26   | 600    | -0.01 em |
| Body            | Inter      | 15   | 22   | 400    | 0        |
| Body emphasized | Inter      | 15   | 22   | 500    | 0        |
| Meta            | Inter      | 13   | 18   | 400    | 0        |
| Caption         | Inter      | 11   | 16   | 600    | 0.06 em  |

## Component metrics (4 px grid: 4, 8, 12, 16, 24, 32, 48, 64)

- Control height (button, input, sync pill): **36 px**
- TaskCard collapsed: **56 px** (cozy) / **44 px** (compact); expanded: **200–400 px**
- Sidebar drawer width: **280 px**, top bar: **40 px**, settings drawer: **560 px**
- Control radius: **12 px**
- Card radius: **12 px**
- Panel / canvas radius: **16 px**
- Chip / pill radius: **999 px**
- Border: 1 px on `border` / `divider`. Focus ring: 2 px `indigo`.
- Density: `cozy` (default, 56/36/36) and `compact` (44/32/32) via `DensityMode`.

## Motion — single spring, three calibrations

Defined in `lib/theme/app_motion.dart` as `AppMotion`. All UI transitions pick
one of these three presets — never invent a new curve.

| Calibration | Mass | Stiffness | Damping | Settles | Use                              |
| ----------- | ---- | --------- | ------- | ------- | -------------------------------- |
| `settle`    | 1.0  | 280       | 28      | 220 ms  | Default — card expand, pickers   |
| `flick`     | 1.0  | 380       | 30      | 160 ms  | Light affordances (pill, chip)   |
| `breathe`   | 1.0  | 180       | 24      | 320 ms  | Heavy surfaces (drawer, sheets)  |

Reduced motion (`MediaQuery.disableAnimations`) → `Duration.zero` for all of
the above. A single component must never use two springs — if it does, it's
doing two jobs.

```dart
import '../theme/app_motion.dart';

final duration = AppMotion.settle.durationFor(context);
final curve = AppMotion.settle.curve;
```

## Backplate

The single allowed gradient lives behind everything as `AppBackplate` (in
`lib/theme/gradients.dart`). It renders two soft radial corners on the ambient
slate base color. The corner alphas drift subtly with the time of day —
this is the only place ambient color is allowed to move.

# Commands

| Command                       | Purpose                |
| ----------------------------- | ---------------------- |
| `flutter pub get`             | Get dependencies       |
| `flutter run -d linux`        | Run on Linux desktop   |
| `flutter analyze --fatal-infos` | Static analysis (CI gate) |
| `dart format .`               | Format Dart sources    |
| `flutter test`                | Run tests              |
| `flutter build linux`         | Build Linux executable |
| `dart run build_runner build` | Regenerate Drift / Riverpod files |

CI runs the same gates on every PR: format check, analyze with fatal-infos,
tests, build. The indigo redesign adds three pre-merge greps:

- `AppGradients` → 0 results in `lib/`
- `BackdropFilter` → 0 results in `lib/` (no glassmorphism)
- `flameSoft|oat|warmCream` → 0 results in `lib/` (no warm tokens)

# Key Dependencies

```yaml
supabase_flutter: ^2.3.0
flutter_riverpod: ^2.x
riverpod_annotation: ^2.x
drift: ^2.x
go_router: ^14.x
google_fonts: ^6.x        # Inter + Newsreader
phosphor_flutter: ^2.0.0  # icons (Phosphor regular, 1.5 px stroke)
shared_preferences: ^2.x
flutter_animate: ^4.5.0
flutter_local_notifications: ^17.x
reorderables: ^0.6.0      # drag-reordering tasks
```

# Supabase Setup

Database tables: `task_lists`, `tasks` — both with Row Level Security per `user_id`.
Auth: Google OAuth via Supabase (scopes: `openid email profile` only).
Redirect URL: `io.listd://login-callback`.
Configuration is supplied via `--dart-define`; the app fails fast at startup if
any are missing. See `lib/config/app_config.dart`:

- `AppConfig.supabaseUrl`
- `AppConfig.supabaseAnonKey`
- `AppConfig.googleClientId`

<important if="you are adding or modifying database schema">
- Drift is the UI source of truth — modify lib/data/database/tables/.
- After schema changes run: `dart run build_runner build --delete-conflicting-outputs`.
- Never modify *.g.dart files directly.
- Bump the schema version in lib/data/database/app_database.dart.
- Mirror any Drift schema changes in Supabase SQL editor too (and add a
  migration under supabase/migrations/). Supabase migrations ship BEFORE the
  Flutter PR merges.
- Every row carries `sync_status` (clean/created/updated/deleted) and
  `deleted_at`. Mutations must update these so TaskSyncService can pick them up.
</important>

<important if="you are implementing authentication flows">
- Auth is fully delegated to Supabase — do NOT write manual PKCE.
- Google OAuth via: `client.auth.signInWithOAuth(OAuthProvider.google)`.
- Auth state via: `client.auth.onAuthStateChange` stream.
- Current user: `client.auth.currentUser`.
- Token refresh is automatic — do not manage tokens manually.
</important>

<important if="you are adding new UI screens or widgets">
- Follow the 2027 · Indigo Edition design system above. Use
  `Theme.of(context).colorScheme` and the `ListdSurfaces` / `ListdMotion` /
  `ListdTypography` ThemeExtensions; do NOT hardcode colors.
- Use `GoogleFonts.inter(...)` / `GoogleFonts.newsreader(...)` — or just lean
  on the TextTheme. No other typefaces.
- Use `phosphor_flutter` for icons — no Material icons.
- Stick to the 4 px grid: 4, 8, 12, 16, 24, 32, 48, 64.
- Selection / focus pattern: `indigoSoft` fill + 2 px `indigo` ring.
- Inline-editable text fields use `InlineEditField` (hairline-rest / 2 px
  indigo focus underline). Never roll a `TextField` for title / notes / step /
  list-name editing.
- Empty surfaces use the `EmptyState` widget (icon / headline / body / CTA).
  Never hand-roll an empty layout.
- All screens must handle AsyncValue loading/error/data states from Riverpod.
- Animations: import `lib/theme/app_motion.dart` and pick `AppMotion.settle`,
  `AppMotion.flick`, or `AppMotion.breathe`. One spring everywhere — never
  invent a new curve.
- BackdropFilter is forbidden everywhere. The settings drawer slides in over
  an opaque slate scrim, not a blurred backdrop.
- Target is Linux desktop — verify on the Linux renderer.
</important>

<important if="you are modifying the task data layer">
- ITaskProvider interface must never change.
- SupabaseTasksProvider in lib/services/tasks/ implements ITaskProvider.
- Always filter by user_id: `client.auth.currentUser!.id`.
- Map PostgrestException(code: 401) → UnauthorizedException.
- Map other PostgrestException → ServerException.
- Mutations should write Drift first, then call TaskSyncService.scheduleSync().
</important>

# History

The original 2026 hairline redesign and 2027 warm-flame redesign are both
retired. The active code path is the **2027 · Indigo Edition**, shipped in
three sequential PRs off `feature/supabase`:

- **PR A — Tokens.** OKLCH-derived indigo / slate / amber palette,
  `AppMotion` calibrations, `DensityMode`, indigo `AppBackplate`.
- **PR B — Surfaces.** Top bar shows the active page title, sidebar drawer
  hosts the single sync pill, calendar strip becomes a horizontal date track,
  settings overlay becomes an opaque side drawer (no `BackdropFilter`),
  list-panel header gets a caption + H1 + progress bar.
- **PR C — Editor + empty states.** `InlineEditField` for titles / notes /
  steps / list names, indigo Complete pill with a steps progress bar, single
  reusable `EmptyState`, capture sheet reserves an AI suggestion slot, About
  pane added to the settings drawer. All deprecated warm tokens removed.

The canonical spec lives under `docs/redesign/2027-indigo/`.
