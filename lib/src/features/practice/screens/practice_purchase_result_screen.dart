import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import 'practice_visuals.dart';

class PracticePurchaseResultScreen extends StatefulWidget {
  const PracticePurchaseResultScreen({super.key});

  @override
  State<PracticePurchaseResultScreen> createState() =>
      _PracticePurchaseResultScreenState();
}

class _PracticePurchaseResultScreenState
    extends State<PracticePurchaseResultScreen> {
  final PracticeApiService _api = const PracticeApiService();
  Map<String, dynamic> _status = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await _api.getPremiumStatus();
    if (!mounted) return;
    setState(() {
      _status = status ?? {'is_premium': false};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final premium = _status['is_premium'] == true;
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: MascotLoading(message: 'Kontrol ediliyor...'))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  children: [
                    const Spacer(),
                    PracticeConfettiOverlay(
                      active: premium,
                      child: PracticeMascot(
                        size: 160,
                        mood: premium
                            ? PracticeMascotMood.excited
                            : PracticeMascotMood.thinking,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      premium ? 'Premium aktif!' : 'Satin alma doğrulanmadi',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: practiceInk,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      premium
                          ? 'Backend satin almani doğruladi. Sınırsız pratik hazır.'
                          : 'Store işlemi tamamlanmadiysa geri yükle veya tekrar dene.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: practiceMuted,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    PracticePrimaryButton(
                      label: premium ? 'PRATİĞE DÖN' : 'PREMIUM SAYFASINA DÖN',
                      color: premium ? practiceGreen : practiceBlue,
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        premium ? '/practice' : '/practice/premium',
                        (route) => route.isFirst,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
