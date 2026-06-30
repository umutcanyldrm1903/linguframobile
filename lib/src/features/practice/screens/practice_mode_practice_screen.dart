import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_repository.dart';
import 'practice_session_screen.dart';
import 'practice_visuals.dart';

class PracticeModePracticeScreen extends StatefulWidget {
  const PracticeModePracticeScreen({super.key});

  @override
  State<PracticeModePracticeScreen> createState() =>
      _PracticeModePracticeScreenState();
}

class _PracticeModePracticeScreenState
    extends State<PracticeModePracticeScreen> {
  static const PracticeRepository _repository = PracticeRepository();
  bool _loading = false;

  Future<void> _startMode(String mode, String title) async {
    if (_loading) return;
    setState(() => _loading = true);
    final questions = await _repository.loadModeQuestions(mode);
    if (!mounted) return;
    setState(() => _loading = false);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionScreen(
          title: title,
          questions: questions,
          onComplete: (correct, total) async {
            final data = await _repository.api.completeModePractice(mode, {
              'correct_count': correct,
              'total_count': total,
            });
            final xp = data?['xp_awarded'];
            return xp != null ? '+$xp XP' : null;
          },
        ),
      ),
    );
  }

  Future<void> _startAdaptive() async {
    if (_loading) return;
    setState(() => _loading = true);
    final questions = await _repository.loadAdaptiveQuestions();
    if (!mounted) return;
    setState(() => _loading = false);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionScreen(
          title: 'Adaptif oturum',
          questions: questions,
          // Adaptif sorular cevaplandıkça answerQuestion ile zaten kaydedilir.
          onComplete: (correct, total) async => null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: practiceInk,
        centerTitle: true,
        title: const Text('Pratik Modlari',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              Row(
                children: const [
                  PracticeMascot(size: 104, mood: PracticeMascotMood.excited),
                  SizedBox(width: 12),
                  Expanded(
                      child: PracticeSpeechBubble(
                          text: 'Bugün hangi oyunlu pratik modunu açalım?')),
                ],
              ),
              const SizedBox(height: 18),
              _ModeCard(
                icon: Icons.all_inclusive_rounded,
                title: 'Sınırsız Pratik',
                subtitle: 'İnternetten sürekli taze çeviri soruları',
                color: practicePurple,
                onTap: () => _startMode('tatoeba', 'Sınırsız pratik'),
              ),
              _ModeCard(
                icon: Icons.style_rounded,
                title: 'Kelime Pratiği',
                subtitle: 'Anlam, ses ve secenekli kelime tekrari',
                color: practiceBlue,
                onTap: () => _startMode('vocabulary', 'Kelime pratiği'),
              ),
              _ModeCard(
                icon: Icons.menu_book_rounded,
                title: 'Gramer Pratiği',
                subtitle: 'Bosluk ve cümle sirasi',
                color: practiceGreen,
                onTap: () => _startMode('grammar', 'Gramer pratiği'),
              ),
              _ModeCard(
                icon: Icons.volume_up_rounded,
                title: 'Dinleme Pratiği',
                subtitle: 'Sesli sorular ve anlama',
                color: practiceOrange,
                onTap: () => _startMode('listening', 'Dinleme pratiği'),
              ),
              _ModeCard(
                icon: Icons.mic_rounded,
                title: 'Konuşma Pratiği',
                subtitle: 'STT ve kelime bazli skor',
                color: practicePurple,
                onTap: () => Navigator.pushNamed(context, '/practice/speaking'),
              ),
              _ModeCard(
                icon: Icons.timer_rounded,
                title: 'Match Madness',
                subtitle: 'Süreli eslestirme oyunu',
                color: practiceBlue,
                onTap: () =>
                    Navigator.pushNamed(context, '/practice/match-madness'),
              ),
              _ModeCard(
                icon: Icons.track_changes_rounded,
                title: 'Adaptif Oturum',
                subtitle: 'Performansina göre secilir',
                color: practiceGreen,
                onTap: _startAdaptive,
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'Sınırsız Pratik cümleleri tatoeba.org (CC BY) kaynaklıdır.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: practiceMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black.withValues(alpha: .25),
              child: const Center(
                child: MascotLoading(message: 'Sorular hazırlanıyor...'),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 0),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: practiceLine, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 38),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: practiceInk,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: practiceMuted, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: practiceMuted),
          ],
        ),
      ),
    );
  }
}
