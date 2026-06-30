import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/storage/secure_storage.dart';
import '../practice_theme.dart';
import 'practice_placement_screen.dart';
import 'practice_visuals.dart';

/// İlk açılış "hızlı başlangıç" akışı (zorunlu test değil — atlanabilir):
/// kısa karşılama + DEVAM → giriş gerektirmeyen 5 soruluk hızlı seviye
/// belirleme → sonuç/teklif ekranı (tahmini seviye + "XP/serini kaydet: giriş
/// yap" veya "ana ekrana geç") → ana hub'a (/app-home).
/// Akıllı Kalem Defteri kimliğiyle; XP/seri yalnız girişten sonra kaydedilir.
class PracticeTasterScreen extends StatefulWidget {
  const PracticeTasterScreen({super.key});

  @override
  State<PracticeTasterScreen> createState() => _PracticeTasterScreenState();
}

class _PracticeTasterScreenState extends State<PracticeTasterScreen> {
  // Login sonrası kullanıcıyı pratiğe döndürmek için (XP/seri orada kaydolur).
  static const _pendingAfterLoginRouteKey = 'pending_after_login_route_v1';

  bool _busy = false;

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    // Girişsiz hızlı seviye belirleme; sonuç ekranındaki butonlar yönlendirir.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeTheme(
          allowGuest: true,
          child: PracticePlacementScreen(
            guest: true,
            onGuestSignIn: _signIn,
            onGuestHome: _goHome,
          ),
        ),
      ),
    );
    // Kullanıcı geri tuşuyla çıktıysa karşılamaya döner; butonu tekrar aç.
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _signIn() async {
    await SecureStorage.setValue(_pendingAfterLoginRouteKey, '/practice');
    await AppPreferences.markAppHomeSeen();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _goHome() async {
    await AppPreferences.markAppHomeSeen();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/app-home');
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Scaffold(
      backgroundColor: practiceKraft,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : () => _goHome(),
                  child: Text(isTr ? 'Atla' : 'Skip'),
                ),
              ),
              const Spacer(),
              const PracticeMascot(size: 150, mood: PracticeMascotMood.excited),
              const SizedBox(height: 26),
              Text(
                isTr ? 'Hızlı başlangıç' : 'Quick start',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: practiceInk,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isTr
                    ? 'Birkaç kısa soru — giriş gerekmez, istediğin an atlayabilirsin. Tahmini seviyeni görelim; sonra canlı dersler ve oyunlu pratik seni bekliyor.'
                    : 'A few quick questions — no sign-in, skip anytime. See your estimated level; then live lessons and gamified practice await.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: practiceMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const Spacer(),
              Practice3DButton(
                label: isTr ? 'DEVAM' : 'CONTINUE',
                onPressed: _busy ? null : () => _start(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
