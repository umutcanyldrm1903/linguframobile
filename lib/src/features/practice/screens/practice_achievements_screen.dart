import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_game_widgets.dart';
import 'practice_visuals.dart';

class PracticeAchievementsScreen extends StatefulWidget {
  const PracticeAchievementsScreen({super.key});

  @override
  State<PracticeAchievementsScreen> createState() =>
      _PracticeAchievementsScreenState();
}

class _PracticeAchievementsScreenState
    extends State<PracticeAchievementsScreen> {
  final PracticeApiService _api = const PracticeApiService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  static const _palette = [
    (Color(0xFFFF4B4B), Icons.local_fire_department_rounded),
    (practiceGreen, Icons.school_rounded),
    (Color(0xFFC86DFF), Icons.timer_rounded),
    (practiceBlue, Icons.bolt_rounded),
    (practiceOrange, Icons.emoji_events_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getAchievements();
    if (!mounted) return;
    setState(() {
      _items = _asList(data?['achievements']);
      if (_items.isEmpty) _items = _fallback();
      _loading = false;
    });
  }

  Future<void> _claim(Map<String, dynamic> item) async {
    final id = _asInt(item['id']);
    if (id <= 0) return;
    final result = await _api.claimAchievement(id);
    if (result != null) {
      await PracticeSoundService.playComplete();
      if (mounted) {
        await showRewardPopup(
          context,
          title: '${item['title'] ?? 'Başarı'} kazanildi!',
          xp: _asInt(item['reward_xp']),
          coins: _asInt(item['reward_coins']),
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
        foregroundColor: const Color(0xFF9AA0A6),
        centerTitle: true,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Color(0xFFB0B0B0),
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/practice/settings'),
            icon: const Icon(Icons.settings_rounded,
                color: practiceBlue, size: 31),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: MascotLoading(message: 'Başarılar yükleniyor...'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                children: [
                  const Text(
                    'Başarılar',
                    style: TextStyle(
                      color: Color(0xFF4B4B4B),
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < _items.length; i++)
                    _AchievementRow(
                      color: _palette[i % _palette.length].$1,
                      icon: _palette[i % _palette.length].$2,
                      item: _items[i],
                      onClaim: () => _claim(_items[i]),
                    ),
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

  // Sahte ilerleme gösterme — başarımlar API'den gelir, yoksa boş (dürüst).
  List<Map<String, dynamic>> _fallback() => const [];
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.color,
    required this.icon,
    required this.item,
    required this.onClaim,
  });

  final Color color;
  final IconData icon;
  final Map<String, dynamic> item;
  final VoidCallback onClaim;

  int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final progressCount = _asInt(item['progress']);
    final target = _asInt(item['target'], fallback: 1);
    final progress = (progressCount / target).clamp(0.0, 1.0);
    final completed = progressCount >= target;
    final claimed = item['claimed'] == true;
    final title = '${item['title'] ?? 'Başarı'}';
    final subtitle = '${item['description'] ?? ''}';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E2E2), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 92,
            height: 110,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(191),
                  offset: const Offset(0, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xEBFFFFFF), size: 48),
                const SizedBox(height: 10),
                Text(
                  claimed ? 'TAMAM' : '1. DUZEY',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF4B4B4B),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 18,
                          backgroundColor: const Color(0xFFE5E5E5),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFFC800)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$progressCount / $target',
                      style: const TextStyle(
                        color: Color(0xFF9B9B9B),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                if (completed && !claimed)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onClaim,
                      child: const Text('ÖDÜL AL'),
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
