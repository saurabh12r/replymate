import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is already initialized by the JS in index.html.
  // initializeApp() here just connects Flutter to that existing instance.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ NOTE: Do NOT call FirebaseFirestore.instance.settings() here.
  // On Flutter Web the Firestore transport is a JS WebChannel — the Dart
  // Settings() API has no effect on it. Long-polling is forced at the JS
  // level in index.html via experimentalForceLongPolling: true instead.

  runApp(const ProviderScope(child: AdminBrokerApp()));
}

class AdminBrokerApp extends ConsumerWidget {
  const AdminBrokerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isDark = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ReplyMet Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
