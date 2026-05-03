import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/motion/app_motion.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../public/public_theme.dart';
import '../public/speak_coach_screen.dart';

class AppHomeScreen extends StatefulWidget {
  const AppHomeScreen({super.key});

  @override
  State<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  static const _hasSeenAppHomeKey = 'has_seen_app_home';

  int _index = 0;

  @override
  void initState() {
    super.initState();
    SecureStorage.setValue(_hasSeenAppHomeKey, 'true');
  }

  void _openSpeakingTask(int step) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => PublicTheme(
          child: SpeakCoachScreen(initialMissionStep: step),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final pages = [
      _NativeHomePage(
        onStartTasks: () => setState(() => _index = 1),
        onOpenTeachers: () => setState(() => _index = 2),
      ),
      _TasksPage(onTaskTap: _openSpeakingTask),
      const _TeachersPage(),
      const _AboutMiniPage(),
      const _ProfileEntryPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: AnimatedPageEntrance(
            key: ValueKey(_index),
            duration: AppMotion.normal,
            offset: const Offset(0, 0.025),
            child: pages[_index],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE3ECF7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandNight.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              _DockItem(
                selected: _index == 0,
                icon: Icons.home_rounded,
                label: isTr ? 'Ana' : 'Home',
                onTap: () => setState(() => _index = 0),
              ),
              _DockItem(
                selected: _index == 1,
                icon: Icons.flag_rounded,
                label: isTr ? 'Gorev' : 'Tasks',
                onTap: () => setState(() => _index = 1),
              ),
              _DockItem(
                selected: _index == 2,
                icon: Icons.groups_rounded,
                label: isTr ? 'Hocalar' : 'Teachers',
                onTap: () => setState(() => _index = 2),
              ),
              _DockItem(
                selected: _index == 3,
                icon: Icons.info_rounded,
                label: isTr ? 'Biz' : 'About',
                onTap: () => setState(() => _index = 3),
              ),
              _DockItem(
                selected: _index == 4,
                icon: Icons.person_rounded,
                label: isTr ? 'Profil' : 'Profile',
                onTap: () => setState(() => _index = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NativeHomePage extends StatelessWidget {
  const _NativeHomePage({
    required this.onStartTasks,
    required this.onOpenTeachers,
  });

  final VoidCallback onStartTasks;
  final VoidCallback onOpenTeachers;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
      children: [
        _PageHeader(
          title: isTr ? 'LinguFranca ana sayfa' : 'LinguFranca home',
          subtitle: isTr
              ? 'Speaking hedefini sec, ucretsiz gorevlerle basla ve sana uygun ogretmeni bul.'
              : 'Choose your speaking goal, start free tasks, and find your matched teacher.',
          icon: Icons.language_rounded,
        ),
        const SizedBox(height: 16),
        _HeroActionCard(
          title: isTr ? 'Ucretsiz speaking rutini' : 'Free speaking routine',
          subtitle: isTr
              ? 'Dinleme, anlama ve konusma gorevleriyle seviyeni olcelim.'
              : 'Measure your level with listening, meaning, and speaking tasks.',
          button: isTr ? 'Gorevlere basla' : 'Start tasks',
          onPressed: onStartTasks,
        ),
        const SizedBox(height: 14),
        _DailyFocusCard(
          onStartTasks: onStartTasks,
          onOpenTeachers: onOpenTeachers,
        ),
        const SizedBox(height: 14),
        _SkillPathPreview(onStartTasks: onStartTasks),
        const SizedBox(height: 14),
        _HomeInsightGrid(
          onStartTasks: onStartTasks,
          onOpenTeachers: onOpenTeachers,
        ),
        const SizedBox(height: 14),
        _TeacherMatchStrip(onOpenTeachers: onOpenTeachers),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                value: '5',
                label: isTr ? 'mini gorev' : 'mini tasks',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                value: '3',
                label: isTr ? 'ogretmen onerisi' : 'teacher picks',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _InfoTile(
          icon: Icons.groups_rounded,
          title: isTr ? 'Ogretmenleri incele' : 'Browse teachers',
          detail: isTr
              ? 'Speaking, is Ingilizcesi ve sinav hedeflerine gore egitmen sec.'
              : 'Pick teachers by speaking, business, or exam goals.',
          onTap: onOpenTeachers,
        ),
        _InfoTile(
          icon: Icons.verified_rounded,
          title: isTr ? 'Deneme dersi akisi' : 'Trial lesson flow',
          detail: isTr
              ? 'Test sonucundan sonra sana uygun deneme dersi yonlendirmesi gelir.'
              : 'After the test, continue with a matched trial lesson.',
          onTap: onStartTasks,
        ),
      ],
    );
  }
}

class _DailyFocusCard extends StatelessWidget {
  const _DailyFocusCard({
    required this.onStartTasks,
    required this.onOpenTeachers,
  });

  final VoidCallback onStartTasks;
  final VoidCallback onOpenTeachers;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF122B72), Color(0xFF1D7CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D7CFF).withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
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
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTr ? 'Bugunku hedefin hazir' : 'Your goal is ready',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTr
                          ? '3 mini gorev yap, seviyeni gor ve sana uygun hocayi sec.'
                          : 'Complete 3 mini tasks, see your level, and pick a matched teacher.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _LightActionButton(
                  label: isTr ? 'Gorev yap' : 'Practice',
                  icon: Icons.play_arrow_rounded,
                  onTap: onStartTasks,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LightActionButton(
                  label: isTr ? 'Hoca sec' : 'Pick teacher',
                  icon: Icons.groups_rounded,
                  onTap: onOpenTeachers,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LightActionButton extends StatelessWidget {
  const _LightActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillPathPreview extends StatelessWidget {
  const _SkillPathPreview({required this.onStartTasks});

  final VoidCallback onStartTasks;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final steps = [
      (Icons.volume_up_rounded, isTr ? 'Dinle' : 'Listen'),
      (Icons.translate_rounded, isTr ? 'Anla' : 'Meaning'),
      (Icons.image_rounded, isTr ? 'Sec' : 'Image'),
      (Icons.mic_rounded, isTr ? 'Konus' : 'Speak'),
      (Icons.emoji_events_rounded, isTr ? 'Odul' : 'Reward'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isTr ? 'Speaking yolu' : 'Speaking path',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.brandNight,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              TextButton(
                onPressed: onStartTasks,
                child: Text(isTr ? 'Basla' : 'Start'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? const Color(0xFF63D60F)
                              : const Color(0xFFEAF4FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          steps[i].$1,
                          color:
                              i == 0 ? Colors.white : const Color(0xFF1D7CFF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        steps[i].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.brandNight,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
                if (i != steps.length - 1)
                  Container(
                    width: 10,
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9E7F7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFFF0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  color: Color(0xFF46B800),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTr
                        ? 'Bitirince ucretsiz mini speaking seansi acilir.'
                        : 'Finish to unlock a free mini speaking session.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF2E7D14),
                          fontWeight: FontWeight.w800,
                        ),
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

class _HomeInsightGrid extends StatelessWidget {
  const _HomeInsightGrid({
    required this.onStartTasks,
    required this.onOpenTeachers,
  });

  final VoidCallback onStartTasks;
  final VoidCallback onOpenTeachers;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InsightCard(
                icon: Icons.local_fire_department_rounded,
                value: '1',
                label: isTr ? 'gunluk seri' : 'day streak',
                detail: isTr ? 'Bugun baslat' : 'Start today',
                color: const Color(0xFFFF8A00),
                onTap: onStartTasks,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InsightCard(
                icon: Icons.schedule_rounded,
                value: '19:00',
                label: isTr ? 'musait ders' : 'open slot',
                detail: isTr ? 'Bugun uygun' : 'Available today',
                color: const Color(0xFF1D7CFF),
                onTap: onOpenTeachers,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _InsightCard(
                icon: Icons.psychology_rounded,
                value: 'A2-B1',
                label: isTr ? 'tahmini seviye' : 'level range',
                detail: isTr ? 'Testle netlesir' : 'Confirm by test',
                color: const Color(0xFF8B5CF6),
                onTap: onStartTasks,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InsightCard(
                icon: Icons.groups_rounded,
                value: '42',
                label: isTr ? 'bugun pratik' : 'practiced today',
                detail: isTr ? 'Topluluk aktif' : 'Community active',
                color: const Color(0xFF10B981),
                onTap: onStartTasks,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.detail,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final String detail;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.brandNight,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.brandNight,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherMatchStrip extends StatelessWidget {
  const _TeacherMatchStrip({required this.onOpenTeachers});

  final VoidCallback onOpenTeachers;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECF7FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8EBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isTr ? 'Sana en uygun 3 hoca' : 'Top 3 matched teachers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.brandNight,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              TextButton(
                onPressed: onOpenTeachers,
                child: Text(isTr ? 'Gor' : 'View'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniTeacherAvatar(name: 'G', label: isTr ? 'En uygun' : 'Best'),
              const SizedBox(width: 10),
              _MiniTeacherAvatar(
                name: 'M',
                label: isTr ? 'Erken musait' : 'Soonest',
                color: const Color(0xFF63D60F),
              ),
              const SizedBox(width: 10),
              _MiniTeacherAvatar(
                name: 'D',
                label: isTr ? 'Speaking' : 'Speaking',
                color: const Color(0xFFFFB347),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTeacherAvatar extends StatelessWidget {
  const _MiniTeacherAvatar({
    required this.name,
    required this.label,
    this.color = const Color(0xFF1D7CFF),
  });

  final String name;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDDEAF8)),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.brandNight,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksPage extends StatelessWidget {
  const _TasksPage({required this.onTaskTap});

  final ValueChanged<int> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      children: [
        _PageHeader(
          title: isTr ? 'Ucretsiz gorevler' : 'Free tasks',
          subtitle: isTr
              ? 'Her gorev tek bir beceriyi olcer. Istedigin gorevden baslayabilirsin.'
              : 'Each task measures one skill. Start from any task.',
          icon: Icons.flag_rounded,
        ),
        const SizedBox(height: 16),
        _TaskTile(
          icon: Icons.volume_up_rounded,
          title: isTr ? 'Dinleme gorevi' : 'Listening task',
          detail: isTr
              ? 'Kelimeyi duy ve dogru Turkce anlami sec.'
              : 'Hear the word and choose the correct meaning.',
          onTap: () => onTaskTap(0),
        ),
        _TaskTile(
          icon: Icons.translate_rounded,
          title: isTr ? 'Cumle anlama' : 'Sentence meaning',
          detail: isTr
              ? 'Ingilizce cumlenin Turkcesini bul.'
              : 'Find the Turkish meaning of the English sentence.',
          onTap: () => onTaskTap(1),
        ),
        _TaskTile(
          icon: Icons.image_search_rounded,
          title: isTr ? 'Resim sec' : 'Choose image',
          detail: isTr
              ? 'Duydugun kelimeye uygun resmi sec.'
              : 'Choose the image that matches the word.',
          onTap: () => onTaskTap(2),
        ),
        _TaskTile(
          icon: Icons.mic_rounded,
          title: isTr ? 'Konusma testi' : 'Speaking test',
          detail: isTr
              ? 'Cumleyi sesli tekrar et ve speaking skorunu gor.'
              : 'Repeat the sentence aloud and see your speaking score.',
          onTap: () => onTaskTap(3),
        ),
      ],
    );
  }
}

class _TeachersPage extends StatelessWidget {
  const _TeachersPage();

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final teachers = [
      (
        'Gizem',
        isTr ? 'Speaking ve gunluk konusma' : 'Speaking and daily conversation',
        isTr
            ? 'A2-B1 seviyesinde akici konusma rutini kurar.'
            : 'Builds fluency routines for A2-B1 learners.',
        Icons.record_voice_over_rounded,
      ),
      (
        'Merve',
        isTr ? 'Is Ingilizcesi' : 'Business English',
        isTr
            ? 'Toplanti, sunum ve is gorusmesi pratigi yaptirir.'
            : 'Practices meetings, presentations, and interviews.',
        Icons.work_rounded,
      ),
      (
        'Daniel',
        isTr ? 'Sinav ve telaffuz' : 'Exam and pronunciation',
        isTr
            ? 'IELTS/TOEFL hedefi ve telaffuz netligi icin uygundur.'
            : 'Good fit for IELTS/TOEFL goals and clearer pronunciation.',
        Icons.school_rounded,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      children: [
        _PageHeader(
          title: isTr ? 'Ogretmenler' : 'Teachers',
          subtitle: isTr
              ? 'Public tanitim kartlari. Rezervasyon icin giris yaptirir, otomatik panele atmaz.'
              : 'Public teacher cards. Booking requires sign-in, but this page does not auto-open the student panel.',
          icon: Icons.groups_rounded,
        ),
        const SizedBox(height: 16),
        for (final teacher in teachers)
          _TeacherPreviewCard(
            name: teacher.$1,
            role: teacher.$2,
            detail: teacher.$3,
            icon: teacher.$4,
          ),
      ],
    );
  }
}

class _TeacherPreviewCard extends StatelessWidget {
  const _TeacherPreviewCard({
    required this.name,
    required this.role,
    required this.detail,
    required this.icon,
  });

  final String name;
  final String role;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1D7CFF), Color(0xFF5CB6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.brandNight,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    role,
                    style: const TextStyle(
                      color: Color(0xFF1D7CFF),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          height: 1.3,
                        ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: Text(isTr ? 'Deneme dersi sec' : 'Choose trial'),
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

class _AboutMiniPage extends StatelessWidget {
  const _AboutMiniPage();

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      children: [
        _PageHeader(
          title: isTr ? 'Biz kimiz?' : 'About us',
          subtitle: isTr
              ? 'LinguFranca, speaking odakli online dil egitimi icin tasarlandi.'
              : 'LinguFranca is built for speaking-first online language learning.',
          icon: Icons.info_rounded,
        ),
        const SizedBox(height: 16),
        _AboutPoint(
          icon: Icons.record_voice_over_rounded,
          title: isTr ? 'Speaking odakli' : 'Speaking-first',
          detail: isTr
              ? 'Kullanici pasif izlemek yerine dinler, cevaplar ve konusur.'
              : 'Learners listen, answer, and speak instead of passively watching.',
        ),
        _AboutPoint(
          icon: Icons.school_rounded,
          title: isTr ? 'Ogretmen eslesmesi' : 'Teacher matching',
          detail: isTr
              ? 'Test sonucu hedefe ve seviyeye uygun ogretmen onerisine baglanir.'
              : 'Test results connect directly to level and goal-based teacher picks.',
        ),
        _AboutPoint(
          icon: Icons.support_agent_rounded,
          title: isTr ? 'Canli destek' : 'Live support',
          detail: isTr
              ? 'Deneme dersi ve rezervasyon akisi sade tutulur.'
              : 'Trial lesson and booking flow stays simple.',
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/about'),
            child: Text(isTr ? 'Detayli tanitim sayfasi' : 'Full about page'),
          ),
        ),
      ],
    );
  }
}

class _ProfileEntryPage extends StatelessWidget {
  const _ProfileEntryPage();

  Future<({bool signedIn, String role})> _sessionState() async {
    final token = (await SecureStorage.getToken() ?? '').trim();
    final role = (await SecureStorage.getRole() ?? 'student').trim();
    return (signedIn: token.isNotEmpty, role: role);
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return FutureBuilder<({bool signedIn, String role})>(
      future: _sessionState(),
      builder: (context, snapshot) {
        final session = snapshot.data ?? (signedIn: false, role: 'student');
        final isInstructor = session.role == 'instructor';
        final panelRoute = isInstructor ? '/instructor' : '/student';

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          children: [
            _PageHeader(
              title: isTr ? 'Profil' : 'Profile',
              subtitle: session.signedIn
                  ? (isTr
                      ? 'Oturumun acik. Hesaptan cikmadan paneline donebilirsin.'
                      : 'You are signed in. Return to your panel without logging out.')
                  : (isTr
                      ? 'Derslerini, ogretmenlerini ve rezervasyonlarini yonetmek icin giris yap.'
                      : 'Sign in to manage lessons, teachers, and bookings.'),
              icon: Icons.person_rounded,
            ),
            const SizedBox(height: 16),
            _HeroActionCard(
              title: session.signedIn
                  ? (isTr ? 'Paneline devam et' : 'Continue to your panel')
                  : (isTr ? 'Hesabina devam et' : 'Continue to your account'),
              subtitle: session.signedIn
                  ? (isTr
                      ? 'Ana sayfadan cikmadan mevcut oturumla panelini ac.'
                      : 'Open your panel with the current signed-in session.')
                  : (isTr
                      ? 'Kayitli kullaniciysan ogrenci paneline giris yap.'
                      : 'If you already have an account, open your student panel.'),
              button: session.signedIn
                  ? (isInstructor
                      ? (isTr
                          ? 'Egitmen paneline don'
                          : 'Back to instructor panel')
                      : (isTr
                          ? 'Ogrenci paneline don'
                          : 'Back to student panel'))
                  : (isTr ? 'Giris yap' : 'Sign in'),
              onPressed: () {
                if (session.signedIn) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    panelRoute,
                    (_) => false,
                  );
                  return;
                }
                Navigator.pushNamed(context, '/login');
              },
            ),
            if (!session.signedIn) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: Text(isTr ? 'Yeni hesap olustur' : 'Create account'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D7CFF), Color(0xFF55B3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D7CFF).withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        height: 1.3,
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

class _HeroActionCard extends StatelessWidget {
  const _HeroActionCard({
    required this.title,
    required this.subtitle,
    required this.button,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String button;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.brandNight,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: PressableScale(
              onTap: onPressed,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF63D60F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  button,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF1D7CFF),
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      icon: icon,
      title: title,
      detail: detail,
      onTap: onTap,
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      icon: icon,
      title: title,
      detail: detail,
      onTap: onTap,
    );
  }
}

class _AboutPoint extends StatelessWidget {
  const _AboutPoint({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      icon: icon,
      title: title,
      detail: detail,
    );
  }
}

class _BaseTile extends StatelessWidget {
  const _BaseTile({
    required this.icon,
    required this.title,
    required this.detail,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF4FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF1D7CFF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.brandNight,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF1D7CFF),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: PressableScale(
          onTap: onTap,
          scale: 0.92,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEAF4FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: selected ? 34 : 30,
                  height: selected ? 28 : 26,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF1D7CFF)
                        : const Color(0xFFF1F6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: selected ? 18 : 17,
                    color: selected
                        ? Colors.white
                        : AppColors.brandNight.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF0F5FD7)
                        : AppColors.brandNight.withValues(alpha: 0.78),
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                    fontSize: 10.5,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
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
