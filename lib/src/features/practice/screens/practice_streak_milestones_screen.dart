import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

/// Streak Society: 7/30/100/365... gün kilometre taşı ödülleri.
/// Backend: `/practice/streak-milestones`.
class PracticeStreakMilestonesScreen extends StatefulWidget {
  const PracticeStreakMilestonesScreen({super.key});

  @override
  State<PracticeStreakMilestonesScreen> createState() =>
      _PracticeStreakMilestonesScreenState();
}

class _PracticeStreakMilestonesScreenState
    extends State<PracticeStreakMilestonesScreen> {
  final PracticeApiService _api = const PracticeApiService();
  bool _loading = true;
  int? _busyDays;
  int _streak = 0;
  int _longest = 0;
  List<Map<String, dynamic>> _milestones = [];

  bool get _isTr => AppStrings.code == 'tr';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getStreakMilestones();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _streak = (data?['current_streak'] as num?)?.toInt() ?? 0;
      _longest = (data?['longest_streak'] as num?)?.toInt() ?? 0;
      _milestones = ((data?['milestones'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    });
  }

  Future<void> _claim(int days) async {
    setState(() => _busyDays = days);
    final res = await _api.claimStreakMilestone(days);
    if (!mounted) return;
    setState(() => _busyDays = null);
    if (res?['reward_coins'] != null) {
      PracticeSoundService.onBadgeEarned();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: practiceGreen,
          content: Text(_isTr
              ? '${res!['reward_coins']} 💎 + ${res['reward_xp']} XP kazandın!'
              : 'You earned ${res!['reward_coins']} 💎 + ${res['reward_xp']} XP!'),
        ),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isTr ? 'Seri Kulübü' : 'Streak Society')),
      body: _loading
          ? const PracticeMascotLoader()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(),
                const SizedBox(height: 16),
                ..._milestones.map(_tile),
              ],
            ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [practiceOrange, Color(0xFFFF9600)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 44)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_streak ${_isTr ? 'günlük seri' : 'day streak'}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
              Text(
                _isTr ? 'En uzun: $_longest gün' : 'Longest: $_longest days',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: .9), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(Map<String, dynamic> m) {
    final days = (m['days'] as num?)?.toInt() ?? 0;
    final coins = (m['reward_coins'] as num?)?.toInt() ?? 0;
    final xp = (m['reward_xp'] as num?)?.toInt() ?? 0;
    final reached = m['reached'] == true;
    final claimed = m['claimed'] == true;
    final claimable = m['claimable'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: claimable ? practiceGreen : practiceLine,
            width: claimable ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: reached
                  ? practiceOrange.withValues(alpha: .15)
                  : practiceLine.withValues(alpha: .4),
              shape: BoxShape.circle,
            ),
            child: Text(reached ? '🔥' : '🔒',
                style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$days ${_isTr ? 'gün' : 'days'}',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: practiceInk)),
                Text('$coins 💎 + $xp XP',
                    style: const TextStyle(
                        color: practiceMuted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (claimed)
            const Icon(Icons.check_circle_rounded, color: practiceGreen)
          else if (claimable)
            SizedBox(
              width: 84,
              child: Practice3DButton(
                label: _busyDays == days ? '...' : (_isTr ? 'AL' : 'CLAIM'),
                color: practiceGreen,
                height: 42,
                onPressed: _busyDays == null ? () => _claim(days) : null,
              ),
            )
          else
            Text(_isTr ? 'Kilitli' : 'Locked',
                style: const TextStyle(color: practiceMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
