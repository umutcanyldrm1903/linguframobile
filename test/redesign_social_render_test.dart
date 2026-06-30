import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingufranca_mobile/src/features/practice/practice_profile_screen.dart';
import 'package:lingufranca_mobile/src/features/practice/screens/practice_daily_quests_screen.dart';
import 'package:lingufranca_mobile/src/features/practice/screens/practice_friends_screen.dart';
import 'package:lingufranca_mobile/src/features/practice/screens/practice_visuals.dart';

// "Defter & Kalem" kimliğine çekilen sosyal/oyunlaştırma ekranlarını (Görevler,
// Arkadaşlar, Profil) gerçek piksele döker. Ağ çağrıları 1ms'de düşüp fallback'e
// geçer; google_fonts'tan kaçınmak için PracticeTheme ile sarılmaz.
class _OfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionTimeout = const Duration(milliseconds: 1);
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await tester.pump();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('test_out/$name.png');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  expect(File('test_out/$name.png').existsSync(), isTrue);
}

Future<void> _pumpScreen(WidgetTester tester, GlobalKey key, Widget screen) {
  return tester.runAsync(() async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(scaffoldBackgroundColor: practiceKraft),
        home: RepaintBoundary(
          key: key,
          child: SizedBox(width: 390, height: 820, child: screen),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await tester.pump();
  });
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _OfflineHttpOverrides();
    SharedPreferences.setMockInitialValues({});
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

  testWidgets('Görevler ekranı (defter checklist) render', (tester) async {
    final key = GlobalKey();
    await _pumpScreen(tester, key, const PracticeDailyQuestsScreen());
    await _capture(tester, key, 'redesign_quests');
  });

  testWidgets('Arkadaşlar BÜLTEN (defter kupürü) render', (tester) async {
    final key = GlobalKey();
    await _pumpScreen(tester, key, const PracticeFriendsScreen());
    await _capture(tester, key, 'redesign_friends');
  });

  testWidgets('Profil (karne kartları) render', (tester) async {
    final key = GlobalKey();
    await _pumpScreen(tester, key, const PracticeProfileScreen());
    await _capture(tester, key, 'redesign_profile');
  });
}
