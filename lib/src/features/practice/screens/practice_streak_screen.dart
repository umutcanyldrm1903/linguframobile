import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../practice_api_service.dart';
import '../practice_repository.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

class PracticeStreakScreen extends StatefulWidget {
  const PracticeStreakScreen({super.key});

  @override
  State<PracticeStreakScreen> createState() => _PracticeStreakScreenState();
}

class _PracticeStreakScreenState extends State<PracticeStreakScreen> {
  static const PracticeRepository _repository = PracticeRepository();
  final PracticeApiService _api = const PracticeApiService();
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  PracticeStats _stats = _repository.loadStats();
  List<Map<String, dynamic>> _days = [];
  int _freezes = 0;
  bool _showMilestone = true;
  bool _buying = false;

  @override
  void initState() {
    super.initState();
    _maybeCelebrate(_stats.streak);
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getStreak();
    if (!mounted || data == null) return;
    setState(() {
      _stats = _repository.parseStats(data['stats']);
      _days = _asList(data['days']);
      _freezes = _asInt(data['streak_freezes']);
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Mağazadaki "streak_freeze" eşyasını coin ile satın alır (mevcut backend).
  Future<void> _buyStreakFreeze() async {
    if (_buying) return;
    final isTr = AppStrings.code == 'tr';
    setState(() => _buying = true);
    final shop = await _api.getShop();
    if (!mounted) {
      _buying = false;
      return;
    }
    final raw = shop?['items'] ?? shop?['shop_items'];
    Map<String, dynamic>? freeze;
    if (raw is List) {
      for (final it in raw.whereType<Map>()) {
        final tag = '${it['type'] ?? it['key'] ?? it['icon'] ?? ''}'
            .toLowerCase();
        if (tag.contains('freeze')) {
          freeze = Map<String, dynamic>.from(it);
          break;
        }
      }
    }
    final id = (freeze?['id'] as num?)?.toInt() ?? 0;
    if (id <= 0) {
      setState(() => _buying = false);
      _toast(isTr
          ? 'Seri dondurma şu an mağazada yok.'
          : 'Streak freeze is not available right now.');
      return;
    }
    final result = await _api.buyShopItem(id);
    if (!mounted) return;
    setState(() => _buying = false);
    if (result != null) {
      await PracticeSoundService.onBadgeEarned();
      await _load();
      if (!mounted) return;
      _toast(isTr ? 'Seri dondurma eklendi!' : 'Streak freeze added!');
    } else {
      _toast(isTr
          ? 'Satın alınamadı — yeterli coin olmayabilir.'
          : 'Purchase failed — you may not have enough coins.');
    }
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  void _maybeCelebrate(int streak) {
    if (_isMilestone(streak)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _confetti.play();
        unawaited(PracticeSoundService.playStreak());
      });
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  bool _isMilestone(int days) => const [7, 14, 30, 50, 100, 365].contains(days);

  Future<void> _share(int streak, int xp) async {
    final isTr = AppStrings.code == 'tr';
    await SharePlus.instance.share(
      ShareParams(
        subject: isTr ? 'Pratik serim' : 'My practice streak',
        text: isTr
            ? '$streak günlük pratik serimi koruyorum. Bu hafta $xp XP yaptım.'
            : 'I am keeping a $streak-day practice streak. I earned $xp XP this week.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final stats = _stats;
    final milestone = _isMilestone(stats.streak);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        title: Text(isTr ? 'Seri' : 'Streak'),
        backgroundColor: const Color(0xFFF6FAFF),
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                Color(0xFFFF9F1C),
                Color(0xFFFFD43B),
                Color(0xFF63D60F),
                practiceBlue,
              ],
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A0A00), Color(0xFF5A2500)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFF9F1C),
                      size: 92,
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .then()
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.08, 1.08),
                          duration: 700.ms,
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .scale(
                          begin: const Offset(1.08, 1.08),
                          end: const Offset(1, 1),
                          duration: 700.ms,
                          curve: Curves.easeInOut,
                        ),
                    Text(
                      '${stats.streak}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 58,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      isTr ? 'günlük seri' : 'day streak',
                      style: const TextStyle(
                        color: Color(0xFFFFD43B),
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _StreakCalendar(days: _days, freezes: _freezes),
              const SizedBox(height: 16),
              _ActionTile(
                icon: Icons.ac_unit_rounded,
                title: isTr ? 'Seri Dondurma' : 'Streak Freeze',
                subtitle: isTr
                    ? 'Elinde $_freezes adet · alıştırma yapmadığın bir günü korur. Almak için dokun.'
                    : 'You have $_freezes · protects a missed day. Tap to get one.',
                onTap: _buyStreakFreeze,
              ),
              const SizedBox(height: 16),
              const _DoubleOrNothingCard(),
              const SizedBox(height: 16),
              _ActionTile(
                icon: Icons.build_rounded,
                title: isTr ? 'Seri tamiri' : 'Streak repair',
                subtitle: isTr
                    ? 'Kacirdigin günü coin ile telafi etmeyi dene.'
                    : 'Try repairing a missed day with coins.',
                onTap: () => Navigator.pushNamed(
                  context,
                  '/practice/streak-repair',
                ),
              ),
              _ActionTile(
                icon: Icons.ios_share_rounded,
                title: isTr ? 'Serimi paylas' : 'Share streak',
                subtitle: isTr
                    ? 'Arkadaşlarina seri ve XP durumunu gönder.'
                    : 'Send your streak and XP progress to friends.',
                onTap: () => _share(stats.streak, stats.weeklyXp),
              ),
            ],
          ),
          if (milestone && _showMilestone)
            _MilestoneOverlay(
              streak: stats.streak,
              onDismiss: () => setState(() => _showMilestone = false),
            ),
        ],
      ),
    );
  }
}

/// "Çift ya da Hiç" teaser kartı → gerçek, sunucu-yönetimli bahis ekranını
/// (/practice/streak-wager) açar. (Eski sürüm yalnızca yerel bir bool yazıyordu;
/// gerçek coin düşmüyor/kazanılmıyordu.)
class _DoubleOrNothingCard extends StatelessWidget {
  const _DoubleOrNothingCard();

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/practice/streak-wager'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: practicePaper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: practiceLine, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: practiceOrange.withValues(alpha: .14),
                shape: BoxShape.circle,
                border: Border.all(color: practiceOrange, width: 2),
              ),
              child: const Icon(Icons.casino_rounded,
                  color: practiceOrange, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTr ? 'Çift ya da Hiç' : 'Double or Nothing',
                    style: const TextStyle(
                      color: practiceInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isTr
                        ? 'Coin yatır, seriyi koru, iki katını kazan.'
                        : 'Wager coins, keep your streak, win double.',
                    style: const TextStyle(
                      color: practiceMuted,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: practiceInk),
          ],
        ),
      ),
    );
  }
}

class _StreakCalendar extends StatelessWidget {
  const _StreakCalendar({required this.days, required this.freezes});

  final List<Map<String, dynamic>> days;
  final int freezes;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    // Son 14 günü al; veri yoksa boş kutucuklar göster.
    final recent = days.length > 14 ? days.sublist(days.length - 14) : days;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isTr ? 'Seri takvimi' : 'Streak calendar',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (freezes > 0)
                Row(
                  children: [
                    const Icon(Icons.ac_unit_rounded,
                        color: practiceBlue, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$freezes',
                      style: const TextStyle(
                        color: practiceBlue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            Text(
              isTr
                  ? 'Pratik yaptıkça günlerin burada işaretlenir.'
                  : 'Your practiced days will appear here.',
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final day in recent) _DayDot(day: day),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.day});

  final Map<String, dynamic> day;

  @override
  Widget build(BuildContext context) {
    final practiced = day['practiced'] == true || _xp(day) > 0;
    final date = '${day['date'] ?? ''}';
    final label = date.length >= 2 ? date.substring(date.length - 2) : '?';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color:
                practiced ? const Color(0xFFFF9F1C) : const Color(0xFFEDEFF2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            practiced
                ? Icons.local_fire_department_rounded
                : Icons.circle_outlined,
            color: practiced ? Colors.white : const Color(0xFFB7C0CC),
            size: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  int _xp(Map<String, dynamic> day) {
    final v = day['xp'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.brand),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _MilestoneOverlay extends StatelessWidget {
  const _MilestoneOverlay({required this.streak, required this.onDismiss});

  final int streak;
  final VoidCallback onDismiss;

  static const _milestones = [7, 14, 30, 50, 100, 365];

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final isRecord = _milestones.where((m) => m > streak).isEmpty;
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: .78),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(28),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔥 Yeni animasyonlu streak kutlaması
                SizedBox(
                  height: 260,
                  child: PracticeStreakCelebration(
                    streak: streak,
                    isNewRecord: isRecord,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isTr
                      ? 'Milestone ödülünu kazandın!'
                      : 'You hit a milestone reward!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: practiceMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),
                Practice3DButton(
                  label: isTr ? 'HARIKA! 🎉' : 'AWESOME! 🎉',
                  onPressed: onDismiss,
                ),
              ],
            ),
          ).animate().scale(
                begin: const Offset(.82, .82),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),
        ),
      ),
    );
  }
}
