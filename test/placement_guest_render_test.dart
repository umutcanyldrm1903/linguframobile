import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/features/practice/screens/practice_placement_screen.dart';

// Misafir (girişsiz) seviye belirleme testi: guest:true iken sunucu çağrısı
// YAPILMAZ (ağ gerekmez) ve ilk soru render olur. Tadımlık akışının çekirdeği.
void main() {
  testWidgets('Misafir placement (girişsiz) render', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: const SizedBox(
            width: 390,
            height: 780,
            child: PracticePlacementScreen(guest: true, popOnFinish: true),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // İlk soru görünür (ağ yok); seçeneklerden biri ekranda.
    expect(find.text('Hello'), findsOneWidget);

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('test_out/placement_guest.png');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(File('test_out/placement_guest.png').existsSync(), isTrue);
  });
}
