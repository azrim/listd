# Listd

A native Flutter task-management app for Linux desktop (Android secondary), backed by Supabase. Sign in with Google, organize tasks into folders, and keep everything synced across devices.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Supabase backend** — Postgres, Realtime, Auth, with last-write-wins sync.
- **Google Sign-In** — OAuth 2.0 PKCE for identity only (no Google Tasks scope).
- **Material 3 + Stitch indigo** — refined indigo design system, light + dark.
- **Local cache** — Drift / SQLite mirrors Supabase data so the UI stays responsive offline.
- **Riverpod** — typed state with `StateNotifier` and `@riverpod`-generated providers.
- **Three-pane desktop layout** — sidebar / list / details, plus Manage Folders and Planned views.

## Screenshots

_Updated when the design rebuild lands. Until then see [docs/screenshots/](docs/screenshots/)._

## Getting started

### Prerequisites

- Flutter SDK 3.x
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
- **Database** — apply the schema in `supabase/migrations/` (see the `supabase/` directory) so the `task_lists` and `tasks` tables exist.

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

| Layer | Tech |
|---|---|
| State | Riverpod 2.x (`StateNotifier` + `@riverpod` generator) |
| Routing | `go_router` |
| Backend | Supabase (Postgres + Realtime + Auth) |
| Local cache | Drift (SQLite) |
| Auth | Google OAuth 2.0 PKCE → Supabase JWT |
| Notifications | `flutter_local_notifications` |

### Project structure

```
lib/
├── main.dart                 # App entry point
├── config/                   # AppConfig (--dart-define wrapper)
├── models/                   # Domain models (Task, TaskList, Step, …)
├── data/database/            # Drift database, tables, DAOs
├── services/
│   ├── auth/                 # Google OAuth + secure storage
│   ├── supabase/             # Supabase client wrapper
│   ├── tasks/                # Task provider + Supabase implementation
│   └── sync/                 # Drift ↔ Supabase sync orchestration
├── providers/                # Riverpod providers
├── router/                   # go_router config
├── theme/                    # Stitch indigo tokens, ColorSchemes, TextTheme
├── screens/                  # Top-level routed screens
└── widgets/                  # Shared widgets
```

## Privacy

See [PRIVACY.html](PRIVACY.html) for information about data handling.

## License

Released under the MIT License — see [LICENSE](LICENSE).

## Acknowledgments

- [Supabase](https://supabase.com)
- [Flutter](https://flutter.dev)
- [Riverpod](https://riverpod.dev)
- [Drift](https://drift.simonbinder.eu)
