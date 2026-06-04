import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/activity/activity_log_service.dart';
import 'core/contact_filter/contact_filter_preferences.dart';
import 'core/contact_filter/contact_filter_sms_policy.dart';
import 'core/services/lifecycle/foreground_sync_coordinator.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_pages.dart';
import 'core/services/auth/user_repository.dart';
import 'core/services/blocked/is_blocked_sync_service.dart';
import 'core/services/subscription/subscription_sync_service.dart';
import 'core/services/local/onboarding_state_service.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/services/notifications/fcm_handler.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      assert(() {
        debugPrint('ReplyMate: main() started');
        return true;
      }());

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        FlutterError.dumpErrorToConsole(
          FlutterErrorDetails(exception: error, stack: stack),
        );
        return true;
      };

      // Initialize Firebase BEFORE runApp so auth is available immediately.
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
      } catch (e, st) {
        assert(() {
          debugPrint('ReplyMate: Firebase.initializeApp failed: $e\n$st');
          return true;
        }());
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp();
          }
        } catch (_) {}
      }

      // Register critical Get services synchronously so bindings/controllers can
      // resolve dependencies immediately (prevents release white-screen).
      if (!Get.isRegistered<OnboardingStateService>()) {
        Get.put<OnboardingStateService>(
          OnboardingStateService(),
          permanent: true,
        );
      }
      if (!Get.isRegistered<UserRepository>()) {
        Get.put<UserRepository>(UserRepository(), permanent: true);
      }
      if (!Get.isRegistered<IsBlockedSyncService>()) {
        Get.put<IsBlockedSyncService>(IsBlockedSyncService(), permanent: true);
      }
      if (!Get.isRegistered<SubscriptionSyncService>()) {
        Get.put<SubscriptionSyncService>(
          SubscriptionSyncService(),
          permanent: true,
        );
      }

      // Restore persisted theme BEFORE runApp so there is no flash.
      final prefs = await SharedPreferences.getInstance();
      final savedModeIndex = prefs.getInt('theme_mode');
      final initialThemeMode = savedModeIndex != null
          ? ThemeMode.values[savedModeIndex.clamp(
              0,
              ThemeMode.values.length - 1,
            )]
          : ThemeMode.system;

      runApp(ReplyMateApp(initialThemeMode: initialThemeMode));

      unawaited(_postRunAppBootstrap());
    },
    (error, stack) {
      FlutterError.dumpErrorToConsole(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    },
  );
}

Future<void> _postRunAppBootstrap() async {
  assert(() {
    debugPrint('ReplyMate: postRunAppBootstrap start');
    return true;
  }());

  // Firebase is already initialized in main() before runApp().

  try {
    await Hive.initFlutter();
    
    // Initialize Push Notifications
    await PushNotificationService.init();
    await PushNotificationHandler.init();
    
    await ActivityLogService.init();
    await ActivityLogService.instance.syncPendingFromNative();
    await ActivityLogService.instance.cleanOldLogs();
  } catch (e, st) {
    assert(() {
      debugPrint('ReplyMate: activity log bootstrap failed: $e\n$st');
      return true;
    }());
  }

  try {
    await ContactFilterSmsPolicy.instance.hydrate();
  } catch (e, st) {
    assert(() {
      debugPrint('ReplyMate: contact filter hydrate failed: $e\n$st');
      return true;
    }());
  }

  try {
    // Best-effort: complete prefs init for onboarding service.
    await Get.find<OnboardingStateService>().init();
  } catch (e, st) {
    assert(() {
      debugPrint('ReplyMate: onboarding init failed: $e\n$st');
      return true;
    }());
  }

  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e, st) {
    assert(() {
      debugPrint('ReplyMate: setPreferredOrientations failed: $e\n$st');
      return true;
    }());
  }

  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        // Match SafeArea/status bar to AppBar primary color.
        statusBarColor: Color(0xFF24389C),
        statusBarIconBrightness: Brightness.light,
      ),
    );
  } catch (e, st) {
    assert(() {
      debugPrint('ReplyMate: setSystemUIOverlayStyle failed: $e\n$st');
      return true;
    }());
  }
  assert(() {
    debugPrint('ReplyMate: postRunAppBootstrap done');
    return true;
  }());
}

Future<void> _syncContactFilterToNativeSafe() async {
  try {
    await ContactFilterPreferences().syncToNative();
  } catch (e, st) {
    assert(() {
      debugPrint('ReplyMate: syncToNative post-frame failed: $e\n$st');
      return true;
    }());
  }
}

class ReplyMateApp extends StatefulWidget {
  const ReplyMateApp({super.key, this.initialThemeMode = ThemeMode.system});

  final ThemeMode initialThemeMode;

  @override
  State<ReplyMateApp> createState() => _ReplyMateAppState();
}

class _ReplyMateAppState extends State<ReplyMateApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_syncContactFilterToNativeSafe());
    });
  }

  @override
  void dispose() {
    ForegroundSyncCoordinator.instance.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ForegroundSyncCoordinator.instance.onAppLifecycleChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ReplyMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: widget.initialThemeMode,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
