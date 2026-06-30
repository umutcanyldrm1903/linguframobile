import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/ui.dart';
import '../practice/practice_repository.dart';

class AppHomeScreen extends StatefulWidget {
  const AppHomeScreen({super.key});

  @override
  State<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  int _index = 0;

  // Pratik istatistikleri (seri/XP/can) tek sefer çekilir; hub kartları bu
  // canlı veriyle dolar. Misafirde fallback (0/0/5), girişte gerçek değerler.
  late final Future<PracticeStats> _statsFuture =
      const PracticeRepository().fetchStats();

  @override
  void initState() {
    super.initState();
    AppPreferences.markAppHomeSeen();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final pages = [
      _NativeHomePage(
        statsFuture: _statsFuture,
        onStartTasks: () => Navigator.pushNamed(context, '/practice'),
        onOpenTeachers: () => setState(() => _index = 1),
      ),
      const _LmsEntryPage(),
      _PracticeHubEntryPage(statsFuture: _statsFuture),
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
                icon: Icons.video_camera_front_rounded,
                label: isTr ? 'Dersler' : 'Lessons',
                onTap: () => setState(() => _index = 1),
              ),
              _DockItem(
                selected: _index == 2,
                icon: Icons.auto_awesome_rounded,
                label: isTr ? 'Pratik' : 'Practice',
                onTap: () => setState(() => _index = 2),
              ),
              _DockItem(
                selected: _index == 3,
                icon: Icons.person_rounded,
                label: isTr ? 'Profil' : 'Profile',
                onTap: () => setState(() => _index = 3),
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
    required this.statsFuture,
    required this.onStartTasks,
    required this.onOpenTeachers,
  });

  final Future<PracticeStats> statsFuture;
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
              ? 'Pratik hedefini seç, oyunlu mini derslerle ilerle ve sana uygun öğretmeni bul.'
              : 'Choose your practice goal, progress with gamified mini lessons, and find your matched teacher.',
          icon: Icons.language_rounded,
        ),
        const SizedBox(height: 16),
        _HeroActionCard(
          title: isTr ? 'Günlük pratik rutini' : 'Daily practice routine',
          subtitle: isTr
              ? 'Kısa oyunlu derslerle XP kazan, serini koru ve eksiklerini tekrar et.'
              : 'Earn XP with quick gamified lessons, keep your streak, and review weak points.',
          button: isTr ? 'Pratiğe başla' : 'Start practice',
          onPressed: onStartTasks,
        ),
        const SizedBox(height: 12),
        _PracticeProgressSummary(
          statsFuture: statsFuture,
          onTap: onStartTasks,
        ),
        const SizedBox(height: 12),
        _PracticeLiveStats(statsFuture: statsFuture, onTap: onStartTasks),
        const SizedBox(height: 14),
        _DailyFocusCard(
          onStartTasks: onStartTasks,
          onOpenTeachers: onOpenTeachers,
        ),
        const SizedBox(height: 14),
        _PracticeModeTile(
          title: isTr ? 'Pratik Yap' : 'Practice',
          detail: isTr
              ? 'XP kazan, serini koru ve mini ders yolunda ilerle.'
              : 'Earn XP, keep your streak, and progress on the mini lesson path.',
          onTap: () => Navigator.pushNamed(context, '/practice'),
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
                label: isTr ? 'mini pratik' : 'mini practices',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                value: '3',
                label: isTr ? 'öğretmen önerisi' : 'teacher picks',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _InfoTile(
          icon: Icons.groups_rounded,
          title: isTr ? 'Öğretmenleri incele' : 'Browse teachers',
          detail: isTr
              ? 'Speaking, iş İngilizcesi ve sınav hedeflerine göre eğitmen seç.'
              : 'Pick teachers by speaking, business, or exam goals.',
          onTap: onOpenTeachers,
        ),
        _InfoTile(
          icon: Icons.verified_rounded,
          title: isTr ? 'Deneme dersi akışı' : 'Trial lesson flow',
          detail: isTr
              ? 'Pratikten sonra seviyene uygun deneme dersi yönlendirmesi gelir.'
              : 'After practice, continue with a matched trial lesson.',
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
    return GradientHero(
      gradient: AppGradients.night,
      padding: const EdgeInsets.all(16),
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
                      isTr ? 'Bugünkü hedefin hazır' : 'Your goal is ready',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTr
                          ? '1 mini pratik yap, XP kazan ve serini bugün başlat.'
                          : 'Complete 1 mini practice, earn XP, and start your streak today.',
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
                  label: isTr ? 'Pratik yap' : 'Practice',
                  icon: Icons.play_arrow_rounded,
                  onTap: onStartTasks,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LightActionButton(
                  label: isTr ? 'Hoca seç' : 'Pick teacher',
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
      (Icons.image_rounded, isTr ? 'Seç' : 'Image'),
      (Icons.mic_rounded, isTr ? 'Konuş' : 'Speak'),
      (Icons.emoji_events_rounded, isTr ? 'Ödül' : 'Reward'),
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: isTr ? 'Pratik yolu' : 'Practice path',
            icon: Icons.route_rounded,
            actionLabel: isTr ? 'Başla' : 'Start',
            onAction: onStartTasks,
          ),
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
                        ? 'Bitirince günlük görev ve XP ödülü açılır.'
                        : 'Finish to unlock daily quests and XP rewards.',
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
                label: isTr ? 'günlük seri' : 'day streak',
                detail: isTr ? 'Bugün başlat' : 'Start today',
                color: const Color(0xFFFF8A00),
                onTap: onStartTasks,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InsightCard(
                icon: Icons.schedule_rounded,
                value: '19:00',
                label: isTr ? 'müsait ders' : 'open slot',
                detail: isTr ? 'Bugün uygun' : 'Available today',
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
                label: isTr ? 'bugün pratik' : 'practiced today',
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
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
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
          SectionHeader(
            title: isTr ? 'Sana en uygun 3 hoca' : 'Top 3 matched teachers',
            icon: Icons.groups_rounded,
            actionLabel: isTr ? 'Gor' : 'View',
            onAction: onOpenTeachers,
          ),
          Row(
            children: [
              _MiniTeacherAvatar(name: 'G', label: isTr ? 'En uygun' : 'Best'),
              const SizedBox(width: 10),
              _MiniTeacherAvatar(
                name: 'M',
                label: isTr ? 'Erken müsait' : 'Soönest',
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

/// Hub'ın "Kurslar" sekmesi: GERÇEK LMS girişi. Sahte öğretmen kartı değil;
/// öğrenci paneline (/student), kurs kataloğuna ve eğitmen/paketlere bağlanır.
class _LmsEntryPage extends StatelessWidget {
  const _LmsEntryPage();

  Future<bool> _signedIn() async {
    final token = (await SecureStorage.getToken() ?? '').trim();
    return token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return FutureBuilder<bool>(
      future: _signedIn(),
      builder: (context, snapshot) {
        final signedIn = snapshot.data == true;
        final lmsRoute = signedIn ? '/student' : '/login';
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          children: [
            _PageHeader(
              title: isTr ? 'Canlı dersler' : 'Live lessons',
              subtitle: isTr
                  ? 'Öğretmenli canlı dersler, paketler ve mesajların tümü burada.'
                  : 'Live teacher lessons, packages, and messages — all here.',
              icon: Icons.video_camera_front_rounded,
            ),
            const SizedBox(height: 16),
            _HeroActionCard(
              title: signedIn
                  ? (isTr ? 'Öğrenci paneline git' : 'Open your student panel')
                  : (isTr ? 'Canlı derslere başla' : 'Start live lessons'),
              subtitle: signedIn
                  ? (isTr
                      ? 'Canlı derslerin, eğitmenlerin, ödevlerin ve mesajların tam panelini aç.'
                      : 'Open your full panel: live lessons, teachers, homework, and messages.')
                  : (isTr
                      ? 'Giriş yap; öğretmen seç, deneme dersi al ve derslerine başla.'
                      : 'Sign in to pick a teacher, book a trial, and start your lessons.'),
              button: signedIn
                  ? (isTr ? 'Panelime git' : 'Go to panel')
                  : (isTr ? 'Giriş yap' : 'Sign in'),
              onPressed: () => Navigator.pushNamed(context, lmsRoute),
            ),
            const SizedBox(height: 4),
            _InfoTile(
              icon: Icons.groups_rounded,
              title: isTr ? 'Eğitmenler' : 'Teachers',
              detail: isTr
                  ? 'Speaking, iş İngilizcesi ve sınav hedeflerine göre eğitmen seç.'
                  : 'Pick teachers by speaking, business, or exam goals.',
              onTap: () => Navigator.pushNamed(context, lmsRoute),
            ),
            _InfoTile(
              icon: Icons.card_membership,
              title: isTr ? 'Paketler' : 'Packages',
              detail: isTr
                  ? 'Ders kredisi paketlerini incele ve satın al.'
                  : 'Review and buy lesson credit packages.',
              onTap: () => Navigator.pushNamed(context, lmsRoute),
            ),
          ],
        );
      },
    );
  }
}

class _PracticeHubEntryPage extends StatelessWidget {
  const _PracticeHubEntryPage({required this.statsFuture});

  final Future<PracticeStats> statsFuture;

  Future<bool> _signedIn() async {
    final token = (await SecureStorage.getToken() ?? '').trim();
    return token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';

    return FutureBuilder<bool>(
      future: _signedIn(),
      builder: (context, snapshot) {
        final signedIn = snapshot.data == true;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          children: [
            _PageHeader(
              title: isTr ? 'Pratik merkezi' : 'Practice hub',
              subtitle: signedIn
                  ? (isTr
                      ? 'Ders yoluna dön, XP kazan ve günlük serini koru.'
                      : 'Return to the lesson path, earn XP, and protect your streak.')
                  : (isTr
                      ? 'Pratik ilerlemesi hesaba bağlanır. Giriş yapinca ders yolu açılır.'
                      : 'Practice progress is account-based. Sign in to open the lesson path.'),
              icon: Icons.auto_awesome_rounded,
            ),
            const SizedBox(height: 16),
            _PracticeModeTile(
              title: isTr ? 'Pratik Yap' : 'Start practice',
              detail: isTr
                  ? 'XP kazan, serini koru, canlarını takip et ve mini dersleri bitir.'
                  : 'Earn XP, keep your streak, track hearts, and finish mini lessons.',
              onTap: () => Navigator.pushNamed(context, '/practice'),
            ),
            const SizedBox(height: 2),
            _PracticeProgressSummary(statsFuture: statsFuture),
            const SizedBox(height: 12),
            _PracticeLiveStats(statsFuture: statsFuture),
            const SizedBox(height: 14),
            _InfoTile(
              icon: Icons.route_rounded,
              title: isTr ? 'Ders yolu' : 'Lesson path',
              detail: isTr
                  ? 'Üniteleri ve kilitli dersleri oyun yolu gibi gör.'
                  : 'See units and locked lessons in a game-like path.',
              onTap: () => Navigator.pushNamed(context, '/practice/path'),
            ),
            _InfoTile(
              icon: Icons.task_alt_rounded,
              title: isTr ? 'Günlük görevler' : 'Daily quests',
              detail: isTr
                  ? 'Bugünün XP ve ödül hedeflerini tamamla.'
                  : 'Complete today\'s XP and reward goals.',
              onTap: () =>
                  Navigator.pushNamed(context, '/practice/daily-quests'),
            ),
            _InfoTile(
              icon: Icons.replay_rounded,
              title: isTr ? 'Hatalarımı çalış' : 'Practice mistakes',
              detail: isTr
                  ? 'Yanlış yaptığın soruları tekrar çöz.'
                  : 'Redo the questions you missed.',
              onTap: () => Navigator.pushNamed(context, '/practice/mistakes'),
            ),
            _InfoTile(
              icon: Icons.emoji_events_rounded,
              title: isTr ? 'Lig ve rozetler' : 'Leagues and badges',
              detail: isTr
                  ? 'Sıralama, rozet ve ödül ekranlarina geç.'
                  : 'Open leaderboard, badges, and reward screens.',
              onTap: () =>
                  Navigator.pushNamed(context, '/practice/leaderboard'),
            ),
            if (!signedIn) ...[
              const SizedBox(height: 6),
              AppGhostButton(
                label: isTr
                    ? 'Giriş yapmadan önce tanitimi gor'
                    : 'Preview sign-in gate',
                onPressed: () => Navigator.pushNamed(context, '/practice'),
                icon: Icons.visibility_rounded,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Hub'da canlı pratik istatistikleri: 🔥 seri · ⚡ XP · ❤️ can.
/// Tek seferlik fetchStats sonucunu gösterir (misafirde 0/0/5 fallback).
class _PracticeLiveStats extends StatelessWidget {
  const _PracticeLiveStats({required this.statsFuture, this.onTap});

  final Future<PracticeStats> statsFuture;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return FutureBuilder<PracticeStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final loading = snapshot.connectionState != ConnectionState.done;
        String v(int? n) => loading ? '…' : '${n ?? 0}';
        final row = Row(
          children: [
            Expanded(
              child: _PracticeStatChip(
                icon: Icons.local_fire_department_rounded,
                label: isTr ? 'Seri' : 'Streak',
                value: v(stats?.streak),
                color: const Color(0xFFFF9600),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PracticeStatChip(
                icon: Icons.bolt_rounded,
                label: 'XP',
                value: v(stats?.xp),
                color: const Color(0xFFFFC800),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PracticeStatChip(
                icon: Icons.favorite_rounded,
                label: isTr ? 'Can' : 'Hearts',
                value: v(stats?.hearts),
                color: const Color(0xFFFF4B4B),
              ),
            ),
          ],
        );
        if (onTap == null) return row;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: row,
        );
      },
    );
  }
}

/// Canlı pratik özetini kit rozetleriyle (StreakBadge/XpPill/AppStatPill) ve
/// GERÇEK seviye ilerlemesini bir ProgressRing ile gösterir. Veriler tek
/// seferlik [statsFuture]'dan gelir; yüklenirken nazik bir iskelet görünür.
class _PracticeProgressSummary extends StatelessWidget {
  const _PracticeProgressSummary({required this.statsFuture, this.onTap});

  final Future<PracticeStats> statsFuture;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return FutureBuilder<PracticeStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final loading = snapshot.connectionState != ConnectionState.done;
        final progress = stats == null
            ? 0.0
            : stats.levelProgress.clamp(0.0, 1.0).toDouble();
        return AppCard(
          onTap: onTap,
          child: Row(
            children: [
              ProgressRing(
                value: loading ? 0 : progress,
                size: 72,
                stroke: 8,
                gradient: AppGradients.brand,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isTr ? 'Seviye' : 'Level',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                    ),
                    Text(
                      loading ? '…' : '${stats?.level ?? 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.brandNight,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTr ? 'Pratik ilerlemen' : 'Your practice progress',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.brandNight,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StreakBadge(days: loading ? 0 : (stats?.streak ?? 0)),
                        XpPill(xp: loading ? 0 : (stats?.xp ?? 0)),
                        AppStatPill(
                          icon: Icons.favorite_rounded,
                          label: '${loading ? '…' : (stats?.hearts ?? 0)}',
                          color: AppPalette.heart,
                          onLight: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PracticeStatChip extends StatelessWidget {
  const _PracticeStatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3ECF7)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.brandNight,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
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
                      ? 'Oturumun açık. Hesaptan çıkmadan paneline dönebilirsin.'
                      : 'You are signed in. Return to your panel without logging out.')
                  : (isTr
                      ? 'Derslerini, öğretmenlerini ve rezervasyonlarini yönetmek için giriş yap.'
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
                      ? 'Ana sayfadan çıkmadan mevcut oturumla panelini aç.'
                      : 'Open your panel with the current signed-in session.')
                  : (isTr
                      ? 'Kayıtlı kullanıcıysan öğrenci paneline giriş yap.'
                      : 'If you already have an account, open your student panel.'),
              button: session.signedIn
                  ? (isInstructor
                      ? (isTr
                          ? 'Eğitmen paneline dön'
                          : 'Back to instructor panel')
                      : (isTr
                          ? 'Öğrenci paneline dön'
                          : 'Back to student panel'))
                  : (isTr ? 'Giriş yap' : 'Sign in'),
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
              AppGhostButton(
                label: isTr ? 'Yeni hesap oluştur' : 'Create account',
                onPressed: () => Navigator.pushNamed(context, '/register'),
                icon: Icons.person_add_alt_1_rounded,
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
    return GradientHero(
      gradient: AppGradients.hero,
      padding: const EdgeInsets.all(18),
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
    return AppCard(
      padding: const EdgeInsets.all(18),
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
          AppButton(
            label: button,
            onPressed: onPressed,
            tone: AppButtonTone.success,
            height: 52,
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
    return AppCard(
      padding: const EdgeInsets.all(16),
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

class _PracticeModeTile extends StatelessWidget {
  const _PracticeModeTile({
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF58CC02),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF46A302),
                offset: Offset(0, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: .92),
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        _PracticeMiniBadge(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Seri',
                        ),
                        SizedBox(width: 8),
                        _PracticeMiniBadge(
                          icon: Icons.bolt_rounded,
                          label: 'XP',
                        ),
                        SizedBox(width: 8),
                        _PracticeMiniBadge(
                          icon: Icons.favorite_rounded,
                          label: 'Can',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeMiniBadge extends StatelessWidget {
  const _PracticeMiniBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF58CC02), size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2E7D14),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(15),
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
