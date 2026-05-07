---
date: 2026-05-07T17:44:33+0700
author: azrim
commit: no-commit
branch: detached
repository: listd
topic: "Listd - Native Flutter To Do App"
tags: [intent, frd, google-tasks, flutter-desktop, riverpod]
status: complete
last_updated: 2026-05-07T17:44:33+0700
last_updated_by: azrim
---

# FRD: Listd - Native Flutter To Do App

## Summary

A native Flutter To Do application called Listd for personal productivity, integrating with Google Tasks. Targets Linux desktop with cross-platform support (Windows, macOS, Android). Uses Material 3 with Indigo brand (#5C6BC0), Riverpod state management, drift for local SQLite caching, go_router for navigation, and oauth2 Dart package for PKCE authentication.

## Problem & Intent

Personal productivity app for managing Google Tasks on Linux desktop. Want a polished, fast native experience - not a web wrapper like the browser version. Secondary goal is portfolio showcase to demonstrate Flutter cross-platform development skills.

## Goals (priority order)

1. **Native Linux desktop experience** — polished, fast, not a web wrapper
2. **Google Tasks integration** — sync tasks from Google Tasks service
3. **Personal productivity** — useful for own task management
4. **Multi-platform** — same codebase runs on Windows, macOS, Android
5. **Portfolio-quality code** — demonstrate Flutter cross-platform skills

## Non-Goals

- **No local-only tasks** — Google account required
- **No team/collaborative features** — personal use only
- **No conflict resolution** — last-write-wins is fine
- **No custom task providers beyond Google Tasks** — ITaskProvider architecture but only Google implementation initially
- **No offline editing** — read-only offline mode (show cached tasks when offline)

## Functional Requirements

1. **Task list view** — show all Google Tasks lists, select one to view tasks
2. **Task management** — create, edit, delete, complete/uncomplete tasks
3. **Task list management** — create, rename, delete task lists
4. **OAuth authentication** — sign in with Google to access Tasks API
5. **Offline read mode** — show cached tasks when offline (no editing)
6. **Dark mode** — toggle between light/dark themes
7. **Cross-platform** — runs on Linux, Windows, macOS, Android
8. **Due date support** — view and set due dates on tasks
9. **Task notes/description** — view and edit task notes
10. **Settings screen** — account info, sign out button

**Deferred to v2:**

- Task reordering
- Subtasks
- Notifications/reminders
- Multiple Google accounts

## Non-Functional Requirements

- **Performance**: Fast startup (< 2 seconds to interactive on Linux desktop), Memory efficient (no memory leaks from stream subscriptions)
- **Security**: Secure token storage (OAuth tokens in flutter_secure_storage), Token auto-refresh (silent re-auth without interrupting the user)
- **UX / Accessibility**: Responsive UI (no UI jank during API calls with loading states), Dark mode flicker-free (theme persists, no flash on startup)
- **Reliability**: Graceful offline (clear indication when offline, show cached data), Error boundaries (API errors show inline messages, never crash the app)

## Constraints & Assumptions

- **OAuth2 PKCE** — Google's required auth flow for desktop/mobile apps
- **.env for client ID** — no hardcoded credentials, loaded via flutter_dotenv
- **Local storage** — flutter_secure_storage for tokens, drift for task cache (SQLite)
- **Material 3 + Indigo** — #5C6BC0, dark mode support
- **Conventional commits** — never commit to main/dev directly
- **Flutter minimum SDK** — Dart 3.x, Flutter 3.19+
- **No third-party UI libraries** — Material 3 only, no extra widget packages
- **oauth2 Dart package with PKCE** — pure Dart, no google_sign_in or AppAuth (fewer platform dependencies)

## Acceptance Criteria

- [ ] **User can sign in** — OAuth flow completes, tokens stored securely
- [ ] **Task lists load** — all Google Tasks lists visible after login
- [ ] **Tasks are manageable** — create, edit, complete, delete all work
- [ ] **Offline shows cached data** — when disconnected, cached tasks display
- [ ] **Dark mode works** — theme toggles correctly, persists across restarts
- [ ] **App runs on Linux** — builds and runs on Linux desktop
- [ ] **No crashes** — app handles errors gracefully, no uncaught exceptions
- [ ] **Due dates and notes save correctly** — changes persist after app restart
- [ ] **Token refresh works silently** — user never sees auth error during normal use

## Recommended Approach

Material 3 app with Riverpod state management, drift for local SQLite caching, go_router for navigation. ITaskProvider interface with GoogleTasksProvider implementation. OAuth2 PKCE via oauth2 Dart package (pure Dart, not google_sign_in or AppAuth), tokens in flutter_secure_storage, client ID from .env via flutter_dotenv. Desktop uses localhost redirect (127.0.0.1), Android uses custom URI scheme (listd://).

## Decisions

### Goals

**Question**: What are the core goals for Listd?
**Recommended**: Native Linux desktop, Google Tasks integration, Portfolio-quality, Personal productivity
**Chosen**: All 4 confirmed, added Multi-platform. Priority: 1, 2, 4, 5, 3
**Rationale**: User confirmed all goals and added multi-platform as priority #4

### Non-Goals

**Question**: What are the Non-Goals (explicitly out of scope)?
**Recommended**: No local-only tasks, No team features, No offline-first, No custom providers
**Chosen**: No local-only tasks, No team/collaborative, No conflict resolution (last-write-wins), No custom providers, No offline editing (read-only mode)
**Rationale**: User corrected #3 to allow offline read mode with cached tasks, no editing

### Constraints

**Question**: What are the key Constraints?
**Recommended**: OAuth2 PKCE, .env for client ID, Local storage, Material 3 + Indigo, Conventional commits
**Chosen**: All 5 plus: Flutter min SDK (Dart 3.x, Flutter 3.19+), No third-party UI libraries
**Rationale**: User added SDK requirement and UI constraint

### Functional Requirements

**Question**: What are the Functional Requirements?
**Recommended**: Task list view, Task management, Task list management, OAuth, Offline, Dark mode, Cross-platform
**Chosen**: All 7 plus: Due date support, Task notes/description, Settings screen (v1). Deferred: reordering, subtasks, notifications, multiple accounts (v2)
**Rationale**: User added v1 requirements and explicitly deferred v2 items

### Non-Functional Requirements

**Question**: What are the Non-Functional Requirements?
**Recommended**: Fast startup, Responsive UI, Secure token storage, Dark mode flicker-free, Graceful offline
**Chosen**: All 5 plus: Token auto-refresh, Error boundaries, Memory efficient
**Rationale**: User added auth and reliability requirements

### Acceptance Criteria

**Question**: What are the Acceptance Criteria?
**Recommended**: Sign in, Task lists load, Tasks manageable, Offline cached, Dark mode, Linux runs, No crashes
**Chosen**: All 7 plus: Due dates/notes persist, Token refresh silent
**Rationale**: User added persistence and auth refresh criteria

### Recommended Approach

**Question**: What's the Recommended Approach?
**Recommended**: Material 3 + Riverpod + drift + go_router, ITaskProvider with GoogleTasksProvider, flutter_secure_storage, PKCE auth
**Chosen**: Same, but use oauth2 Dart package directly (not google_sign_in or AppAuth) — pure Dart approach
**Rationale**: User corrected to use oauth2 package for fewer platform-specific dependencies

## Open Questions

_None — all items were resolved during the interview._

## References

- Feature description provided by user:
  - Targets: Linux, Windows, macOS, Android
  - Brand: Indigo (#5C6BC0), Material 3, dark mode support
  - Provider-agnostic architecture via ITaskProvider interface
  - Google OAuth2 PKCE, localhost redirect (desktop), URI scheme (Android)
  - Client ID loaded from .env via flutter_dotenv
  - State: Riverpod, Storage: flutter_secure_storage + drift, Router: go_router
  - Conventional commits, never commit to main/dev directly
