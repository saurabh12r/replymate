import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/activity/activity_log_service.dart';
import 'core/contact_filter/contact_filter_preferences.dart';
import 'core/contact_filter/contact_filter_sms_policy.dart';
import 'core/services/lifecycle/foreground_sync_coordinator.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_pages.dart';
import 'core/services/auth/user_repository.dart';
import 'core/services/local/onboarding_state_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await ActivityLogService.init();
  await ActivityLogService.instance.syncPendingFromNative();
  await ActivityLogService.instance.cleanOldLogs();
  await ContactFilterSmsPolicy.instance.hydrate();

  final onboardingStateService = OnboardingStateService();
  await onboardingStateService.init();
  Get.put<OnboardingStateService>(onboardingStateService, permanent: true);
  if (!Get.isRegistered<UserRepository>()) {
    Get.put<UserRepository>(UserRepository(), permanent: true);
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ReplyMateApp());
}

class ReplyMateApp extends StatefulWidget {
  const ReplyMateApp({super.key});

  @override
  State<ReplyMateApp> createState() => _ReplyMateAppState();
}

class _ReplyMateAppState extends State<ReplyMateApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ContactFilterPreferences().syncToNative();
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
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
