import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

import 'practice_ad_service.dart';
import 'practice_api_service.dart';
import 'practice_lesson_screen.dart';
import 'practice_premium_offer_service.dart';
import 'practice_review_service.dart';
import 'practice_sound_service.dart';
import 'practice_trial_lesson_cta.dart';
import 'screens/practice_game_widgets.dart';
import 'screens/practice_visuals.dart';

class PracticeResultScreen extends StatefulWidget {
  const PracticeResultScreen({super.key, required this.args});

  final PracticeResultArgs args;

  @override
  State<PracticeResultScreen> createState() => _PracticeResultScreenState();
}

class _PracticeResultScreenState extends State<PracticeResultScreen> {
  final PracticeApiService _api = const PracticeApiService();
  final PracticeAdService _ads = PracticeAdService();
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  bool get _perfect => widget.args.correct == widget.args.total;
  int get _earnedXp => widget.args.lesson.xp + (_perfect ? 10 : 0);
  int get _accuracy =>
      ((widget.args.correct / widget.args.total.clamp(1, 999)) * 100).round();

  String get _timeLabel {
    final d = widget.args.duration;
    if (d == null) return '0:00';
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _confetti.play();
      unawaited(PracticeSoundService.playComplete());
      unawaited(PracticeReviewService.requestAfterGreatLesson(
        perfect: _perfect,
      ));
      unawaited(_maybeLevelUp());
      unawaited(_loadChest());
      unawaited(_loadPremium());
    });
  }

  bool _chestAvailable = false;
  bool? _isPremium;

  Future<void> _loadPremium() async {
    final premium = await PracticePremiumOfferService.instance.premiumState();
    if (!mounted) return;
    setState(() => _isPremium = premium);
  }

  /// Ders sonunda sandık hak edildiyse (her 5 derste bir) bayrak set edilir.
  Future<void> _loadChest() async {
    final data = await _api.getTreasureChest();
    if (!mounted || data == null) return;
    if (data['available'] == true) {
      setState(() => _chestAvailable = true);
    }
  }

  /// Devam: sandık varsa önce sandığı aç, sonra ana ekrana dön.
  Future<void> _onContinue() async {
    if (_chestAvailable) {
      await Navigator.pushNamed(context, '/practice/treasure-chest');
    }
    if (!mounted) return;
    await _ads.showInterstitialAtNaturalBreak(
      premium: _isPremium == true,
      every: 4,
    );
    if (!mounted) return;
    // Pratik bittiğinde /practice ana ekranına dön, ama alttaki kabuğu (LMS
    // /student veya /instructor, ya da misafir /app-home / /home) stack'te
    // bırak ki kullanıcı kurslar tarafına geri çıkabilsin.
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/practice',
      (route) {
        final name = route.settings.name;
        return name == '/app-home' ||
            name == '/student' ||
            name == '/instructor' ||
            name == '/home' ||
            name == '/' ||
            route.isFirst;
      },
    );
  }

  /// Bu ders ile seviye atlandıysa kutlama göster.
  Future<void> _maybeLevelUp() async {
    final data = await _api.getStats();
    if (!mounted || data == null) return;
    final stats = data['stats'];
    final newXp = stats is Map ? _asInt(stats['total_xp'] ?? stats['xp']) : 0;
    if (newXp <= 0) return;
    final oldXp = (newXp - _earnedXp).clamp(0, newXp);
    final newLevel = (newXp ~/ 100) + 1;
    final oldLevel = (oldXp ~/ 100) + 1;
    if (newLevel > oldLevel && mounted) {
      await showLevelUpPopup(context, level: newLevel);
    }
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Pratik sonucu',
        text: 'Dersimi tamamladım: $_earnedXp puan, $_accuracy% doğruluk!',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 34,
              gravity: .30,
              colors: const [
                practiceGreen,
                practiceYellow,
                practiceBlue,
                Color(0xFFFF5964),
                practiceOrange,
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  const Text(
                    'Defter sayfası\ntamam!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: practiceGreen,
                      fontSize: 38,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Positioned(
                            left: 96, bottom: 20, child: _ResultPerson()),
                        Positioned(
                          right: 84,
                          top: 16,
                          child: const PracticeMascot(size: 128)
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scaleXY(
                                begin: 1,
                                end: 1.06,
                                duration: 700.ms,
                                curve: Curves.easeInOut,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_perfect) ...[
                    const _PerfectBanner(),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _ResultBox(
                          color: practiceYellow,
                          title: 'PUAN NOTU',
                          icon: Icons.edit_note_rounded,
                          value: '',
                          countTo: _earnedXp,
                        ).animate().fadeIn(delay: 150.ms).slideY(
                              begin: .3,
                              end: 0,
                              duration: 300.ms,
                              curve: Curves.easeOut,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResultBox(
                          color: practiceBlue,
                          title: 'SÜRE',
                          icon: Icons.timer_rounded,
                          value: _timeLabel,
                        ).animate().fadeIn(delay: 300.ms).slideY(
                              begin: .3,
                              end: 0,
                              duration: 300.ms,
                              curve: Curves.easeOut,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResultBox(
                          color: practiceGreen,
                          title: 'İSABET',
                          icon: Icons.my_location_rounded,
                          value: '%$_accuracy',
                        ).animate().fadeIn(delay: 450.ms).slideY(
                              begin: .3,
                              end: 0,
                              duration: 300.ms,
                              curve: Curves.easeOut,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_isPremium == false) ...[
                    _ResultPremiumCard(
                      onTap: () =>
                          PracticePremiumOfferService.instance.showOffer(
                        context,
                        trigger: PracticePremiumTrigger.lessonResult,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const PracticeTrialLessonCta(
                    compact: true,
                    source: 'practice_result',
                    sourceLabel: 'Bu başarıyı',
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('PAYLAŞ'),
                  ),
                  const SizedBox(height: 8),
                  PracticePrimaryButton(
                    label: _chestAvailable ? 'ÖDÜL KUTUSU' : 'DEVAM ET',
                    color: _chestAvailable ? practiceYellow : practiceBlue,
                    onPressed: _onContinue,
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

class _ResultPremiumCard extends StatelessWidget {
  const _ResultPremiumCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F6FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: practiceBlue, width: 1.5),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.workspace_premium_rounded,
                color: practiceBlue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kesintisiz pratik yap',
                    style: TextStyle(
                      color: practiceInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Sınırsız can, reklamsız kullanım ve gelişmiş AI.',
                    style: TextStyle(
                      color: practiceMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: practiceBlue),
          ],
        ),
      ),
    );
  }
}

class _PerfectBanner extends StatelessWidget {
  const _PerfectBanner();

  @override
  Widget build(BuildContext context) {
    return PracticeConfettiOverlay(
      active: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFE08A), width: 2),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: practiceYellow,
              child: Icon(Icons.auto_awesome_rounded, color: practiceOrange),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kusursuz Sayfa',
                    style: TextStyle(
                      color: practiceInk,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '+10 bonus XP kazandın.',
                    style: TextStyle(
                      color: practiceMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({
    required this.color,
    required this.title,
    required this.icon,
    required this.value,
    this.countTo,
  });

  final Color color;
  final String title;
  final IconData icon;
  final String value;

  /// Verilirse 0'dan bu değere sayan rakam gösterir.
  final int? countTo;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 7),
                if (countTo != null)
                  AnimatedCounter(
                    value: countTo!,
                    style: TextStyle(
                      color: color,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
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

class _ResultPerson extends StatelessWidget {
  const _ResultPerson();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 190,
      child: CustomPaint(painter: _ResultPersonPainter()),
    );
  }
}

class _ResultPersonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    p.color = const Color(0xFFE5E5E5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .14, h * .90, w * .72, h * .04),
        Radius.circular(w * .04),
      ),
      p,
    );
    p.color = const Color(0xFFA66BFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .25, h * .08, w * .46, h * .42),
        Radius.circular(w * .15),
      ),
      p,
    );
    p.color = const Color(0xFFFFC2B4);
    canvas.drawCircle(Offset(w * .50, h * .30), w * .16, p);
    p.color = const Color(0xFF4F3C8F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .35, h * .50, w * .34, h * .27),
        Radius.circular(w * .06),
      ),
      p,
    );
    p.color = const Color(0xFFA66BFF);
    canvas.drawRect(Rect.fromLTWH(w * .43, h * .75, w * .08, h * .18), p);
    canvas.drawRect(Rect.fromLTWH(w * .57, h * .75, w * .08, h * .18), p);
    p.color = const Color(0xFF4F3C8F);
    canvas.drawOval(Rect.fromLTWH(w * .36, h * .92, w * .18, h * .05), p);
    canvas.drawOval(Rect.fromLTWH(w * .56, h * .92, w * .18, h * .05), p);
    p.color = practiceInk;
    canvas.drawCircle(Offset(w * .45, h * .29), w * .018, p);
    canvas.drawCircle(Offset(w * .57, h * .29), w * .018, p);
    p.strokeWidth = w * .018;
    p.style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromLTWH(w * .44, h * .34, w * .18, h * .08), 3.14,
        3.14, false, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
