import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
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
            ? 'LinguFranca, online dil egitimini speaking odakli, olculebilir ve ogretmen destekli hale getiren bir platformdur.'
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
    return _SectionCard(
      dark: true,
      icon: Icons.record_voice_over_rounded,
      title: isTr
          ? 'Amacimiz: konusabilen ogrenci yetistirmek'
          : 'Our goal: learners who can speak',
      description: isTr
          ? 'LinguFranca sadece video izleten bir kurs deneyimi degil. Kullanici dinler, cevap verir, konusur ve test sonucuna gore kendisine uygun ogretmenle deneme dersine yonlenir.'
          : 'LinguFranca is not just a video course experience. Learners listen, answer, speak, and continue to a matched teacher based on their test result.',
    );
  }
}

class _ValueSection extends StatelessWidget {
  const _ValueSection();

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final items = [
      (
        Icons.mic_rounded,
        isTr ? 'Speaking odakli akış' : 'Speaking-first flow',
        isTr
            ? 'Kullanici ilk dakikadan itibaren dinleme, anlama ve konusma gorevlerine girer.'
            : 'Users start with listening, meaning, and speaking tasks from the first minute.',
      ),
      (
        Icons.insights_rounded,
        isTr ? 'Seviye ve zayif alan analizi' : 'Level and weak-area insight',
        isTr
            ? 'Test sonucu sadece skor degil; seviye, zayif alan ve uygun hedefe baglanir.'
            : 'The result is not only a score; it connects level, weak area, and next goal.',
      ),
      (
        Icons.groups_rounded,
        isTr ? 'Ogretmen eslesmesi' : 'Teacher matching',
        isTr
            ? 'Kullanici hedeflerine gore speaking, is Ingilizcesi veya sinav odakli ogretmen onerisi alir.'
            : 'Users see teacher suggestions for speaking, business English, or exam goals.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(isTr ? 'Neden LinguFranca?' : 'Why LinguFranca?'),
          const SizedBox(height: 10),
          for (final item in items)
            _InfoTile(icon: item.$1, title: item.$2, detail: item.$3),
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
    return _SectionCard(
      icon: Icons.school_rounded,
      title: isTr ? 'Egitmen modeli' : 'Teacher model',
      description: isTr
          ? 'Egitmenler ogrencinin hedefini ve seviyesini dikkate alarak canli derste pratik yaptirir. Amac ezber degil, gercek konusma refleksi kazandirmaktir.'
          : 'Teachers use the learner goal and level to guide live speaking practice. The aim is real speaking reflex, not memorization.',
      actionLabel: isTr ? 'Ogretmenleri gor' : 'See teachers',
      onAction: () => Navigator.pushReplacementNamed(context, '/app-home'),
    );
  }
}

class _FlowSection extends StatelessWidget {
  const _FlowSection();

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final steps = [
      isTr ? 'Ucretsiz speaking testi' : 'Free speaking test',
      isTr ? 'Seviye ve zayif alan sonucu' : 'Level and weak-area result',
      isTr ? 'Ogretmen onerisi' : 'Teacher recommendation',
      isTr ? 'Deneme dersine yonlendirme' : 'Trial lesson direction',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(isTr ? 'Kullanici akisi' : 'User flow'),
            const SizedBox(height: 14),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding:
                    EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: const Color(0xFFEAF4FF),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Color(0xFF1D7CFF),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: const TextStyle(
                          color: AppColors.brandNight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
        isTr ? 'Dersler kimler icin?' : 'Who are the lessons for?',
        isTr
            ? 'Konusma pratigine ihtiyaci olan baslangic, orta ve ileri seviyedeki ogrenciler icin.'
            : 'For beginner, intermediate, and advanced learners who need speaking practice.',
      ),
      (
        isTr ? 'Ucretsiz test ne ise yarar?' : 'What is the free test for?',
        isTr
            ? 'Kullanici seviyesini, zayif alanini ve uygun ogretmen tipini anlamak icin.'
            : 'To understand the learner level, weak area, and matching teacher type.',
      ),
      (
        isTr ? 'Deneme dersi zorunlu mu?' : 'Is the trial lesson required?',
        isTr
            ? 'Hayir. Kullanici isterse once gorevleri dener, sonra kayit olur.'
            : 'No. Users can try free tasks first and register when ready.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(isTr ? 'Sikca sorulan sorular' : 'FAQ'),
          const SizedBox(height: 10),
          for (final item in items)
            _InfoTile(
              icon: Icons.check_rounded,
              title: item.$1,
              detail: item.$2,
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
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(isTr ? 'Hazirsan baslayalim' : 'Ready to start'),
            const SizedBox(height: 8),
            Text(
              isTr
                  ? 'Ana sayfada ucretsiz gorevleri, ogretmenleri ve profil girisini tek yerden gorebilirsin.'
                  : 'The app home brings free tasks, teachers, and profile access into one place.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/app-home',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D7CFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isTr ? 'Ana sayfaya gec' : 'Go to app home',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.description,
    this.dark = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool dark;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: dark
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D7CFF), Color(0xFF2635D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D7CFF).withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              )
            : _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: dark
                  ? Colors.white.withValues(alpha: 0.16)
                  : const Color(0xFFEAF4FF),
              child: Icon(icon,
                  color: dark ? Colors.white : const Color(0xFF1D7CFF)),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: dark ? Colors.white : AppColors.brandNight,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.84)
                        : AppColors.muted,
                    height: 1.45,
                  ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEAF4FF),
              child: Icon(icon, color: const Color(0xFF1D7CFF)),
            ),
            const SizedBox(width: 12),
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
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.brandNight,
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xFFE3ECF7)),
    boxShadow: [
      BoxShadow(
        color: AppColors.brandNight.withValues(alpha: 0.05),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
