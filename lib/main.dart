import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lingufranca_mobile/src/core/localization/app_currency_provider.dart';
import 'package:lingufranca_mobile/src/core/localization/app_locale_provider.dart';
import 'package:lingufranca_mobile/src/core/localization/app_strings.dart';
import 'package:lingufranca_mobile/src/core/storage/secure_storage.dart';
import 'package:lingufranca_mobile/src/core/theme/app_colors.dart';
import 'package:lingufranca_mobile/src/core/theme/app_theme.dart';
import 'package:lingufranca_mobile/src/features/auth/login_screen.dart';
import 'package:lingufranca_mobile/src/features/auth/register_screen.dart';
import 'package:lingufranca_mobile/src/features/auth/forgot_password_screen.dart';
import 'package:lingufranca_mobile/src/features/auth/reset_password_screen.dart';
import 'package:lingufranca_mobile/src/features/home/home_screen.dart';
import 'package:lingufranca_mobile/src/features/public/about_screen.dart';
import 'package:lingufranca_mobile/src/features/public/blog_screen.dart';
import 'package:lingufranca_mobile/src/features/public/contact_screen.dart';
import 'package:lingufranca_mobile/src/features/public/corporate_screen.dart';
import 'package:lingufranca_mobile/src/features/public/placement_test_screen.dart';
import 'package:lingufranca_mobile/src/features/public/privacy_screen.dart';
import 'package:lingufranca_mobile/src/features/public/public_theme.dart';
import 'package:lingufranca_mobile/src/features/public/terms_screen.dart';
import 'package:lingufranca_mobile/src/features/shell/instructor_shell.dart';
import 'package:lingufranca_mobile/src/features/shell/student_shell.dart';
import 'package:lingufranca_mobile/src/features/payment/payment_native_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DateFormat(...) calls across student/instructor screens require intl locale data.
  await initializeDateFormatting();
  // Initialize the platform channel early so deep-links aren't missed.
  PaymentNativeService.deepLinkStream.listen((_) {});
  await AppStrings.load();
  await AppCurrency.load();
  runApp(const ProviderScope(child: LingufrancaApp()));
}

class LingufrancaApp extends ConsumerWidget {
  const LingufrancaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appLocaleProvider);
    ref.watch(appCurrencyProvider);
    return MaterialApp(
      title: 'Lingufranca',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/': (_) => const PublicTheme(child: HomeScreen()),
        '/home': (_) => const PublicTheme(child: HomeScreen()),
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/about': (_) => const PublicTheme(child: AboutScreen()),
        '/blog': (_) => const PublicTheme(child: BlogScreen()),
        '/contact': (_) => const PublicTheme(child: ContactScreen()),
        '/corporate': (_) => const PublicTheme(child: CorporateScreen()),
        '/placement-test': (_) =>
            const PublicTheme(child: PlacementTestScreen()),
        '/terms': (_) => const PublicTheme(child: TermsScreen()),
        '/privacy': (_) => const PublicTheme(child: PrivacyScreen()),
        '/student': (_) => const StudentShell(),
        '/instructor': (_) => const InstructorShell(),
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    final token = await SecureStorage.getToken();
    final role = await SecureStorage.getRole();
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      if (role == 'instructor') {
        Navigator.pushReplacementNamed(context, '/instructor');
      } else {
        Navigator.pushReplacementNamed(context, '/student');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.brand, Color(0xFFFBBF24)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white,
                child: Icon(Icons.school, color: AppColors.brand, size: 40),
              ),
              SizedBox(height: 16),
              Text(
                'Lingufranca',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        label: Text(AppStrings.t('Start')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
