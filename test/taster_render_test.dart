import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/features/practice/screens/practice_taster_screen.dart';
import 'package:lingufranca_mobile/src/features/practice/screens/practice_visuals.dart';

// Misafir "tadımlık" intro ekranı: karşılama + DEVAM butonu. Gerçek route
// PracticeTheme(allowGuest: true) ile sarılır (giriş kapısı atlanır); burada
// ekranın kendisini sade temayla render edip içeriği ve görseli doğruluyoruz.
// (google_fonts CI'da ağ/asset gerektirdiği için PracticeTheme sarılmaz.)
void main() {
  testWidgets('Misafir tadımlık intro render', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(scaffoldBackgroundColor: practiceKraft),
        home: RepaintBoundary(
          key: key,
          child: const SizedBox(
            width: 390,
            height: 780,
            child: PracticeTasterScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // İçerik doğru: DEVAM/CONTINUE birincil butonu görünür.
    final hasCta = find.text('DEVAM').evaluate().isNotEmpty ||
        find.text('CONTINUE').evaluate().isNotEmpty;
    expect(hasCta, isTrue);

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('test_out/taster_intro.png');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(File('test_out/taster_intro.png').existsSync(), isTrue);
  });
}
