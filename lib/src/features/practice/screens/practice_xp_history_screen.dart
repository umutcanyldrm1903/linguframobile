import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import 'practice_visuals.dart';

class PracticeXpHistoryScreen extends StatefulWidget {
  const PracticeXpHistoryScreen({super.key});

  @override
  State<PracticeXpHistoryScreen> createState() =>
      _PracticeXpHistoryScreenState();
}

class _PracticeXpHistoryScreenState extends State<PracticeXpHistoryScreen> {
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
    final data = await _api.getXpLogs();
    if (!mounted) return;
    final raw = data?['logs'] ?? data?['xp_logs'];
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
        title: const Text('XP Geçmişi',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(
              child: MascotLoading(message: 'XP geçmişi yükleniyor...'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4CF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded,
                            color: practiceOrange, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Toplam: ${_logs.fold<int>(0, (s, e) => s + ((e['xp'] as num?)?.toInt() ?? 0))} XP',
                          style: const TextStyle(
                              color: practiceOrange,
                              fontWeight: FontWeight.w900,
                              fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  for (final log in _logs) _XpLogRow(log: log),
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

  List<Map<String, dynamic>> _fallback() => [
        {'xp': 20, 'source': 'lesson', 'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String()},
        {'xp': 10, 'source': 'daily_quest', 'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String()},
        {'xp': 15, 'source': 'streak_bonus', 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
        {'xp': 30, 'source': 'placement', 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
      ];
}

class _XpLogRow extends StatelessWidget {
  const _XpLogRow({required this.log});
  final Map<String, dynamic> log;

  static final _sourceLabels = <String, String>{
    'lesson': 'Ders tamamlandı',
    'daily_quest': 'Günlük görev',
    'weekly_quest': 'Haftalık görev',
    'streak_bonus': 'Seri bonusu',
    'placement': 'Seviye testi',
    'achievement': 'Rozet ödülü',
    'shop': 'Mağaza',
    'ad_reward': 'Reklam ödülü',
    'xp_boost': 'XP Boost',
  };

  static final _sourceIcons = <String, IconData>{
    'lesson': Icons.school_rounded,
    'daily_quest': Icons.task_alt_rounded,
    'weekly_quest': Icons.calendar_month_rounded,
    'streak_bonus': Icons.local_fire_department_rounded,
    'placement': Icons.assessment_rounded,
    'achievement': Icons.emoji_events_rounded,
    'ad_reward': Icons.play_circle_rounded,
    'xp_boost': Icons.bolt_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final source = '${log['source'] ?? ''}';
    final xp = (log['xp'] as num?)?.toInt() ?? 0;
    final label = _sourceLabels[source] ?? source;
    final icon = _sourceIcons[source] ?? Icons.bolt_rounded;
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
              color: const Color(0xFFFFF4CF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: practiceOrange, size: 24),
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
            '+$xp XP',
            style: const TextStyle(
              color: practiceOrange,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}
