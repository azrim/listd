import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/gradients.dart';
import 'services/supabase/supabase_client_service.dart'
    show supabaseClientProvider, SupabaseClientService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-warm SharedPreferences in parallel with Supabase init so the
  // first frame's settings hydrate without an extra disk roundtrip.
  // Also pre-warm Inter (UI) and Newsreader (display serif) so the
  // first frame doesn't flash a fallback typeface — particularly
  // visible on the Today canvas headline which uses Newsreader.
  await Future.wait<void>([
    SupabaseClientService.initialize(),
    SharedPreferences.getInstance().then((_) {}),
    GoogleFonts.pendingFonts([GoogleFonts.inter(), GoogleFonts.newsreader()]),
  ]);

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
    final accent = ref.watch(accentColorProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Listd',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        colorScheme: AppTheme.lightTheme.colorScheme.copyWith(primary: accent),
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        colorScheme: AppTheme.darkTheme.colorScheme.copyWith(primary: accent),
      ),
      themeMode: themeMode,
      builder: (context, child) {
        // Apply the user's selected font scale on top of the platform
        // default, then wrap the entire surface in the 2027 ambient
        // backplate so every screen sits on the warm radial wash.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(fontScale)),
          child: AppBackplate(child: child ?? const SizedBox.shrink()),
        );
      },
      routerConfig: appRouter,
    );
  }
}
