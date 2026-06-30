import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/ui.dart';
import 'public_page_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PublicPageShell(
        title: isTr ? 'Hakkimizda' : 'About us',
        breadcrumb: isTr ? 'Ana Sayfa  >  Hakkimizda' : 'Home  >  About us',
        description: isTr
            ? 'LinguFranca, online dil eğitimini speaking odaklı, ölçülebilir ve öğretmen destekli hale getiren bir platformdur.'
            : 'LinguFranca is a speaking-first online language learning platform with measurable progress and teacher support.',
        icon: Icons.info_outline_rounded,
        children: const [
          _MissionSection(),
          _ValueSection(),
          _TeacherSection(),
          _FlowSection(),
          _FaqSection(),
          _AboutHomeCta(),
        ],
      ),
    );
  }
}

class _MissionSection extends StatelessWidget {
  const _MissionSection();

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: AnimatedPageEntrance(
        child: GradientHero(
          gradient: AppGradients.hero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: AppRadius.all(AppRadius.md),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Icon(
                      Icons.record_voice_over_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: AppStatPill(
                      icon: Icons.flag_rounded,
                      label: isTr ? 'Misyonumuz' : 'Our mission',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                isTr
                    ? 'Amaçımız: konuşabilen öğrenci yetiştirmek'
                    : 'Our goal: learners who can speak',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                isTr
                    ? 'LinguFranca sadece video izleten bir kurs deneyimi değil. Kullanıcı dinler, cevap verir, konuşur ve test sonucuna göre kendisine uygun öğretmenle deneme dersine yönlenir.'
                    : 'LinguFranca is not just a video course experience. Learners listen, answer, speak, and continue to a matched teacher based on their test result.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                      height: 1.45,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueSection extends StatelessWidget {
  const _ValueSection();

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final items = <(IconData, String, String, Color)>[
      (
        Icons.mic_rounded,
        isTr ? 'Speaking odaklı akış' : 'Speaking-first flow',
        isTr
            ? 'Kullanıcı ilk dakikadan itibaren dinleme, anlama ve konuşma gorevlerine girer.'
            : 'Users start with listening, meaning, and speaking tasks from the first minute.',
        AppColors.brand,
      ),
      (
        Icons.insights_rounded,
        isTr ? 'Seviye ve zayıf alan analizi' : 'Level and weak-area insight',
        isTr
            ? 'Test sonucu sadece skor değil; seviye, zayıf alan ve uygun hedefe bağlanır.'
            : 'The result is not only a score; it connects level, weak area, and next goal.',
        AppPalette.violet,
      ),
      (
        Icons.groups_rounded,
        isTr ? 'Öğretmen eşleşmesi' : 'Teacher matching',
        isTr
            ? 'Kullanıcı hedeflerine göre speaking, is Ingilizcesi veya sınav odaklı öğretmen önerisi alir.'
            : 'Users see teacher suggestions for speaking, business English, or exam goals.',
        AppPalette.teal,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: isTr ? 'Neden LinguFranca?' : 'Why LinguFranca?',
            icon: Icons.auto_awesome_rounded,
          ),
          StaggeredReveal(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.md),
                  child: _ValueTile(
                    icon: item.$1,
                    title: item.$2,
                    detail: item.$3,
                    color: item.$4,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppGradients.pair(color, color.withValues(alpha: 0.7)),
              borderRadius: AppRadius.all(AppRadius.md),
              boxShadow: AppShadows.glow(color, opacity: 0.28),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.brandNight,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.35,
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

class _TeacherSection extends StatelessWidget {
  const _TeacherSection();

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: AnimatedPageEntrance(
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppGradients.brand,
                      borderRadius: AppRadius.all(AppRadius.md),
                      boxShadow:
                          AppShadows.glow(AppColors.brand, opacity: 0.26),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(
                      isTr ? 'Egitmen modeli' : 'Teacher model',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.brandNight,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                isTr
                    ? 'Eğitmenler ogrencinin hedefini ve seviyesini dikkate alarak canlı derste pratik yaptirir. Amaç ezber değil, gerçek konuşma refleksi kazandirmaktir.'
                    : 'Teachers use the learner goal and level to guide live speaking practice. The aim is real speaking reflex, not memorization.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: AppSpace.lg),
              AppButton(
                label: isTr ? 'Ogretmenleri gor' : 'See teachers',
                icon: Icons.arrow_forward_rounded,
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/app-home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowSection extends StatelessWidget {
  const _FlowSection();

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final steps = [
      isTr ? 'Ücretsiz speaking testi' : 'Free speaking test',
      isTr ? 'Seviye ve zayıf alan sonucu' : 'Level and weak-area result',
      isTr ? 'Öğretmen önerisi' : 'Teacher recommendation',
      isTr ? 'Deneme dersine yonlendirme' : 'Trial lesson direction',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: isTr ? 'Kullanıcı akışı' : 'User flow',
            icon: Icons.route_rounded,
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < steps.length; i++)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: AppGradients.brand,
                                shape: BoxShape.circle,
                                boxShadow: AppShadows.glow(AppColors.brand,
                                    opacity: 0.26),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (i != steps.length - 1)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  color: AppColors.brand
                                      .withValues(alpha: 0.20),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: i == steps.length - 1 ? 0 : AppSpace.lg,
                              top: 6,
                            ),
                            child: Text(
                              steps[i],
                              style: const TextStyle(
                                color: AppColors.brandNight,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final items = [
      (
        isTr ? 'Dersler kimler için?' : 'Who are the lessons for?',
        isTr
            ? 'Konuşma pratiğine ihtiyacı olan başlangıç, orta ve ileri seviyedeki öğrenciler için.'
            : 'For beginner, intermediate, and advanced learners who need speaking practice.',
      ),
      (
        isTr ? 'Ücretsiz test ne ise yarar?' : 'What is the free test for?',
        isTr
            ? 'Kullanıcı seviyesini, zayıf alanını ve uygun öğretmen tipini anlamak için.'
            : 'To understand the learner level, weak area, and matching teacher type.',
      ),
      (
        isTr ? 'Deneme dersi zorunlu mu?' : 'Is the trial lesson required?',
        isTr
            ? 'Hayir. Kullanıcı isterse önce görevleri dener, sonra kayıt olur.'
            : 'No. Users can try free tasks first and register when ready.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: isTr ? 'Sikca sorulan sorular' : 'FAQ',
            icon: Icons.help_outline_rounded,
          ),
          StaggeredReveal(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.md),
                  child: _FaqTile(question: item.$1, answer: item.$2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      onTap: () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: const Icon(Icons.help_rounded,
                    size: 18, color: AppColors.brand),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  widget.question,
                  style: const TextStyle(
                    color: AppColors.brandNight,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.muted),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm, left: 46),
              child: Text(
                widget.answer,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      height: 1.4,
                    ),
              ),
            ),
            crossFadeState: _open
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _AboutHomeCta extends StatelessWidget {
  const _AboutHomeCta();

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: AnimatedPageEntrance(
        child: GradientHero(
          gradient: AppGradients.violet,
          glowColor: AppPalette.violet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AchievementBadge(
                    icon: Icons.rocket_launch_rounded,
                    label: isTr ? 'Basla' : 'Start',
                    color: AppPalette.gold,
                    size: 52,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(
                      isTr ? 'Hazirsan baslayalim' : 'Ready to start',
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                isTr
                    ? 'Ana sayfada ücretsiz görevleri, öğretmenleri ve profil girisini tek yerden görebilirsin.'
                    : 'The app home brings free tasks, teachers, and profile access into one place.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: AppSpace.lg),
              AppButton(
                label: isTr ? 'Ana sayfaya geç' : 'Go to app home',
                tone: AppButtonTone.gold,
                icon: Icons.home_rounded,
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/app-home',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
