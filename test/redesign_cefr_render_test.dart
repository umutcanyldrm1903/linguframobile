import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/features/practice/screens/practice_cefr_score_screen.dart';
import 'package:lingufranca_mobile/src/features/practice/screens/practice_visuals.dart';

// CEFR skor ekranı: yeni "LinkedIn'de paylaş" + "Skorumu paylaş" butonları
// görünür olmalı. Ağ 1ms'de düşer; google_fonts'tan kaçınmak için PracticeTheme
// ile sarılmaz (butonlar bu yüzden Material varsayılan renginde görünür).
class _OfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionTimeout = const Duration(milliseconds: 1);
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    HttpOverrides.global = _OfflineHttpOverrides();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });
  tearDownAll(() {
    HttpOverrides.global = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  testWidgets('CEFR paylaşım butonları render', (tester) async {
    final key = GlobalKey();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(scaffoldBackgroundColor: practiceKraft),
          home: RepaintBoundary(
            key: key,
            child: const SizedBox(
              width: 390,
              height: 820,
              child: PracticeCefrScoreScreen(),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await tester.pump();
    });

    expect(find.text('LinkedIn\'de paylaş'), findsOneWidget);
    expect(find.text('Skorumu paylaş'), findsOneWidget);

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('test_out/redesign_cefr.png');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(File('test_out/redesign_cefr.png').existsSync(), isTrue);
  });
}
