import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/storage/app_preferences.dart';
import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

/// Günlük şans çarkı — günde 1 kez çevirilir.
class PracticeLuckySpinScreen extends StatefulWidget {
  const PracticeLuckySpinScreen({super.key});

  @override
  State<PracticeLuckySpinScreen> createState() =>
      _PracticeLuckySpinScreenState();
}

class _PracticeLuckySpinScreenState extends State<PracticeLuckySpinScreen>
    with TickerProviderStateMixin {
  // ── Ödül dilimleri ──────────────────────────────────────────────────────────
  static const _prizes = [
    _SpinPrize('⚡', '+50 XP', Color(0xFFFFD700), 'xp', 50),
    _SpinPrize('💎', '+20 Gem', practiceBlue, 'gem', 20),
    _SpinPrize('🪙', '+100 Coin', Color(0xFFFF9600), 'coin', 100),
    _SpinPrize('🔥', '2x XP/1sa', Color(0xFFFF5964), 'boost', 0),
    _SpinPrize('⚡', '+100 XP', Color(0xFFFFD700), 'xp', 100),
    _SpinPrize('❤️', '+3 Can', Color(0xFFFF4B4B), 'heart', 3),
    _SpinPrize('🪙', '+50 Coin', Color(0xFFFF9600), 'coin', 50),
    _SpinPrize('⭐', '+200 XP', practiceGreen, 'xp', 200),
  ];

  late final AnimationController _spinCtrl;
  late Animation<double> _spinAngle;
  late final ConfettiController _confetti;

  bool _spinning = false;
  bool _spun = false;
  bool _canSpin = true;
  int _prizeIndex = 0;

  final PracticeApiService _api = const PracticeApiService();

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 5));
    _spinCtrl = AnimationController(vsync: this);
    // İlk animasyon değeri (dur konumunda)
    _spinAngle = const AlwaysStoppedAnimation(0.0);
    _checkCanSpin();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _checkCanSpin() async {
    final lastSpin = await AppPreferences.getLastSpinDate();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (mounted) setState(() => _canSpin = lastSpin != today);
  }

  Future<void> _spin() async {
    if (_spinning || _spun || !_canSpin) return;
    setState(() => _spinning = true);

    final isTr = AppStrings.code == 'tr';
    final result = await _api.claimDailySpin();
    if (!mounted) return;
    if (result == null) {
      setState(() => _spinning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isTr
              ? 'Ödül alınamadı. Bağlantını kontrol edip tekrar dene.'
              : 'Could not get the reward. Check your connection and retry.'),
        ),
      );
      return;
    }
    if (result['claimed'] != true) {
      setState(() {
        _spinning = false;
        _spun = true;
        _canSpin = false;
      });
      return;
    }

    final key = '${result['prize'] ?? ''}';
    final amount = (result['amount'] as num?)?.toInt() ?? 0;
    final selected = _prizes.indexWhere(
      (item) => item.key == key && item.amount == amount,
    );
    _prizeIndex = selected >= 0 ? selected : 0;

    final extraTurns = 5 + math.Random().nextInt(4);
    final sliceAngle = (math.pi * 2) / _prizes.length;
    final targetSlice = sliceAngle * _prizeIndex;
    final target = (extraTurns * math.pi * 2) +
        (math.pi * 2 - targetSlice - sliceAngle / 2);

    _spinCtrl.duration = const Duration(milliseconds: 4400);
    _spinAngle = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _spinCtrl, curve: Curves.fastLinearToSlowEaseIn),
    );

    unawaited(PracticeSoundService.playStreak());
    await _spinCtrl.forward();
    if (!mounted) return;
    setState(() {
      _spinning = false;
      _spun = true;
      _canSpin = false;
    });
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await AppPreferences.setLastSpinDate(today);
    unawaited(PracticeSoundService.onBadgeEarned());
    _confetti.play();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final prize = _prizes[_prizeIndex];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isTr ? '🎰 Şans Çarkı' : '🎰 Lucky Spin',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // ── Arka plan yıldızları ──
          ...List.generate(16, (i) {
            final angle = (i / 16) * math.pi * 2;
            final r = size.width * 0.42;
            final cx = size.width / 2 + math.cos(angle) * r;
            final cy = size.height / 2 + math.sin(angle) * r - 60;
            return Positioned(
              left: cx - 5,
              top: cy - 5,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color:
                      _prizes[i % _prizes.length].color.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
              )
                  .animate(
                    onPlay: (c) => c.repeat(reverse: true),
                    delay: Duration(milliseconds: 150 * i),
                  )
                  .scaleXY(
                    begin: 0.4,
                    end: 1.0,
                    duration: 800.ms,
                  )
                  .fadeIn(duration: 400.ms),
            );
          }),

          // ── İçerik ──
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isTr ? 'Günlük şansını dene!' : 'Spin your daily luck!',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 32),

              // ── Çark ──
              SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dış parlama
                    Container(
                      width: 310,
                      height: 310,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: practiceYellow.withValues(alpha: 0.18),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    // Dönen çark
                    AnimatedBuilder(
                      animation: _spinCtrl,
                      builder: (_, __) => Transform.rotate(
                        angle: _spinCtrl.isAnimating ? _spinAngle.value : 0.0,
                        child: CustomPaint(
                          size: const Size(300, 300),
                          painter: _WheelPainter(prizes: _prizes),
                        ),
                      ),
                    ),
                    // Merkez dairesi
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black38, blurRadius: 14),
                        ],
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFD700),
                        size: 36,
                      ),
                    ),
                    // Ok işaretçi (üstte sabit)
                    const Positioned(
                      top: 4,
                      child: _SpinPointer(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Ödül gösterimi ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _spun
                    ? Container(
                        key: ValueKey('prize_$_prizeIndex'),
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 16),
                        decoration: BoxDecoration(
                          color: prize.color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: prize.color.withValues(alpha: 0.55),
                              blurRadius: 26,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(prize.emoji,
                                style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 12),
                            Text(
                              prize.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      )
                        .animate()
                        .scaleXY(
                          begin: 0.2,
                          end: 1.0,
                          duration: 550.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 200.ms)
                    : const SizedBox(height: 72, key: ValueKey('empty')),
              ),

              // ── Spin butonu ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: _canSpin
                    ? Practice3DButton(
                        label: _spinning
                            ? (isTr ? 'DÖNÜYOR...' : 'SPINNING...')
                            : (isTr ? '🎰 ÇEVİR!' : '🎰 SPIN!'),
                        color: const Color(0xFFFFD700),
                        textColor: const Color(0xFF4B2D00),
                        onPressed: _spinning ? null : _spin,
                      )
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isTr
                              ? '⏰ Yarın yeniden çevirebilirsin'
                              : '⏰ Come back tomorrow to spin again',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),

              if (_spun) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isTr ? 'Kapat' : 'Close',
                    style: const TextStyle(
                        color: Colors.white38, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),

          // ── Konfeti ──
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 55,
            colors: const [
              Color(0xFFFFD700),
              practiceGreen,
              practiceBlue,
              Color(0xFFFF5964),
              Colors.white,
            ],
            gravity: 0.25,
            emissionFrequency: 0.04,
          ),
        ],
      ),
    );
  }
}

// ── Veri sınıfı ──────────────────────────────────────────────────────────────
class _SpinPrize {
  const _SpinPrize(this.emoji, this.label, this.color, this.key, this.amount);
  final String emoji;
  final String label;
  final Color color;
  final String key;
  final int amount;
}

// ── Ok işaretçi ──────────────────────────────────────────────────────────────
class _SpinPointer extends StatelessWidget {
  const _SpinPointer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(28, 36),
      painter: _PointerPainter(),
    );
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
    final shadow = Paint()
      ..color = Colors.black38
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, shadow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Çark ressam ──────────────────────────────────────────────────────────────
class _WheelPainter extends CustomPainter {
  const _WheelPainter({required this.prizes});
  final List<_SpinPrize> prizes;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final sliceAngle = (math.pi * 2) / prizes.length;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < prizes.length; i++) {
      final start = i * sliceAngle - math.pi / 2;

      // Dilim rengi
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sliceAngle,
        true,
        Paint()
          ..color = i.isEven
              ? prizes[i].color
              : prizes[i].color.withValues(alpha: 0.78)
          ..style = PaintingStyle.fill,
      );

      // Kenar
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sliceAngle,
        true,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );

      // Emoji
      final mid = start + sliceAngle / 2;
      final r = radius * 0.65;
      final lx = center.dx + math.cos(mid) * r;
      final ly = center.dy + math.sin(mid) * r;

      tp.text =
          TextSpan(text: prizes[i].emoji, style: const TextStyle(fontSize: 22));
      tp.layout();
      canvas
        ..save()
        ..translate(lx, ly)
        ..rotate(mid + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
