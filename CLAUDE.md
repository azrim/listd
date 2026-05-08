# Project Overview

Listd is a native Flutter to-do application for Linux desktop (cross-platform).
Local-first storage with background Supabase sync. Riverpod for state, Drift
(SQLite) as the UI source of truth, Supabase for auth + cloud, go_router for
navigation.

> Google Tasks API integration was removed.
> Backend is Supabase. Auth is Supabase OAuth via Google (identity only).
> Glassmorphism is gone — see "Design System" below for the 2026 hairline tokens.

# Architecture

```
lib/
├── main.dart                        # App entry point + Supabase.initialize() + SharedPreferences pre-warm
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
├── screens/
│   ├── auth/
│   │   ├── auth_screen.dart         # Hairline login: centered logo + Inter title + Continue button
│   │   └── callback_screen.dart     # 14 px accent spinner + "Signing you in…"
│   ├── home/
│   │   └── home_screen.dart         # Three-pane layout: sidebar / list / inspector (200 ms entry)
│   ├── settings/
│   │   └── settings_screen.dart     # Settings (theme, accent, font scale, notifications, profile)
│   └── folders/
│       └── manage_folders_screen.dart # Folder CRUD
├── widgets/
│   ├── sidebar_panel.dart           # 36 px rows, accent-soft fill + 2 px left bar on selection
│   ├── task_list_panel.dart         # 22 px H2, 32 px borderless capture, 44 px rows w/ hairline separators
│   ├── task_detail_panel.dart       # Inspector pane: 22 px title, 96 px label-gutter metadata rows
│   ├── sync_status_pill.dart        # 32 px pill: Synced / Syncing… / N pending / Sync failed
│   ├── glass_card.dart              # NOTE: hairline shim (1 px border, 12 px radius, no blur)
│   ├── glass_text_field.dart        # NOTE: hairline shim (32 px, 8 px radius, 2 px accent focus ring)
│   └── gradient_button.dart         # NOTE: hairline shim (flat accent fill, 32 px, no glow)
└── theme/
    ├── app_theme.dart               # ThemeData (light + dark), Inter type ramp, ListdSurfaces extension
    ├── app_colors.dart              # AppColors tokens (surface/elevated/sunken, accent, accentSoft, …)
    └── gradients.dart               # Const-safe shim — every gradient resolves to flat AppColors.accent
```

Data flow: **UI ← Drift streams ← DAOs ← TaskSyncService ← Supabase**.
Mutations write Drift first (`syncStatus = created/updated/deleted`), then
`TaskSyncService.scheduleSync()` pushes them to Supabase in the background.

# Design System (2026)

**Aesthetic:** quiet, neutral-first, hairlines only. One typeface (Inter), one
accent (indigo), grayscale everything else. Hierarchy is carried by **type and
weight, not color**. No glass, no gradients, no glow, no decorative shadows.

| Token              | Light       | Dark        | Use                            |
| ------------------ | ----------- | ----------- | ------------------------------ |
| `surface`          | `#FFFFFF`   | `#0B0B0E`   | Page background, list pane     |
| `surface-elevated` | `#FAFAFA`   | `#121217`   | Sidebar, inspector             |
| `surface-sunken`   | `#F4F4F5`   | `#191920`   | Capture input, hover row       |
| `border`           | `#E5E5E7`   | `#26262C`   | 1 px hairlines                 |
| `accent`           | `#4F46E5`   | `#7C7BFF`   | Selection, focus ring, primary |
| `accent-soft`      | `#EEF0FF`   | `#1B1D3A`   | Selected row fill              |
| `text-primary`     | `#0A0A0B`   | `#F2F2F4`   | Titles, body                   |
| `text-secondary`   | `#5C5C66`   | `#9C9CA6`   | Meta, captions                 |
| `text-tertiary`    | `#9A9AA3`   | `#5F5F6B`   | Placeholder, disabled          |

| Functional | Light       | Dark        | Use                       |
| ---------- | ----------- | ----------- | ------------------------- |
| `success`  | `#16A34A`   | `#22C55E`   | "Synced" pill dot         |
| `warning`  | `#D97706`   | `#F59E0B`   | "N pending" pill dot      |
| `error`    | `#DC2626`   | `#EF4444`   | "Sync failed" pill dot    |

**Type ramp** (Inter, weights 400 / 500 / 600 only):

| Role            | Size | Line | Weight | Tracking |
| --------------- | ---- | ---- | ------ | -------- |
| Display H1      | 32   | 40   | 600    | -0.02 em |
| Title H2        | 22   | 28   | 600    | -0.01 em |
| Body            | 15   | 22   | 400    | 0        |
| Body emphasized | 15   | 22   | 500    | 0        |
| Meta            | 13   | 18   | 400    | 0        |
| Caption         | 11   | 16   | 600    | 0.06 em  |

**Component metrics** (all on a 4 px grid: 4, 8, 12, 16, 24, 32, 48, 64):

- Control height (button, input, sync pill): **32 px**
- Row height (task tile): **44 px**
- Sidebar item: **36 px**
- Control radius: **8 px**
- Card radius: **12 px**
- Pane padding: 24 px top, 16 px sides, 16 px bottom
- Inspector label gutter: **96 px**
- Hairline borders are always **1 px**; focus ring is **2 px accent** (no glow)

**Motion:**

- Hover: 120 ms ease-out fill change to `surface-sunken` (no scale, no shadow)
- Selection: instant — fill + 2 px left bar appear on the same frame
- Inspector entry: 200 ms cubic-bezier(0.2, 0, 0, 1), translates from +16 px X
- Checkbox toggle: 160 ms — circle fills with `accent`, check draws in 80 ms
- Loading: 14 px spinner with 1.5 px stroke in `accent` (no shimmer)

**Key widgets**: `SidebarPanel`, `TaskListPanel`, `TaskDetailPanel`,
`SyncStatusPill`. Legacy widget names (`GlassCard`, `GlassTextField`,
`FocusedGlassTextField`, `GradientButton`) have been kept as **hairline shims**
with the same public APIs so external callers keep compiling — they're just
visually flat now. Prefer plain `Container` / `Material` with the design tokens
when writing new code.

The full spec lives in `listd_design_system.md`.

# Commands

| Command                       | Purpose                |
| ----------------------------- | ---------------------- |
| `flutter pub get`             | Get dependencies       |
| `flutter run -d linux`        | Run on Linux desktop   |
| `flutter analyze`             | Static analysis        |
| `dart format lib`             | Format Dart sources    |
| `flutter test`                | Run tests              |
| `flutter build linux`         | Build Linux executable |
| `dart run build_runner build` | Regenerate Drift files |

# Key Dependencies

```yaml
supabase_flutter: ^2.3.0
flutter_riverpod: ^2.x
riverpod_annotation: ^2.x
drift: ^2.x
go_router: ^14.x
google_fonts: ^6.x   # Inter only
shared_preferences: ^2.x
flutter_animate: ^4.5.0
flutter_local_notifications: ^17.x
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
- After schema changes run: `dart run build_runner build`.
- Never modify *.g.dart files directly.
- Bump the schema version in lib/data/database/app_database.dart.
- Mirror any Drift schema changes in Supabase SQL editor too (and add a
  migration under supabase/migrations/).
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
- Follow the 2026 design system above. Use `Theme.of(context).colorScheme` and
  the `ListdSurfaces` ThemeExtension; do NOT hardcode colors.
- Use `GoogleFonts.inter(...)` (or just lean on the TextTheme). Do NOT use
  Manrope, Space Grotesk, or any other typeface.
- Hairlines, not shadows. Borders are 1 px `scheme.outlineVariant`. Focus rings
  are 2 px `scheme.primary`. Do NOT add `boxShadow` or `BackdropFilter`.
- Stick to the 4 px grid: 4, 8, 12, 16, 24, 32, 48, 64.
- Selection pattern: `scheme.primaryContainer` fill + 2 px accent left bar.
  Do NOT use rounded "selection chips".
- All screens must handle AsyncValue loading/error/data states from Riverpod.
- Animations: prefer the timings in the Motion table above. Avoid scale/bounce.
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
