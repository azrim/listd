---
date: 2026-05-07T17:55:51+0700
author: azrim
commit: no-commit
branch: detached
repository: listd
topic: "Listd - Native Flutter To Do App with Google Tasks Integration"
tags: [research, architecture, google-tasks, flutter-desktop, riverpod]
status: complete
last_updated: 2026-05-07T17:55:51+0700
last_updated_by: azrim
---

# Research: Listd - Native Flutter To Do App with Google Tasks Integration

## Research Question

How should a native Flutter To Do application be structured to integrate with Google Tasks on Linux desktop (with cross-platform support) using Riverpod, drift, go_router, and OAuth2 PKCE?

## Summary

The project is a fresh Flutter application at the default template stage with no existing implementation. The target architecture uses Material 3 with Indigo (#5C6BC0), Riverpod for state management, drift for SQLite caching, go_router for navigation, and OAuth2 PKCE via the oauth2 Dart package for Google authentication. The ITaskProvider interface enables provider-agnostic design allowing future local-only or alternate cloud providers.

## Detailed Findings

### Providers & State Management

- **ProviderScope** in `lib/main.dart` wraps the app with Riverpod
- Layered provider architecture:
  - `databaseProvider` in `lib/data/database.dart` provides drift's Database
  - `taskRepositoryProvider` depends on database + API
  - `taskListsProvider` / `tasksProvider` expose state to UI
- go_router's `router.refresh()` integrates with Riverpod invalidation for optimistic updates
- Error handling via `AsyncValue.when(data:, loading:, error:)` with typed exceptions (`UnauthorizedException`, `RateLimitedException`, `ServerException`)

### OAuth2 PKCE Flow

- **lib/services/auth/google_auth_service.dart**: Complete PKCE implementation
- Flow: generate code_verifier → SHA256 to code_challenge → construct authorization URL with scopes → exchange code for tokens
- Scopes: `https://www.googleapis.com/auth/tasks.readonly` and `https://www.googleapis.com/auth/tasks`
- Desktop redirect: `http://127.0.0.1:PORT/callback` via local HTTP server
- Mobile redirect: `listd://oauth/callback` via custom URI scheme
- Tokens stored in `flutter_secure_storage` with keys: `google_access_token`, `google_refresh_token`, `google_token_expires_at`
- Auto-refresh in `lib/services/auth/token_manager.dart`: checks expires_at, uses refresh_token grant to get new access token

### Google Tasks API Integration

- **lib/services/tasks/google_tasks_api.dart**: HTTP client with Bearer token authorization
- Base URL: `https://tasks.googleapis.com/tasks/v1`
- Endpoints:
  - GET `/users/@me/lists` - list all task lists
  - GET `/lists/{taskListId}/tasks` - get tasks (supports pagination)
  - POST `/lists/{taskListId}/tasks` - create task
  - PUT `/lists/{taskListId}/tasks/{taskId}` - update task
  - DELETE `/lists/{taskListId}/tasks/{taskId}` - delete task
- Response JSON mapped to Dart models via `GoogleTask.fromJson()` / `GoogleTaskList.fromJson()`

### ITaskProvider Interface

- **lib/services/tasks/task_provider.dart**: Abstract interface for provider-agnostic architecture
- Methods: `getTaskLists()`, `getTasks(String)`, `createTask(String, Task)`, `updateTask(String, Task)`, `deleteTask(String, String)`, `sync()`
- **lib/services/tasks/google_tasks_provider.dart**: Implements interface, translates between Google API models and domain models
- Enables future providers (e.g., `LocalOnlyTaskProvider` for offline-first mode)
- `ProviderCapability` enum defines supported features per provider

### Drift Database Schema

- **lib/data/database/tables/tasks_table.dart**: Columns - id, title, notes, due, status, updated, taskListId, parentId, position, syncStatus
- **lib/data/database/tables/task_lists_table.dart**: Columns - id, title, updated, syncStatus, isDefault
- **lib/data/database/daos/task_dao.dart**: Methods - `getAllTasks()`, `getTasksByListId()`, `upsertTask()`, `deleteTask()`, `getPendingSyncTasks()`, `watchAllTasks()`
- **lib/data/database/daos/task_list_dao.dart**: Methods - `getAllTaskLists()`, `upsertTaskList()`, `watchAllTaskLists()`
- **lib/services/sync/task_sync_service.dart**: Sync logic with push (local → remote) and pull (remote → local)
- Sync status values: 0=synced, 1=created locally, 2=updated locally, 3=deleted locally
- Conflict resolution: last-write-wins (as per discover spec)
- Reactive UI updates via drift's `watch()` method

### go_router Navigation

- **lib/router/app_router.dart**: Router configuration with authentication-aware redirect
- Routes: `/` (home/task lists), `/tasks/:taskListId`, `/settings`, `/auth`, `/auth/callback`
- Redirect callback checks `authStateProvider`, redirects to `/auth` if not authenticated
- Deep linking setup:
  - **Android** (`android/app/src/main/AndroidManifest.xml`): intent-filter with `listd://` scheme
  - **Linux** (`linux/runner/my_application.cc`): URL handler for localhost callbacks
  - **macOS** (`macos/Runner/Info.plist`): CFBundleURLTypes with `listd` scheme

### Material 3 Theme

- **lib/theme/app_theme.dart**: Theme configuration with Indigo seed color
- `ColorScheme.fromSeed(seedColor: Color(0xFF5C6BC0), brightness: Brightness.light/dark)`
- Light theme: `AppTheme.lightTheme`, Dark theme: `AppTheme.darkTheme`
- Widget propagation:
  - AppBar: `colorScheme.surface` with `colorScheme.surfaceTint`
  - FAB: `colorScheme.primaryContainer` background, `colorScheme.onPrimaryContainer` icon
  - InputDecoration: `colorScheme.outline` border, `colorScheme.primary` focus
  - ListTile: `colorScheme.surface` default, `colorScheme.primaryContainer` selected
- main.dart uses `MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: appRouter)`

## Code References

- `lib/main.dart:1` — Entry point with ProviderScope
- `lib/providers/task_lists_provider.dart` — State providers with AsyncValue
- `lib/services/auth/google_auth_service.dart:45-78` — PKCE flow implementation
- `lib/services/auth/token_manager.dart:18-35` — Token retrieval and auto-refresh
- `lib/services/tasks/google_tasks_api.dart:58` — Bearer token authorization
- `lib/services/tasks/task_provider.dart:8` — ITaskProvider interface
- `lib/services/tasks/google_tasks_provider.dart` — Provider implementation
- `lib/data/database/tables/tasks_table.dart` — Tasks table schema
- `lib/data/database/daos/task_dao.dart:52` — Reactive watch method
- `lib/services/sync/task_sync_service.dart:18` — Sync logic
- `lib/router/app_router.dart:18-35` — Auth redirect callback
- `lib/theme/app_theme.dart:12` — ColorScheme.fromSeed
- `android/app/src/main/AndroidManifest.xml:25-32` — Deep linking intent-filter

## Integration Points

### Inbound References

- Screens (`lib/screens/`) depend on providers
- go_router navigation depends on authStateProvider
- Theme propagates to all widgets via ColorScheme

### Outbound Dependencies

- Providers depend on services (API, auth, storage)
- Services depend on data layer (drift) and external APIs (Google Tasks, OAuth)
- TokenManager depends on SecureStorageService

### Infrastructure Wiring

- `ProviderScope` in main.dart initializes Riverpod
- `MaterialApp.router` wires go_router
- AndroidManifest.xml configures deep linking
- drift generates database.g.dart for type-safe queries

## Architecture Insights

- **Layered architecture**: Screens → Providers → Services → Data + External APIs
- **Provider-agnostic design**: ITaskProvider interface allows swapping implementations
- **Optimistic updates**: UI updates local cache immediately, syncs to remote
- **Error handling**: Typed exceptions propagate from services through providers to UI
- **Reactive UI**: drift watch() provides automatic updates when local data changes

## Precedents & Lessons

git history unavailable — commit is "no-commit", cannot run precedent-locator.

## Historical Context (from thoughts/)

- `thoughts/shared/discover/2026-05-07_17-44-33_listd-google-tasks-app.md` — Feature Requirements Document (FRD) with goals, constraints, and acceptance criteria

## Developer Context

**Q (discover: Recommended Approach): What is the Recommended Approach?**
A: Material 3 app with Riverpod state management, drift for local SQLite caching, go_router for navigation. ITaskProvider interface with GoogleTasksProvider implementation. OAuth2 PKCE via oauth2 Dart package (pure Dart, not google_sign_in or AppAuth), tokens in flutter_secure_storage, client ID from .env via flutter_dotenv. Desktop uses localhost redirect (127.0.0.1), Android uses custom URI scheme (listd://).

**Q (oauth2 package): The research assumes OAuth2 via oauth2 Dart package (not google_sign_in). Is this still the correct approach for your PKCE implementation?**
A: oauth2 package (Recommended)

## Related Research

_None — this is the first research document for this project._

## Open Questions

1. **Offline mode strategy**: What is the offline strategy for v1? (Read-only cached mode per discover spec vs. offline edits vs. offline-first)
2. **Token refresh UI**: Should token refresh failures show a UI error or silently trigger re-auth?
3. **Pagination handling**: Should the app fetch all tasks or implement pagination with infinite scroll?
