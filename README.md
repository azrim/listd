# Listd

A native Flutter to-do application with Google Tasks integration for Linux desktop (with cross-platform support).

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Google Tasks Integration** - Sync your Google Tasks seamlessly
- **Material 3 Design** - Modern UI with Indigo (#5C6BC0) color scheme
- **Dark/Light Theme** - Support for system, light, and dark modes
- **Local Caching** - Offline-ready with SQLite (Drift) database
- **OAuth 2.0 PKCE** - Secure authentication with Google

## Screenshots

| Auth Screen | Task Lists | Tasks |
|-------------|------------|-------|
| ![Auth](docs/screenshots/auth.png) | ![Lists](docs/screenshots/task-lists.png) | ![Tasks](docs/screenshots/tasks.png) |

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Google Cloud Console project with OAuth 2.0 credentials

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/azrim/listd.git
   cd listd
   ```

2. Create a `.env` file (see `.env.example`):
   ```
   GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
   GOOGLE_CLIENT_SECRET=your_client_secret
   ```

3. Get dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run -d linux \
     --dart-define=GOOGLE_CLIENT_ID=your_client_id \
     --dart-define=GOOGLE_CLIENT_SECRET=your_client_secret
   ```

### Google Cloud Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project (or use existing)
3. Enable the **Google Tasks API**
4. Create OAuth 2.0 credentials (Desktop app type)
5. Add `http://localhost:8080/callback` as authorized redirect URI
6. Copy the Client ID and Client Secret to your `.env` file

## Architecture

- **State Management**: Riverpod
- **Database**: Drift (SQLite)
- **Navigation**: go_router
- **Authentication**: OAuth 2.0 PKCE

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Domain models
├── data/database/           # Drift database & DAOs
├── services/
│   ├── auth/                # OAuth authentication
│   ├── tasks/               # Google Tasks API
│   └── sync/                # Task sync service
├── providers/               # Riverpod providers
├── router/                  # go_router configuration
├── screens/                 # UI screens
└── widgets/                 # Reusable widgets
```

## Privacy

See [PRIVACY.md](PRIVACY.md) for information about data handling.

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- [Google Tasks API](https://developers.google.com/tasks/v1/reference)
- [Flutter](https://flutter.dev)
- [Riverpod](https://riverpod.dev)
- [Drift](https://driftcode.netlify.app)