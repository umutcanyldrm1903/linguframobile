import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/features/splash/splash_screen.dart';

// Yeni oyunlaştırılmış splash ekranını gerçek piksele döker (cihazsız).
void main() {
  testWidgets('Splash ekranı PNG render et', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(key: key, child: const SplashScreen()),
      ),
    );

    // Giriş animasyonlarının (mascot/isim/sayaç) oturması için kareler ilerlet.
    for (var i = 0; i < 110; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('test_out/splash.png');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });

    expect(File('test_out/splash.png').existsSync(), isTrue);
  });
}
