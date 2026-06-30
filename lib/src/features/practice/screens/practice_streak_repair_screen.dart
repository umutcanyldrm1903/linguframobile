import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../practice_repository.dart';
import '../practice_sound_service.dart';

class PracticeStreakRepairScreen extends StatefulWidget {
  const PracticeStreakRepairScreen({super.key});

  @override
  State<PracticeStreakRepairScreen> createState() =>
      _PracticeStreakRepairScreenState();
}

class _PracticeStreakRepairScreenState
    extends State<PracticeStreakRepairScreen> {
  static const PracticeRepository _repository = PracticeRepository();
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  bool _loading = false;
  bool _repaired = false;
  // Gerçek coin/seri değerleri (loadStats sabit 0 döndürür; canlıyı çekeriz).
  PracticeStats _stats = const PracticeRepository().loadStats();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final stats = await _repository.fetchStats();
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _repair() async {
    if (_loading) return;
    setState(() => _loading = true);
    final isTr = AppStrings.code == 'tr';
    final eligible = await _repository.checkStreakRepairEligible();
    if (!mounted) return;
    if (!eligible) {
      setState(() => _loading = false);
      _toast(isTr
          ? 'Seri tamiri için yeterli coin yok.'
          : 'Not enough coins for streak repair.');
      return;
    }

    final result = await _repository.repairStreak();
    if (!mounted) return;
    if (result['success'] != true) {
      setState(() => _loading = false);
      _toast(isTr
          ? 'Seri tamiri yapılamadı. Bağlantını kontrol et.'
          : 'Streak repair failed. Check your connection.');
      return;
    }
    // Başarı: gerçek güncel bakiyeyi/seriyi çek, sonra kutla.
    final fresh = await _repository.fetchStats();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _repaired = true;
      _stats = fresh;
    });
    _confetti.play();
    unawaited(PracticeSoundService.playStreak());
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final stats = _stats;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        title: Text(isTr ? 'Seri tamiri' : 'Streak repair'),
        backgroundColor: const Color(0xFFF6FAFF),
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                Color(0xFFFF9F1C),
                Color(0xFFFFD43B),
                Color(0xFF63D60F),
                Color(0xFF0E7C6B),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Spacer(),
                Icon(
                  _repaired
                      ? Icons.verified_rounded
                      : Icons.local_fire_department_rounded,
                  color: _repaired
                      ? const Color(0xFF63D60F)
                      : const Color(0xFFFF9F1C),
                  size: 96,
                ),
                const SizedBox(height: 18),
                Text(
                  _repaired
                      ? (isTr ? 'Serin kurtarildi!' : 'Streak saved!')
                      : (isTr ? 'Serini tamir et' : 'Repair your streak'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  _repaired
                      ? (isTr
                          ? '${stats.streak} günlük serin guvende.'
                          : 'Your ${stats.streak}-day streak is protected.')
                      : (isTr
                          ? '200 coin harcayarak kacirdigin günü telafi edebilirsin.'
                          : 'Spend 200 coins to recover a missed day.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        color: Color(0xFFFFD43B),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isTr
                              ? 'Mevcut coin: ${stats.coins}'
                              : 'Current coins: ${stats.coins}',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Text(
                        '-200',
                        style: TextStyle(
                          color: Color(0xFFFF5964),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        _repaired ? () => Navigator.pop(context) : _repair,
                    child: Text(
                      _loading
                          ? (isTr ? 'Tamir ediliyor...' : 'Repairing...')
                          : _repaired
                              ? (isTr ? 'Devam et' : 'Continue')
                              : (isTr ? 'Seriyi tamir et' : 'Repair streak'),
                    ),
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
