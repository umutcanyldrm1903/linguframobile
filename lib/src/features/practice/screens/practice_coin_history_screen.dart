import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import 'practice_visuals.dart';

class PracticeCoinHistoryScreen extends StatefulWidget {
  const PracticeCoinHistoryScreen({super.key});

  @override
  State<PracticeCoinHistoryScreen> createState() =>
      _PracticeCoinHistoryScreenState();
}

class _PracticeCoinHistoryScreenState
    extends State<PracticeCoinHistoryScreen> {
  final PracticeApiService _api = const PracticeApiService();
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.getCoinLogs();
    if (!mounted) return;
    final raw = data?['logs'] ?? data?['coin_logs'];
    setState(() {
      _logs = _asList(raw);
      if (_logs.isEmpty) _logs = _fallback();
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
        title: const Text('Coin Geçmişi',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(
              child: MascotLoading(message: 'Coin geçmişi yükleniyor...'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.diamond_rounded,
                            color: practiceBlue, size: 28),
                        const SizedBox(width: 8),
                        Builder(builder: (context) {
                          final earned = _logs
                              .where((e) =>
                                  ((e['amount'] as num?)?.toInt() ?? 0) > 0)
                              .fold<int>(
                                  0,
                                  (s, e) =>
                                      s +
                                      ((e['amount'] as num?)?.toInt() ?? 0));
                          return Text(
                            'Toplam Kazanilan: $earned coin',
                            style: const TextStyle(
                                color: practiceBlue,
                                fontWeight: FontWeight.w900,
                                fontSize: 16),
                          );
                        }),
                      ],
                    ),
                  ),
                  for (final log in _logs) _CoinLogRow(log: log),
                ],
              ),
            ),
    );
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // Sahte işlem gösterme — veri yoksa boş (dürüst).
  List<Map<String, dynamic>> _fallback() => const [];
}

class _CoinLogRow extends StatelessWidget {
  const _CoinLogRow({required this.log});
  final Map<String, dynamic> log;

  static final _sourceLabels = <String, String>{
    'lesson': 'Ders tamamlandı',
    'daily_quest': 'Günlük görev',
    'weekly_quest': 'Haftalık görev',
    'achievement': 'Rozet ödülü',
    'streak_repair': 'Seri tamiri',
    'shop': 'Mağaza alimi',
    'ad_reward': 'Reklam ödülü',
    'heart_refill': 'Can yenileme',
  };

  static final _sourceIcons = <String, IconData>{
    'lesson': Icons.school_rounded,
    'daily_quest': Icons.task_alt_rounded,
    'weekly_quest': Icons.calendar_month_rounded,
    'achievement': Icons.emoji_events_rounded,
    'streak_repair': Icons.build_rounded,
    'shop': Icons.shopping_bag_rounded,
    'ad_reward': Icons.play_circle_rounded,
    'heart_refill': Icons.favorite_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final source = '${log['source'] ?? ''}';
    final amount = (log['amount'] as num?)?.toInt() ?? 0;
    final isPositive = amount >= 0;
    final label = _sourceLabels[source] ?? source;
    final icon = _sourceIcons[source] ?? Icons.diamond_rounded;
    final dateStr = '${log['created_at'] ?? ''}';
    final date = DateTime.tryParse(dateStr)?.toLocal();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPositive
                  ? const Color(0xFFF0F9FF)
                  : const Color(0xFFFFEEEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: isPositive ? practiceBlue : practiceRed, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: practiceInk,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                if (date != null)
                  Text(
                    '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: practiceMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}$amount',
            style: TextStyle(
              color: isPositive ? practiceBlue : practiceRed,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}
