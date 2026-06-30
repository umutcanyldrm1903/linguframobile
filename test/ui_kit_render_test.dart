import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/core/theme/app_colors.dart';
import 'package:lingufranca_mobile/src/core/ui/ui.dart';

// Lingufranca Premium bileşen kitini gerçek piksele döker (cihazsız):
// hero, kartlar, butonlar, stat kartı (sparkline/trend), ilerleme halkası,
// oyunlaştırma rozetleri ve başarı madalyonları. Çizimde hata çıkmamalı.
void main() {
  testWidgets('UI kit galeri PNG render et', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
        home: RepaintBoundary(
          key: key,
          child: Material(
            type: MaterialType.transparency,
            child: AppGlowBackground(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero
                    GradientHero(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Merhaba, Umut 👋',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900)),
                          SizedBox(height: 6),
                          Text('Bugün 3 ders seni bekliyor',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 14),
                          Row(children: [
                            StreakBadge(days: 12),
                            SizedBox(width: 8),
                            XpPill(xp: 2340, onLight: false),
                            SizedBox(width: 8),
                            LevelChip(level: 5),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    // Stat kartları
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            icon: Icons.menu_book_rounded,
                            label: 'Tamamlanan ders',
                            value: 48,
                            trend: 12,
                            spark: const [3, 5, 4, 7, 6, 9, 11],
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: StatCard(
                            icon: Icons.timer_rounded,
                            label: 'Dakika',
                            value: 1240,
                            color: AppPalette.violet,
                            trend: -5,
                            spark: const [9, 8, 8, 6, 7, 5, 6],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.lg),
                    // İlerleme halkaları
                    AppCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ProgressRing(value: 0.75, color: AppColors.brand),
                          ProgressRing(
                              value: 0.45,
                              color: AppPalette.success,
                              gradient: AppGradients.success),
                          ProgressRing(
                              value: 0.9,
                              color: AppPalette.streak,
                              gradient: AppGradients.streak),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    // Butonlar
                    const AppButton(
                        label: 'DERSE BAŞLA', onPressed: _noop, icon: Icons.play_arrow_rounded),
                    const SizedBox(height: 10),
                    const AppButton(
                        label: 'ÖDÜLÜ AL',
                        onPressed: _noop,
                        tone: AppButtonTone.gold,
                        icon: Icons.card_giftcard_rounded),
                    const SizedBox(height: 10),
                    AppGhostButton(label: 'Daha sonra', onPressed: () {}),
                    const SizedBox(height: AppSpace.lg),
                    // Rozetler / madalyalar
                    AppCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          AchievementBadge(
                              icon: Icons.emoji_events_rounded,
                              label: 'İlk Ders',
                              color: AppPalette.gold),
                          AchievementBadge(
                              icon: Icons.local_fire_department_rounded,
                              label: '7 Gün Seri',
                              color: AppPalette.streak),
                          AchievementBadge(
                              icon: Icons.workspace_premium_rounded,
                              label: 'Kilitli',
                              unlocked: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Row(
                      children: [
                        AppChip(label: 'Tümü', selected: true, onTap: _noop),
                        const SizedBox(width: 8),
                        AppChip(
                            label: 'Gramer',
                            selected: false,
                            onTap: _noop,
                            icon: Icons.spellcheck_rounded),
                        const SizedBox(width: 8),
                        const RankPill(rank: 127, trendUp: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('test_out/ui_kit_gallery.png');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });

    expect(File('test_out/ui_kit_gallery.png').existsSync(), isTrue);
  });
}

void _noop() {}
