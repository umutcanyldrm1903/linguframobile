import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/core/theme/app_colors.dart';
import 'package:lingufranca_mobile/src/core/ui/ui.dart';
import 'package:lingufranca_mobile/src/features/shell/app_shell_scaffold.dart';

// Alt menü "clearance" düzeltmesini doğrular: sayfanın en altındaki buton
// (örn. Çıkış) yüzen alt menünün ARKASINDA kalmamalı, üstünde görünmeli.
void main() {
  testWidgets('Shell alt-boşluk: alttaki buton nav arkasında kalmıyor',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final key = GlobalKey();
    final page = Column(
      children: [
        const SizedBox(height: 12),
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: AppCard(child: SizedBox(height: 48, width: double.infinity)),
          ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: AppButton(
            label: 'ÇIKIŞ YAP',
            tone: AppButtonTone.danger,
            icon: Icons.logout_rounded,
            onPressed: () {},
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: AppShellScaffold(
            currentIndex: 0,
            roleLabel: 'Öğrenci',
            accentColor: AppColors.brand,
            onLogout: () async {},
            onDestinationSelected: (_) {},
            destinations: const [
              AppShellDestination(
                  title: 'Profil', label: 'Profil', icon: Icons.person_rounded),
              AppShellDestination(
                  title: 'Ana', label: 'Ana', icon: Icons.home_rounded),
            ],
            pages: [page, const SizedBox.shrink()],
          ),
        ),
      ),
    );

    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('test_out/shell_clearance.png');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    expect(File('test_out/shell_clearance.png').existsSync(), isTrue);
  });
}
