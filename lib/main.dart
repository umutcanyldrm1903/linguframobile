import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lingufranca_mobile/src/core/localization/app_currency_provider.dart';
import 'package:lingufranca_mobile/src/core/localization/app_locale_provider.dart';
import 'package:lingufranca_mobile/src/core/localization/app_strings.dart';
import 'package:lingufranca_mobile/src/core/analytics/app_telemetry_service.dart';
import 'package:lingufranca_mobile/src/core/motion/app_motion.dart';
import 'package:lingufranca_mobile/src/core/notifications/app_notification_service.dart';
import 'package:lingufranca_mobile/src/core/storage/app_preferences.dart';
import 'package:lingufranca_mobile/src/core/storage/secure_storage.dart';
import 'package:lingufranca_mobile/src/core/theme/app_theme.dart';
import 'package:lingufranca_mobile/src/features/auth/login_screen.dart';
import 'package:lingufranca_mobile/src/features/auth/register_screen.dart';
import 'package:lingufranca_mobile/src/features/auth/forgot_password_screen.dart';
import 'package:lingufranca_mobile/src/features/auth/reset_password_screen.dart';
import 'package:lingufranca_mobile/src/features/home/app_home_screen.dart';
import 'package:lingufranca_mobile/src/features/home/home_screen.dart';
import 'package:lingufranca_mobile/src/features/public/after_test_screen.dart';
import 'package:lingufranca_mobile/src/features/public/about_screen.dart';
import 'package:lingufranca_mobile/src/features/public/blog_screen.dart';
import 'package:lingufranca_mobile/src/features/public/contact_screen.dart';
import 'package:lingufranca_mobile/src/features/public/corporate_screen.dart';
import 'package:lingufranca_mobile/src/features/public/placement_test_screen.dart';
import 'package:lingufranca_mobile/src/features/public/privacy_screen.dart';
import 'package:lingufranca_mobile/src/features/public/public_theme.dart';
import 'package:lingufranca_mobile/src/features/practice/practice_ad_service.dart';
import 'package:lingufranca_mobile/src/features/practice/practice_assistant_overlay.dart';
import 'package:lingufranca_mobile/src/features/practice/practice_screens.dart';
import 'package:lingufranca_mobile/src/features/practice/practice_theme.dart';
import 'package:lingufranca_mobile/src/features/public/terms_screen.dart';
import 'package:lingufranca_mobile/src/features/shell/instructor_shell.dart';
import 'package:lingufranca_mobile/src/features/shell/student_shell.dart';
import 'package:lingufranca_mobile/src/features/auth/auth_provider.dart';
import 'package:lingufranca_mobile/src/features/payment/payment_native_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureIosStoreKit();
  AppTelemetryService.instance.initialize();
  // Initialize the platform channel early so deep-links aren't missed.
  PaymentNativeService.deepLinkStream.listen((_) {});

  runApp(const ProviderScope(child: LingufrancaApp()));
  unawaited(_runStartupTask('warmup', _warmUpAppServices));
}

Future<void> _configureIosStoreKit() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

  try {
    // StoreKit 2 can return an empty platform response for otherwise valid
    // App Store products. Re-register the official plugin with its StoreKit 1
    // compatibility path before any purchase stream or product query starts.
    // ignore: deprecated_member_use
    await InAppPurchaseStoreKitPlatform.enableStoreKit1();
    InAppPurchaseStoreKitPlatform.registerPlatform();
  } catch (error, stackTrace) {
    debugPrint('StoreKit compatibility setup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _warmUpAppServices() async {
  await _runStartupTask('localization', () async {
    await Future.wait([
      initializeDateFormatting(),
      AppStrings.load(),
      AppCurrency.load(),
    ]);
  });

  await _runStartupTask(
    'telemetry-ready',
    AppTelemetryService.instance.markAppReady,
  );
  unawaited(_runStartupTask(
    'notifications',
    AppNotificationService.instance.initialize,
  ));
  unawaited(_runStartupTask('ads', () => PracticeAdService().initialize()));
}

Future<void> _runStartupTask(
  String name,
  Future<void> Function() task,
) async {
  try {
    await task();
  } catch (error, stackTrace) {
    debugPrint('Startup task failed ($name): $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class LingufrancaApp extends ConsumerWidget {
  const LingufrancaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appLocaleProvider);
    ref.watch(appCurrencyProvider);
    // Initialize auth token from secure storage
    ref.watch(authTokenInitializationProvider);
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      navigatorObservers: [practiceAssistantRouteObserver],
      title: 'Lingufranca',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => PracticeAssistantOverlay(
        child: child ?? const SizedBox.shrink(),
      ),
      initialRoute: '/splash',
      routes: {
        '/': (_) => const PublicTheme(child: HomeScreen()),
        '/home': (_) => const PublicTheme(child: HomeScreen()),
        '/app-home': (_) => const AppHomeScreen(),
        '/splash': (_) => const SplashScreen(),
        '/taster': (_) => const PracticeTheme(
            allowGuest: true, child: PracticeTasterScreen()),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/about': (_) => const PublicTheme(child: AboutScreen()),
        '/after-test': (_) => const PublicTheme(child: AfterTestScreen()),
        '/blog': (_) => const PublicTheme(child: BlogScreen()),
        '/contact': (_) => const PublicTheme(child: ContactScreen()),
        '/corporate': (_) => const PublicTheme(child: CorporateScreen()),
        '/placement-test': (_) =>
            const PublicTheme(child: PlacementTestScreen()),
        '/terms': (_) => const PublicTheme(child: TermsScreen()),
        '/privacy': (_) => const PublicTheme(child: PrivacyScreen()),
        '/start-speaking': (_) =>
            const PracticeTheme(child: PracticeHomeScreen()),
        '/student': (_) => const StudentShell(),
        '/instructor': (_) => const InstructorShell(),
        '/practice': (_) => const PracticeTheme(child: PracticeHomeScreen()),
        '/practice/onboarding': (_) =>
            const PracticeTheme(child: PracticeOnboardingScreen()),
        '/practice/path': (_) =>
            const PracticeTheme(child: PracticePathScreen()),
        '/practice/placement': (_) =>
            const PracticeTheme(child: PracticePlacementScreen()),
        '/practice/leaderboard': (_) =>
            const PracticeTheme(child: PracticeLeaderboardScreen()),
        '/practice/shop': (_) =>
            const PracticeTheme(child: PracticeShopScreen()),
        '/practice/profile': (_) =>
            const PracticeTheme(child: PracticeProfileScreen()),
        '/practice/friends': (_) =>
            const PracticeTheme(child: PracticeFriendsScreen()),
        '/practice/streak': (_) =>
            const PracticeTheme(child: PracticeStreakScreen()),
        '/practice/streak-repair': (_) =>
            const PracticeTheme(child: PracticeStreakRepairScreen()),
        '/practice/hearts': (_) =>
            const PracticeTheme(child: PracticeHeartsScreen()),
        '/practice/energy': (_) =>
            const PracticeTheme(child: PracticeEnergyScreen()),
        '/practice/xp-boost': (_) =>
            const PracticeTheme(child: PracticeXpBoostScreen()),
        '/practice/legendary': (_) =>
            const PracticeTheme(child: PracticeLegendaryScreen()),
        '/practice/achievements': (_) =>
            const PracticeTheme(child: PracticeAchievementsScreen()),
        '/practice/daily-quests': (_) =>
            const PracticeTheme(child: PracticeDailyQuestsScreen()),
        '/practice/quests': (_) =>
            const PracticeTheme(child: PracticeDailyQuestsScreen()),
        '/practice/weekly-quests': (_) =>
            const PracticeTheme(child: PracticeWeeklyQuestsScreen()),
        '/practice/hub': (_) => const PracticeTheme(child: PracticeHubScreen()),
        '/practice/guidebook': (_) =>
            const PracticeTheme(child: PracticeGuidebookScreen()),
        '/practice/league-result': (_) =>
            const PracticeTheme(child: PracticeLeagueResultScreen()),
        '/practice/follow': (_) =>
            const PracticeTheme(child: PracticeFollowListScreen()),
        '/practice/treasure-chest': (_) =>
            const PracticeTheme(child: PracticeTreasureChestScreen()),
        '/practice/daily-chests': (_) =>
            const PracticeTheme(child: PracticeDailyChestsScreen()),
        '/practice/lucky-spin': (_) =>
            const PracticeTheme(child: PracticeLuckySpinScreen()),
        '/practice/streak-wager': (_) =>
            const PracticeTheme(child: PracticeStreakWagerScreen()),
        '/practice/streak-milestones': (_) =>
            const PracticeTheme(child: PracticeStreakMilestonesScreen()),
        '/practice/mistakes': (_) =>
            const PracticeTheme(child: PracticeMistakesScreen()),
        '/practice/weak-words': (_) =>
            const PracticeTheme(child: PracticeWeakWordsScreen()),
        '/practice/mode': (_) =>
            const PracticeTheme(child: PracticeModePracticeScreen()),
        '/practice/inventory': (_) =>
            const PracticeTheme(child: PracticeInventoryScreen()),
        '/practice/history': (_) =>
            const PracticeTheme(child: PracticeHistoryScreen()),
        '/practice/notifications': (_) =>
            const PracticeTheme(child: PracticeNotificationsScreen()),
        '/practice/notification-settings': (_) =>
            const PracticeTheme(child: PracticeNotificationSettingsScreen()),
        '/practice/offline': (_) =>
            const PracticeTheme(child: PracticeOfflineScreen()),
        '/practice/analytics': (_) =>
            const PracticeTheme(child: PracticeAnalyticsScreen()),
        '/practice/premium': (_) =>
            const PracticeTheme(child: PracticePremiumScreen()),
        '/practice/premium-compare': (_) =>
            const PracticeTheme(child: PracticePremiumCompareScreen()),
        '/practice/purchase-result': (_) =>
            const PracticeTheme(child: PracticePurchaseResultScreen()),
        '/practice/radio': (_) =>
            const PracticeTheme(child: PracticeRadioLessonScreen()),
        '/practice/story': (_) =>
            const PracticeTheme(child: PracticeStoryDetailScreen()),
        '/practice/special': (_) =>
            const PracticeTheme(child: PracticeSpecialListScreen()),
        '/practice/special-detail': (_) =>
            const PracticeTheme(child: PracticeSpecialDetailScreen()),
        '/practice/adventure': (_) =>
            const PracticeTheme(child: PracticeAdventurePlayScreen()),
        '/practice/challenge': (_) =>
            const PracticeTheme(child: PracticeChallengePlayScreen()),
        '/practice/ai-coach': (_) =>
            const PracticeTheme(child: PracticeAiCoachScreen()),
        '/practice/character-call': (_) =>
            const PracticeTheme(child: PracticeCharacterCallScreen()),
        '/practice/characters': (_) =>
            const PracticeTheme(child: PracticeCharactersScreen()),
        '/practice/speaking': (_) =>
            const PracticeTheme(child: PracticeSpeakingPracticeScreen()),
        '/practice/speaking-result': (_) =>
            const PracticeTheme(child: PracticeSpeakingResultScreen()),
        '/practice/reward-focus': (_) =>
            const PracticeTheme(child: PracticeRewardFocusScreen()),
        '/practice/match-madness': (_) =>
            const PracticeTheme(child: PracticeMatchMadnessScreen()),
        '/practice/cefr': (_) =>
            const PracticeTheme(child: PracticeCefrScoreScreen()),
        '/practice/settings': (_) =>
            const PracticeTheme(child: PracticeSettingsScreen()),
        '/practice/xp-history': (_) =>
            const PracticeTheme(child: PracticeXpHistoryScreen()),
        '/practice/coin-history': (_) =>
            const PracticeTheme(child: PracticeCoinHistoryScreen()),
        '/practice/lesson': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! PracticeLesson) {
            return const PracticeTheme(child: _PracticeLessonEntryScreen());
          }
          return PracticeTheme(child: PracticeLessonScreen(lesson: args));
        },
        '/practice/result': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is PracticeResultArgs) {
            return PracticeTheme(child: PracticeResultScreen(args: args));
          }
          return const PracticeTheme(child: PracticeHomeScreen());
        },
      },
    );
  }
}

class _PracticeLessonEntryScreen extends StatefulWidget {
  const _PracticeLessonEntryScreen();

  @override
  State<_PracticeLessonEntryScreen> createState() =>
      _PracticeLessonEntryScreenState();
}

class _PracticeLessonEntryScreenState
    extends State<_PracticeLessonEntryScreen> {
  static const _repository = PracticeRepository();
  late final Future<PracticeLesson?> _lesson = _loadLesson();

  Future<PracticeLesson?> _loadLesson() async {
    final lessons = await _repository.fetchLessons();
    for (final lesson in lessons) {
      if (!lesson.locked) return lesson;
    }
    return lessons.isEmpty ? null : lessons.first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PracticeLesson?>(
      future: _lesson,
      builder: (context, snapshot) {
        final lesson = snapshot.data;
        if (lesson != null) {
          return PracticeLessonScreen(lesson: lesson);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Pratik dersi bulunamadı',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error?.toString() ??
                          'Ders yolunu açıp tekrar dene.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/practice'),
                      child: const Text('Pratik ana sayfasına dön'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Set<String> _allowedNotificationRoutes = {
    '/home',
    '/app-home',
    '/start-speaking',
    '/student',
    '/instructor',
    '/practice',
    '/practice/path',
    '/practice/mistakes',
    '/practice/weak-words',
    '/practice/daily-quests',
    '/practice/shop',
    '/practice/friends',
    '/practice/streak',
    '/practice/streak-repair',
    '/practice/hearts',
    '/practice/xp-boost',
    '/practice/legendary',
    '/practice/achievements',
    '/practice/offline',
    '/practice/analytics',
    '/practice/quests',
    '/placement-test',
    '/login',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    final token = await SecureStorage.getToken();
    final role = await SecureStorage.getRole();
    final pendingRoute =
        await AppNotificationService.instance.consumePendingRoute();
    if (!mounted) return;
    if (pendingRoute != null &&
        _allowedNotificationRoutes.contains(pendingRoute)) {
      if (pendingRoute == '/student' && role == 'instructor') {
        Navigator.pushReplacementNamed(context, '/instructor');
        return;
      }
      if (pendingRoute == '/instructor' && role != 'instructor') {
        Navigator.pushReplacementNamed(
            context, token == null || token.isEmpty ? '/login' : '/student');
        return;
      }
      if ((pendingRoute == '/student' || pendingRoute == '/instructor') &&
          (token == null || token.isEmpty)) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      Navigator.pushReplacementNamed(context, pendingRoute);
      return;
    }
    if (token != null && token.isNotEmpty) {
      if (!mounted) return;
      // Eğitmen kendi paneline; öğrenci ise hub'a (AppHomeScreen) düşer. Hub'dan
      // hem gerçek LMS paneline (/student: kurslar/dersler/eğitmenler) hem oyunlu
      // pratiğe (/practice) tek dokunuşla geçer; ikisi de görünür kalır.
      Navigator.pushReplacementNamed(
        context,
        role == 'instructor' ? '/instructor' : '/app-home',
      );
    } else {
      final hasSeenAppHome = await AppPreferences.hasSeenAppHome();
      if (!mounted) return;
      // İlk açılış: misafir tadımlık (Devam → birkaç giriş-siz soru → hub).
      // Sonraki açılışlarda doğrudan hub gösterilir.
      Navigator.pushReplacementNamed(
        context,
        hasSeenAppHome ? '/app-home' : '/taster',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const Center(
        child: MascotLoading(
          message: 'LinguFranca hazirlaniyor...',
          size: 78,
        ),
      ),
    );
  }
}
