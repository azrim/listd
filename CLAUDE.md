# Project Overview

Listd is a native Flutter to-do application with Google Tasks integration for Linux desktop (cross-platform). Uses Riverpod for state management, Drift (SQLite) for local caching, Supabase for backend services, and go_router for navigation.

# Architecture

```
lib/
├── main.dart                 # App entry point
├── models/                   # Domain models (Task, TaskList, etc.)
├── data/                     # Data layer (Drift database)
│   └── database/             # Database implementation
│       ├── daos/             # Data Access Objects
│       └── tables/           # Database table definitions
├── providers/                # Riverpod state management
├── router/                   # go_router configuration
├── services/                 # Business logic services
│   ├── auth/                 # Authentication (OAuth, Supabase)
│   ├── tasks/                # Task services (Google Tasks, Supabase)
│   ├── supabase/             # Supabase client initialization
│   └── sync/                 # Task synchronization service
├── screens/                  # UI screens (Auth, Home, Settings, etc.)
├── widgets/                  # Reusable UI components
└── theme/                    # Theme and styling definitions
```

Data flows: UI (screens/widgets) → Providers → Services → Data layer → Local/Remote storage
Dependencies flow inward: UI depends on Providers/Services, Providers depend on Services, Services depend on Data layer

# Commands

| Command                       | Purpose                       |
| ----------------------------- | ----------------------------- |
| `flutter pub get`             | Get dependencies              |
| `flutter run -d linux`        | Run app on Linux desktop      |
| `flutter test`                | Run tests                     |
| `flutter build linux`         | Build Linux executable        |
| `dart run build_runner build` | Generate Drift database files |

# Business Context

A native Flutter to-do application focused on providing seamless Google Tasks integration with offline capabilities through local SQLite caching. Targets Linux desktop users who want a modern, Material 3-designed task management app with secure OAuth 2.0 authentication.

<important if="you are adding or modifying database schema">
- Drift is used for ORM - modify .dart files in lib/data/database/tables/
- After schema changes, run: `dart run build_runner build` to generate DAO files
- Never modify generated *.g.dart files directly
- Migrations handled automatically by Drift
</important>

<important if="you are implementing authentication flows">
- Supabase Auth used for OAuth 2.0 PKCE flow
- Desktop uses local HTTP server callback (localhost:8090)
- Web uses external application launch mode
- Token storage uses Flutter Secure Storage
- Auth state managed via Riverpod providers
</important>

<important if="you are adding new UI screens or widgets">
- Follow Material 3 design principles with Indigo (#5C6BC0) color scheme
- Use responsive layouts suitable for desktop
- Reuse existing widget patterns from lib/widgets/
- Screen navigation via go_router in lib/router/app_router.dart
</important>
</content>
