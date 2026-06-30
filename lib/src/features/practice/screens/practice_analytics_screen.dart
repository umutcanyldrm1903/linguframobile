import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import 'practice_visuals.dart';

class PracticeAnalyticsScreen extends StatefulWidget {
  const PracticeAnalyticsScreen({super.key});

  @override
  State<PracticeAnalyticsScreen> createState() =>
      _PracticeAnalyticsScreenState();
}

class _PracticeAnalyticsScreenState extends State<PracticeAnalyticsScreen> {
  final PracticeApiService _api = const PracticeApiService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  // Aktivite (gün-aralığı) bölümü
  int _rangeDays = 30;
  List<Map<String, dynamic>> _activityDays = [];
  Map<String, dynamic> _activitySummary = {};

  static const _ranges = [7, 30, 90];

  @override
  void initState() {
    super.initState();
    _load();
    _loadActivity();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.getAnalyticsDashboard();
    if (!mounted) return;
    setState(() {
      _data = data ?? _fallback();
      _loading = false;
    });
  }

  Future<void> _loadActivity() async {
    final data = await _api.getActivity(days: _rangeDays);
    if (!mounted) return;
    setState(() {
      _activityDays = _asList(data?['days']);
      _activitySummary =
          data?['summary'] is Map ? _asMap(data!['summary']) : {};
    });
  }

  void _setRange(int days) {
    if (_rangeDays == days) return;
    setState(() => _rangeDays = days);
    _loadActivity();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _asMap(_data?['stats']);
    final answerTypes = _asList(_data?['answers_by_type']);
    final xpByDay = _asList(_data?['xp_by_day']);
    final focusAreas = _asList(_data?['focus_areas']);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: practiceInk,
        centerTitle: true,
        title: const Text(
          'Analitik',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(
              child: MascotLoading(message: 'Analitik yükleniyor...'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  Row(
                    children: [
                      PracticeMascot(
                        size: 104,
                        mood: PracticeMascotMood.thinking,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: PracticeSpeechBubble(
                          text:
                              'Performansina göre hangi pratiği öne alacağımızı burada görürsün.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _StatTile(
                        icon: Icons.bolt_rounded,
                        value: '${stats['total_xp'] ?? 0}',
                        label: 'Toplam XP',
                        color: practiceYellow,
                      ),
                      const SizedBox(width: 10),
                      _StatTile(
                        icon: Icons.local_fire_department_rounded,
                        value: '${stats['streak'] ?? 0}',
                        label: 'Seri',
                        color: practiceOrange,
                      ),
                      const SizedBox(width: 10),
                      _StatTile(
                        icon: Icons.favorite_rounded,
                        value: '${stats['hearts'] ?? 5}',
                        label: 'Can',
                        color: const Color(0xFFFF4B70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Panel(
                    title: 'Soru tipi başarısi',
                    children: [
                      for (final item in answerTypes)
                        _ProgressLine(
                          title: '${item['question_type'] ?? item['type']}',
                          label:
                              '${item['correct'] ?? 0}/${item['attempts'] ?? item['total'] ?? 0}',
                          value: _ratio(item),
                          color: practiceBlue,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    title: 'Haftalık XP',
                    children: [
                      for (final item in xpByDay.take(7))
                        _ProgressLine(
                          title: '${item['date'] ?? item['day']}',
                          label: '${item['xp'] ?? item['total_xp'] ?? 0} XP',
                          value: (_asInt(item['xp'] ?? item['total_xp']) / 100)
                              .clamp(0, 1),
                          color: practiceGreen,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    title: 'Aktivite',
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final r in _ranges)
                            ChoiceChip(
                              label: Text('$r gün'),
                              selected: _rangeDays == r,
                              onSelected: (_) => _setRange(r),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_activitySummary.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Aktif gün: ${_activitySummary['active_days'] ?? 0}'
                            ' · Toplam XP: ${_activitySummary['total_xp'] ?? 0}'
                            ' · Ort: ${_activitySummary['average_xp'] ?? 0}',
                            style: const TextStyle(
                              color: practiceInk,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      for (final item
                          in _activityDays.take(_rangeDays > 30 ? 14 : 7))
                        _ProgressLine(
                          title: '${item['date'] ?? item['day'] ?? ''}',
                          label: '${item['xp'] ?? 0} XP',
                          value: (_asInt(item['xp']) / 100).clamp(0, 1),
                          color: practiceOrange,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    title: 'Adaptif odak',
                    children: [
                      for (final item in focusAreas)
                        _FocusRow(
                          title:
                              '${item['title'] ?? item['label'] ?? item['type'] ?? 'Odak'}',
                          subtitle:
                              '${item['reason'] ?? item['subtitle'] ?? 'Tekrar önerisi'}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 2),
    );
  }

  double _ratio(Map<String, dynamic> item) {
    final correct = _asInt(item['correct'] ?? item['correct_count']);
    final attempts = _asInt(
      item['attempts'] ?? item['total'] ?? item['total_count'],
      fallback: 1,
    );
    return (correct / attempts).clamp(0, 1);
  }

  int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  Map<String, dynamic> _asMap(Object? value) {
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // Sahte performans verisi gösterme — veri yoksa dürüst sıfır/boş.
  Map<String, dynamic> _fallback() {
    return {
      'stats': {'total_xp': 0, 'streak': 0, 'hearts': 5},
      'answers_by_type': <Map<String, dynamic>>[],
      'xp_by_day': <Map<String, dynamic>>[],
      'focus_areas': <Map<String, dynamic>>[],
    };
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: practiceLine, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: practiceInk,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: practiceMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (children.isEmpty)
            const Text(
              'Veri geldikce burada gosterilecek.',
              style: TextStyle(
                color: practiceMuted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.title,
    required this.label,
    required this.value,
    required this.color,
  });

  final String title;
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: practiceInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: practiceMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 14,
              value: value,
              backgroundColor: const Color(0xFFE5E5E5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusRow extends StatelessWidget {
  const _FocusRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.track_changes_rounded, color: practiceOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: practiceInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
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
