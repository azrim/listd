# Listd

A native Flutter task-management app for Linux desktop (Android secondary), backed by Supabase. Local-first storage with background sync, sign in with Google, and a quiet 2026 design language: hairlines, neutral surfaces, one accent.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Local-first** — Drift / SQLite is the source of truth for the UI; a background `TaskSyncService` pushes pending mutations and pulls remote changes from Supabase.
- **Supabase backend** — Postgres + Auth, RLS-scoped per user, last-write-wins.
- **Google sign-in** — OAuth via Supabase (identity scope only, no Google Tasks).
- **Three-pane desktop layout** — sidebar / list / inspector. Inspector slides in over 200 ms; selection is instant.
- **Sync status pill** — live "Synced / Syncing… / N pending / Sync failed" indicator with a manual sync action.
- **Settings persist asynchronously** — theme, accent, font scale, notification prefs all flush via `shared_preferences` on a separate microtask so the UI never blocks.
- **2026 design system** — Inter type ramp, 4 px grid, hairline borders, no glass blurs / gradients / shadows. See [`docs/design-system.md`](docs/design-system.md) (or `listd_design_system.md`) for the spec.

## Screenshots

_Coming soon — see [docs/screenshots/](docs/screenshots/) for the previous indigo build._

## Getting started

### Prerequisites

- Flutter SDK 3.x (developed against 3.41.x)
- A Supabase project (free tier is fine)
- A Google Cloud OAuth 2.0 Client ID (Desktop or Web client; identity scope only)
- For Linux desktop: `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `liblzma-dev`

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
├── main.dart                 # App entry point + Supabase.initialize()
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
├── theme/                    # 2026 design tokens (app_colors, app_theme, gradients)
├── screens/                  # auth, callback, home, settings, folders
└── widgets/                  # sidebar_panel, task_list_panel, task_detail_panel,
                              # sync_status_pill, glass_card / glass_text_field /
                              # gradient_button (now hairline shims for back-compat)
```

## Design system (2026)

| Token                | Light       | Dark        | Use                            |
| -------------------- | ----------- | ----------- | ------------------------------ |
| `surface`            | `#FFFFFF`   | `#0B0B0E`   | Page background, list pane     |
| `surface-elevated`   | `#FAFAFA`   | `#121217`   | Sidebar, inspector             |
| `surface-sunken`     | `#F4F4F5`   | `#191920`   | Capture input, hover row       |
| `border`             | `#E5E5E7`   | `#26262C`   | 1 px hairlines                 |
| `accent`             | `#4F46E5`   | `#7C7BFF`   | Selection, focus ring, primary |
| `accent-soft`        | `#EEF0FF`   | `#1B1D3A`   | Selected row fill              |
| `text-primary`       | `#0A0A0B`   | `#F2F2F4`   | Titles, body                   |
| `text-secondary`     | `#5C5C66`   | `#9C9CA6`   | Meta, captions                 |
| `text-tertiary`      | `#9A9AA3`   | `#5F5F6B`   | Placeholder, disabled          |

- **One typeface** — Inter, weights 400 / 500 / 600.
- **4 px base grid** — allowed values: 4, 8, 12, 16, 24, 32, 48, 64.
- **Hairlines, not shadows** — every border is 1 px; the focus ring is 2 px accent (no glow).
- **Component metrics** — control height 32 px, row height 44 px, sidebar item 36 px, control radius 8 px, card radius 12 px.
- **Motion** — hover 120 ms ease-out fill change, selection instant, inspector entry 200 ms cubic-bezier(0.2, 0, 0, 1), checkbox toggle 160 ms.

The full spec lives in `listd_design_system.md`.

## Privacy

See [PRIVACY.html](PRIVACY.html) for information about data handling.

## License

Released under the MIT License — see [LICENSE](LICENSE).

## Acknowledgments

- [Supabase](https://supabase.com)
- [Flutter](https://flutter.dev)
- [Riverpod](https://riverpod.dev)
- [Drift](https://drift.simonbinder.eu)
