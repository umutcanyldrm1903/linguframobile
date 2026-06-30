import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../practice_api_service.dart';
import '../practice_repository.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

/// XP Boost — backend'e bağlı. Boost mağazadaki `xp_boost` eşyasıyla alınır ve
/// sunucu XP çarpanını ayarlar (eski sürüm yalnızca yerel bir timer'dı,
/// gerçekte coin düşmüyor/çarpan değişmiyordu).
class PracticeXpBoostScreen extends StatefulWidget {
  const PracticeXpBoostScreen({super.key});

  @override
  State<PracticeXpBoostScreen> createState() => _PracticeXpBoostScreenState();
}

class _PracticeXpBoostScreenState extends State<PracticeXpBoostScreen> {
  final PracticeApiService _api = const PracticeApiService();
  final PracticeRepository _repo = const PracticeRepository();

  PracticeStats _stats = const PracticeRepository().loadStats();
  List<Map<String, dynamic>> _boostItems = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _repo.fetchStats();
    final shop = await _api.getShop();
    if (!mounted) return;
    final raw = shop?['items'] ?? shop?['shop_items'];
    final boosts = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final it in raw.whereType<Map>()) {
        final tag = '${it['type'] ?? it['key'] ?? ''}'.toLowerCase();
        if (tag.contains('boost')) boosts.add(Map<String, dynamic>.from(it));
      }
    }
    setState(() {
      _stats = stats;
      _boostItems = boosts;
      _loading = false;
    });
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _buy(Map<String, dynamic> item) async {
    if (_busy) return;
    final id = (item['id'] as num?)?.toInt() ?? 0;
    if (id <= 0) return;
    final isTr = AppStrings.code == 'tr';
    setState(() => _busy = true);
    final res = await _api.buyShopItem(id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res != null) {
      await PracticeSoundService.onBadgeEarned();
      await _load();
      if (!mounted) return;
      _toast(isTr ? 'XP Boost aktif edildi!' : 'XP Boost activated!');
    } else {
      _toast(isTr
          ? 'Satın alınamadı — yeterli coin olmayabilir.'
          : 'Purchase failed — you may not have enough coins.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final active = _stats.xpMultiplier > 1;
    return Scaffold(
      backgroundColor: practiceKraft,
      appBar: AppBar(
        backgroundColor: practiceKraft,
        elevation: 0,
        foregroundColor: practiceInk,
        centerTitle: true,
        title: const Text('XP Boost',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
        children: [
          // Gerçek durum (sunucu çarpanı)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: practicePaper,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: practiceLine, width: 1.5),
            ),
            child: Column(
              children: [
                PracticeMascot(
                  size: 110,
                  mood: active
                      ? PracticeMascotMood.excited
                      : PracticeMascotMood.thinking,
                ),
                const SizedBox(height: 12),
                Text(
                  active
                      ? (isTr ? '${_stats.xpMultiplier}x XP aktif!' : '${_stats.xpMultiplier}x XP active!')
                      : (isTr ? 'Boost pasif' : 'Boost inactive'),
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isTr
                      ? 'XP Boost ile kazandığın XP katlanır. Coin ile satın al.'
                      : 'XP Boost multiplies the XP you earn. Buy it with coins.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: practiceMuted,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: PracticeMascotLoader(),
            ))
          else if (_boostItems.isEmpty)
            _InfoCard(
              text: isTr
                  ? 'Şu an mağazada XP Boost eşyası yok. Mağazadan kontrol edebilirsin.'
                  : 'No XP Boost item in the shop right now. Check the shop.',
              actionLabel: isTr ? 'MAĞAZA' : 'SHOP',
              onTap: () => Navigator.pushNamed(context, '/practice/shop'),
            )
          else
            for (final item in _boostItems)
              _BoostBuyCard(
                item: item,
                busy: _busy,
                onBuy: () => _buy(item),
              ),
        ],
      ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 3),
    );
  }
}

class _BoostBuyCard extends StatelessWidget {
  const _BoostBuyCard({
    required this.item,
    required this.busy,
    required this.onBuy,
  });

  final Map<String, dynamic> item;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final name = '${item['name'] ?? (isTr ? 'XP Boost' : 'XP Boost')}';
    final cost = (item['coin_cost'] ?? item['price_coins'] as num?) ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: practiceOrange.withValues(alpha: .14),
              shape: BoxShape.circle,
              border: Border.all(color: practiceOrange, width: 2),
            ),
            child: const Icon(Icons.bolt_rounded,
                color: practiceOrange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: practiceInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text('$cost coin',
                    style: const TextStyle(
                        color: practiceMuted, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          GestureDetector(
            onTap: busy ? null : onBuy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: busy ? practiceMuted : practiceBlue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: practiceDarken(practiceBlue, .12), width: 2),
              ),
              child: Text(isTr ? 'AL' : 'BUY',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.text,
    required this.actionLabel,
    required this.onTap,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: practiceMuted,
                    fontWeight: FontWeight.w700,
                    height: 1.3)),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: practiceBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(actionLabel,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
