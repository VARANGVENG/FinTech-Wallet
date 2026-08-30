import 'package:fintech_wallet/app/main_navigation.dart';
import 'package:fintech_wallet/core/providers/core_providers.dart';
import 'package:fintech_wallet/core/storage/local_storage_service.dart';
import 'package:fintech_wallet/features/authentication/presentation/providers/auth_provider.dart';
import 'package:fintech_wallet/features/authentication/presentation/screen/login_screen.dart';
import 'package:fintech_wallet/features/authentication/presentation/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStorage = await LocalStorageService.create();

  runApp(
    ProviderScope(
      overrides: [localStorageProvider.overrideWithValue(localStorage)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamilyFallback: const ['NotoSansKhmer']),
      home: const _StartupGate(),
    );
  }
}

/// Decides where the app opens: `LoginScreen` if there's no saved auth
/// token, `MainNavigation` if there is one. This only checks whether a
/// token exists locally, not whether it's still valid server-side — an
/// expired/revoked token is instead caught by `AuthInterceptor` on the
/// first authenticated API call that gets a 401.
class _StartupGate extends ConsumerStatefulWidget {
  const _StartupGate();

  @override
  ConsumerState<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends ConsumerState<_StartupGate> {
  late final Future<bool> _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = _resolveInitialRoute();
  }

  Future<bool> _resolveInitialRoute() async {
    final hasToken = await ref.read(secureStorageProvider).isLoggedIn;
    if (!hasToken) return false;

    await ref.read(authProvider.notifier).restoreSession();
    // Re-check rather than trusting `hasToken`: `restoreSession()` clears
    // the token only on a confirmed 401. If it's still here, either the
    // session was confirmed valid, or we simply couldn't check (offline/5xx)
    // — either way, that's not grounds to bounce the user to LoginScreen.
    return ref.read(secureStorageProvider).isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }
        return snapshot.data == true
            ? const MainNavigation()
            : const LoginScreen();
      },
    );
  }
}
