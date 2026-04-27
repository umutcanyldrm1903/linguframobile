import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../shared/native_video_player_screen.dart';
import 'public_page_scaffold.dart';
import 'public_theme.dart';
import 'speak_coach_screen.dart';

class AfterTestScreen extends StatelessWidget {
  const AfterTestScreen({super.key});

  static const _videos = [
    _AfterTestVideo(
      titleTr: 'CNN Turk tanitim',
      titleEn: 'CNN Turk feature',
      path: '/uploads/website-videos/hero/cnn-tanitim-1080p.mp4',
    ),
    _AfterTestVideo(
      titleTr: 'Derslerden kisa kesit 1',
      titleEn: 'Short lesson preview 1',
      path: '/uploads/website-videos/home-showcase-web/home-video-01.mp4',
    ),
    _AfterTestVideo(
      titleTr: 'Derslerden kisa kesit 2',
      titleEn: 'Short lesson preview 2',
      path: '/uploads/website-videos/home-showcase-web/home-video-02.mp4',
    ),
    _AfterTestVideo(
      titleTr: 'Derslerden kisa kesit 3',
      titleEn: 'Short lesson preview 3',
      path: '/uploads/website-videos/home-showcase-web/home-video-03.mp4',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Scaffold(
      backgroundColor: Colors.white,
      body: publicAppViewport(
        context,
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (_) => false,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isTr ? 'Test sonrasi' : 'After your test',
                      style: const TextStyle(
                        color: Color(0xFF1D7CFF),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isTr
                      ? 'Lingufranca ile konusma pratiğini canlı derse taşı.'
                      : 'Turn your speaking result into a live lesson plan.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.brandNight,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  isTr
                      ? 'Test sonucuna göre seviyeni, zayıf alanını ve sana uygun öğretmeni belirliyoruz. Deneme dersinde doğrudan konuşma pratiğiyle başlarsın.'
                      : 'We use your test result to match your level, weak area, and teacher. Your trial lesson starts directly with speaking practice.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 22),
                _AfterTestBenefitGrid(isTr: isTr),
                const SizedBox(height: 22),
                _AfterTestProofStrip(isTr: isTr),
                const SizedBox(height: 22),
                Text(
                  isTr ? 'Bizi videolarla tani' : 'Meet us through videos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.brandNight,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                ..._videos.map(
                  (video) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AfterTestVideoTile(video: video, isTr: isTr),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D7CFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      isTr
                          ? 'Ucretsiz deneme dersimi ayirt'
                          : 'Book my free trial lesson',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PublicTheme(
                            child: SpeakCoachScreen(initialMissionStep: 0),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      isTr
                          ? 'Speaking testini tekrar yap'
                          : 'Retake speaking test',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (_) => false,
                    ),
                    child: Text(
                      isTr ? 'Basa don' : 'Back to start',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        expandHeight: true,
      ),
    );
  }
}

class _AfterTestBenefitGrid extends StatelessWidget {
  const _AfterTestBenefitGrid({required this.isTr});

  final bool isTr;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.record_voice_over_rounded,
        isTr ? 'Canli speaking' : 'Live speaking',
        isTr
            ? 'Ogretmenle gercek konusma pratigi.'
            : 'Real speaking practice with a teacher.',
      ),
      (
        Icons.route_rounded,
        isTr ? 'Kisisel plan' : 'Personal plan',
        isTr
            ? 'Seviyene gore 7 gunluk rota.'
            : 'A 7-day route based on your level.',
      ),
      (
        Icons.workspace_premium_rounded,
        isTr ? 'Ucretsiz deneme' : 'Free trial',
        isTr
            ? 'Ilk dersi risk almadan dene.'
            : 'Try the first lesson without risk.',
      ),
    ];

    return Column(
      children: items
          .map(
            (item) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FBFF),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE3EAF5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF7FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.$1, color: const Color(0xFF1D7CFF)),
                  ),
                  const SizedBox(width: 12),
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
          )
          .toList(),
    );
  }
}

class _AfterTestProofStrip extends StatelessWidget {
  const _AfterTestProofStrip({required this.isTr});

  final bool isTr;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF12345B), Color(0xFF1D7CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTr ? 'Neden guven veriyor?' : 'Why it builds trust',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isTr
                ? 'Videolar, ogrenci deneyimleri ve medya gorunumleriyle test sonucunu gercek bir ders deneyimine bagliyoruz.'
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
    return InkWell(
      borderRadius: BorderRadius.circular(20),
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE3EAF5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandNight.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF1D7CFF),
                size: 34,
              ),
            ),
            const SizedBox(width: 12),
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
