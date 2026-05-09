# Project Overview

Listd is a native Flutter to-do app for Linux desktop (cross-platform). Local-first
storage with background Supabase sync. Riverpod for state, Drift (SQLite) as the
UI source of truth, Supabase for auth + cloud, go_router for navigation.

> Backend is Supabase. Auth is Supabase OAuth via Google (identity only).
> Design language is the **2027 Listd system** — warm neutrals, layered surfaces,
> two accents (flame + oat), one typeface family pair (Inter + Newsreader),
> Phosphor icons, single spring everywhere. See "Design System" below.

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
├── screens/                         # Screens — Today (P4), List, Inbox, Settings overlay (P7), Auth
├── widgets/
│   ├── task_card.dart               # 2027 expand-in-place card (P3) — replaces _TaskRow + inspector
│   ├── command_palette.dart         # Ctrl+K palette (P6)
│   ├── capture_sheet.dart           # Ctrl+N quick capture (P6)
│   ├── calendar_strip.dart          # 7-day strip on Today (P4)
│   ├── sidebar_drawer.dart          # Hidden drawer + top bar (P5)
│   ├── sync_status_pill.dart        # Synced / Syncing… / N pending / Sync failed
│   ├── glass_card.dart              # @Deprecated alias — wraps the 2027 card primitive
│   ├── glass_text_field.dart        # @Deprecated alias — wraps the 2027 TextField
│   └── gradient_button.dart         # @Deprecated alias — wraps a 2027 FilledButton
└── theme/
    ├── app_theme.dart               # ThemeData (light + dark) + 3 ThemeExtensions
    ├── app_colors.dart              # AppColors tokens (warm neutrals + flame + oat)
    ├── gradients.dart               # AppBackplate widget (the only allowed gradient)
    └── spring.dart                  # ListdSpring — single canonical spring physics
```

Data flow: **UI ← Drift streams ← DAOs ← TaskSyncService ← Supabase**.
Mutations write Drift first (`syncStatus = created/updated/deleted`), then
`TaskSyncService.scheduleSync()` pushes them to Supabase in the background.

# Design System (2027)

**Aesthetic:** warm, focused, layered. Surfaces stack like islands on an ambient
backplate. One vibrant accent (flame), one muted accent (oat), warm neutrals
everywhere else. Hierarchy is carried by **type, weight, and surface depth** —
not bright color.

**Allowed**:

- One ambient backplate, one BackdropFilter (settings overlay only, P7).
- Soft warm shadows (`shadowSm/Md/Lg` from `ListdSurfaces`).
- Layered surfaces: ambient → canvas → panel → card → chip.
- Single spring everywhere (`ListdSpring.standard`).

**Forbidden**:

- Hardcoded colors outside `lib/theme/app_colors.dart`.
- Multiple springs / curves. There is **one** spring.
- Gradients other than `AppBackplate` (P7 enforces `grep -R 'AppGradients' lib/` → 0).
- BackdropFilter outside the settings overlay (P7 enforces exactly 1 result).
- Material icons. Use `phosphor_flutter` everywhere.
- Manrope, Space Grotesk, or any typeface other than Inter / Newsreader.

## Surface stack

| Token       | Light       | Dark        | Use                                          |
| ----------- | ----------- | ----------- | -------------------------------------------- |
| `ambient`   | `#F6F1EA`   | `#0E0C10`   | Backplate behind everything (`AppBackplate`) |
| `canvas`    | `#FFFFFF`   | `#1A171F`   | Page background — 20 px radius "island"      |
| `panel`     | `#FBF6EE`   | `#16131A`   | Sidebar drawer, settings overlay             |
| `card`      | `#FFFFFF`   | `#1F1B25`   | Task card — 16 px radius                     |
| `chip`      | `#F1EAE0`   | `#26212C`   | Tag / chip / pill — 999 px radius            |

## Color tokens

| Token              | Light       | Dark        | Use                            |
| ------------------ | ----------- | ----------- | ------------------------------ |
| `flame`            | `#FF6B35`   | `#FF8A5C`   | Selection, focus ring, primary |
| `flameSoft`        | `#FFE4D6`   | `#3D241A`   | Selected row fill, today cell  |
| `oat`              | `#A89878`   | `#C4B294`   | Counts, secondary chips        |
| `oatSoft`          | `#F1EAE0`   | `#2A2620`   | Tag chip fill, hover row       |
| `text-primary`     | `#1B1A18`   | `#F4EFE7`   | Titles, body                   |
| `text-secondary`   | `#5C564E`   | `#A8A199`   | Meta, captions                 |
| `text-tertiary`    | `#9A938B`   | `#6E6862`   | Placeholder, disabled          |
| `border`           | `#E6DFD4`   | `#2C2730`   | 1 px hairlines                 |
| `divider`          | `#EFEAE0`   | `#221F26`   | List separators                |

| Functional | Light       | Dark        | Use                       |
| ---------- | ----------- | ----------- | ------------------------- |
| `success`  | `#3F8F4F`   | `#5BB070`   | "Synced" pill dot only    |
| `warning`  | `#C97C2C`   | `#E09A50`   | "N pending" pill dot only |
| `error`    | `#B84A3A`   | `#D8694F`   | "Sync failed" pill dot only |

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
- TaskCard collapsed: **56 px**, expanded: **200–400 px**
- Sidebar drawer width: **240 px**, top bar: **40 px**
- Control radius: **12 px**
- Card radius: **16 px**
- Panel / canvas radius: **20 px**
- Chip / pill radius: **999 px**
- Settings overlay: **560 × 640 px**
- Border: 1 px on `border` / `divider`. Focus ring: 2 px `flame`.

## Motion — single spring

`ListdSpring.standard`: mass 1.0, stiffness 280, damping 28, settles in ~220 ms.
The reverse path waits 40 ms before unwinding so collapse motions don't read as
nervous. Reduced motion (`MediaQuery.disableAnimations`) → `Duration.zero`.

```dart
import '../theme/spring.dart';

final duration = ListdSpring.durationFor(context); // 220 ms or 0 ms
```

## Backplate

The single allowed gradient lives behind everything as `AppBackplate` (in
`lib/theme/gradients.dart`). It renders two soft radial corners on the ambient
base color. The corner alphas drift subtly with the time of day (warmer in the
morning, cooler in the evening) — this is the only place ambient color is
allowed to move.

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
tests, build. P7 adds two extra greps: `AppGradients` → 0 results, and
`BackdropFilter` → exactly 1 result.

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
reorderables: ^0.6.0      # added in P3 for drag-reordering tasks
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
- Follow the 2027 design system above. Use `Theme.of(context).colorScheme` and
  the `ListdSurfaces` / `ListdMotion` / `ListdTypography` ThemeExtensions; do
  NOT hardcode colors.
- Use `GoogleFonts.inter(...)` / `GoogleFonts.newsreader(...)` — or just lean
  on the TextTheme. No other typefaces.
- Use `phosphor_flutter` for icons — no Material icons.
- Stick to the 4 px grid: 4, 8, 12, 16, 24, 32, 48, 64.
- Selection / focus pattern: `flameSoft` fill + 2 px `flame` ring.
- All screens must handle AsyncValue loading/error/data states from Riverpod.
- Animations: import `lib/theme/spring.dart` and use `ListdSpring.standard` /
  `ListdSpring.durationFor(context)`. One spring everywhere — never invent a
  new curve.
- BackdropFilter is forbidden everywhere except the P7 settings overlay.
  P7's pre-merge gate enforces exactly 1 BackdropFilter in `lib/`.
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

# 2027 redesign branches

The 2027 redesign ships across 7 phases on the `redesign/2027` umbrella branch.
Each phase is a short PR off the umbrella; phases land in order, gated by CI.
The umbrella squash-merges back into `feature/supabase` at the end of P7. See
`listd_2027_implementation_plan.md` for the full phase plan.
