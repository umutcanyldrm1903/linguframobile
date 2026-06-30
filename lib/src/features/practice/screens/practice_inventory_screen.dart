import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import '../practice_repository.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

class PracticeInventoryScreen extends StatefulWidget {
  const PracticeInventoryScreen({super.key});

  @override
  State<PracticeInventoryScreen> createState() =>
      _PracticeInventoryScreenState();
}

class _PracticeInventoryScreenState extends State<PracticeInventoryScreen> {
  static const PracticeRepository _repository = PracticeRepository();
  final PracticeApiService _api = const PracticeApiService();
  List<Map<String, dynamic>> _items = [];
  int _coins = 0;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _coins = _repository.loadStats().coins;
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getInventory();
    if (!mounted) return;
    setState(() {
      _items = _asList(data?['items']);
      _coins = _repository.parseStats(data?['stats']).coins;
      _loading = false;
    });
  }

  Future<void> _use(Map<String, dynamic> item) async {
    if (_busy) return;
    final id = _asInt(item['id']);
    if (id <= 0) return;
    setState(() => _busy = true);
    final data = await _api.useInventoryItem(id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = false);
    if (data != null) {
      await PracticeSoundService.playComplete();
      messenger.showSnackBar(
        SnackBar(content: Text('${data['message'] ?? 'Esya kullanildi.'}')),
      );
      await _load();
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Esya kullanilamadi.')),
      );
    }
  }

  (Color, IconData) _visual(String type) {
    switch (type) {
      case 'xp_boost':
        return (practiceBlue, Icons.bolt_rounded);
      case 'streak_freeze':
        return (practiceOrange, Icons.ac_unit_rounded);
      case 'heart_refill':
        return (practiceGreen, Icons.favorite_rounded);
      case 'legendary':
      case 'legendary_pass':
        return (practicePurple, Icons.auto_awesome_rounded);
      default:
        return (practiceBlue, Icons.card_giftcard_rounded);
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
          'Envanter',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(child: MascotLoading(message: 'Envanter yükleniyor...'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                children: [
                  _InventoryHeader(coins: _coins),
                  const SizedBox(height: 18),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'Cantanda henüz esya yok. Mağazadan boost ve can alabilirsin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: practiceMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final item in _items)
                      Builder(builder: (context) {
                        final visual = _visual('${item['type'] ?? ''}');
                        final count = _asInt(item['quantity'], fallback: 1);
                        return _InventoryItemCard(
                          color: visual.$1,
                          icon: visual.$2,
                          title: '${item['title'] ?? 'Esya'}',
                          subtitle: '${item['description'] ?? ''}',
                          count: count,
                          action: _busy ? '...' : 'KULLAN',
                          onTap: _busy ? () {} : () => _use(item),
                        );
                      }),
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

  int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBDEAFF), width: 2),
      ),
      child: Row(
        children: [
          const PracticeTreasure(size: 84),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esya cantan',
                  style: TextStyle(
                    color: practiceInk,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$coins coin ile boost ve can alabilirsin.',
                  style: const TextStyle(
                    color: practiceMuted,
                    fontWeight: FontWeight.w700,
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

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.action,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: practiceInk,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'x$count',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: practiceMuted,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      action,
                      style: const TextStyle(fontWeight: FontWeight.w900),
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
