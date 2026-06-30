import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/localization/app_strings.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';
import 'practice_repository.dart';
import 'practice_premium_offer_service.dart';
import 'practice_trial_lesson_cta.dart';
import 'practice_widget_service.dart';
import 'screens/practice_characters.dart';
import 'screens/practice_game_widgets.dart';
import 'screens/practice_session_screen.dart';
import 'screens/practice_visuals.dart';

class PracticeHomeScreen extends StatefulWidget {
  const PracticeHomeScreen({super.key});

  @override
  State<PracticeHomeScreen> createState() => _PracticeHomeScreenState();
}

class _PracticeHomeScreenState extends State<PracticeHomeScreen> {
  static const PracticeRepository _repository = PracticeRepository();
  late Future<_PracticeHomeData> _homeData;
  bool _premiumOfferScheduled = false;

  @override
  void initState() {
    super.initState();
    _homeData = _loadHomeData();
  }

  Future<_PracticeHomeData> _loadHomeData() async {
    final stats = await _repository.fetchStats();
    final units = await _repository.fetchUnits();
    await PracticeWidgetService.update(
      streak: stats.streak,
      xp: stats.xp,
      hearts: stats.hearts,
    );
    return _PracticeHomeData(stats: stats, units: units);
  }

  void _retry() {
    setState(() => _homeData = _loadHomeData());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PracticeHomeData>(
      future: _homeData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: practiceKraft,
            body: SafeArea(
              child: Center(
                child: PracticeMascotLoader(label: 'Pratik hazırlanıyor'),
              ),
            ),
            bottomNavigationBar: PracticeBottomTabs(selected: 0),
          );
        }

        final data = snapshot.data;
        if (snapshot.hasError || data == null || data.units.isEmpty) {
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
                      const SizedBox(height: 16),
                      const Text(
                        'Pratik dersleri yüklenemedi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: practiceInk,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'İnternet bağlantını ve oturumunu kontrol edip tekrar dene.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: practiceMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tekrar dene'),
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
        final units = data.units;
        if (!_premiumOfferScheduled) {
          _premiumOfferScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            unawaited(
              PracticePremiumOfferService.instance.maybeShowHomeOffer(context),
            );
          });
        }

        return Scaffold(
          backgroundColor: practiceKraft,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: _PracticeTopHud(stats: stats),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: PracticeDailyGoalCard(),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _LuckySpinEntry(
                    onTap: () =>
                        Navigator.pushNamed(context, '/practice/lucky-spin'),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                    children: [
                      _CharacterShowcase(
                        onOpenAll: () => Navigator.pushNamed(
                          context,
                          '/practice/characters',
                        ),
                        onOpenCharacter: (character) => Navigator.pushNamed(
                          context,
                          '/practice/character-call',
                          arguments: {
                            'character_name': character.name,
                            'scenario': _scenarioFor(character.name),
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      const PracticeTrialLessonCta(source: 'practice_home'),
                      const SizedBox(height: 18),
                      for (var u = 0; u < units.length; u++)
                        _UnitSection(
                          unit: units[u],
                          onOpen: _openLesson,
                          onGuide: () => Navigator.pushNamed(
                              context, '/practice/guidebook'),
                          onTestOut: _testOut,
                        ),
                    ],
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

  String _scenarioFor(String name) {
    return switch (name) {
      'Lingu' => 'Kafede sipariş',
      'Mina' => 'Yeni biriyle tanışma',
      'Efe' => 'İş görüşmesi',
      'Zara' => 'Seyahatte yol tarifi',
      'Bao' => 'Restoranda konuşma',
      _ => 'Günlük konuşma',
    };
  }

  void _openLesson(PracticeLesson lesson) {
    Navigator.pushNamed(context, '/practice/lesson', arguments: lesson);
  }

  /// Üniteyi atla testi: geçerse (≥%80) ünite açılır mesajı.
  Future<void> _testOut() async {
    final isTr = AppStrings.code == 'tr';
    final questions = await _repository.loadModeQuestions('grammar');
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionScreen(
          title: isTr ? 'Üniteyi atla testi' : 'Test out',
          questions: questions,
          enforceHearts: false,
          onComplete: (correct, total) async {
            final ratio = total == 0 ? 0.0 : correct / total;
            if (ratio >= 0.8) {
              return isTr
                  ? 'Tebrikler! Üniteyi atladin.'
                  : 'Great! You tested out of the unit.';
            }
            return isTr
                ? 'Yeterli değil, derslerle devam et.'
                : 'Not enough, keep practicing.';
          },
        ),
      ),
    );
  }
}

class _CharacterShowcase extends StatelessWidget {
  const _CharacterShowcase({
    required this.onOpenAll,
    required this.onOpenCharacter,
  });

  final VoidCallback onOpenAll;
  final ValueChanged<PracticeCharacter> onOpenCharacter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Karakterlerle konuş',
                      style: TextStyle(
                        color: practiceInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Bir karakter seç, sesli veya yazılı pratik yap.',
                      style: TextStyle(
                        color: practiceMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onOpenAll,
                child: const Text('TÜMÜ'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final character in practiceCharacters)
                Semantics(
                  button: true,
                  label: '${character.name} ile konuş',
                  child: InkWell(
                    onTap: () => onOpenCharacter(character),
                    customBorder: const CircleBorder(),
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: character.color.withValues(alpha: .12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: character.color.withValues(alpha: .45),
                            ),
                          ),
                          child: PracticeCharacterAvatar(
                            character: character,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          character.name,
                          style: const TextStyle(
                            color: practiceInk,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: .08);
  }
}

class _LuckySpinEntry extends StatelessWidget {
  const _LuckySpinEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD84D), Color(0xFFFF9F1C)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0xFFD58100), offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .28),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: Text('🎰', style: TextStyle(fontSize: 25)),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .rotate(begin: -0.04, end: 0.04, duration: 900.ms),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTr ? 'Günlük Şans Çarkı' : 'Daily Lucky Spin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isTr
                        ? 'XP, coin, can veya 2x boost kazan'
                        : 'Win XP, coins, hearts or 2x boost',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .9),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white, size: 30),
          ],
        ),
      ).animate().fadeIn(duration: 280.ms).slideY(begin: .12),
    );
  }
}

class _PracticeHomeData {
  const _PracticeHomeData({required this.stats, required this.units});

  final PracticeStats stats;
  final List<PracticeUnit> units;
}

class _PracticeTopHud extends StatefulWidget {
  const _PracticeTopHud({required this.stats});

  final PracticeStats stats;

  @override
  State<_PracticeTopHud> createState() => _PracticeTopHudState();
}

class _PracticeTopHudState extends State<_PracticeTopHud> {
  double _barValue = 0;

  @override
  void initState() {
    super.initState();
    // XP bar animasyonu: 0'dan gerçek değere doğru dolsun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _barValue = widget.stats.levelProgress.clamp(0.0, 1.0));
      }
    });
  }

  @override
  void didUpdateWidget(_PracticeTopHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stats.levelProgress != widget.stats.levelProgress) {
      setState(() => _barValue = widget.stats.levelProgress.clamp(0.0, 1.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF9AA0A6)),
        ),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _barValue),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) =>
                PracticeProgressBar(value: value, height: 12),
          ),
        ),
        const SizedBox(width: 10),
        // Streak badge: hafif ateş shimmer
        _HudPill(
          icon: Icons.local_fire_department_rounded,
          value: '${widget.stats.streak}',
          color: const Color(0xFF3D5CFF),
          glow: widget.stats.streak > 0,
        ),
        const SizedBox(width: 8),
        _HudPill(
          icon: Icons.favorite_rounded,
          value: '${widget.stats.hearts}',
          color: const Color(0xFF2B7CFF),
        ),
      ],
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.icon,
    required this.value,
    required this.color,
    this.glow = false,
  });

  final IconData icon;
  final String value;
  final Color color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE8F7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              value,
              key: ValueKey(value),
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    // Streak pill'i periyodik shimmer ile parlatır
    if (glow) {
      pill = pill.animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
            duration: 2200.ms,
            color: practiceOrange.withValues(alpha: 0.25),
            angle: math.pi / 6,
          );
    }
    return pill;
  }
}

/// Bir üniteyi gösterir: yeşil başlık kartı + kıvrılan ders düğümleri.
class _UnitSection extends StatelessWidget {
  const _UnitSection({
    required this.unit,
    required this.onOpen,
    required this.onGuide,
    required this.onTestOut,
  });

  final PracticeUnit unit;
  final void Function(PracticeLesson) onOpen;
  final VoidCallback onGuide;
  final VoidCallback onTestOut;

  @override
  Widget build(BuildContext context) {
    // Her ünitedeki ilk devam edilebilir dersi açılacak sayfa olarak işaretle.
    var startIndex = -1;
    for (var i = 0; i < unit.lessons.length; i++) {
      final lesson = unit.lessons[i];
      if (!lesson.locked &&
          lesson.status != 'completed' &&
          lesson.status != 'legendary') {
        startIndex = i;
        break;
      }
    }
    return Column(
      children: [
        _UnitHeaderCard(
          section: unit.section,
          title: unit.title,
          subtitle: unit.subtitle,
          onGuide: onGuide,
          onTestOut: onTestOut,
        ),
        const SizedBox(height: 12),
        // Yılankavi/zigzag düğüm dizilimi YOK → dikey defter satırları.
        for (var i = 0; i < unit.lessons.length; i++)
          _PathDot(
            index: i + 1,
            lesson: unit.lessons[i],
            active: !unit.lessons[i].locked,
            showStart: i == startIndex,
            onTap:
                unit.lessons[i].locked ? null : () => onOpen(unit.lessons[i]),
          )
              .animate(delay: Duration(milliseconds: 50 * i))
              .fadeIn(duration: 300.ms)
              .slideY(
                begin: 0.18,
                end: 0,
                curve: Curves.easeOutCubic,
                duration: 300.ms,
              ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _UnitHeaderCard extends StatelessWidget {
  const _UnitHeaderCard({
    required this.section,
    required this.title,
    required this.subtitle,
    required this.onGuide,
    required this.onTestOut,
  });

  final String section;
  final String title;
  final String subtitle;
  final VoidCallback onGuide;
  final VoidCallback onTestOut;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final displayTitle = isTr ? title.replaceFirst('Ünite', 'Defter') : title;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102A73), Color(0xFF2457D6)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF173E9F),
            offset: Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: .30)),
            ),
            child: Text(
              isTr ? 'AKILLI KALEM DEFTERİ' : 'SMART PENCIL NOTEBOOK',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: .7,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  section.isNotEmpty ? section : title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onGuide,
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            displayTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              height: 1.05,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTestOut,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fast_forward_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    isTr ? 'BUNU BILIYORUM' : 'TEST OUT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kıvrılan defter yolu üzerindeki bir pratik sayfası.
/// Defter satırı: kâğıt kart + sol mürekkep şeridi + ders ikonu. Dairesel
/// yılan-yol düğümü değil; path ekranındaki _LessonRow ile aynı dil.
class _PathDot extends StatelessWidget {
  const _PathDot({
    required this.index,
    required this.lesson,
    required this.active,
    required this.showStart,
    required this.onTap,
  });

  final int index;
  final PracticeLesson lesson;
  final bool active;
  final bool showStart;
  final VoidCallback? onTap;

  IconData _iconFor(String key) {
    if (lesson.locked) return Icons.lock_rounded;
    switch (key) {
      case 'bolt':
      case 'daily':
        return Icons.bolt_rounded;
      case 'map':
      case 'travel':
        return Icons.map_rounded;
      case 'work':
      case 'business':
        return Icons.work_rounded;
      case 'shield':
      case 'legend':
        return Icons.shield_rounded;
      case 'listening':
      case 'radio':
        return Icons.volume_up_rounded;
      case 'speaking':
        return Icons.mic_rounded;
      case 'vocabulary':
        return Icons.style_rounded;
      case 'grammar':
        return Icons.menu_book_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final isDone = lesson.status == 'completed' || lesson.status == 'legendary';
    final Color accent = isDone
        ? practiceBlue
        : showStart
            ? practiceGreen
            : (active ? practiceBlue : practiceMuted);
    final String tag = lesson.locked
        ? (isTr ? 'KİLİTLİ' : 'LOCKED')
        : isDone
            ? (isTr ? 'TAMAMLANDI' : 'COMPLETED')
            : (showStart
                ? (isTr ? 'SAYFAYI AÇ' : 'OPEN PAGE')
                : (isTr ? 'DERS' : 'LESSON'));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: active ? 1 : .55,
        child: PressableScale(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: practicePaper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: showStart ? accent : practiceLine,
                width: showStart ? 2 : 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 5, color: accent),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .12),
                          shape: BoxShape.circle,
                          border: Border.all(color: accent, width: 1.5),
                        ),
                        child: Icon(
                          isDone ? Icons.check_rounded : _iconFor(lesson.icon),
                          color: accent,
                          size: 22,
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
                        lesson.locked
                            ? Icons.lock_rounded
                            : Icons.chevron_right_rounded,
                        color: lesson.locked ? practiceMuted : practiceInk,
                        size: lesson.locked ? 20 : 26,
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
