import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_game_widgets.dart';
import 'practice_visuals.dart';

class PracticeDailyQuestsScreen extends StatefulWidget {
  const PracticeDailyQuestsScreen({super.key});

  @override
  State<PracticeDailyQuestsScreen> createState() =>
      _PracticeDailyQuestsScreenState();
}

class _PracticeDailyQuestsScreenState extends State<PracticeDailyQuestsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: practiceKraft,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _QuestTabs(
              selected: _tab,
              onChanged: (value) => setState(() => _tab = value),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _tab == 0
                    ? const _DailyQuestPanel(key: ValueKey('quests'))
                    : const _BadgesPanel(key: ValueKey('badges')),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 3),
    );
  }
}

class _QuestTabs extends StatelessWidget {
  const _QuestTabs({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: practiceKraft,
        border: Border(bottom: BorderSide(color: practiceLine, width: 1.5)),
      ),
      child: Row(
        children: [
          _QuestTabButton(
            label: AppStrings.code == 'tr' ? 'GÖREVLER' : 'QUESTS',
            selected: selected == 0,
            onTap: () => onChanged(0),
          ),
          _QuestTabButton(
            label: AppStrings.code == 'tr' ? 'ROZETLER' : 'BADGES',
            selected: selected == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _QuestTabButton extends StatelessWidget {
  const _QuestTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? practiceInk : practiceMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: 54,
              decoration: BoxDecoration(
                color: selected ? practiceOrange : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _DailyQuestPanel extends StatefulWidget {
  const _DailyQuestPanel({super.key});

  @override
  State<_DailyQuestPanel> createState() => _DailyQuestPanelState();
}

class _DailyQuestPanelState extends State<_DailyQuestPanel> {
  final PracticeApiService _api = const PracticeApiService();
  List<Map<String, dynamic>> _quests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getDailyQuests();
    final raw = data?['quests'] ?? data?['daily_quests'];
    if (!mounted) return;
    setState(() {
      _quests = _asList(raw);
      if (_quests.isEmpty) _quests = _fallback();
      _loading = false;
    });
  }

  Future<void> _claim(Map<String, dynamic> quest) async {
    final id = _asInt(quest['id']);
    if (id <= 0) return;
    final result = await _api.claimDailyQuest(id);
    if (result != null) {
      await PracticeSoundService.playComplete();
      if (mounted) {
        await showRewardPopup(
          context,
          title: AppStrings.code == 'tr' ? 'Görev tamamlandı!' : 'Quest complete!',
          xp: _asInt(quest['reward_xp']),
          coins: _asInt(quest['reward_coins']),
        );
      }
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
          child: MascotLoading(
              message: AppStrings.code == 'tr'
                  ? 'Görevler yükleniyor...'
                  : 'Loading quests...'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _QuestHero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
            child: Text(
              AppStrings.code == 'tr' ? 'Günlük Görev' : 'Daily quest',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: practiceInk,
              ),
            ),
          ),
          for (final quest in _quests)
            _QuestCard(quest: quest, onClaim: () => _claim(quest)),
          const SizedBox(height: 24),
        ],
      ),
    );
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

  List<Map<String, dynamic>> _fallback() => [
        {
          'id': 0,
          'title': '10 Puan kazan',
          'description': 'Günlük hedefini tamamla.',
          'progress': 10,
          'target': 10,
          'reward_xp': 10,
          'claimed': false,
        },
        {
          'id': 0,
          'title': '1 ders tamamla',
          'description': 'Kısa bir pratik bitir.',
          'progress': 0,
          'target': 1,
          'reward_coins': 5,
          'claimed': false,
        },
      ];
}

class _QuestHero extends StatelessWidget {
  const _QuestHero();

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 18, 22, 0),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Defter cilt payı (sol mürekkep şeridi)
              Container(width: 5, color: practiceOrange),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 6, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.checklist_rounded,
                              color: practiceOrange, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            isTr ? 'Günün görevleri' : 'Today’s quests',
                            style: const TextStyle(
                              color: practiceInk,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isTr
                            ? 'Görevleri tamamla, defterine XP ve ödül işle. Her gün yenilenir.'
                            : 'Finish the quests to note XP and rewards. Refreshes daily.',
                        style: const TextStyle(
                          color: practiceMuted,
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: PracticeMascot(size: 78, mood: PracticeMascotMood.proud),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest, required this.onClaim});

  final Map<String, dynamic> quest;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final progress = _asInt(quest['progress']);
    final target = _asInt(quest['target'], fallback: 1);
    final completed = progress >= target;
    final claimed = quest['claimed'] == true;
    final rewardXp = _asInt(quest['reward_xp']);
    final rewardCoins = _asInt(quest['reward_coins']);
    final isTr = AppStrings.code == 'tr';
    final ratio = (progress / target).clamp(0.0, 1.0);
    final rewardText = rewardXp > 0 ? '+$rewardXp XP' : '+$rewardCoins ◆';
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 12, 22, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // El-çizimi onay kutusu: bitince mürekkep tik damgası.
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: completed ? practiceBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: completed ? practiceBlue : practiceMuted,
                    width: 2,
                  ),
                ),
                child: completed
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 19)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${quest['title'] ?? (isTr ? 'Günlük görev' : 'Daily quest')}',
                      style: const TextStyle(
                        color: practiceInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    if ('${quest['description'] ?? ''}'.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${quest['description']}',
                        style: const TextStyle(
                          color: practiceMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // XP "notu" — sıcak turuncu kenar yazısı
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: practiceOrange.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: practiceOrange.withValues(alpha: .5), width: 1),
                ),
                child: Text(
                  rewardText,
                  style: const TextStyle(
                    color: practiceOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: PracticeProgressBar(value: ratio, height: 8)),
              const SizedBox(width: 10),
              Text(
                '$progress/$target',
                style: const TextStyle(
                  color: practiceMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: claimed
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: practiceBlue, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        isTr ? 'İşlendi' : 'Claimed',
                        style: const TextStyle(
                          color: practiceMuted,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                : (completed
                    ? InkWell(
                        onTap: onClaim,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: practiceOrange,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: practiceDarken(practiceOrange, .12),
                                width: 2),
                          ),
                          child: Text(
                            isTr ? 'ÖDÜLÜ İŞLE' : 'CLAIM',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: .3,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        isTr ? 'Devam ediyor' : 'In progress',
                        style: const TextStyle(
                          color: practiceMuted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      )),
          ),
        ],
      ),
    );
  }

  int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}

class _BadgesPanel extends StatefulWidget {
  const _BadgesPanel({super.key});

  @override
  State<_BadgesPanel> createState() => _BadgesPanelState();
}

class _BadgesPanelState extends State<_BadgesPanel> {
  final PracticeApiService _api = const PracticeApiService();
  List<Map<String, dynamic>> _badges = [];
  int _monthlyXp = 0;
  int _monthlyGoal = 1000;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Önce özel /badges endpoint'i; yoksa achievements + activity fallback.
    final data = await _api.getBadges();
    var badges = _asList(data?['badges']);
    var monthly = 0;
    var goal = 1000;
    final mc = data?['monthly_challenge'];
    if (mc is Map) {
      monthly = _asInt(mc['xp']);
      final g = _asInt(mc['goal']);
      if (g > 0) goal = g;
    }
    if (badges.isEmpty) {
      final ach = await _api.getAchievements();
      badges = _asList(ach?['achievements']);
      // Gerçek monthly_challenge yoksa aylık XP'yi aktiviteden türet.
      if (mc is! Map) {
        final activity = await _api.getActivity(days: 30);
        final summary = activity?['summary'];
        if (summary is Map) monthly = _asInt(summary['total_xp']);
      }
    }
    if (!mounted) return;
    setState(() {
      _badges = badges.isEmpty ? _fallback() : badges;
      _monthlyXp = monthly;
      _monthlyGoal = goal;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
          child: MascotLoading(
              message: AppStrings.code == 'tr'
                  ? 'Rozetler yükleniyor...'
                  : 'Loading badges...'));
    }
    final monthRatio = (_monthlyXp / _monthlyGoal).clamp(0.0, 1.0);
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 40),
      children: [
        // Aylık mücadele — kâğıt "hedef notu" kartı
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: practicePaper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: practiceLine, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag_rounded,
                      color: practiceOrange, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.code == 'tr'
                        ? 'Aylık mücadele'
                        : 'Monthly challenge',
                    style: const TextStyle(
                      color: practiceInk,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.code == 'tr'
                    ? 'Bu ay $_monthlyGoal XP topla, özel rozeti defterine ekle.'
                    : 'Collect $_monthlyGoal XP this month to earn a special badge.',
                style: const TextStyle(
                  color: practiceMuted,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              PracticeProgressBar(value: monthRatio, height: 12),
              const SizedBox(height: 8),
              Text(
                '$_monthlyXp / $_monthlyGoal XP',
                style: const TextStyle(
                  color: practiceInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.code == 'tr' ? 'Rozetler' : 'Badges',
          style: const TextStyle(
            color: practiceInk,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: .82,
          children: [
            for (var i = 0; i < _badges.length; i++)
              _BadgeTile(badge: _badges[i], index: i),
          ],
        ),
      ],
    );
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

  List<Map<String, dynamic>> _fallback() => [
        {'title': 'Istikrarli', 'progress': 1, 'target': 3, 'claimed': false},
        {'title': 'Bilge', 'progress': 11, 'target': 100, 'claimed': false},
        {'title': 'Maratoncu', 'progress': 0, 'target': 30, 'claimed': false},
        {'title': 'Kasif', 'progress': 0, 'target': 10, 'claimed': false},
        {'title': 'Konuşkan', 'progress': 0, 'target': 20, 'claimed': false},
        {'title': 'Efsane', 'progress': 0, 'target': 50, 'claimed': false},
      ];
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.index});

  final Map<String, dynamic> badge;
  final int index;

  static const _palette = [
    (practiceBlue, Icons.bolt_rounded),
    (practiceGreen, Icons.school_rounded),
    (practiceOrange, Icons.local_fire_department_rounded),
    (practiceRed, Icons.mic_rounded),
    (practiceBlueDark, Icons.explore_rounded),
    (practiceYellow, Icons.emoji_events_rounded),
  ];

  int _asInt(Object? v, {int fb = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fb;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _asInt(badge['progress']);
    final target = _asInt(badge['target'], fb: 1);
    final earned = badge['claimed'] == true || progress >= target;
    final visual = _palette[index % _palette.length];
    final accent = visual.$1;
    // Kazanılan: renkli "mürekkep mührü" (kâğıt + renkli kenar + ikon).
    // Kilitli: boş kraft mühür yuvası + soluk kilit.
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: earned
                ? accent.withValues(alpha: .14)
                : practicePaper,
            shape: BoxShape.circle,
            border: Border.all(
              color: earned ? accent : practiceLine,
              width: earned ? 2.5 : 2,
            ),
          ),
          child: Icon(
            earned ? visual.$2 : Icons.lock_outline_rounded,
            color: earned ? accent : practiceMuted,
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${badge['title'] ?? (AppStrings.code == 'tr' ? 'Rozet' : 'Badge')}',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: earned ? practiceInk : practiceMuted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

