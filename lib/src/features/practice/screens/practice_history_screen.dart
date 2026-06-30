import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import 'practice_visuals.dart';

class PracticeHistoryScreen extends StatefulWidget {
  const PracticeHistoryScreen({super.key});

  @override
  State<PracticeHistoryScreen> createState() => _PracticeHistoryScreenState();
}

class _PracticeHistoryScreenState extends State<PracticeHistoryScreen> {
  final PracticeApiService _api = const PracticeApiService();
  List<Map<String, dynamic>> _xp = [];
  List<Map<String, dynamic>> _coins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final xp = await _api.getXpLogs();
    final coins = await _api.getCoinLogs();
    if (!mounted) return;
    setState(() {
      _xp = _asList(xp?['logs'] ?? xp?['xp_logs']);
      _coins = _asList(coins?['logs'] ?? coins?['coin_logs']);
      if (_xp.isEmpty) {
        _xp = [
          {'source': 'lesson', 'xp': 20, 'created_at': 'Bugün'},
          {'source': 'daily_quest', 'xp': 10, 'created_at': 'Dun'},
        ];
      }
      _loading = false;
    });
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
          'Geçmiş',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(child: MascotLoading(message: 'Geçmiş yükleniyor...'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  _Panel(
                    title: 'XP Geçmişi',
                    icon: Icons.bolt_rounded,
                    color: practiceYellow,
                    items: _xp,
                    valueKey: 'xp',
                  ),
                  const SizedBox(height: 16),
                  _Panel(
                    title: 'Coin Geçmişi',
                    icon: Icons.diamond_rounded,
                    color: practiceBlue,
                    items: _coins,
                    valueKey: 'coins',
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
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.valueKey,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> items;
  final String valueKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: practiceInk,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'Kayıt yok.',
              style: TextStyle(
                color: practiceMuted,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${item['source'] ?? item['type'] ?? 'practice'}',
                        style: const TextStyle(
                          color: practiceInk,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '+${item[valueKey] ?? item['amount'] ?? 0}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
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
