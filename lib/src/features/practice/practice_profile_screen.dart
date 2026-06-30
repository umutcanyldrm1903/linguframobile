import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/motion/app_motion.dart';
import 'practice_api_service.dart';
import 'practice_repository.dart';
import 'screens/practice_visuals.dart';

class PracticeProfileScreen extends StatefulWidget {
  const PracticeProfileScreen({super.key});

  @override
  State<PracticeProfileScreen> createState() => _PracticeProfileScreenState();
}

class _PracticeProfileScreenState extends State<PracticeProfileScreen> {
  final PracticeApiService _api = const PracticeApiService();
  static const PracticeRepository _repository = PracticeRepository();

  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.getProfile();
    if (!mounted) return;
    setState(() {
      _profile = data;
      _loading = false;
    });
  }

  /// Profil paylaşımı — eski sürümde butonun callback'i boştu (hiçbir şey
  /// yapmıyordu); artık sistem paylaşımıyla ilerleme paylaşılır.
  Future<void> _shareProfile(
      String name, int level, int totalXp, int streak) async {
    final text =
        '$name · Seviye $level · $totalXp XP · $streak günlük seri 🔥\n'
        'Lingufranca ile İngilizce pratiği 👉 https://www.lingufranca.com';
    await SharePlus.instance.share(
      ShareParams(subject: 'Lingufranca pratik profilim', text: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _repository.loadStats();
    final profile = _profile;

    // Data — prefer API, fall back to local cache
    final name = '${profile?['name'] ?? profile?['username'] ?? 'Kullanıcı'}';
    final totalXp =
        (profile?['stats']?['total_xp'] as num?)?.toInt() ?? stats.xp;
    final streak =
        (profile?['stats']?['streak'] as num?)?.toInt() ?? stats.streak;
    final coins =
        (profile?['stats']?['coins'] as num?)?.toInt() ?? stats.coins;
    final hearts =
        (profile?['stats']?['hearts'] as num?)?.toInt() ?? stats.hearts;
    final accuracy = (profile?['accuracy'] as num?)?.toInt() ?? 0;
    final completedLessons =
        (profile?['completed_lessons'] as num?)?.toInt() ?? 0;
    final learnedWords = (profile?['learned_words'] as num?)?.toInt() ?? 0;
    final achievementsEarned =
        (profile?['achievements_earned'] as num?)?.toInt() ?? 0;
    final level = profile?['level'];
    final levelLabel =
        '${level?['label'] ?? level?['name'] ?? 'Başlangi\u00e7'}';
    final levelNum = (level?['level'] as num?)?.toInt() ?? 1;
    final weeklyActivity = _asList(profile?['weekly_activity']);

    return Scaffold(
      backgroundColor: practiceKraft,
      appBar: AppBar(
        backgroundColor: practiceKraft,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: practiceInk,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/practice/settings'),
            icon: const Icon(Icons.settings_rounded,
                color: practiceBlue, size: 31),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: MascotLoading(message: 'Profil yükleniyor...'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: practiceInk,
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Seviye $levelNum — $levelLabel',
                              style: const TextStyle(
                                color: practiceBlue,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: practiceBlue.withValues(alpha: 0.1),
                          border: Border.all(
                            color: practiceBlue.withValues(alpha: 0.3),
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: practiceBlue,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Takip / Takipçi ─────────────────────────────────────
                  Row(
                    children: [
                      _FollowStat(
                        label: 'Takip',
                        count: (profile?['following_count'] as num?)?.toInt() ??
                            (profile?['friends_count'] as num?)?.toInt() ??
                            0,
                        onTap: () =>
                            Navigator.pushNamed(context, '/practice/follow'),
                      ),
                      const SizedBox(width: 22),
                      _FollowStat(
                        label: 'Takipçi',
                        count: (profile?['followers_count'] as num?)?.toInt() ??
                            0,
                        onTap: () =>
                            Navigator.pushNamed(context, '/practice/follow'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Action buttons ───────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/practice/friends'),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('ARKADAŞ EKLE'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: practiceBlue,
                            side:
                                const BorderSide(color: practiceLine, width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 64,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () =>
                              _shareProfile(name, levelNum, totalXp, streak),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: practiceBlue,
                            side:
                                const BorderSide(color: practiceLine, width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Icon(Icons.ios_share_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── Stats Grid ──────────────────────────────────────────
                  const Text(
                    'İstatistikler',
                    style: TextStyle(
                      color: practiceInk,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.45,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, '/practice/streak'),
                        child: _StatTile(
                            icon: Icons.local_fire_department_rounded,
                            value: '$streak',
                            label: 'Günlük seri',
                            color: practiceOrange),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, '/practice/xp-history'),
                        child: _StatTile(
                            icon: Icons.bolt_rounded,
                            value: '$totalXp',
                            label: 'Toplam XP',
                            color: practiceYellow),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, '/practice/coin-history'),
                        child: _StatTile(
                            icon: Icons.diamond_rounded,
                            value: '$coins',
                            label: 'Coinler',
                            color: practiceBlue),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, '/practice/hearts'),
                        child: _StatTile(
                            icon: Icons.favorite_rounded,
                            value: '$hearts',
                            label: 'Canlar',
                            color: practiceRed),
                      ),
                      _StatTile(
                          icon: Icons.track_changes,
                          value: '$accuracy%',
                          label: 'Doğruluk',
                          color: practiceGreen),
                      _StatTile(
                          icon: Icons.school_rounded,
                          value: '$completedLessons',
                          label: 'Ders',
                          color: practiceBlueDark),
                      _StatTile(
                          icon: Icons.menu_book_rounded,
                          value: '$learnedWords',
                          label: 'Kelime',
                          color: practiceBlue),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, '/practice/achievements'),
                        child: _StatTile(
                            icon: Icons.emoji_events_rounded,
                            value: '$achievementsEarned',
                            label: 'Rozet',
                            color: practiceYellow),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // ── Weekly Activity ─────────────────────────────────────
                  if (weeklyActivity.isNotEmpty) ...[
                    const Text(
                      'Bu Hafta Aktivite',
                      style: TextStyle(
                        color: practiceInk,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _WeeklyActivityBar(days: weeklyActivity),
                    const SizedBox(height: 26),
                  ],

                  // ── Quick Links ─────────────────────────────────────────
                  const Text(
                    'Hızlı Erişim',
                    style: TextStyle(
                      color: practiceInk,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _QuickLink(
                    icon: Icons.bolt_rounded,
                    color: practiceOrange,
                    label: 'XP Geçmişi',
                    onTap: () =>
                        Navigator.pushNamed(context, '/practice/xp-history'),
                  ),
                  _QuickLink(
                    icon: Icons.diamond_rounded,
                    color: practiceBlue,
                    label: 'Coin Geçmişi',
                    onTap: () =>
                        Navigator.pushNamed(context, '/practice/coin-history'),
                  ),
                  _QuickLink(
                    icon: Icons.emoji_events_rounded,
                    color: practiceYellow,
                    label: 'Başarılar',
                    onTap: () =>
                        Navigator.pushNamed(context, '/practice/achievements'),
                  ),
                  _QuickLink(
                    icon: Icons.analytics_rounded,
                    color: practiceBlueDark,
                    label: 'Detaylı Analitik',
                    onTap: () =>
                        Navigator.pushNamed(context, '/practice/analytics'),
                  ),
                  _QuickLink(
                    icon: Icons.assessment_rounded,
                    color: practiceGreen,
                    label: 'CEFR Seviyem',
                    onTap: () =>
                        Navigator.pushNamed(context, '/practice/cefr'),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 2),
    );
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}

class _FollowStat extends StatelessWidget {
  const _FollowStat({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: const TextStyle(
                color: practiceInk,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: practiceBlue,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: practiceInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: practiceMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: practicePaper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: practiceLine, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: practiceInk,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: practiceMuted, size: 24),
          ],
        ),
      ),
    );
  }
}

class _WeeklyActivityBar extends StatelessWidget {
  const _WeeklyActivityBar({required this.days});
  final List<Map<String, dynamic>> days;

  @override
  Widget build(BuildContext context) {
    final maxXp = days.fold<int>(
        1, (m, d) => ((d['xp'] as num?)?.toInt() ?? 0) > m ? (d['xp'] as num).toInt() : m);
    final dayLabels = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          days.length.clamp(0, 7),
          (i) {
            final d = days[i];
            final xp = (d['xp'] as num?)?.toInt() ?? 0;
            final active = xp > 0;
            final ratio = (xp / maxXp).clamp(0.05, 1.0);
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 400 + i * 60),
                  width: 28,
                  height: (48 * ratio),
                  decoration: BoxDecoration(
                    color: active ? practiceBlue : const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dayLabels[i % 7],
                  style: TextStyle(
                    color: active ? practiceBlue : practiceMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
