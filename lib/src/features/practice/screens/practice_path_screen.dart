import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_repository.dart';
import 'practice_visuals.dart';

class PracticePathScreen extends StatefulWidget {
  const PracticePathScreen({super.key});

  @override
  State<PracticePathScreen> createState() => _PracticePathScreenState();
}

class _PracticePathScreenState extends State<PracticePathScreen> {
  static const PracticeRepository _repository = PracticeRepository();
  late Future<_PathData> _pathData;

  @override
  void initState() {
    super.initState();
    _pathData = _loadPathData();
  }

  Future<_PathData> _loadPathData() async {
    final stats = await _repository.fetchStats();
    final lessons = await _repository.fetchLessons();
    return _PathData(stats: stats, lessons: lessons);
  }

  void _retry() {
    setState(() => _pathData = _loadPathData());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PathData>(
      future: _pathData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: practiceKraft,
            body: SafeArea(
              child: Center(
                child: PracticeMascotLoader(label: 'Ders yolu hazırlanıyor'),
              ),
            ),
            bottomNavigationBar: PracticeBottomTabs(selected: 0),
          );
        }

        final data = snapshot.data;
        if (snapshot.hasError || data == null || data.lessons.isEmpty) {
          final error = snapshot.error;
          final isAuthError = error is PracticeAuthException;
          final detail = error is PracticeApiLoadException
              ? error.message
              : isAuthError
                  ? 'Ders yoluna devam etmek için yeniden giriş yap.'
                  : 'Bağlantını kontrol edip tekrar dene.';
          return Scaffold(
            backgroundColor: practiceKraft,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: practiceBlue,
                        size: 54,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isAuthError
                            ? 'Oturum yenilemen gerekiyor'
                            : 'Ders yolu yüklenemedi',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: practiceInk,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        detail,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: practiceMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: isAuthError
                            ? () => Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                )
                            : _retry,
                        icon: Icon(
                          isAuthError
                              ? Icons.login_rounded
                              : Icons.refresh_rounded,
                        ),
                        label: Text(isAuthError ? 'Giriş yap' : 'Tekrar dene'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: const PracticeBottomTabs(selected: 0),
          );
        }

        final stats = data.stats;
        final lessons = data.lessons;

        return Scaffold(
          backgroundColor: practiceKraft,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _PathTopBar(stats: stats),
                _PathUnitHeader(
                  section: '1. Kısım: Çaylak',
                  title: '1. Ünite',
                  subtitle: 'İçecek teklif et ve kabul et',
                ),
                Expanded(
                  // Yılankavi yol + daire balon YOK → dikey "ciltli defter"
                  // listesi; her ders = kâğıt satır + mürekkep-dolum göstergesi.
                  child: lessons.isEmpty
                      ? const Center(child: PracticeMascotLoader())
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                          itemCount: lessons.length,
                          itemBuilder: (context, i) {
                            final lesson = lessons[i];
                            final isLast = i == lessons.length - 1;
                            final status = lesson.status == 'completed' ||
                                    lesson.status == 'legendary'
                                ? _RowStatus.done
                                : lesson.locked
                                    ? _RowStatus.locked
                                    : isLast &&
                                            (lesson.icon == 'checkpoint' ||
                                                lesson.icon == 'test_lesson')
                                        ? _RowStatus.test
                                        : _RowStatus.active;
                            return _LessonRow(
                              index: i + 1,
                              lesson: lesson,
                              status: status,
                              progress: i == 0 ? 0.6 : 0.0,
                              onTap: status == _RowStatus.locked
                                  ? null
                                  : (isLast
                                      ? () => Navigator.pushNamed(
                                          context, '/practice/legendary')
                                      : () => _openLesson(lesson)),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const PracticeBottomTabs(selected: 0),
        );
      },
    );
  }

  void _openLesson(PracticeLesson lesson) {
    Navigator.pushNamed(context, '/practice/lesson', arguments: lesson);
  }
}

class _PathData {
  const _PathData({required this.stats, required this.lessons});

  final PracticeStats stats;
  final List<PracticeLesson> lessons;
}

class _PathTopBar extends StatelessWidget {
  const _PathTopBar({required this.stats});

  final PracticeStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: practiceKraft,
        border: Border(bottom: BorderSide(color: practiceLine, width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Row(
        children: [
          const Icon(Icons.auto_stories_rounded, color: practiceInk, size: 22),
          const SizedBox(width: 8),
          const Text(
            'İngilizce Defteri',
            style: TextStyle(
              color: practiceInk,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          _TopStat(
            icon: Icons.local_fire_department_rounded,
            value: '${stats.streak}',
            color: practiceOrange,
          ),
          const SizedBox(width: 18),
          _TopStat(
            icon: Icons.water_drop_rounded,
            value: '${stats.coins}',
            color: practiceBlue,
          ),
          const SizedBox(width: 18),
          _TopStat(
            icon: Icons.favorite_rounded,
            value: '${stats.hearts}',
            color: practiceRed,
          ),
        ],
      ),
    );
  }
}

class _TopStat extends StatelessWidget {
  const _TopStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 25),
        const SizedBox(width: 5),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            value,
            key: ValueKey(value),
            style: const TextStyle(
              color: practiceInk,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _PathUnitHeader extends StatelessWidget {
  const _PathUnitHeader({
    required this.section,
    required this.title,
    required this.subtitle,
  });

  final String section;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102A73), Color(0xFF2457D6)],
        ),
        border: Border(bottom: BorderSide(color: practiceGreenDark, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(width: 34, height: 34),
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const Spacer(),
              Text(
                section.replaceFirst('Kısım', 'Defter'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(width: 34, height: 34),
                onPressed: () =>
                    Navigator.pushNamed(context, '/practice/guidebook'),
                icon: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.replaceFirst('Ünite', 'Sayfa'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Defter satırı: kâğıt kart + sol mürekkep şeridi + dolma-kalem dolum
/// göstergesi. Daire-balonlu yılan yol yerine dikey, "ciltli defter" düzeni.
class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.index,
    required this.lesson,
    required this.status,
    required this.progress,
    required this.onTap,
  });

  final int index;
  final PracticeLesson lesson;
  final _RowStatus status;
  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool locked = status == _RowStatus.locked;
    final Color accent = switch (status) {
      _RowStatus.active => practiceGreen,
      _RowStatus.test => practiceOrange,
      _RowStatus.done => practiceBlue,
      _RowStatus.locked => practiceMuted,
    };
    final IconData badge = switch (status) {
      _RowStatus.active => Icons.edit_rounded,
      _RowStatus.test => Icons.emoji_events_rounded,
      _RowStatus.done => Icons.check_rounded,
      _RowStatus.locked => Icons.lock_rounded,
    };
    final String tag = switch (status) {
      _RowStatus.active => 'SAYFAYI AÇ',
      _RowStatus.test => 'BÖLÜM TESTİ',
      _RowStatus.done => 'TAMAMLANDI',
      _RowStatus.locked => 'KİLİTLİ',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: locked ? .55 : 1,
        child: PressableScale(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: practicePaper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: practiceLine, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sol mürekkep şeridi (defter cilt payı)
                    Container(width: 5, color: accent),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(46, 46),
                              painter: _InkGaugePainter(
                                progress: progress,
                                active: !locked,
                                accent: accent,
                              ),
                            ),
                            Icon(badge, color: accent, size: 22),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$index. $tag',
                              style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lesson.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: practiceInk,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12, left: 6),
                      child: Icon(
                        locked
                            ? Icons.lock_rounded
                            : Icons.chevron_right_rounded,
                        color: locked ? practiceMuted : practiceInk,
                        size: locked ? 20 : 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _RowStatus { active, locked, test, done }

/// Dolma-kalem "mürekkep dolum" göstergesi: kraft halka + ilerleme yayı.
class _InkGaugePainter extends CustomPainter {
  _InkGaugePainter({
    required this.progress,
    required this.active,
    required this.accent,
  });

  final double progress;
  final bool active;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = practiceLine;
    canvas.drawCircle(center, radius, track);

    final p = progress.clamp(0.0, 1.0);
    if (active && p > 0) {
      final fill = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = accent;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * p,
        false,
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _InkGaugePainter old) =>
      old.progress != progress || old.active != active || old.accent != accent;
}
