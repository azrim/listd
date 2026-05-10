# Project Overview

Listd is a native Flutter to-do app for Linux desktop (cross-platform). Local-first
storage with background Supabase sync. Riverpod for state, Drift (SQLite) as the
UI source of truth, Supabase for auth + cloud, go_router for navigation.

> Backend is Supabase. Auth is Supabase OAuth via Google (identity only).
> Design language is the **2027 · Indigo Edition** — cool indigo + slate
> neutrals, amber-only stars, two typeface families (Inter + Newsreader),
> Phosphor icons, single spring with three calibrations (settle / flick /
> breathe), no glassmorphism. See "Design System" below.

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
├── screens/                         # Today, list view, smart buckets (Inbox/Important/Planned/All), Settings drawer, Auth
├── widgets/
│   ├── app_shell.dart               # Floating sidebar + canvas panels on the indigo backplate
│   ├── top_bar.dart                 # 44 px bar inside the canvas card (panel toggle + title + Search·⌘K + avatar)
│   ├── sidebar_drawer.dart          # 240 px floating sidebar — Ctrl+\ toggles, pill rows + count badges
│   ├── task_card.dart               # Single-Container morph between collapsed flat row and expanded bordered card
│   ├── task_action_rail.dart        # Right-hand metadata column inside the expanded card
│   ├── inline_edit_field.dart       # Transparent inline edit (title / notes / step text)
│   ├── task_list_panel.dart         # List header (caption + H1 + progress bar + count pill + ⋯) + capture row + TaskCards
│   ├── command_palette.dart         # Ctrl+K palette
│   ├── capture_sheet.dart           # Ctrl+N quick capture
│   ├── calendar_strip.dart          # 7-day strip on Today
│   ├── settings_overlay.dart        # 4-category settings drawer — only allowed BackdropFilter
│   ├── undo_toast.dart              # 6 s undo for delete/complete/list-delete
│   └── sync_status_pill.dart        # Synced / Syncing… / N pending / Sync failed
└── theme/
    ├── app_theme.dart               # ThemeData (light + dark) + ListdSurfaces / ListdMotion / ListdTypography ThemeExtensions
    ├── app_colors.dart              # AppColors tokens (indigo + slate + amber)
    ├── app_motion.dart              # AppMotion.settle / .flick / .breathe — three spring calibrations
    ├── app_density.dart             # DensityMode (cozy / compact) — task row + control heights
    ├── gradients.dart               # AppBackplate widget (the only allowed gradient)
    ├── spring.dart                  # ListdSpring.standard (legacy; identical to AppMotion.settle)
    └── text_styles.dart             # Inter + Newsreader text style helpers
```

Data flow: **UI ← Drift streams ← DAOs ← TaskSyncService ← Supabase**.
Mutations write Drift first (`syncStatus = created/updated/deleted`), then
`TaskSyncService.scheduleSync()` pushes them to Supabase in the background.

# Design System (2027 · Indigo Edition)

**Aesthetic:** cool, focused, layered. Floating cards sit on top of an indigo
backplate. Indigo is the only primary; amber is reserved for star glyphs.
Hierarchy is carried by **type, weight, and surface depth** — not bright
color.

**Allowed**:

- One ambient backplate (`AppBackplate`) — soft indigo radial gradient.
- One BackdropFilter (settings overlay only).
- Soft slate-tinted shadows (`shadowSm/Md/Lg` from `ListdSurfaces`).
- Layered floating surfaces: ambient → panel → canvas → card → chip.
- Single spring with three calibrations (`AppMotion.settle/.flick/.breathe`).

**Forbidden**:

- Hardcoded colors outside `lib/theme/app_colors.dart`.
- Multiple springs / curves outside `AppMotion`.
- Gradients other than `AppBackplate`.
- BackdropFilter outside the settings overlay.
- Material icons. Use `phosphor_flutter` everywhere.
- Any typeface other than Inter / Newsreader (via `google_fonts`).
- Accent override at the `ColorScheme.primary` level. Settings → Accent
  is preview-only; indigo is the fixed primary.

## Floating panel architecture

The app shell renders **two separate floating cards** on the indigo backplate:

- **Sidebar** — 240 px fixed, 20 px radius, 16 px outer gutters on top / left / bottom.
- **Canvas** — flexed, 20 px radius, 16 px outer gutters on top / right / bottom.
- 12 px gap between the two panels (backplate shows through).
- TopBar lives **inside** the canvas card (panel toggle + page title +
  Search·⌘K pill + avatar — title uses `Expanded` so search + avatar sit
  flush against the canvas edge).
- Both panels carry a soft `shadowSm` and a sub-1 px optical hairline at
  alpha 0.7 of `outlineVariant` so the panel edge reads against the
  backplate without framing.

## Surface stack

| Token       | Light       | Dark        | Use                                                |
| ----------- | ----------- | ----------- | -------------------------------------------------- |
| `ambient`   | `#F8FAFC`   | `#0B1224`   | Backplate (indigo radial drift)                    |
| `panel`     | `#F8FAFC`   | `#0F172A`   | Sidebar floating card                              |
| `canvas`    | `#FFFFFF`   | `#0F172A`   | Right-hand floating card (page background)         |
| `card`      | `#FFFFFF`   | `#1E293B`   | Expanded task card — 14 px radius                  |
| `chip`      | `#F1F5F9`   | `#334155`   | Tag / chip / pill / hover overlay — 999 px radius  |

Per `mockups/png/02_today_dark.png`, **`panel ≡ canvas` in BOTH modes** —
the sidebar and the right-hand canvas are the same surface, and a 1 px
`outlineVariant` hairline + the floating-card shadow do all the
separation. Dark mode collapses to four stops (ambient → panel = canvas
→ card → chip); the expanded task card's bordered-card silhouette is
carried by the 2 px indigo border + `shadowMd`, not a brightness step
over the canvas it sits on. The sync pill lifts onto `surfaces.card` so
it pops one stop above the panel/canvas it lives on.

## Color tokens

| Token              | Light       | Dark        | Use                                       |
| ------------------ | ----------- | ----------- | ----------------------------------------- |
| `indigo` (primary) | `#4F46E5`   | `#7376F8`   | Selection, focus ring, expanded border    |
| `indigoSoft`       | `#EEF2FF`   | `#1E1B4B`   | Selected row fill, today date cell        |
| `amber`            | `#FBBF24`   | `#FCD34D`   | Star fill / star glyph only               |
| `text-primary`     | `#0F172A`   | `#F8FAFC`   | Titles, body                              |
| `text-secondary`   | `#64748B`   | `#94A3B8`   | Meta, captions, action-rail placeholders  |
| `text-tertiary`    | `#94A3B8`   | `#64748B`   | Disabled, italic placeholders             |
| `border`           | `#E2E8F0`   | `#334155`   | 1 px hairlines (alpha 0.6–0.7 in use)     |
| `divider`          | `#F1F5F9`   | `#1E293B`   | `outlineVariant` — topbar bottom, row dividers |

`outlineVariant` maps to `divider` — light `slate-100`, dark `slate-800`.
`outline` maps to `border` — light `slate-200`, dark `slate-700`.
Structural borders (panels, overlays, cards) use `outline` (border);
row separators and hairlines use `outlineVariant` (divider).

| Functional | Light       | Dark        | Use                                |
| ---------- | ----------- | ----------- | ---------------------------------- |
| `success`  | `#10B981`   | `#34D399`   | "Synced" pill dot only             |
| `warning`  | `#F59E0B`   | `#FBBF24`   | "N pending" pill dot only          |
| `error`    | `#DC2626`   | `#F87171`   | "Sync failed" pill dot only        |

Functional colors are scoped to **6 px state-pill dots only**. They never
appear on type, selection, or backgrounds.

## Type ramp

Two faces (Inter + Newsreader), weights 400 / 500 / 600 / 700. Newsreader
appears in only three places: Today headline, empty states, About quote.

| Role            | Family     | Size | Line | Weight | Tracking |
| --------------- | ---------- | ---- | ---- | ------ | -------- |
| Display Serif   | Newsreader | 40   | 48   | 500    | -0.02 em |
| H1              | Inter      | 22   | 30   | 700    | -0.02 em |
| H2              | Inter      | 18   | 26   | 600    | -0.01 em |
| Body            | Inter      | 15   | 22   | 400    | 0        |
| Body emphasized | Inter      | 15   | 22   | 500    | 0        |
| Meta            | Inter      | 13   | 18   | 400    | 0        |
| Caption         | Inter      | 11   | 16   | 600    | 0.06 em  |

## Component metrics (4 px grid: 4, 8, 12, 16, 24, 32, 48, 64)

- Control height (button, input, sync pill): **36 px**.
- TaskCard collapsed: **56 px** (cozy) / **44 px** (compact). Expanded: **200–400 px**.
- Sidebar width: **240 px** fixed. TopBar height: **40 px**.
- Control radius: **10 px**.
- Card radius: **14 px** (fully expanded; collapsed task row is flush so no radius).
- Panel / canvas radius: **20 px**.
- Chip / pill radius: **999 px**.
- Settings overlay: **560 × 640 px**.
- Border: 1 px on `border` / `divider` (rendered at alpha 0.6–0.7).
- Selected row: indigo-soft fill + 2 px indigo left bar (mailbox style).
- Expanded card: 2 px indigo border on all 4 sides + soft `shadowMd`.
- Focus ring: 2 px indigo (used by inline edit fields when focused).

## Task card morph

The collapse ↔ expand transition uses a **single** AnimationController `t`
(0 → 1) and **a single Container with a single 4-sided Border**. Every visual
property — fill, border color per side, border width per side, radius, outer
padding, shadow — interpolates on the same `t`. There is **no** discrete
render switch at any value of `t`, so the silhouette morphs continuously
between collapsed-flat (no padding, no border, transparent / hover /
indigo-soft fill, alpha-0.6 hairline bottom + optional 2 px indigo left bar
on selection) and expanded-card (12/8 padding, 1.5 px indigo on all sides,
16 px radius, `shadowMd`, `cardBg` fill).

## Inline edit fields

`InlineEditField` powers task title, notes, list name, step text. The
field renders **transparently** on whatever surface it sits on — only the
underline carries the affordance:

- Rest underline: **alpha 0.6** of `outlineVariant`, 1 px.
- Hover underline: solid `onSurfaceVariant`, 1 px.
- Focus underline: **2 px indigo** (`primary`).
- Italic placeholder in `text-tertiary` slate.

The field explicitly overrides the global `inputDecorationTheme` to force
`filled: false`, `fillColor: transparent`, `hoverColor: transparent`,
`focusColor: transparent`. Without this override the theme's default
`fillColor: scheme.surface` would paint every field as a darker rectangle
inside the expanded card and bleed the card's `InkWell` hover into all
fields at once.

## Motion — single spring, three calibrations

| Calibration         | Mass | Stiffness | Damping | Settle  | Use                                |
| ------------------- | ---- | --------- | ------- | ------- | ---------------------------------- |
| `AppMotion.settle`  | 1.0  | 280       | 28      | ~220 ms | Default state changes, hover/select |
| `AppMotion.flick`   | 1.0  | 380       | 30      | ~160 ms | Tap feedback, checkbox toggle       |
| `AppMotion.breathe` | 1.0  | 180       | 24      | ~320 ms | Sheet / drawer enter, settings      |

`ListdSpring.standard` is the legacy alias and is identical to `AppMotion.settle`.
Reduced motion (`MediaQuery.disableAnimations`) collapses every duration
to `Duration.zero`. Never invent a new curve.

```dart
import '../theme/app_motion.dart';

final duration = AppMotion.durationFor(context, AppMotion.settle);
```

## Backplate

The single allowed gradient lives behind everything as `AppBackplate`
(`lib/theme/gradients.dart`). It renders soft radial corners on the ambient
base color. The corner alphas drift subtly with the time of day (warmer in
the morning, cooler in the evening) — this is the only place ambient color
is allowed to move. Settings → Backplate has a "Time-of-day drift" toggle
that disables the drift to keep a static gradient.

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
tests, build. There are also two grep-based gates: `BackdropFilter` must
appear exactly **1** time in `lib/` (the settings overlay), and any old
`AppGradients` symbol should be **0** results.

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
- Follow the 2027 Indigo Edition design system above. Use
  `Theme.of(context).colorScheme` and the `ListdSurfaces` /
  `ListdMotion` / `ListdTypography` ThemeExtensions; do NOT hardcode colors.
- Use `GoogleFonts.inter(...)` / `GoogleFonts.newsreader(...)` — or just lean
  on the TextTheme. No other typefaces.
- Use `phosphor_flutter` for icons — no Material icons.
- Stick to the 4 px grid: 4, 8, 12, 16, 24, 32, 48, 64.
- Selection / focus pattern: indigo-soft fill + 2 px indigo bar (collapsed),
  1.5 px indigo border (expanded card), 2 px indigo focus ring (inputs).
- Inline edit fields: use `InlineEditField` from `lib/widgets/`. It already
  forces `filled: false` and renders only the underline.
- All screens must handle AsyncValue loading/error/data states from Riverpod.
- Animations: import `lib/theme/app_motion.dart` and use one of
  `AppMotion.settle/.flick/.breathe`. The legacy `ListdSpring.standard`
  is identical to `AppMotion.settle`. Never invent a new curve.
- BackdropFilter is forbidden everywhere except the settings overlay.
  CI's pre-merge gate enforces exactly 1 BackdropFilter in `lib/`.
- Target is Linux desktop — verify on the Linux renderer.
- Mockups for the 2027 layout live in `docs/redesign/2027-indigo/mockups/`.
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

The 2027 redesign shipped across 7 phases on the `redesign/2027` umbrella branch
and squash-merged back into `feature/supabase`. The 2026 hairline layer (legacy
`SidebarPanel`, `TaskDetailPanel`, `_TaskRow`, `GlassCard`, `GlassTextField`,
`GradientButton`, the `use2027Cards` feature flag, and the `task_lists_screen` /
`planned_screen` v1 sweep) was deleted afterwards.

Following that, the 2027 surface was migrated from the original warm-neutrals
palette (flame + oat) to the **2027 · Indigo Edition** described above
(indigo + slate + amber). The Indigo Edition shipped as PRs D-1 through D-6
on `feature/supabase`:

- **PR D-1** — Initial Indigo token swap.
- **PR D-2** — Drop outer card / restructure smart buckets to render directly on canvas.
- **PR D-3** — Floating sidebar + canvas panels on backplate (foundation).
- **PR D-4** — Task card polish (border thickness, tag chips, "saves automatically" footer).
- **PR D-5** — Inline-field hover transparency + topbar layout + text contrast bump + softer hairlines.
- **PR D-6** — Single-Container task card morph (no more "square for a millisec") + dark-mode 5-layer surface hierarchy + visible inline-field rest underline.
