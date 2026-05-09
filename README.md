# Listd

A native Flutter task-management app for Linux desktop (Android secondary), backed by Supabase. Local-first storage with background sync, sign in with Google, and the **2027 · Indigo Edition** design language: cool indigo + slate neutrals, amber-only stars, Inter + Newsreader, Phosphor icons, single spring with three calibrations (settle / flick / breathe), no glassmorphism.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Local-first** — Drift / SQLite is the source of truth for the UI; a background `TaskSyncService` pushes pending mutations and pulls remote changes from Supabase.
- **Supabase backend** — Postgres + Auth, RLS-scoped per user, last-write-wins.
- **Google sign-in** — OAuth via Supabase (identity scope only, no Google Tasks).
- **Today-first layout** — opens to Today with a Newsreader headline, 7-day calendar strip, and inline expand-in-place task cards.
- **Smart buckets** — Today / Inbox / Important / Planned / All / list views, all driven by Drift queries (no hardcoded data).
- **Capture in <1 s** — `Ctrl+N` opens a single-line capture sheet that parses dates, tags, list prefixes, and stars.
- **Two keystrokes to anywhere** — `Ctrl+K` command palette searches lists, tasks, and actions.
- **Sync status pill** — live "Synced / Syncing… / N pending / Sync failed" indicator with a manual sync action.
- **Settings persist asynchronously** — theme, accent, font scale, notification prefs all flush via `shared_preferences` on a separate microtask so the UI never blocks.

## Screenshots

_Coming with the P4 / P5 / P6 phase PRs — see [docs/screenshots/](docs/screenshots/) for previous builds._

## Getting started

### Prerequisites

- Flutter SDK 3.41.x (CI pins `3.41.9`).
- A Supabase project (free tier is fine).
- A Google Cloud OAuth 2.0 Client ID (Desktop or Web client; identity scope only).
- For Linux desktop: `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `liblzma-dev`.

### 1. Clone and install dependencies

```bash
git clone https://github.com/azrim/listd.git
cd listd
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 2. Configure Supabase

Create a project at [supabase.com](https://supabase.com), then in the Supabase Dashboard:

- **Settings → API** — copy the **Project URL** and **anon public** key.
- **Authentication → Providers → Google** — enable, paste your Google OAuth Client ID and Client Secret.
- **Authentication → URL Configuration → Redirect URLs** — add `io.listd://login-callback`.
- **Database** — apply the schema in `supabase/migrations/` so the `task_lists` and `tasks` tables exist with RLS.

### 3. Configure Google OAuth

In [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials:

- Create an **OAuth 2.0 Client ID** (Desktop application is fine for local dev).
- No additional scopes are required — Listd only reads the user's profile/email.

### 4. Run the app

All credentials are passed via `--dart-define` so they never live in the repo. The app fails fast at startup if any are missing.

```bash
flutter run -d linux \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_PUBLIC_KEY \
  --dart-define=GOOGLE_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com
```

You can also stash these in a shell alias or VS Code launch config; see `.env.example` for the full list of keys.

## Architecture

| Layer            | Tech                                                              |
| ---------------- | ----------------------------------------------------------------- |
| State            | Riverpod 2.x (`StateNotifier` + `@riverpod` generator)            |
| Routing          | `go_router`                                                       |
| Source of truth  | **Drift / SQLite** (UI watches Drift streams)                     |
| Backend          | Supabase (Postgres + Auth, RLS per user)                          |
| Sync             | `TaskSyncService` (debounced push + pull, manual sync via pill)   |
| Auth             | Google OAuth → Supabase JWT (managed by `supabase_flutter`)       |
| Notifications    | `flutter_local_notifications`                                     |
| Icons            | `phosphor_flutter` (Phosphor regular, 1.5 px stroke)              |
| Type             | `google_fonts` (Inter + Newsreader)                               |

### Data flow

```
UI ←─ Drift streams ←──── DAOs ←──── TaskSyncService ←─── Supabase (Postgres)
            │
            └── mutations: write Drift first (syncStatus = created/updated/deleted),
                then TaskSyncService.scheduleSync() pushes to Supabase in the background.
```

### Project structure

```
lib/
├── main.dart                 # App entry — Supabase init + AppBackplate wrap
├── config/                   # AppConfig (--dart-define wrapper)
├── models/                   # Domain models (Task, TaskList, TaskStep, …)
├── data/database/            # Drift database, tables, DAOs (source of truth)
├── services/
│   ├── auth/                 # Google OAuth + Supabase token manager
│   ├── supabase/             # Supabase client wrapper
│   ├── tasks/                # ITaskProvider + Supabase implementation
│   └── sync/                 # task_sync_service.dart (background push/pull)
├── providers/                # Riverpod providers (UI watches Drift via these)
├── router/                   # go_router config
├── theme/                    # 2027 indigo design tokens (app_colors, app_theme, app_motion, app_density, gradients, spring)
├── screens/                  # Today, lists, inbox, important, planned, all, settings drawer, auth
└── widgets/                  # task_card, command_palette, capture_sheet, calendar_strip, inline_edit_field,
                              # empty_state, sidebar_drawer, settings_overlay, sync_status_pill
```

## Design system (2027 · Indigo Edition)

| Token            | Light       | Dark        | Use                                      |
| ---------------- | ----------- | ----------- | ---------------------------------------- |
| `ambient`        | `#F8FAFC`   | `#020617`   | Backplate behind everything              |
| `canvas`         | `#FFFFFF`   | `#0F172A`   | Page background — 16 px radius "island"  |
| `panel`          | `#F8FAFC`   | `#0F172A`   | Sidebar drawer, settings drawer          |
| `card`           | `#FFFFFF`   | `#1E293B`   | Task card — 12 px radius                 |
| `chip`           | `#F1F5F9`   | `#334155`   | Tag / chip / pill — 999 px radius        |
| `indigo`         | `#4F46E5`   | `#7376F8`   | Selection, focus ring, primary action    |
| `indigoSoft`     | `#EEF2FF`   | `#1E1B4B`   | Selected row fill, today date cell       |
| `amber`          | `#FBBF24`   | `#FCD34D`   | Star fill / star glyph only              |
| `text-primary`   | `#0F172A`   | `#F8FAFC`   | Titles, body                             |
| `text-secondary` | `#64748B`   | `#94A3B8`   | Meta, captions                           |
| `border`         | `#E2E8F0`   | `#334155`   | 1 px hairlines                           |

- **Two faces** — Inter (UI) + Newsreader (display, 3 places only: Today headline, empty states, About).
- **4 px base grid** — allowed values: 4, 8, 12, 16, 24, 32, 48, 64.
- **Soft slate-tinted shadows** — `shadowSm` / `shadowMd` / `shadowLg` from the `ListdSurfaces` extension.
- **Component metrics** — control 36 px, TaskCard 56 px (cozy) / 44 px (compact) → 200–400 px expanded, control radius 12 px, card radius 12 px, panel radius 16 px, chip 999 px, focus ring 2 px indigo. `DensityMode` toggles cozy ↔ compact.
- **Motion** — one spring with three calibrations: `AppMotion.settle` (220 ms default), `AppMotion.flick` (160 ms light affordances), `AppMotion.breathe` (320 ms heavy surfaces). Reduced motion → 0 ms snap.
- **Icons** — Phosphor regular (1.5 px stroke).
- **No glassmorphism** — there is no `BackdropFilter` anywhere; the settings drawer slides in over an opaque slate scrim.

The full spec lives under `docs/redesign/2027-indigo/` (00–06 plus mockups).

## Privacy

See [PRIVACY.html](PRIVACY.html) for information about data handling.

## License

Released under the MIT License — see [LICENSE](LICENSE).

## Acknowledgments

- [Supabase](https://supabase.com)
- [Flutter](https://flutter.dev)
- [Riverpod](https://riverpod.dev)
- [Drift](https://drift.simonbinder.eu)
- [Phosphor Icons](https://phosphoricons.com)
