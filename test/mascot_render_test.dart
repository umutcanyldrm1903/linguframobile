import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/features/practice/screens/practice_visuals.dart';

// Akıllı kalem maskotunu GERÇEK piksele render edip PNG'ye yazar.
// Cihaz/emülatör gerekmez (flutter test yazılım renderer'ı kullanır).
void main() {
  testWidgets('maskotu PNG olarak render et', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    PracticeMascot(size: 150, mood: PracticeMascotMood.happy),
                    SizedBox(width: 20),
                    PracticeMascot(size: 150, mood: PracticeMascotMood.proud),
                    SizedBox(width: 20),
                    PracticeMascot(size: 150, mood: PracticeMascotMood.thinking),
                    SizedBox(width: 20),
                    PracticeMascot(size: 150, mood: PracticeMascotMood.wink),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // animasyonu ortada bir kareye getir
    await tester.pump(const Duration(milliseconds: 400));

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('test_out/mascot_smart_pencil.png');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });

    expect(File('test_out/mascot_smart_pencil.png').existsSync(), isTrue);
  });
}
