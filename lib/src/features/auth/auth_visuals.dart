import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Maskotun ruh hali — giriş akışına göre değişir.
enum AuthMascotMood { idle, happy, thinking, cheer }

/// Tepki veren "akıllı kalem" maskotu.
///
/// Giriş/kayıt ekranlarında kullanıcıyı izler: e-posta yazarken bakışları
/// imleci takip eder ([lookX]/[lookDown]), şifre alanına geçince gözlerini
/// elleriyle kapatır ([cover]). Bu, formun canlı/oyunlaştırılmış hissini verir.
class AuthMascot extends StatefulWidget {
  const AuthMascot({
    super.key,
    this.size = 132,
    this.lookX = 0,
    this.lookDown = 0,
    this.cover = 0,
    this.mood = AuthMascotMood.idle,
  });

  final double size;

  /// Yatay bakış yönü, -1 (sol) .. 1 (sağ).
  final double lookX;

  /// Aşağı bakış miktarı, 0 (ileri) .. 1 (alan/forma bakar).
  final double lookDown;

  /// Gözleri kapatma miktarı, 0 (açık) .. 1 (tamamen kapalı).
  final double cover;

  final AuthMascotMood mood;

  @override
  State<AuthMascot> createState() => _AuthMascotState();
}

class _AuthMascotState extends State<AuthMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  // Hedeflere yumuşak geçiş için canlı değerler.
  double _lookX = 0;
  double _lookDown = 0;
  double _cover = 0;

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
        // Her karede hedefe doğru kolayca yaklaş (kritik sönümlü hisli takip).
        _lookX += (widget.lookX - _lookX) * 0.18;
        _lookDown += (widget.lookDown - _lookDown) * 0.18;
        _cover += (widget.cover - _cover) * 0.22;

        final t = _c.value; // 0..1
        final phase = t * 2 * math.pi;
        final bob = math.sin(phase) * (widget.size * .03);
        final sway = math.sin(phase) * 0.045;
        final wave = math.sin(phase * 2);
        // Döngü sonunda kısa göz kırpma (gözler açıkken).
        final blink =
            (_cover < 0.4 && t > 0.90 && t < 0.965) ? 1.0 : 0.0;

        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.rotate(
            angle: sway * (1 - _cover), // kapatınca sabit dursun
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _AuthPencilPainter(
                  mood: widget.mood,
                  blink: blink,
                  wave: wave,
                  lookX: _lookX,
                  lookDown: _lookDown,
                  cover: _cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuthPencilPainter extends CustomPainter {
  _AuthPencilPainter({
    required this.mood,
    required this.blink,
    required this.wave,
    required this.lookX,
    required this.lookDown,
    required this.cover,
  });

  final AuthMascotMood mood;
  final double blink;
  final double wave;
  final double lookX;
  final double lookDown;
  final double cover;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    const ink = Color(0xFF3A3A3A);
    final bodyLeft = w * .37;
    final bodyRight = w * .63;
    final bodyTop = h * .25;
    final bodyBottom = h * .72;
    final r = Radius.circular(w * .02);

    // Gölge
    p.color = const Color(0x22000000);
    canvas.drawOval(Rect.fromLTWH(w * .30, h * .885, w * .40, h * .055), p);

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
    p.color = const Color(0xFFFFC83D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(bodyLeft, bodyTop, bodyRight, bodyBottom), r),
      p,
    );
    p.color = const Color(0xFFFFE07A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(bodyLeft, bodyTop,
            bodyLeft + (bodyRight - bodyLeft) * .30, bodyBottom),
        r,
      ),
      p,
    );
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
    final graphite = Path()
      ..moveTo(w * .49, h * .835)
      ..lineTo(w * .51, h * .835)
      ..lineTo(w * .525, h * .87)
      ..lineTo(w * .475, h * .87)
      ..close();
    p.color = ink;
    canvas.drawPath(graphite, p);

    // Yüz — gözler (eller kapatmadan önce çizilir, böylece eller örtebilir)
    final eyeY = h * .39 + lookDown * h * .03;
    final pupil = w * .024;
    final lookPx = lookX * w * .022;
    final lookPy = lookDown * h * .018;

    if (cover < 0.85) {
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
        // Göz akı
        p.color = Colors.white;
        canvas.drawCircle(Offset(w * .45, eyeY), w * .05, p);
        canvas.drawCircle(Offset(w * .55, eyeY), w * .05, p);
        // Bebekler (bakış yönüne kayar)
        p.color = ink;
        canvas.drawCircle(
            Offset(w * .45 + lookPx, eyeY + lookPy), pupil, p);
        canvas.drawCircle(
            Offset(w * .55 + lookPx, eyeY + lookPy), pupil, p);
        // Parıltı
        p.color = Colors.white;
        canvas.drawCircle(
            Offset(w * .465 + lookPx, eyeY - h * .012 + lookPy), w * .011, p);
        canvas.drawCircle(
            Offset(w * .565 + lookPx, eyeY - h * .012 + lookPy), w * .011, p);
      }

      // Yanak (pembe)
      p.color = const Color(0x33FF7AAE);
      canvas.drawCircle(Offset(w * .40, h * .45), w * .028, p);
      canvas.drawCircle(Offset(w * .60, h * .45), w * .028, p);

      // Ağız (moda göre)
      _drawMouth(canvas, p, w, h);
    }

    // Kollar + eldivenli eller.
    // Dinlenme konumu ↔ gözleri kapatma konumu arasında 'cover' ile geçiş.
    final armPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * .036
      ..color = const Color(0xFFE6A700);

    final lShoulder = Offset(bodyLeft, h * .52);
    final rShoulder = Offset(bodyRight, h * .50);

    // Dinlenmede: sağ el hafifçe sallanır.
    final waveY = h * .42 + wave * h * .05;
    final lRest = Offset(w * .25, h * .605);
    final rRest = Offset(w * .76, waveY);
    // Kapatma: eller gözlerin üstüne gelir.
    final lCover = Offset(w * .455, eyeY - h * .01);
    final rCover = Offset(w * .545, eyeY - h * .01);

    final lHand = Offset.lerp(lRest, lCover, cover)!;
    final rHand = Offset.lerp(rRest, rCover, cover)!;

    canvas.drawLine(lShoulder, lHand, armPaint);
    canvas.drawLine(rShoulder, rHand, armPaint);

    p.color = Colors.white;
    canvas.drawCircle(lHand, w * .052, p);
    canvas.drawCircle(rHand, w * .052, p);
    p
      ..color = const Color(0x14000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .006;
    canvas.drawCircle(lHand, w * .052, p);
    canvas.drawCircle(rHand, w * .052, p);
    p.style = PaintingStyle.fill;

    // Tamamen kapalıyken parmak arası küçük "gözetleme" çizgisi.
    if (cover > 0.85 && mood != AuthMascotMood.cheer) {
      p
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .012
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(w * .47, eyeY + h * .002),
        Offset(w * .47, eyeY + h * .03),
        p,
      );
      p.style = PaintingStyle.fill;
    }
  }

  void _drawMouth(Canvas canvas, Paint p, double w, double h) {
    p
      ..color = const Color(0xFF3A3A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .02
      ..strokeCap = StrokeCap.round;
    final mouthY = h * .50;
    final path = Path();
    switch (mood) {
      case AuthMascotMood.cheer:
        // Büyük açık gülümseme
        p.style = PaintingStyle.fill;
        p.color = const Color(0xFF7A3B2E);
        path
          ..moveTo(w * .455, mouthY)
          ..quadraticBezierTo(w * .50, mouthY + h * .06, w * .545, mouthY)
          ..close();
        canvas.drawPath(path, p);
        return;
      case AuthMascotMood.thinking:
        path
          ..moveTo(w * .47, mouthY + h * .01)
          ..lineTo(w * .53, mouthY + h * .01);
        break;
      case AuthMascotMood.happy:
      case AuthMascotMood.idle:
        path
          ..moveTo(w * .465, mouthY)
          ..quadraticBezierTo(w * .50, mouthY + h * .035, w * .535, mouthY);
        break;
    }
    canvas.drawPath(path, p);
    p.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant _AuthPencilPainter old) =>
      old.blink != blink ||
      old.wave != wave ||
      old.lookX != lookX ||
      old.lookDown != lookDown ||
      old.cover != cover ||
      old.mood != mood;
}

/// Animasyonlu, dil temalı arka plan: yumuşak sürüklenen ışık küreleri +
/// hafifçe yükselen çok dilli harfler. Auth ekranlarının "canlı" zeminidir.
class AuthBackground extends StatefulWidget {
  const AuthBackground({super.key, this.child});

  final Widget? child;

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Temel gradyan
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2138D9),
                Color(0xFF3D5CFF),
                Color(0xFF5B73FF),
              ],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
        // Sürüklenen küreler + harfler
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              painter: _AuthBackdropPainter(_c.value),
              size: Size.infinite,
            ),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _AuthBackdropPainter extends CustomPainter {
  _AuthBackdropPainter(this.t);

  final double t; // 0..1 döngü

  // Çok dilli harfler — dil öğrenme temasını sezdirir.
  // Her fontta bulunan Latin/Yunan glifleri seçildi (tofu/kutu riski yok).
  static const _glyphs = ['A', 'ñ', 'ü', 'é', 'ß', 'B', 'Ω', 'Ç', 'ø', 'Σ'];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Yumuşak ışık küreleri
    final orb = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48);
    final phase = t * 2 * math.pi;

    orb.color = AppColors.accent.withValues(alpha: 0.22);
    canvas.drawCircle(
      Offset(w * (0.18 + 0.04 * math.sin(phase)),
          h * (0.16 + 0.03 * math.cos(phase))),
      w * 0.34,
      orb,
    );
    orb.color = const Color(0xFF8E9BFF).withValues(alpha: 0.30);
    canvas.drawCircle(
      Offset(w * (0.86 + 0.05 * math.cos(phase * 0.8)),
          h * (0.30 + 0.04 * math.sin(phase * 0.8))),
      w * 0.40,
      orb,
    );
    orb.color = const Color(0xFF22E0B0).withValues(alpha: 0.16);
    canvas.drawCircle(
      Offset(w * (0.72 + 0.05 * math.sin(phase * 1.2)),
          h * (0.86 + 0.03 * math.cos(phase * 1.1))),
      w * 0.30,
      orb,
    );

    // Yükselen çok dilli harfler
    for (var i = 0; i < _glyphs.length; i++) {
      final seed = i / _glyphs.length;
      final speed = 0.6 + (i % 3) * 0.25;
      // 0..1 arası dikey ilerleme, sararak yükselir.
      final prog = (seed + t * speed) % 1.0;
      final x = w * (0.08 + 0.86 * _frac(seed * 7.3));
      final y = h * (1.05 - prog * 1.15);
      final sway = math.sin((prog + seed) * 2 * math.pi) * w * 0.02;
      final fontSize = w * (0.05 + (i % 4) * 0.012);
      // Kenarlarda sönümlenen opaklık
      final fade = (1 - (prog - 0.5).abs() * 2).clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: _glyphs[i],
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.10 * fade + 0.04),
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + sway, y));
    }
  }

  double _frac(double v) => v - v.floorToDouble();

  @override
  bool shouldRepaint(covariant _AuthBackdropPainter old) => old.t != t;
}
