import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'services/supabase/supabase_client_service.dart' show supabaseClientProvider, SupabaseClientService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseClientService.initialize();
  
  runApp(
    ProviderScope(
      overrides: [
        // Override supabaseClientProvider to use the initialized client
        supabaseClientProvider.overrideWithValue(SupabaseClientService.client),
      ],
      child: const ListdApp(),
    ),
  );
}

/// Main application widget.
class ListdApp extends ConsumerWidget {
  const ListdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Listd',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}