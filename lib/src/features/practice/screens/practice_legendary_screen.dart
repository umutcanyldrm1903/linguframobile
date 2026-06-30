import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_repository.dart';
import 'practice_visuals.dart';

class PracticeLegendaryScreen extends StatefulWidget {
  const PracticeLegendaryScreen({super.key});

  @override
  State<PracticeLegendaryScreen> createState() =>
      _PracticeLegendaryScreenState();
}

class _PracticeLegendaryScreenState extends State<PracticeLegendaryScreen> {
  static const PracticeRepository _repository = PracticeRepository();

  bool _loading = true;
  List<PracticeLesson> _lessons = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final lessons = await _repository.fetchLegendaryLessons();
    if (!mounted) return;
    setState(() {
      _lessons = lessons;
      _loading = false;
    });
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
        title: const Text(
          'Ustalık Modu',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(
              child: MascotLoading(message: 'Ustalık dersleri hazırlanıyor...'),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFE08A),
                        width: 2,
                      ),
                    ),
                    child: const Column(
                      children: [
                        PracticeMascot(
                          size: 118,
                          mood: PracticeMascotMood.proud,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Bir hata hakkın var',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: practiceInk,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'En az %90 doğrulukla bitir ve dersi ustalık seviyesine çıkar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: practiceMuted,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_lessons.isEmpty)
                    const _EmptyLegendary()
                  else
                    for (final lesson in _lessons)
                      _LegendaryLessonCard(
                        lesson: lesson,
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            '/practice/lesson',
                            arguments: lesson.copyWith(
                              mode: 'legendary',
                              locked: false,
                            ),
                          );
                          if (mounted) await _load();
                        },
                      ),
                ],
              ),
            ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 0),
    );
  }
}

class _EmptyLegendary extends StatelessWidget {
  const _EmptyLegendary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: const Column(
        children: [
          Icon(Icons.lock_open_rounded, color: practiceMuted, size: 46),
          SizedBox(height: 12),
          Text(
            'Henüz ustalık dersi açılmadı',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: practiceInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Normal derslerden birini tamamladığında burada görünecek.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: practiceMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendaryLessonCard extends StatelessWidget {
  const _LegendaryLessonCard({
    required this.lesson,
    required this.onTap,
  });

  final PracticeLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mastered = lesson.status == 'legendary';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: mastered ? practiceYellow : practiceLine,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF6CF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              mastered
                  ? Icons.workspace_premium_rounded
                  : Icons.auto_awesome_rounded,
              color: practiceYellow,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mastered
                      ? 'Ustalık tamamlandı · tekrar oynanabilir'
                      : 'Zor mod · ${lesson.xp} XP',
                  style: const TextStyle(
                    color: practiceMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: mastered ? practiceYellow : practiceGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              mastered ? 'TEKRAR' : 'BAŞLA',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
