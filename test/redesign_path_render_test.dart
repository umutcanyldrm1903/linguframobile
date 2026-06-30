import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/features/practice/screens/practice_path_screen.dart';
import 'package:lingufranca_mobile/src/features/practice/screens/practice_visuals.dart';

// Test ortamında ağ çağrısının asılı timer bırakmaması için bağlantıyı anında
// düşürür → repository senkron fallback derslere döner.
class _OfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionTimeout = const Duration(milliseconds: 1);
  }
}

// Yeni "Defter & Kalem" path ekranını (dikey defter satırları, yılan-yol YOK)
// gerçek piksele döker. Cihaz/ağ gerekmez: repository senkron fallback verir.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _OfflineHttpOverrides();
    // Token okuması (flutter_secure_storage) test'te boş dönsün.
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

  testWidgets('Defter path ekranını PNG render et', (tester) async {
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
              height: 780,
              child: PracticePathScreen(),
            ),
          ),
        ),
      );
      // Ağ çağrısı 1ms'de düşsün, FutureBuilder fallback derslere geçsin.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await tester.pump();

      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('test_out/redesign_defter_path.png');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(File('test_out/redesign_defter_path.png').existsSync(), isTrue);
  });
}
