import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/core/motion/app_motion.dart';

// MascotLoading (uygulama genel yükleme göstergesi) artık mezuniyet şapkası
// app-icon yerine akıllı kalem maskotunu göstermeli. Görsel doğrulama.
void main() {
  testWidgets('MascotLoading akıllı kalem render', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: const SizedBox(
                width: 280,
                height: 280,
                child: Center(child: MascotLoading(message: 'Hazırlanıyor')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('test_out/mascot_loading.png');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(File('test_out/mascot_loading.png').existsSync(), isTrue);
  });
}
