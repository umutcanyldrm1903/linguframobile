import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_strings.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/ui.dart';
import '../shared/native_video_player_screen.dart';
import 'public_page_scaffold.dart';

class AfterTestScreen extends StatelessWidget {
  const AfterTestScreen({super.key});

  static const _trialBookingIntentKey = 'trial_booking_intent_v1';

  static const _videos = [
    _AfterTestVideo(
      titleTr: 'CNN Turk tanitim',
      titleEn: 'CNN Turk feature',
      path: '/uploads/website-videos/hero/cnn-tanitim-1080p.mp4',
    ),
    _AfterTestVideo(
      titleTr: 'Derslerden kısa kesit 1',
      titleEn: 'Short lesson preview 1',
      path: '/uploads/website-videos/home-showcase-web/home-video-01.mp4',
    ),
    _AfterTestVideo(
      titleTr: 'Derslerden kısa kesit 2',
      titleEn: 'Short lesson preview 2',
      path: '/uploads/website-videos/home-showcase-web/home-video-02.mp4',
    ),
    _AfterTestVideo(
      titleTr: 'Derslerden kısa kesit 3',
      titleEn: 'Short lesson preview 3',
      path: '/uploads/website-videos/home-showcase-web/home-video-03.mp4',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: publicAppViewport(
        context,
        AppGlowBackground(
          accent: AppColors.brand,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 0,
                      child: IconButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/app-home',
                          (_) => false,
                        ),
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  AnimatedPageEntrance(
                    child: _AchievementHero(isTr: isTr),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Text(
                    isTr
                        ? 'Lingufranca ile konuşma pratiğini canlı derse taşı.'
                        : 'Turn your speaking result into a live lesson plan.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.brandNight,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    isTr
                        ? 'Test sonucuna göre seviyeni, zayıf alanını ve sana uygun öğretmeni belirliyoruz. Deneme dersinde doğrudan konuşma pratiğiyle başlarsın.'
                        : 'We use your test result to match your level, weak area, and teacher. Your trial lesson starts directly with speaking practice.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xxl),
                  _AfterTestBenefitGrid(isTr: isTr),
                  const SizedBox(height: AppSpace.xxl),
                  _AfterTestProofStrip(isTr: isTr),
                  const SizedBox(height: AppSpace.xxl),
                  SectionHeader(
                    title: isTr ? 'Bizi videolarla tani' : 'Meet us through videos',
                    icon: Icons.play_circle_fill_rounded,
                  ),
                  StaggeredReveal(
                    children: [
                      for (final video in _videos)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.md),
                          child: _AfterTestVideoTile(video: video, isTr: isTr),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  AppButton(
                    label: isTr
                        ? 'Ücretsiz deneme dersimi ayirt'
                        : 'Book my free trial lesson',
                    tone: AppButtonTone.gold,
                    icon: Icons.workspace_premium_rounded,
                    onPressed: () async {
                      await SecureStorage.setValue(
                        _trialBookingIntentKey,
                        DateTime.now().toIso8601String(),
                      );
                      if (!context.mounted) return;
                      Navigator.pushNamed(context, '/register');
                    },
                  ),
                  const SizedBox(height: AppSpace.md),
                  AppGhostButton(
                    label: isTr ? 'Pratiği tekrar aç' : 'Open practice again',
                    icon: Icons.replay_rounded,
                    onPressed: () => Navigator.pushNamed(context, '/practice'),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/app-home',
                        (_) => false,
                      ),
                      child: Text(
                        isTr ? 'Ana sayfaya dön' : 'Back to home',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        expandHeight: true,
      ),
    );
  }
}

class _AchievementHero extends StatelessWidget {
  const _AchievementHero({required this.isTr});

  final bool isTr;

  @override
  Widget build(BuildContext context) {
    return GradientHero(
      gradient: AppGradients.gold,
      glowColor: Colors.white,
      child: Row(
        children: [
          AchievementBadge(
            icon: Icons.emoji_events_rounded,
            label: isTr ? 'Test tamamlandı' : 'Test complete',
            color: Colors.white,
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTr ? 'Başarı açıldı!' : 'Achievement unlocked!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isTr
                      ? 'Test sonrasi'
                      : 'After your test',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AfterTestBenefitGrid extends StatelessWidget {
  const _AfterTestBenefitGrid({required this.isTr});

  final bool isTr;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String, Gradient)>[
      (
        Icons.record_voice_over_rounded,
        isTr ? 'Canlı speaking' : 'Live speaking',
        isTr
            ? 'Ogretmenle gerçek konuşma pratigi.'
            : 'Real speaking practice with a teacher.',
        AppGradients.brand,
      ),
      (
        Icons.route_rounded,
        isTr ? 'Kisisel plan' : 'Personal plan',
        isTr
            ? 'Seviyene göre 7 günlük rota.'
            : 'A 7-day route based on your level.',
        AppGradients.violet,
      ),
      (
        Icons.workspace_premium_rounded,
        isTr ? 'Ücretsiz deneme' : 'Free trial',
        isTr
            ? 'İlk dersi risk almadan dene.'
            : 'Try the first lesson without risk.',
        AppGradients.gold,
      ),
    ];

    return StaggeredReveal(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: item.$4,
                      borderRadius: AppRadius.all(AppRadius.md),
                      boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.22),
                    ),
                    child: Icon(item.$1, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.brandNight,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.$3,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.muted,
                                    height: 1.35,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AfterTestProofStrip extends StatelessWidget {
  const _AfterTestProofStrip({required this.isTr});

  final bool isTr;

  @override
  Widget build(BuildContext context) {
    return GradientHero(
      gradient: AppGradients.night,
      glowColor: AppColors.accent,
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.white, size: 22),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  isTr ? 'Neden güven veriyor?' : 'Why it builds trust',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            isTr
                ? 'Videolar, öğrenci deneyimleri ve medya gorunumleriyle test sonucunu gerçek bir ders deneyimine bağlıyoruz.'
                : 'Videos, student stories, and media features connect the test result to a real lesson experience.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _AfterTestVideoTile extends StatelessWidget {
  const _AfterTestVideoTile({
    required this.video,
    required this.isTr,
  });

  final _AfterTestVideo video;
  final bool isTr;

  @override
  Widget build(BuildContext context) {
    final title = isTr ? video.titleTr : video.titleEn;
    final url = '${AppConfig.webBaseUrl}${video.path}';
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NativeVideoPlayerScreen(
              title: title,
              videoUrl: url,
            ),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 62,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: AppRadius.all(AppRadius.md),
              boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.24),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.brandNight,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _AfterTestVideo {
  const _AfterTestVideo({
    required this.titleTr,
    required this.titleEn,
    required this.path,
  });

  final String titleTr;
  final String titleEn;
  final String path;
}
