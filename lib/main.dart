import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'services/supabase/supabase_client_service.dart'
    show supabaseClientProvider, SupabaseClientService;
import 'theme/app_theme.dart';
import 'theme/gradients.dart';

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
    final fontScale = ref.watch(fontScaleProvider);
    final appRouter = ref.watch(appRouterProvider);

    // Per `docs/redesign/2027-indigo/00_overview.md` indigo carries
    // selection / focus / progress everywhere. The Settings → Accent
    // picker is preview-only — it never overrides the ColorScheme's
    // primary. Reading `accentColorProvider` here would re-introduce
    // the divergence the user reported (cyan / emerald borders).
    return MaterialApp.router(
      title: 'Listd',
      // Top-level ScaffoldMessenger so toast/snackbar presentation lives
      // above every route. Without this, a snackbar fired after an
      // awaited mutation that spans a navigation crashes with
      // "_scaffolds.isNotEmpty" because the captured per-route
      // messenger's Scaffold is gone. This key is the canonical
      // surface for any post-await user feedback.
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
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

/// Top-level ScaffoldMessenger key — see [ListdApp.build] above for
/// why this exists. Use `rootScaffoldMessengerKey.currentState` for
/// any toast that fires after an `await` that could span a route
/// change. In-route synchronous toasts can keep using
/// `ScaffoldMessenger.of(context)` for locality.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
