import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/localization/app_strings.dart';

// "Defter & Kalem" kimliği — kraft kâğıt + mürekkep mavisi çalışma masası.
// Legacy isimler geriye uyumluluk için korunuyor; değerler yeni sıcak palete
// taşındı. (primary=mürekkep mavisi, secondary=teal, accent=sıcak turuncu,
// zemin=kraft, metin=sıcak ink.)
const practiceGreen = Color(0xFF2457D6); // birincil — mürekkep mavisi
const practiceGreenDark = Color(0xFF173E9F); // koyu mürekkep
const practiceBlue = Color(0xFF0E7C6B); // ikincil — teal
const practiceBlueDark = Color(0xFF0A5C50); // koyu teal (gradyan alt ucu)
const practiceYellow = Color(0xFFF0B45A); // sıcak sarı
const practiceOrange = Color(0xFFE8923B); // aksan — sıcak turuncu (seri)
const practicePurple = Color(0xFF7C5CFF); // nadir mor
const practiceInk = Color(0xFF2B2620); // sıcak koyu mürekkep (metin)
const practiceMuted = Color(0xFF8A8170); // sıcak gri (kraft notu)
const practiceLine = Color(0xFFE3D9C2); // kraft kâğıt çizgisi
const practiceRed = Color(0xFFC44536); // sıcak danger
const practicePaper = Color(0xFFFBF6EA); // kart/yüzey kâğıdı
const practiceKraft = Color(0xFFF4ECDC); // arka plan kraft

/// Rengi koyulaştırır (3B butonun alt kenarı için).
Color practiceDarken(Color color, [double amount = .18]) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

/// Defter & Kalem "damga" butonu: düz dolgu + 2px koyu kenar, basınca yüz
/// aşağı İNMEZ (3B kenar yok), sadece hafifçe küçülür (mürekkep damgası hissi).
class Practice3DButton extends StatefulWidget {
  const Practice3DButton({
    required this.label,
    required this.onPressed,
    this.color = practiceGreen,
    this.textColor = Colors.white,
    this.outlined = false,
    this.height = 52,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;

  /// true → beyaz yüz + gri kenar (ikincil aksiyon).
  final bool outlined;
  final double height;

  @override
  State<Practice3DButton> createState() => _Practice3DButtonState();
}

class _Practice3DButtonState extends State<Practice3DButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final faceColor = !enabled
        ? const Color(0xFFE7E0CE)
        : (widget.outlined ? Colors.transparent : widget.color);
    final borderColor = !enabled
        ? const Color(0xFFD8CFB8)
        : (widget.outlined ? widget.color : practiceDarken(widget.color, .12));
    final textColor = !enabled
        ? const Color(0xFFA89F88)
        : (widget.outlined ? widget.color : widget.textColor);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: faceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              letterSpacing: .3,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tam genişlik birincil buton (3B). İmza geriye dönük uyumlu.
class PracticePrimaryButton extends StatelessWidget {
  const PracticePrimaryButton({
    required this.label,
    required this.onPressed,
    this.color = practiceGreen,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Practice3DButton(
      label: label,
      onPressed: onPressed,
      color: color,
    );
  }
}

/// Defter çizgisi ilerleme çubuğu — parıltı/gloss YOK, hafif köşeli (radius 6),
/// kraft track üzerinde düz mürekkep dolum.
class PracticeProgressBar extends StatelessWidget {
  const PracticeProgressBar({
    required this.value,
    this.color = practiceGreen,
    this.height = 14,
    super.key,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: height,
        color: practiceLine,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: clamped == 0 ? 0.0001 : clamped,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PracticeSpeechBubble extends StatelessWidget {
  const PracticeSpeechBubble({
    required this.text,
    this.alignLeftTail = true,
    super.key,
  });

  final String text;
  final bool alignLeftTail;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpeechBubbleTailPainter(alignLeftTail: alignLeftTail),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE2E2E2), width: 2),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF555555),
            fontSize: 19,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SpeechBubbleTailPainter extends CustomPainter {
  const _SpeechBubbleTailPainter({required this.alignLeftTail});

  final bool alignLeftTail;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFFE2E2E2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final x = alignLeftTail ? 5.0 : size.width / 2 - 10;
    final path = Path()
      ..moveTo(x, size.height * .48)
      ..lineTo(x - 18, size.height * .55)
      ..lineTo(x, size.height * .63)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubbleTailPainter oldDelegate) {
    return oldDelegate.alignLeftTail != alignLeftTail;
  }
}

/// Lingo — canlı "akıllı kalem" maskotu. Sürekli zıplar, sallanır,
/// göz kırpar ve el sallar. Tüm pratik ekranlarında aynı widget kullanılır.
class PracticeMascot extends StatefulWidget {
  const PracticeMascot({
    this.size = 120,
    this.mood = PracticeMascotMood.happy,
    super.key,
  });

  final double size;
  final PracticeMascotMood mood;

  @override
  State<PracticeMascot> createState() => _PracticeMascotState();
}

class _PracticeMascotState extends State<PracticeMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value; // 0..1
        final phase = t * 2 * math.pi;
        final bob = math.sin(phase) * (widget.size * .035);
        final sway = math.sin(phase) * 0.05; // radyan
        final wave = math.sin(phase * 2); // el sallama -1..1
        // Döngü sonunda hızlı bir göz kırpma.
        final blink = (t > 0.90 && t < 0.965) ? 1.0 : 0.0;
        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.rotate(
            angle: sway,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _PencilMascotPainter(widget.mood, blink, wave),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum PracticeMascotMood { happy, wink, proud, sad, excited, thinking }

class _PencilMascotPainter extends CustomPainter {
  _PencilMascotPainter(this.mood, this.blink, this.wave);

  final PracticeMascotMood mood;
  final double blink; // 0..1 (1 = göz kapalı)
  final double wave; // -1..1 (el sallama)

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    const ink = Color(0xFF4B4B4B);
    final bodyLeft = w * .37;
    final bodyRight = w * .63;
    final bodyTop = h * .25;
    final bodyBottom = h * .72;
    final r = Radius.circular(w * .02);

    // Gölge
    p.color = const Color(0x1F000000);
    canvas.drawOval(Rect.fromLTWH(w * .30, h * .885, w * .40, h * .06), p);

    // Silgi (üst, pembe)
    p.color = const Color(0xFFFF7AAE);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(bodyLeft, h * .11, bodyRight, h * .19),
        Radius.circular(w * .055),
      ),
      p,
    );
    // Metal bilezik
    p.color = const Color(0xFFC4C9D1);
    canvas.drawRect(Rect.fromLTRB(bodyLeft, h * .19, bodyRight, h * .25), p);
    p.color = const Color(0xFF9AA0A6);
    canvas.drawRect(Rect.fromLTRB(bodyLeft, h * .215, bodyRight, h * .227), p);

    // Gövde (sarı kalem)
    p.color = practiceYellow;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(bodyLeft, bodyTop, bodyRight, bodyBottom), r),
      p,
    );
    // Sol parlak şerit
    p.color = const Color(0xFFFFE07A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(bodyLeft, bodyTop,
            bodyLeft + (bodyRight - bodyLeft) * .30, bodyBottom),
        r,
      ),
      p,
    );
    // Sağ gölge şerit
    p.color = const Color(0xFFE6A700);
    canvas.drawRect(
      Rect.fromLTRB(bodyRight - (bodyRight - bodyLeft) * .16, bodyTop,
          bodyRight, bodyBottom),
      p,
    );

    // Sivri uç (tahta)
    final tip = Path()
      ..moveTo(bodyLeft, bodyBottom)
      ..lineTo(bodyRight, bodyBottom)
      ..lineTo(w * .525, h * .87)
      ..lineTo(w * .475, h * .87)
      ..close();
    p.color = const Color(0xFFE8B06B);
    canvas.drawPath(tip, p);
    // Grafit uç
    final graphite = Path()
      ..moveTo(w * .49, h * .835)
      ..lineTo(w * .51, h * .835)
      ..lineTo(w * .525, h * .87)
      ..lineTo(w * .475, h * .87)
      ..close();
    p.color = ink;
    canvas.drawPath(graphite, p);

    // Kollar + eldivenli eller (sağ el sürekli sallanır)
    final arm = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * .035
      ..color = const Color(0xFFE6A700);
    canvas.drawLine(Offset(bodyLeft, h * .52), Offset(w * .26, h * .60), arm);
    final waveY = h * .40 + wave * h * .05;
    canvas.drawLine(Offset(bodyRight, h * .50), Offset(w * .76, waveY), arm);
    p.color = Colors.white;
    canvas.drawCircle(Offset(w * .25, h * .605), w * .05, p);
    canvas.drawCircle(Offset(w * .77, waveY), w * .05, p);

    // Yüz — gözler
    final eyeY = h * .39;
    if (blink > 0.5) {
      p
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .022
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w * .425, eyeY), Offset(w * .475, eyeY), p);
      canvas.drawLine(Offset(w * .525, eyeY), Offset(w * .575, eyeY), p);
      p.style = PaintingStyle.fill;
    } else {
      p.color = Colors.white;
      canvas.drawCircle(Offset(w * .45, eyeY), w * .05, p);
      canvas.drawCircle(Offset(w * .55, eyeY), w * .05, p);
      p.color = ink;
      if (mood == PracticeMascotMood.wink) {
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .022
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(w * .525, eyeY), Offset(w * .575, eyeY), p);
        p.style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * .45, eyeY), w * .024, p);
      } else {
        final look = mood == PracticeMascotMood.thinking ? -w * .012 : 0.0;
        canvas.drawCircle(
            Offset(w * .45 + look, eyeY - look.abs()), w * .024, p);
        canvas.drawCircle(
            Offset(w * .55 + look, eyeY - look.abs()), w * .024, p);
      }
      // parıltı
      p.color = Colors.white;
      canvas.drawCircle(Offset(w * .465, eyeY - h * .012), w * .012, p);
      canvas.drawCircle(Offset(w * .565, eyeY - h * .012), w * .012, p);
    }

    // Yanak (pembe)
    p.color = const Color(0x33FF7AAE);
    canvas.drawCircle(Offset(w * .40, h * .45), w * .03, p);
    canvas.drawCircle(Offset(w * .60, h * .45), w * .03, p);

    // Ağız (moda göre)
    p
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .02
      ..strokeCap = StrokeCap.round;
    final mouthRect = Rect.fromLTWH(w * .45, h * .45, w * .10, h * .08);
    if (mood == PracticeMascotMood.sad) {
      canvas.drawArc(Rect.fromLTWH(w * .45, h * .50, w * .10, h * .06), math.pi,
          math.pi, false, p);
    } else if (mood == PracticeMascotMood.excited ||
        mood == PracticeMascotMood.proud) {
      p.style = PaintingStyle.fill;
      canvas.drawArc(mouthRect, 0, math.pi, true, p);
    } else if (mood == PracticeMascotMood.thinking) {
      p.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(w * .52, h * .50), w * .018, p);
    } else {
      canvas.drawArc(mouthRect, 0.2, math.pi - 0.4, false, p);
    }
    p.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant _PencilMascotPainter old) =>
      old.mood != mood || old.blink != blink || old.wave != wave;
}

/// Canlı akıllı-kalem maskotlu yükleme göstergesi. Pratik ekranlarında
/// CircularProgressIndicator yerine kullanılır.
class PracticeMascotLoader extends StatelessWidget {
  const PracticeMascotLoader({this.label, this.size = 92, super.key});

  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final text =
        label ?? (AppStrings.code == 'tr' ? 'Yükleniyor...' : 'Loading...');
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PracticeMascot(size: size, mood: PracticeMascotMood.thinking),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              color: practiceMuted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class PracticeConfettiOverlay extends StatelessWidget {
  const PracticeConfettiOverlay({
    required this.child,
    required this.active,
    super.key,
  });

  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (active)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _MiniConfettiPainter()),
            ),
          ),
      ],
    );
  }
}

class _MiniConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      practiceGreen,
      practiceYellow,
      practiceBlue,
      practiceOrange,
      const Color(0xFFFF5964),
    ];
    final safeWidth = size.width <= 1 ? 1 : size.width.toInt();
    final safeHeight = size.height <= 1 ? 1 : size.height.toInt();
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 44; i++) {
      paint.color = colors[i % colors.length].withValues(alpha: .78);
      final x = (i * 37 % safeWidth).toDouble();
      final y = (i * 71 % safeHeight).toDouble();
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(i * .31);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 8, 13),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LessonCountdown extends StatefulWidget {
  const LessonCountdown({
    required this.onFinished,
    super.key,
  });

  final VoidCallback onFinished;

  @override
  State<LessonCountdown> createState() => _LessonCountdownState();
}

class _LessonCountdownState extends State<LessonCountdown> {
  int _value = 3;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 650), _tick);
  }

  void _tick() {
    if (!mounted) return;
    if (_value == 1) {
      widget.onFinished();
      return;
    }
    setState(() => _value--);
    Future<void>.delayed(const Duration(milliseconds: 650), _tick);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Text(
            '$_value',
            key: ValueKey(_value),
            style: const TextStyle(
              color: practiceGreen,
              fontSize: 92,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class PracticeTreasure extends StatelessWidget {
  const PracticeTreasure({this.size = 180, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TreasurePainter()),
    );
  }
}

class _TreasurePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    p.color = const Color(0x22000000);
    canvas.drawOval(Rect.fromLTWH(w * .18, h * .76, w * .64, h * .08), p);
    p.color = const Color(0xFF8B4A20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .27, h * .34, w * .46, h * .38),
        Radius.circular(w * .05),
      ),
      p,
    );
    p.color = const Color(0xFFFFC800);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .22, h * .52, w * .56, h * .27),
        Radius.circular(w * .04),
      ),
      p,
    );
    p.color = practiceOrange;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .43, h * .50, w * .14, h * .24),
        Radius.circular(w * .03),
      ),
      p,
    );
    p.color = practiceBlue;
    canvas.drawOval(Rect.fromLTWH(w * .36, h * .35, w * .18, h * .18), p);
    canvas.drawOval(Rect.fromLTWH(w * .50, h * .37, w * .20, h * .18), p);
    p.color = const Color(0xFF83D9FF);
    canvas.drawOval(Rect.fromLTWH(w * .40, h * .38, w * .06, h * .05), p);
    canvas.drawOval(Rect.fromLTWH(w * .55, h * .40, w * .07, h * .05), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PracticeLeagueLockedGraphic extends StatelessWidget {
  const PracticeLeagueLockedGraphic({this.size = 190, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LeagueLockedPainter()),
    );
  }
}

class _LeagueLockedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    p.color = const Color(0xFFE2C5A5);
    canvas.save();
    canvas.translate(w * .18, h * .35);
    canvas.rotate(-0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w * .32, h * .36), Radius.circular(w * .06)),
      p,
    );
    canvas.restore();
    p.color = practiceYellow;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .36, h * .25, w * .28, h * .44),
        Radius.circular(w * .07),
      ),
      p,
    );
    p.color = const Color(0xFF8DDC19);
    canvas.save();
    canvas.translate(w * .62, h * .34);
    canvas.rotate(0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w * .30, h * .34), Radius.circular(w * .06)),
      p,
    );
    canvas.restore();
    p.color = practiceOrange;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .44, h * .45, w * .14, h * .16),
        Radius.circular(w * .025),
      ),
      p,
    );
    p
      ..color = practiceOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .035;
    canvas.drawArc(
      Rect.fromLTWH(w * .455, h * .36, w * .11, h * .16),
      3.14,
      3.14,
      false,
      p,
    );
    p.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PracticeBottomTabs extends StatelessWidget {
  const PracticeBottomTabs({required this.selected, super.key});

  final int selected;

  @override
  Widget build(BuildContext context) {
    // Defter & Kalem: renk karnavalı + seçili-pill YOK. Tek-renk (ink/muted)
    // outline ikon + etiket; aktif sekmenin altında kısa turuncu vurgu çizgisi.
    final items = [
      (Icons.auto_stories_outlined, '/practice', 'Defter'),
      (Icons.leaderboard_outlined, '/practice/leaderboard', 'Sıralama'),
      (Icons.school_outlined, '/practice/profile', 'Profil'),
      (Icons.inventory_2_outlined, '/practice/daily-quests', 'Görevler'),
      (Icons.chat_bubble_outline_rounded, '/practice/friends', 'Sohbet'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: practicePaper,
        border: Border(top: BorderSide(color: practiceLine)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openTab(context, items[i].$2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].$1,
                          color: i == selected ? practiceInk : practiceMuted,
                          size: 26,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].$3,
                          style: TextStyle(
                            color: i == selected ? practiceInk : practiceMuted,
                            fontSize: 11,
                            fontWeight: i == selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 3,
                          width: 18,
                          decoration: BoxDecoration(
                            color: i == selected
                                ? practiceOrange
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTab(BuildContext context, String route) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) return;

    final navigator = Navigator.of(context);
    if (route == '/practice') {
      navigator.pushNamedAndRemoveUntil(route, (existing) {
        final name = existing.settings.name;
        return name == '/app-home' ||
            name == '/student' ||
            name == '/instructor' ||
            name == '/home' ||
            name == '/' ||
            existing.isFirst;
      });
      return;
    }

    navigator.pushReplacementNamed(route);
  }
}

/// Yanlış cevapta soru kartını sarsar.
/// Kullanım: bir `GlobalKey<PracticeShakeWidgetState>` ile `.currentState?.shake()`.
class PracticeShakeWidget extends StatefulWidget {
  const PracticeShakeWidget({required this.child, super.key});

  final Widget child;

  @override
  PracticeShakeWidgetState createState() => PracticeShakeWidgetState();
}

class PracticeShakeWidgetState extends State<PracticeShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _anim = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 12.0, end: -10.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
  ]).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void shake() => _ctrl.forward(from: 0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) =>
          Transform.translate(offset: Offset(_anim.value, 0), child: child),
      child: widget.child,
    );
  }
}

/// Ders ortasında beliren motivasyon mesajı ("3 soru kaldı!" vb.).
class PracticeMotivationToast extends StatefulWidget {
  const PracticeMotivationToast({
    required this.message,
    required this.onDone,
    super.key,
  });

  final String message;
  final VoidCallback onDone;

  @override
  State<PracticeMotivationToast> createState() =>
      _PracticeMotivationToastState();
}

class _PracticeMotivationToastState extends State<PracticeMotivationToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  late final Animation<double> _anim = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 20,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
  ]).animate(_ctrl);

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Opacity(
        opacity: _anim.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.85 + 0.15 * _anim.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: practiceInk,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Günlük XP hedefi seçici (onboarding / ayarlar).
class PracticeXpGoalSelector extends StatelessWidget {
  const PracticeXpGoalSelector({
    required this.selectedGoal,
    required this.onSelect,
    super.key,
  });

  final int selectedGoal;
  final ValueChanged<int> onSelect;

  static const _goals = [
    (10, '😊', 'Hafif', 'Günde 5 dakika'),
    (20, '🎯', 'Orta', 'Günde 10 dakika'),
    (30, '💪', 'Yoğun', 'Günde 15 dakika'),
    (50, '🔥', 'Çılgın', 'Günde 20+ dakika'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _goals.map((goal) {
        final isSelected = selectedGoal == goal.$1;
        return GestureDetector(
          onTap: () => onSelect(goal.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? practiceBlue.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? practiceBlue : practiceLine,
                width: isSelected ? 2.5 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(goal.$2, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            goal.$3,
                            style: TextStyle(
                              color: isSelected ? practiceBlue : practiceInk,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: practiceYellow,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${goal.$1} XP/gün',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        goal.$4,
                        style: const TextStyle(
                          color: practiceMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      color: practiceBlue, size: 28),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PracticeStreakCelebration — streak milestone kutlaması
// ═══════════════════════════════════════════════════════════════════════════

/// Seri kutlaması: ateş ikonu + animasyonlu sayaç + konfeti.
/// Milestone günlerde (7, 14, 30, 100, 365) göster.
class PracticeStreakCelebration extends StatefulWidget {
  const PracticeStreakCelebration({
    required this.streak,
    this.isNewRecord = false,
    super.key,
  });

  final int streak;
  final bool isNewRecord;

  @override
  State<PracticeStreakCelebration> createState() =>
      _PracticeStreakCelebrationState();
}

class _PracticeStreakCelebrationState extends State<PracticeStreakCelebration>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _fireCtrl;
  late final AnimationController _countCtrl;
  late final Animation<double> _fireScale;
  late final Animation<double> _count;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _fireCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fireScale = Tween<double>(begin: 0.93, end: 1.10).animate(
      CurvedAnimation(parent: _fireCtrl, curve: Curves.easeInOut),
    );
    _countCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _count = Tween<double>(begin: 0, end: widget.streak.toDouble()).animate(
      CurvedAnimation(parent: _countCtrl, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confetti.play();
      _countCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fireCtrl.dispose();
    _countCtrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Stack(
      alignment: Alignment.center,
      children: [
        // Konfeti patlaması
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 32,
          colors: const [
            practiceOrange,
            practiceYellow,
            Color(0xFFFF5964),
            Colors.white,
          ],
          gravity: 0.4,
          emissionFrequency: 0.04,
        ),

        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ateş + sayaç
            ScaleTransition(
              scale: _fireScale,
              child: Column(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 76))
                      .animate()
                      .scaleXY(
                        begin: 0.3,
                        end: 1.0,
                        duration: 700.ms,
                        curve: Curves.elasticOut,
                      ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _count,
                    builder: (context, _) => Text(
                      '${_count.value.round()}',
                      style: const TextStyle(
                        color: practiceOrange,
                        fontSize: 84,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // "GÜNLÜK SERİ" / "YENİ REKOR!"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isNewRecord
                    ? const Color(0xFFFFD700)
                    : practiceOrange,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                widget.isNewRecord
                    ? (isTr ? '🏆 YENİ REKOR!' : '🏆 NEW RECORD!')
                    : (isTr ? '🔥 GÜNLÜK SERİ' : '🔥 DAY STREAK'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            )
                .animate(delay: 600.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.4),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PracticeLeagueTransition — lig terfi / düşme animasyonu
// ═══════════════════════════════════════════════════════════════════════════

/// Lig haftası bitişinde oyuncuya terfi veya düşme mesajını dramatik şekilde gösterir.
/// [isPromotion]=true → yukarıdan içeri girer + konfeti; false → aşağıdan kırmızıyla çıkar.
class PracticeLeagueTransition extends StatefulWidget {
  const PracticeLeagueTransition({
    required this.isPromotion,
    required this.leagueName,
    required this.leagueColor,
    super.key,
  });

  final bool isPromotion;
  final String leagueName;
  final Color leagueColor;

  @override
  State<PracticeLeagueTransition> createState() =>
      _PracticeLeagueTransitionState();
}

class _PracticeLeagueTransitionState extends State<PracticeLeagueTransition>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 5));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scale = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );
    _slide = Tween<Offset>(
      begin: widget.isPromotion ? const Offset(0, -0.6) : const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.forward();
      if (widget.isPromotion) _confetti.play();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final color =
        widget.isPromotion ? widget.leagueColor : const Color(0xFFFF4B4B);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Konfeti (sadece terfi)
        if (widget.isPromotion)
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 45,
            colors: [
              widget.leagueColor,
              practiceYellow,
              Colors.white,
              practiceGreen,
            ],
            gravity: 0.3,
            emissionFrequency: 0.03,
          ),

        // Ana içerik
        FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Büyük emoji
                  Text(
                    widget.isPromotion ? '🎉' : '😢',
                    style: const TextStyle(fontSize: 72),
                  ),
                  const SizedBox(height: 12),

                  // Başlık
                  Text(
                    widget.isPromotion
                        ? (isTr
                            ? '${widget.leagueName} LİGİNE\nYÜKSELDİN!'
                            : 'PROMOTED TO\n${widget.leagueName}!')
                        : (isTr ? 'DÜŞME BÖLGESİNDESİN' : 'DEMOTION ZONE'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lig rozeti
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isPromotion
                          ? Icons.emoji_events_rounded
                          : Icons.trending_down_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Alt bilgi
                  Text(
                    widget.leagueName,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
