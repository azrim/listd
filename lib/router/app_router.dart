import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/all/all_tasks_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/callback_screen.dart';
import '../screens/folders/manage_folders_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/important/important_screen.dart';
import '../screens/inbox/inbox_screen.dart';
import '../screens/planned/planned_screen_2027.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/today/today_screen.dart';

/// Provider that forces router refresh when auth changes
final _authRefreshProvider = Provider<void>((ref) {
  // This provider depends on authNotifierProvider
  // Any change to auth will cause this to be re-evaluated
  ref.watch(authNotifierProvider);
  return;
});

/// The main router configuration for the application.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Depend on auth refresh to force router rebuild
  ref.watch(_authRefreshProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isAuthenticated = authState is AuthAuthenticated;
      final isAuthRoute =
          state.matchedLocation == '/auth' ||
          state.matchedLocation == '/auth/callback';

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/auth/callback',
        name: 'auth-callback',
        builder: (context, state) => const CallbackScreen(),
      ),
      GoRoute(path: '/', name: 'home', redirect: (_, _) => '/today'),
      // 2027 P4 — Today is the new default home with calendar strip.
      GoRoute(
        path: '/today',
        name: 'today',
        builder: (context, state) => const TodayScreen(),
      ),
      GoRoute(
        path: '/inbox',
        name: 'inbox',
        builder: (context, state) => InboxScreen(),
      ),
      GoRoute(
        path: '/important',
        name: 'important',
        builder: (context, state) => ImportantScreen(),
      ),
      GoRoute(
        path: '/planned',
        name: 'planned',
        builder: (context, state) => PlannedScreen2027(),
      ),
      GoRoute(
        path: '/all',
        name: 'all',
        builder: (context, state) => AllTasksScreen(),
      ),
      // User-list canvas — same 2-pane HomeScreen but pre-selecting
      // the requested list. The id is read by HomeScreen on first
      // build via go_router.
      GoRoute(
        path: '/list/:id',
        name: 'list',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/folders',
        name: 'folders',
        builder: (context, state) => const ManageFoldersScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Page not found'))),
  );
});
