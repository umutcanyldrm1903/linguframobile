import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/features/practice/screens/practice_placement_screen.dart';

// Misafir hızlı başlangıç: 5 soruyu yanıtlayıp sonuç/teklif ekranına ulaş.
// Ekranda tahmini seviye + "GİRİŞ YAP" / "ANA EKRANA GEÇ" butonları olmalı.
void main() {
  testWidgets('Misafir sonuç/teklif ekranı (giriş yap / ana ekran)',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: const SizedBox(
            width: 390,
            height: 820,
            child: PracticePlacementScreen(guest: true, popOnFinish: true),
          ),
        ),
      ),
    );

    const answers = [
      'Hello',
      'am',
      'I would like water.',
      'went',
      'Where are you from?',
    ];
    for (final answer in answers) {
      await tester.pump(const Duration(milliseconds: 260));
      await tester.tap(find.text(answer));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.tap(find.text('DEVAM ET'));
    }
    // AnimatedSwitcher geçişinin tam yerleşmesi için birkaç kare ilerlet.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Sonuç/teklif ekranı: iki buton görünür.
    expect(find.text('GİRİŞ YAP'), findsOneWidget);
    expect(find.text('ANA EKRANA GEÇ'), findsOneWidget);

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('test_out/placement_guest_result.png');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(File('test_out/placement_guest_result.png').existsSync(), isTrue);
  });
}
