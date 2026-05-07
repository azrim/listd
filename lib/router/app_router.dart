import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/callback_screen.dart';
import '../screens/task_lists/task_lists_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../screens/settings/settings_screen.dart';

/// The main router configuration for the application.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState is AuthAuthenticated;
      final isAuthRoute =
          state.matchedLocation == '/auth' ||
          state.matchedLocation == '/auth/callback';

      // If not authenticated and not on auth route, redirect to auth
      if (!isAuthenticated && !isAuthRoute) {
        return '/auth';
      }

      // If authenticated and on auth route, redirect to home
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
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const TaskListsScreen(),
      ),
      GoRoute(
        path: '/tasks/:taskListId',
        name: 'tasks',
        builder: (context, state) {
          final taskListId = state.pathParameters['taskListId']!;
          final taskListTitle = state.uri.queryParameters['title'] ?? 'Tasks';
          return TasksScreen(
            taskListId: taskListId,
            taskListTitle: taskListTitle,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );
});
