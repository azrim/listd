# Project Overview

Listd is a native Flutter to-do application for Linux desktop (cross-platform).
Uses Riverpod for state management, Drift (SQLite) for local caching,
Supabase for backend + auth, and go_router for navigation.

> Google Tasks API integration has been removed.
> Backend is now Supabase. Auth is Supabase OAuth via Google (identity only).

# Architecture

```
lib/
├── main.dart                        # App entry point + Supabase.initialize()
├── config/
│   └── app_config.dart              # Supabase URL, anon key, Google client ID, redirectUrl
├── models/                          # Domain models (Task, TaskList, etc.)
├── data/
│   └── database/                    # Drift local SQLite cache
│       ├── daos/                    # Data Access Objects
│       └── tables/                  # Table definitions
├── providers/                       # Riverpod state management
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
│       └── task_sync_service.dart   # Supabase → Drift cache sync
├── screens/
│   ├── auth/
│   │   ├── auth_screen.dart         # Glassmorphism login, Google sign-in button
│   │   └── callback_screen.dart     # Listens to onAuthStateChange, redirects
│   ├── task_lists/
│   │   └── task_lists_screen.dart   # Home screen with glass UI
│   ├── tasks/
│   │   └── tasks_screen.dart        # Task detail screen with glass UI
│   └── settings/
│       └── settings_screen.dart     # Glass settings, theme toggle
├── widgets/
│   ├── glass_card.dart              # BackdropFilter glass card component
│   ├── glass_text_field.dart        # Glass input field with indigo focus glow
│   ├── gradient_button.dart         # Indigo gradient button with loading state
│   ├── task_list_tile.dart          # Glass list tile for task lists
│   └── task_tile.dart               # Glass task item with animated checkbox
└── theme/
    ├── app_theme.dart               # ThemeData (dark + light), Space Grotesk
    ├── app_colors.dart              # AppColors constants (primary: #5C6BC0)
    └── gradients.dart               # AppGradients (violet → blue)
```

Data flow: UI → Providers → Services → Supabase (cloud) + Drift (local cache)

# Design System

**Aesthetic:** Glassmorphism / Futuristic dark UI

| Token              | Value                                                |
| ------------------ | ---------------------------------------------------- |
| Primary            | `Color(0xFF5C6BC0)` — always via `AppColors.primary` |
| Background deep    | `Color(0xFF07081A)`                                  |
| Background mid     | `Color(0xFF0E1030)`                                  |
| Background surface | `Color(0xFF131440)`                                  |
| Glass fill         | `Color(0x12FFFFFF)`                                  |
| Glass border       | `Color(0x40FFFFFF)`                                  |
| Font               | Space Grotesk (`google_fonts`)                       |

Key widgets: `GlassCard`, `GlassTextField`, `GradientButton`
All `BackdropFilter` widgets require `import 'dart:ui'`.

# Commands

| Command                       | Purpose                |
| ----------------------------- | ---------------------- |
| `flutter pub get`             | Get dependencies       |
| `flutter run -d linux`        | Run on Linux desktop   |
| `flutter test`                | Run tests              |
| `flutter build linux`         | Build Linux executable |
| `dart run build_runner build` | Regenerate Drift files |

# Key Dependencies

```yaml
supabase_flutter: ^2.3.0
flutter_riverpod: ...
drift: ...
go_router: ...
google_fonts: ^6.1.0
flutter_animate: ^4.5.0
shimmer: ^3.0.0
```

# Supabase Setup

Database tables: `task_lists`, `tasks` — both with Row Level Security.
Auth: Google OAuth via Supabase (scopes: `openid email profile` only).
Redirect URL: `io.listd://login-callback`
Config placeholders in `lib/config/app_config.dart`:

- `AppConfig.supabaseUrl`
- `AppConfig.supabaseAnonKey`
- `AppConfig.googleClientId`

<important if="you are adding or modifying database schema">
- Drift handles local SQLite cache — modify lib/data/database/tables/
- After schema changes run: `dart run build_runner build`
- Never modify *.g.dart files directly
- Mirror any Drift schema changes in Supabase SQL editor too
</important>

<important if="you are implementing authentication flows">
- Auth is fully delegated to Supabase — do NOT write manual PKCE
- Google OAuth via: `client.auth.signInWithOAuth(OAuthProvider.google)`
- Auth state via: `client.auth.onAuthStateChange` stream
- Current user: `client.auth.currentUser`
- Token refresh is automatic — do not manage tokens manually
</important>

<important if="you are adding new UI screens or widgets">
- Use GlassCard, GlassTextField, GradientButton from lib/widgets/
- Primary color is ALWAYS AppColors.primary — never hardcode Color(0xFF5C6BC0)
- All screens must handle AsyncValue loading/error/data states from Riverpod
- BackdropFilter requires import 'dart:ui'
- Target is Linux desktop — test glass blur on Linux renderer
- Animations via flutter_animate: .fadeIn().slideY() for screen entry
</important>

<important if="you are modifying the task data layer">
- ITaskProvider interface must never change
- SupabaseTasksProvider in lib/services/tasks/ implements ITaskProvider
- Always filter by user_id: client.auth.currentUser!.id
- Map PostgrestException(code: 401) → UnauthorizedException
- Map other PostgrestException → ServerException
</important>
