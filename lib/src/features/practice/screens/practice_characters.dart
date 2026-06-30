import 'package:flutter/material.dart';

import 'practice_visuals.dart';

/// Akıllı Kalem Defteri karakter kadrosu. Her karakterin rengi, biçimi ve
/// kişiliği farklı; derslerde/hikâyelerde/roleplay'de konuşmacı olarak kullanılır.
class PracticeCharacter {
  const PracticeCharacter({
    required this.name,
    required this.color,
    required this.accent,
    required this.shape,
    required this.persona,
  });

  final String name;
  final Color color;
  final Color accent;
  final PracticeCharShape shape;

  /// Roleplay/hikâye için kısa kişilik notu.
  final String persona;
}

enum PracticeCharShape { owl, round, tall, fox, bear }

const List<PracticeCharacter> practiceCharacters = [
  PracticeCharacter(
    name: 'Lingu',
    color: practiceGreen,
    accent: practiceOrange,
    shape: PracticeCharShape.owl,
    persona: 'Neşeli rehber baykuş',
  ),
  PracticeCharacter(
    name: 'Mina',
    color: Color(0xFFFF7AC8),
    accent: Color(0xFFFFD43B),
    shape: PracticeCharShape.round,
    persona: 'Meraklı ve enerjik',
  ),
  PracticeCharacter(
    name: 'Efe',
    color: practiceBlue,
    accent: Colors.white,
    shape: PracticeCharShape.tall,
    persona: 'Sakin ve düşünceli',
  ),
  PracticeCharacter(
    name: 'Zara',
    color: practicePurple,
    accent: Color(0xFFFFE1B2),
    shape: PracticeCharShape.fox,
    persona: 'Esprili ve hızlı',
  ),
  PracticeCharacter(
    name: 'Bao',
    color: practiceOrange,
    accent: Color(0xFF7FE62F),
    shape: PracticeCharShape.bear,
    persona: 'Cana yakın ve sabırlı',
  ),
];

PracticeCharacter practiceCharacterByName(String? name) {
  if (name == null || name.trim().isEmpty) return practiceCharacters.first;
  final lower = name.trim().toLowerCase();
  for (final c in practiceCharacters) {
    if (c.name.toLowerCase() == lower) return c;
  }
  // İsme göre deterministik seçim (kadro dışı isimler için).
  final idx =
      lower.codeUnits.fold<int>(0, (a, b) => a + b) % practiceCharacters.length;
  return practiceCharacters[idx];
}

/// Bir karakteri çizen yuvarlak avatar.
class PracticeCharacterAvatar extends StatelessWidget {
  const PracticeCharacterAvatar({
    required this.character,
    this.size = 64,
    super.key,
  });

  final PracticeCharacter character;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CharacterPainter(character)),
    );
  }
}

class _CharacterPainter extends CustomPainter {
  const _CharacterPainter(this.c);

  final PracticeCharacter c;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // gölge
    p.color = const Color(0x18000000);
    canvas.drawOval(Rect.fromLTWH(w * .20, h * .84, w * .60, h * .10), p);

    // gövde
    p.color = c.color;
    switch (c.shape) {
      case PracticeCharShape.tall:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .26, h * .14, w * .48, h * .70),
            Radius.circular(w * .24),
          ),
          p,
        );
      case PracticeCharShape.round:
        canvas.drawCircle(Offset(w * .5, h * .52), w * .34, p);
      case PracticeCharShape.fox:
        final path = Path()
          ..moveTo(w * .5, h * .14)
          ..lineTo(w * .82, h * .42)
          ..lineTo(w * .70, h * .82)
          ..lineTo(w * .30, h * .82)
          ..lineTo(w * .18, h * .42)
          ..close();
        canvas.drawPath(path, p);
      case PracticeCharShape.bear:
        canvas.drawCircle(Offset(w * .30, h * .26), w * .12, p);
        canvas.drawCircle(Offset(w * .70, h * .26), w * .12, p);
        canvas.drawCircle(Offset(w * .5, h * .54), w * .34, p);
      case PracticeCharShape.owl:
        final body = Path()
          ..moveTo(w * .22, h * .44)
          ..cubicTo(w * .14, h * .24, w * .30, h * .12, w * .5, h * .16)
          ..cubicTo(w * .70, h * .12, w * .86, h * .24, w * .78, h * .44)
          ..cubicTo(w * .86, h * .64, w * .70, h * .82, w * .5, h * .82)
          ..cubicTo(w * .30, h * .82, w * .14, h * .64, w * .22, h * .44)
          ..close();
        canvas.drawPath(body, p);
    }

    // göz beyazları
    p.color = Colors.white;
    canvas.drawCircle(Offset(w * .40, h * .46), w * .11, p);
    canvas.drawCircle(Offset(w * .60, h * .46), w * .11, p);
    // göz bebekleri
    p.color = practiceInk;
    canvas.drawCircle(Offset(w * .41, h * .47), w * .05, p);
    canvas.drawCircle(Offset(w * .59, h * .47), w * .05, p);

    // gaga / ağız (accent)
    p.color = c.accent == Colors.white ? practiceOrange : c.accent;
    final beak = Path()
      ..moveTo(w * .5, h * .56)
      ..lineTo(w * .56, h * .60)
      ..lineTo(w * .5, h * .65)
      ..lineTo(w * .44, h * .60)
      ..close();
    canvas.drawPath(beak, p);
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) =>
      oldDelegate.c.name != c.name;
}
