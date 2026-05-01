import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../core/localization/app_strings.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../public/public_theme.dart';
import '../public/speak_coach_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static void _openSpeakingTask(BuildContext context, int step) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 620),
        reverseTransitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (_, __, ___) => PublicTheme(
          child: SpeakCoachScreen(initialMissionStep: step),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ));
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              left: -60,
              top: -40,
              child: _HomeGlowOrb(
                size: 188,
                color: Color(0x1463D60F),
              ),
            ),
            const Positioned(
              right: -46,
              top: 110,
              child: _HomeGlowOrb(
                size: 134,
                color: Color(0x143D5CFF),
              ),
            ),
            const Positioned(
              left: -38,
              bottom: 180,
              child: _HomeGlowOrb(
                size: 126,
                color: Color(0x14FFB347),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final short = constraints.maxHeight < 720;
                final veryShort = constraints.maxHeight < 620;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    28,
                    veryShort ? 8 : 12,
                    28,
                    18,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 30,
                    ),
                    child: AnimatedPageEntrance(
                      child: Column(
                        children: [
                          SizedBox(height: veryShort ? 4 : (short ? 10 : 24)),
                          _HomeLogoGuide(
                            size: veryShort ? 118 : (short ? 142 : 182),
                            bubbleText: isTr
                                ? '5 dakikada speaking seviyeni olcelim.'
                                : 'Measure your speaking level in 5 minutes.',
                          ),
                          SizedBox(height: veryShort ? 10 : 18),
                          Text(
                            isTr
                                ? 'Ucretsiz Speaking Testi'
                                : 'Free Speaking Test',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: const Color(0xFF1D7CFF),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                  fontSize: veryShort ? 22 : null,
                                ),
                          ),
                          SizedBox(height: veryShort ? 6 : 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Text(
                              isTr
                                  ? 'Dinle, anla, resim sec ve konus. Sonunda seviyeni, zayif alanini ve sana uygun ogretmeni goreceksin.'
                                  : 'Listen, understand, choose an image, and speak. See your level, weak area, and matched teacher at the end.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppColors.muted,
                                    height: 1.35,
                                    fontSize: veryShort ? 14 : null,
                                  ),
                            ),
                          ),
                          SizedBox(height: veryShort ? 10 : 18),
                          _TodayPlanCard(
                            compact: veryShort,
                            onStart: () => _openSpeakingTask(context, 0),
                          ),
                          SizedBox(height: veryShort ? 10 : 14),
                          Container(
                            padding: EdgeInsets.all(veryShort ? 10 : 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFF),
                              borderRadius: BorderRadius.circular(22),
                              border:
                                  Border.all(color: const Color(0xFFE5ECF6)),
                            ),
                            child: Column(
                              children: [
                                _HomePathStep(
                                  number: '1',
                                  label: isTr ? 'Dinle' : 'Listen',
                                  compact: veryShort,
                                ),
                                _HomePathStep(
                                  number: '2',
                                  label: isTr ? 'Anla' : 'Understand',
                                  compact: veryShort,
                                ),
                                _HomePathStep(
                                  number: '3',
                                  label: isTr ? 'Resim sec' : 'Choose image',
                                  compact: veryShort,
                                ),
                                _HomePathStep(
                                  number: '4',
                                  label: isTr ? 'Konus' : 'Speak',
                                  compact: veryShort,
                                ),
                                _HomePathStep(
                                  number: '5',
                                  label: isTr
                                      ? 'Sonuc + deneme dersi'
                                      : 'Result + trial lesson',
                                  isLast: true,
                                  compact: veryShort,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: veryShort ? 10 : 14),
                          _RewardStrip(compact: veryShort),
                          SizedBox(height: veryShort ? 10 : 14),
                          _MiniTaskGrid(
                            compact: veryShort,
                            onListen: () => _openSpeakingTask(context, 0),
                            onUnderstand: () => _openSpeakingTask(context, 1),
                            onSpeak: () => _openSpeakingTask(context, 3),
                          ),
                          SizedBox(height: veryShort ? 10 : 14),
                          _LevelPromiseCard(compact: veryShort),
                          SizedBox(height: veryShort ? 10 : 14),
                          _TeacherMatchPreview(
                            compact: veryShort,
                            onStart: () => _openSpeakingTask(context, 0),
                          ),
                          SizedBox(height: veryShort ? 14 : (short ? 18 : 28)),
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: () => _openSpeakingTask(context, 0),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF63D60F),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                isTr
                                    ? 'Speaking seviyemi olc'
                                    : 'Measure my speaking level',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/login'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF63D60F),
                                side:
                                    const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: Colors.white,
                              ),
                              child: Text(
                                isTr
                                    ? 'Zaten hesabim var'
                                    : 'I already have an account',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  const _TodayPlanCard({
    required this.compact,
    required this.onStart,
  });

  final bool compact;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5FD7), Color(0xFF1D7CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D7CFF).withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 46 : 52,
            height: compact ? 46 : 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTr ? 'Bugunun speaking plani' : 'Today\'s speaking plan',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isTr
                      ? '1 dinleme, 1 anlam, 1 konusma gorevi. Sonunda seviye raporu.'
                      : '1 listening, 1 meaning, 1 speaking task. Level report at the end.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onStart,
            color: Colors.white,
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }
}

class _RewardStrip extends StatelessWidget {
  const _RewardStrip({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFFF0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8F4B7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, color: Color(0xFF46B800)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isTr
                  ? 'Testi bitir, 1 ucretsiz mini speaking seansi hakkini ac.'
                  : 'Finish the test and unlock 1 free mini speaking session.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF2E7D14),
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isTr ? '24 saat' : '24h',
              style: const TextStyle(
                color: Color(0xFF46B800),
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTaskGrid extends StatelessWidget {
  const _MiniTaskGrid({
    required this.compact,
    required this.onListen,
    required this.onUnderstand,
    required this.onSpeak,
  });

  final bool compact;
  final VoidCallback onListen;
  final VoidCallback onUnderstand;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniTaskCard(
                icon: Icons.volume_up_rounded,
                title: isTr ? 'Kelime dinle' : 'Listen',
                detail: isTr ? '10 sn' : '10 sec',
                compact: compact,
                onTap: onListen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniTaskCard(
                icon: Icons.translate_rounded,
                title: isTr ? 'Cumle anla' : 'Meaning',
                detail: isTr ? '1 soru' : '1 task',
                compact: compact,
                onTap: onUnderstand,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MiniTaskCard(
          icon: Icons.mic_rounded,
          title: isTr ? 'Mikrofonda tekrar et' : 'Repeat with mic',
          detail: isTr ? 'Telaffuz skorunu gor' : 'See pronunciation score',
          compact: compact,
          onTap: onSpeak,
        ),
        SizedBox(height: compact ? 10 : 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_alt_rounded,
              color: Color(0xFF1D7CFF),
              size: 18,
            ),
            const SizedBox(width: 7),
            Text(
              isTr
                  ? 'Bugun 42 kisi speaking gorevi yapti'
                  : '42 learners practiced speaking today',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniTaskCard extends StatelessWidget {
  const _MiniTaskCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(compact ? 11 : 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE3ECF7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandNight.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 34 : 40,
                height: compact ? 34 : 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF4FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF1D7CFF), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.brandNight,
                            fontWeight: FontWeight.w900,
                            fontSize: compact ? 12 : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            fontSize: compact ? 10 : null,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF1D7CFF),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelPromiseCard extends StatelessWidget {
  const _LevelPromiseCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                color: Color(0xFF1D7CFF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isTr ? 'Test sonunda net rapor' : 'Clear report at the end',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.brandNight,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PromisePill(label: isTr ? 'Seviye: A2-B1' : 'Level: A2-B1'),
              _PromisePill(label: isTr ? 'Zayif alan' : 'Weak area'),
              _PromisePill(label: isTr ? 'Hedef plan' : 'Goal plan'),
              _PromisePill(label: isTr ? '3 hoca onerisi' : '3 teachers'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromisePill extends StatelessWidget {
  const _PromisePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDEAF8)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF12345B),
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _TeacherMatchPreview extends StatelessWidget {
  const _TeacherMatchPreview({
    required this.compact,
    required this.onStart,
  });

  final bool compact;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3ECF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNight.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _TeacherBubble(initial: 'G', offset: Offset.zero),
              const _TeacherBubble(
                initial: 'M',
                offset: Offset(26, 6),
                color: Color(0xFF63D60F),
              ),
              const _TeacherBubble(
                initial: 'D',
                offset: Offset(13, 30),
                color: Color(0xFFFFB347),
              ),
            ],
          ),
          const SizedBox(width: 66),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTr ? 'Sana uygun hoca eslesir' : 'Matched teacher picks',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.brandNight,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isTr
                      ? 'Sonuca gore en uygun, en erken musait ve speaking uzmani hocalari gosteririz.'
                      : 'We show best match, earliest available, and speaking specialist.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onStart,
                  child: Text(
                    isTr ? 'Testi baslat' : 'Start test',
                    style: const TextStyle(
                      color: Color(0xFF1D7CFF),
                      fontWeight: FontWeight.w900,
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

class _TeacherBubble extends StatelessWidget {
  const _TeacherBubble({
    required this.initial,
    required this.offset,
    this.color = const Color(0xFF1D7CFF),
  });

  final String initial;
  final Offset offset;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _HomeGlowOrb extends StatelessWidget {
  const _HomeGlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.45,
            spreadRadius: size * 0.04,
          ),
        ],
      ),
      child: SizedBox(width: size, height: size),
    );
  }
}

class _HomePathStep extends StatelessWidget {
  const _HomePathStep({
    required this.number,
    required this.label,
    this.isLast = false,
    this.compact = false,
  });

  final String number;
  final String label;
  final bool isLast;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : (compact ? 5 : 8)),
      child: Row(
        children: [
          Container(
            width: compact ? 24 : 28,
            height: compact ? 24 : 28,
            decoration: const BoxDecoration(
              color: Color(0xFF1D7CFF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.brandNight,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 13 : null,
                  ),
            ),
          ),
          Icon(
            isLast ? Icons.flag_rounded : Icons.chevron_right_rounded,
            color: const Color(0xFF1D7CFF),
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _HomeLogoGuide extends StatefulWidget {
  const _HomeLogoGuide({
    required this.size,
    required this.bubbleText,
  });

  final double size;
  final String bubbleText;

  @override
  State<_HomeLogoGuide> createState() => _HomeLogoGuideState();
}

class _HomeLogoGuideState extends State<_HomeLogoGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final wave = math.sin(_controller.value * math.pi * 2);
        final secondaryWave = math.cos(_controller.value * math.pi * 2);
        final bounce = wave * 10;
        final rotation = secondaryWave * 0.05;
        final shadowScale = 1 - (wave.abs() * 0.12);
        final glow = 0.14 + ((secondaryWave + 1) * 0.06);
        const bodyColor = Color(0xFF1D7CFF);
        const bodyDark = Color(0xFF1368E8);
        const accentBlue = Color(0xFF00A7E8);
        const innerEarColor = Color(0xFFEAF6FF);
        const muzzleColor = Color(0xFFF8FCFF);
        const noseColor = Color(0xFF12345B);
        double blinkAt(double center, double width) {
          final distance = (_controller.value - center).abs();
          if (distance >= width) return 1;
          return (distance / width).clamp(0.0, 1.0);
        }

        final blink = math.min(blinkAt(0.18, 0.045), blinkAt(0.72, 0.035));
        final eyeHeight =
            math.max(widget.size * 0.032, widget.size * 0.11 * blink);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, -6 + bounce),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE7EEF8)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x143D5CFF),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  widget.bubbleText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.brandNight,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: widget.size + 34,
              height: widget.size + 42,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 12,
                    top: 18 + (secondaryWave * 5),
                    child: _MiniSpark(
                      size: 13,
                      color: const Color(0xFF63D60F).withValues(alpha: 0.8),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 36 - (wave * 6),
                    child: _MiniSpark(
                      size: 11,
                      color: const Color(0xFF3D5CFF).withValues(alpha: 0.8),
                    ),
                  ),
                  Positioned(
                    right: 26,
                    bottom: 34 + (wave * 5),
                    child: _MiniSpark(
                      size: 9,
                      color: accentBlue.withValues(alpha: 0.9),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, bounce),
                    child: Transform.rotate(
                      angle: rotation,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: widget.size * 0.08,
                            bottom: widget.size * 0.2,
                            child: Transform.rotate(
                              angle: -0.62 + (wave * 0.05),
                              child: Container(
                                width: widget.size * 0.18,
                                height: widget.size * 0.34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFBFE3FF),
                                  borderRadius: BorderRadius.circular(
                                    widget.size,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: -widget.size * 0.02,
                            bottom: widget.size * 0.17,
                            child: Transform.rotate(
                              angle: 0.88 - (wave * 0.12),
                              child: Container(
                                width: widget.size * 0.22,
                                height: widget.size * 0.5,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      bodyColor,
                                      Color(0xFFBFE3FF),
                                      Colors.white,
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    widget.size,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: widget.size * 0.06,
                            left: widget.size * 0.25,
                            child: Transform.rotate(
                              angle: -0.28,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: widget.size * 0.2,
                                    height: widget.size * 0.24,
                                    decoration: BoxDecoration(
                                      color: bodyColor,
                                      borderRadius: BorderRadius.circular(
                                        widget.size * 0.08,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: widget.size * 0.1,
                                    height: widget.size * 0.12,
                                    decoration: BoxDecoration(
                                      color: innerEarColor,
                                      borderRadius: BorderRadius.circular(
                                        widget.size * 0.06,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: widget.size * 0.06,
                            right: widget.size * 0.25,
                            child: Transform.rotate(
                              angle: 0.28,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: widget.size * 0.2,
                                    height: widget.size * 0.24,
                                    decoration: BoxDecoration(
                                      color: bodyColor,
                                      borderRadius: BorderRadius.circular(
                                        widget.size * 0.08,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: widget.size * 0.1,
                                    height: widget.size * 0.12,
                                    decoration: BoxDecoration(
                                      color: innerEarColor,
                                      borderRadius: BorderRadius.circular(
                                        widget.size * 0.06,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: widget.size * 0.12,
                            child: Container(
                              width: widget.size * 0.42,
                              height: widget.size * 0.08,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius:
                                    BorderRadius.circular(widget.size),
                              ),
                            ),
                          ),
                          Container(
                            width: widget.size * 0.9,
                            height: widget.size * 0.88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                widget.size * 0.42,
                              ),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF54A7FF), bodyDark],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: bodyColor.withValues(
                                    alpha: glow,
                                  ),
                                  blurRadius: 30,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  top: widget.size * 0.2,
                                  child: Container(
                                    width: widget.size * 0.62,
                                    height: widget.size * 0.42,
                                    decoration: BoxDecoration(
                                      color: muzzleColor,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(
                                          widget.size * 0.28,
                                        ),
                                        topRight: Radius.circular(
                                          widget.size * 0.28,
                                        ),
                                        bottomLeft: Radius.circular(
                                          widget.size * 0.16,
                                        ),
                                        bottomRight: Radius.circular(
                                          widget.size * 0.16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: widget.size * 0.08,
                                  child: Container(
                                    width: widget.size * 0.42,
                                    height: widget.size * 0.32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        widget.size * 0.24,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: widget.size * 0.22,
                                  left: widget.size * 0.2,
                                  child: _HomeMascotEye(
                                    size: widget.size * 0.22,
                                    eyeHeight: eyeHeight,
                                    eyelidColor: bodyColor,
                                  ),
                                ),
                                Positioned(
                                  top: widget.size * 0.22,
                                  right: widget.size * 0.2,
                                  child: _HomeMascotEye(
                                    size: widget.size * 0.22,
                                    eyeHeight: eyeHeight,
                                    eyelidColor: bodyColor,
                                  ),
                                ),
                                Positioned(
                                  top: widget.size * 0.46,
                                  child: Column(
                                    children: [
                                      Transform.rotate(
                                        angle: math.pi / 4,
                                        child: Container(
                                          width: widget.size * 0.11,
                                          height: widget.size * 0.11,
                                          decoration: const BoxDecoration(
                                            color: noseColor,
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(3),
                                              bottomRight: Radius.circular(6),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: widget.size * 0.025),
                                      Container(
                                        width: widget.size * 0.18,
                                        height: widget.size * 0.035,
                                        decoration: BoxDecoration(
                                          color:
                                              noseColor.withValues(alpha: 0.72),
                                          borderRadius: BorderRadius.circular(
                                            widget.size,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: widget.size * 0.04,
                            left: widget.size * 0.34,
                            child: Container(
                              width: widget.size * 0.05,
                              height: widget.size * 0.12,
                              decoration: BoxDecoration(
                                color: noseColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: widget.size * 0.04,
                            right: widget.size * 0.34,
                            child: Container(
                              width: widget.size * 0.05,
                              height: widget.size * 0.12,
                              decoration: BoxDecoration(
                                color: noseColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    child: Transform.scale(
                      scaleX: shadowScale,
                      child: Container(
                        width: widget.size * 0.54,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HomeMascotEye extends StatelessWidget {
  const _HomeMascotEye({
    required this.size,
    required this.eyeHeight,
    required this.eyelidColor,
  });

  final double size;
  final double eyeHeight;
  final Color eyelidColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size * 0.78,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size),
            ),
          ),
          Container(
            width: size * 0.3,
            height: eyeHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF1D2733),
              borderRadius: BorderRadius.circular(size),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: size,
              height: ((1 - (eyeHeight / (size * 0.78)).clamp(0.08, 1.0)) *
                      size *
                      0.56)
                  .clamp(0, size * 0.4),
              decoration: BoxDecoration(
                color: eyelidColor,
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSpark extends StatelessWidget {
  const _MiniSpark({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}
