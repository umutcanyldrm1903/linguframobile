import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

/// Double or Nothing: coin yatır, 7 gün streak koru, 2x geri al.
/// Backend: `/practice/streak-wager`.
class PracticeStreakWagerScreen extends StatefulWidget {
  const PracticeStreakWagerScreen({super.key});

  @override
  State<PracticeStreakWagerScreen> createState() =>
      _PracticeStreakWagerScreenState();
}

class _PracticeStreakWagerScreenState extends State<PracticeStreakWagerScreen> {
  final PracticeApiService _api = const PracticeApiService();
  bool _loading = true;
  bool _busy = false;
  Map<String, dynamic>? _data;

  bool get _isTr => AppStrings.code == 'tr';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getStreakWager();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _data = data;
    });
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    final res = await _api.startStreakWager();
    if (!mounted) return;
    setState(() => _busy = false);
    if (res?['stats'] != null) {
      PracticeSoundService.onTap();
      _load();
    } else {
      _toast(_isTr ? 'Yeterli coin yok ya da aktif bahis var.' : 'Not enough coins or active wager.');
    }
  }

  Future<void> _claim() async {
    setState(() => _busy = true);
    final res = await _api.claimStreakWager();
    if (!mounted) return;
    setState(() => _busy = false);
    if (res?['reward_coins'] != null) {
      PracticeSoundService.onBadgeEarned();
      _toast(_isTr
          ? '${res!['reward_coins']} coin kazandın! 🎉'
          : 'You won ${res!['reward_coins']} coins! 🎉');
      _load();
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final wager = _data?['wager'] as Map?;
    final cost = (_data?['cost'] as num?)?.toInt() ?? 50;
    final reward = (_data?['reward'] as num?)?.toInt() ?? 100;
    final target = (_data?['target_days'] as num?)?.toInt() ?? 7;
    final coins = (_data?['coins'] as num?)?.toInt() ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(_isTr ? 'İkiye Katla' : 'Double or Nothing')),
      body: _loading
          ? const PracticeMascotLoader()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Center(child: Text('🎰', style: TextStyle(fontSize: 64))),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _isTr ? 'İkiye Katla ya da Kaybet' : 'Double or Nothing',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: practiceInk),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _isTr
                        ? '$cost coin yatır, $target gün streak\'ini koru, $reward coin kazan!'
                        : 'Wager $cost coins, keep your streak $target days, win $reward coins!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: practiceMuted, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),
                if (wager == null)
                  _startCard(cost, coins)
                else
                  _activeCard(wager, target),
              ],
            ),
    );
  }

  Widget _startCard(int cost, int coins) {
    final canAfford = coins >= cost;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: practiceYellow.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💎', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                _isTr ? 'Coin\'lerin: $coins' : 'Your coins: $coins',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: practiceInk),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Practice3DButton(
          label: _busy
              ? '...'
              : (_isTr ? 'BAHSİ BAŞLAT ($cost 💎)' : 'START WAGER ($cost 💎)'),
          color: canAfford ? practiceGreen : practiceMuted,
          onPressed: (canAfford && !_busy) ? _start : null,
        ),
        if (!canAfford) ...[
          const SizedBox(height: 8),
          Text(_isTr ? 'Yeterli coin yok.' : 'Not enough coins.',
              style: const TextStyle(color: practiceMuted)),
        ],
      ],
    );
  }

  Widget _activeCard(Map wager, int target) {
    final status = wager['status']?.toString() ?? 'active';
    final daysDone = (wager['days_done'] as num?)?.toInt() ?? 0;
    final rewardCoins = (wager['reward_coins'] as num?)?.toInt() ?? 100;
    final won = status == 'won';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: won ? practiceGreen : practiceBlue, width: 2),
          ),
          child: Column(
            children: [
              Text(
                won
                    ? (_isTr ? 'Başardın! 🎉' : 'You did it! 🎉')
                    : (_isTr ? 'Bahis aktif 🔥' : 'Wager active 🔥'),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: won ? practiceGreen : practiceInk),
              ),
              const SizedBox(height: 14),
              PracticeProgressBar(value: target == 0 ? 0 : daysDone / target),
              const SizedBox(height: 8),
              Text('$daysDone / $target ${_isTr ? 'gün' : 'days'}',
                  style: const TextStyle(
                      color: practiceMuted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (won)
          Practice3DButton(
            label: _busy
                ? '...'
                : (_isTr
                    ? 'ÖDÜLÜ AL ($rewardCoins 💎)'
                    : 'CLAIM ($rewardCoins 💎)'),
            color: practiceGreen,
            onPressed: _busy ? null : _claim,
          )
        else
          Text(
            _isTr
                ? 'Her gün pratik yaparak streak\'ini koru!'
                : 'Keep your streak by practicing every day!',
            textAlign: TextAlign.center,
            style: const TextStyle(color: practiceMuted),
          ),
      ],
    );
  }
}
