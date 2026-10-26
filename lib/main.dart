import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_screen.dart';
import 'services/supabase_service.dart';
import 'shells/foodie_shell.dart';
import 'shells/truck_owner_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase if configured via --dart-define
  await SupabaseService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const RoamBiteApp(),
    ),
  );
}

class RoamBiteApp extends StatelessWidget {
  const RoamBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'RoamBite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Light theme is DEFAULT (Phase 5)
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const RootGatekeeper(),
    );
  }
}

class RootGatekeeper extends StatelessWidget {
  const RootGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Loading / Splash state
    if (auth.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/roambite_logo.jpg',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_shipping, size: 48),
                ),
              ),
              const SizedBox(height: 18),
              const Text('RoamBite', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 12),
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
      );
    }

    // Unauthenticated user -> Auth Screen (Phase 2)
    if (!auth.isSignedIn) {
      return const AuthScreen();
    }

    // Role-segregated shells (Phase 1 & Phase 2)
    // A foodie account never sees or reaches truck owner screens or routes.
    if (auth.isTruckOwner) {
      return const TruckOwnerShell();
    }

    // Cold start lands on Home dashboard (never on radar/scan)
    return const FoodieShell();
  }
}
