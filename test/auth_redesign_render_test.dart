import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/features/auth/auth_visuals.dart';
import 'package:lingufranca_mobile/src/features/auth/auth_widgets.dart';

// Yeni oyunlaştırılmış giriş/kayıt kimliğini gerçek piksele döker (cihazsız):
// animasyonlu zemin + tepkili akıllı kalem maskotu (bak / gözünü kapat) +
// beyaz form kartı bileşenleri. Çizimde hata çıkmadığını garanti eder.
void main() {
  testWidgets('Auth oyunlaştırılmış ekranı PNG render et', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final key = GlobalKey();
    final emailCtrl = TextEditingController(text: 'merhaba@dil.app');
    final passCtrl = TextEditingController(text: '123456');

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFF2138D9),
            child: Material(
              type: MaterialType.transparency,
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animasyonlu zemin örneği (sınırlı kutuda)
                  const SizedBox(height: 150, child: AuthBackground()),
                  const SizedBox(height: 8),
                  // Üç maskot durumu yan yana
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      AuthMascot(size: 84, mood: AuthMascotMood.idle),
                      AuthMascot(
                          size: 84,
                          lookX: 0.6,
                          lookDown: 0.7,
                          mood: AuthMascotMood.thinking),
                      AuthMascot(size: 84, cover: 1, mood: AuthMascotMood.idle),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AuthTextField(
                          controller: emailCtrl,
                          label: 'E-posta',
                          icon: Icons.alternate_email_rounded,
                        ),
                        const SizedBox(height: 14),
                        AuthPasswordField(
                          controller: passCtrl,
                          label: 'Şifre',
                        ),
                        const SizedBox(height: 18),
                        AuthPrimaryButton(
                          label: 'GİRİŞ YAP',
                          icon: Icons.login_rounded,
                          onPressed: () {},
                        ),
                        const SizedBox(height: 18),
                        const AuthDivider(label: 'Veya şununla devam et'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
    // Maskotun göz-kapatma lerp'inin tam oturması için birkaç kare ilerlet.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('test_out/auth_redesign.png');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });

    expect(File('test_out/auth_redesign.png').existsSync(), isTrue);

    emailCtrl.dispose();
    passCtrl.dispose();
  });
}
