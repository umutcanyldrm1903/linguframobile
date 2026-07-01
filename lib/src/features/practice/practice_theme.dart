import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/localization/app_strings.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import 'screens/practice_visuals.dart';

const bool _practiceQaAuthBypass =
    bool.fromEnvironment('PRACTICE_QA_AUTH_BYPASS');

/// Akıllı Kalem Defteri pratik modülünü saran yerel tema.
/// Yuvarlak Nunito fontu ve oyunlaştırılmış kontrol stillerini uygular;
/// LMS tarafının global Poppins teması etkilenmez.
class PracticeTheme extends StatelessWidget {
  const PracticeTheme(
      {super.key, required this.child, this.allowGuest = false});

  final Widget child;

  /// true ise giriş kapısı (_PracticeAuthGate) atlanır — yalnızca giriş
  /// gerektirmeyen "misafir tadımlık" akışı için kullanılır.
  final bool allowGuest;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final body = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: practiceInk,
      displayColor: practiceInk,
    );
    // El-yazısı (Caveat) yalnızca büyük başlıklarda; gövde okunaklı Nunito kalır.
    final textTheme = body.copyWith(
      displayLarge: GoogleFonts.caveat(
          textStyle: body.displayLarge,
          fontWeight: FontWeight.w700,
          color: practiceInk),
      displayMedium: GoogleFonts.caveat(
          textStyle: body.displayMedium,
          fontWeight: FontWeight.w700,
          color: practiceInk),
      headlineLarge: GoogleFonts.caveat(
          textStyle: body.headlineLarge,
          fontWeight: FontWeight.w700,
          color: practiceInk),
    );

    return Theme(
      data: base.copyWith(
        textTheme: textTheme,
        primaryTextTheme: textTheme,
        scaffoldBackgroundColor: practiceKraft,
        colorScheme: base.colorScheme.copyWith(
          primary: practiceGreen,
          secondary: practiceBlue,
          surface: practicePaper,
        ),
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: practiceKraft,
          foregroundColor: practiceInk,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: practiceInk,
            fontSize: 18,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: practiceGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE5E5E5),
            disabledForegroundColor: const Color(0xFFAFAFAF),
            elevation: 0,
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
              fontSize: 16,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: practiceBlue,
            side: const BorderSide(color: practiceLine, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: .4,
              fontSize: 14,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: practiceBlue,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
        ),
        chipTheme: base.chipTheme.copyWith(
          backgroundColor: const Color(0xFFF3F7FF),
          selectedColor: practiceBlue.withValues(alpha: .16),
          side: const BorderSide(color: practiceLine, width: 2),
          labelStyle: const TextStyle(
            color: practiceInk,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: practicePaper,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(
            color: practiceMuted,
            fontWeight: FontWeight.w700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: practiceLine, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: practiceLine, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: practiceBlue, width: 2),
          ),
        ),
      ),
      child: allowGuest ? child : _PracticeAuthGate(child: child),
    );
  }
}

class _PracticeAuthGate extends StatefulWidget {
  const _PracticeAuthGate({required this.child});

  final Widget child;

  @override
  State<_PracticeAuthGate> createState() => _PracticeAuthGateState();
}

class _PracticeAuthGateState extends State<_PracticeAuthGate> {
  late final Future<bool> _signedIn = _hasToken();

  Future<bool> _hasToken() async {
    if (_practiceQaAuthBypass) return true;
    final token = (await SecureStorage.getToken() ?? '').trim();
    if (token.isEmpty) return false;

    try {
      await ApiClient.dio
          .get('/check-access-token')
          .timeout(const Duration(seconds: 10));
      return true;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        await SecureStorage.clearToken();
        await SecureStorage.deleteValue('pending_after_login_route_v1');
        return false;
      }

      // If the network is temporarily unavailable, let the target screen show
      // its detailed connection diagnostic instead of forcing a logout.
      return true;
    } on Object {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _signedIn,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: PracticeMascotLoader(label: 'Hazırlanıyor')),
          );
        }

        if (snapshot.data == true) {
          return widget.child;
        }

        final routeName = ModalRoute.of(context)?.settings.name ?? '/practice';
        return _PracticeGuestGate(routeName: routeName);
      },
    );
  }
}

class _PracticeGuestGate extends StatelessWidget {
  const _PracticeGuestGate({required this.routeName});

  static const _pendingAfterLoginRouteKey = 'pending_after_login_route_v1';

  final String routeName;

  Future<void> _openAuth(BuildContext context, String route) async {
    await SecureStorage.setValue(
      _pendingAfterLoginRouteKey,
      routeName.startsWith('/practice') ? routeName : '/practice',
    );
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                color: const Color(0xFF9AA0A6),
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: PracticeMascot(
                size: 148,
                mood: PracticeMascotMood.excited,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isTr ? 'Pratik yapmak için giriş yap' : 'Sign in to practice',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: practiceInk,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              isTr
                  ? 'XP, seri, can, rozet ve ders yolu hesabına bağlı tutulur. Bu yüzden pratik modu sadece giriş yapan kullanıcılar için açılır.'
                  : 'XP, streaks, hearts, badges, and lesson progress are tied to your account, so practice opens after sign-in.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: practiceMuted,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 24),
            _GuestFeatureRow(
              icon: Icons.route_rounded,
              color: practiceGreen,
              title: isTr ? 'Ders yolunda ilerle' : 'Follow the lesson path',
              detail: isTr
                  ? 'Kısa pratikleri bitir, yeni derslerin kilidini aç.'
                  : 'Finish short practices and unlock new lessons.',
            ),
            _GuestFeatureRow(
              icon: Icons.local_fire_department_rounded,
              color: practiceOrange,
              title: isTr ? 'Serini koru' : 'Protect your streak',
              detail: isTr
                  ? 'Günlük seri, can ve ödüller hesabında saklanır.'
                  : 'Daily streak, hearts, and rewards stay on your account.',
            ),
            _GuestFeatureRow(
              icon: Icons.workspace_premium_rounded,
              color: practiceBlue,
              title: isTr ? 'XP ve rozet kazan' : 'Earn XP and badges',
              detail: isTr
                  ? 'Sonuçların, hatalarin ve hedeflerin kaydedilir.'
                  : 'Results, mistakes, and goals are saved.',
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => _openAuth(context, '/login'),
                child: Text(isTr ? 'GİRİŞ YAP VE BAŞLA' : 'SIGN IN TO START'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: () => _openAuth(context, '/register'),
                child: Text(isTr ? 'HESAP OLUŞTUR' : 'CREATE ACCOUNT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestFeatureRow extends StatelessWidget {
  const _GuestFeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: practiceInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: practiceMuted,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
