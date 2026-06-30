import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_game_widgets.dart';
import 'practice_visuals.dart';

class PracticeWeeklyQuestsScreen extends StatefulWidget {
  const PracticeWeeklyQuestsScreen({super.key});

  @override
  State<PracticeWeeklyQuestsScreen> createState() =>
      _PracticeWeeklyQuestsScreenState();
}

class _PracticeWeeklyQuestsScreenState
    extends State<PracticeWeeklyQuestsScreen> {
  final PracticeApiService _api = const PracticeApiService();
  List<Map<String, dynamic>> _quests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.getWeeklyQuests();
    final raw = data?['quests'] ?? data?['weekly_quests'];
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
    final result = await _api.claimWeeklyQuest(id);
    if (result != null) {
      await PracticeSoundService.playComplete();
      if (mounted) {
        await showRewardPopup(
          context,
          title: 'Haftalık görev tamam!',
          xp: _asInt(quest['reward_xp']),
          coins: _asInt(quest['reward_coins']),
        );
      }
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: practiceInk,
        centerTitle: true,
        title: const Text(
          'Haftalık Görevler',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(
              child: MascotLoading(message: 'Görevler yükleniyor...'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: practicePurple,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Text(
                            'Haftalık sandığı açmak için uzun hedefleri bitir.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        PracticeMascot(
                          size: 88,
                          mood: PracticeMascotMood.proud,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final quest in _quests)
                    _QuestCard(quest: quest, onClaim: () => _claim(quest)),
                ],
              ),
            ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 3),
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
          'title': 'Bu hafta 300 XP kazan',
          'description': 'Haftalık XP hedefini tamamla.',
          'progress': 120,
          'target': 300,
          'reward_xp': 50,
          'claimed': false,
        },
        {
          'id': 0,
          'title': '10 ders tamamla',
          'description': 'Kısa pratikleri bitir.',
          'progress': 3,
          'target': 10,
          'reward_coins': 25,
          'claimed': false,
        },
      ];
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  color: practicePurple, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${quest['title'] ?? 'Haftalık görev'}',
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '+${quest['reward_xp'] ?? 0} XP',
                style: const TextStyle(
                  color: practiceOrange,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${quest['description'] ?? ''}',
            style: const TextStyle(
              color: practiceMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 18,
              value: (progress / target).clamp(0, 1),
              backgroundColor: const Color(0xFFE5E5E5),
              valueColor: const AlwaysStoppedAnimation<Color>(practicePurple),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$progress / $target',
                style: const TextStyle(
                  color: practiceMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: completed && !claimed ? onClaim : null,
                child: Text(claimed ? 'ALINDI' : 'ÖDÜL AL'),
              ),
            ],
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
