import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/features/practice/screens/practice_visuals.dart';

// "Defter & Kalem" yeni kimliğini gerçek piksele döker (cihazsız).
void main() {
  testWidgets('Defter & Kalem bileşenlerini PNG render et', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: Container(
            color: practiceKraft,
            width: 390,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const PracticeMascot(size: 88, mood: PracticeMascotMood.proud),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: practicePaper,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: practiceLine, width: 1.5),
                        ),
                        child: const Text(
                          'Defterim — 1. Ünite\nİçecek teklif et',
                          style: TextStyle(
                              color: practiceInk,
                              fontSize: 16,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // kraft "index kartı"
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: practicePaper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: practiceLine, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: practiceInk.withValues(alpha: .06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selamlaşmalar',
                          style: TextStyle(
                              color: practiceInk,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text('4 / 5 tamamlandı',
                          style: TextStyle(color: practiceMuted, fontSize: 13)),
                      const SizedBox(height: 12),
                      const PracticeProgressBar(value: 0.8),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Practice3DButton(label: 'SAYFAYI AÇ', onPressed: () {}),
                const SizedBox(height: 12),
                Practice3DButton(
                    label: 'İPUCU AL', onPressed: () {}, outlined: true),
                const SizedBox(height: 10),
                const Practice3DButton(label: 'KİLİTLİ', onPressed: null),
                const Spacer(),
                const PracticeBottomTabs(selected: 0),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('test_out/redesign_defter_kalem.png');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(File('test_out/redesign_defter_kalem.png').existsSync(), isTrue);
  });
}
