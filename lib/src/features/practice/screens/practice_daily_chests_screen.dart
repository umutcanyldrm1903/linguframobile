import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

/// Early Bird 🌅 / Night Owl 🦉 günlük zamanlı sandıklar.
/// Backend: `/practice/daily-chests`. Ödül: 15 dk XP Boost.
class PracticeDailyChestsScreen extends StatefulWidget {
  const PracticeDailyChestsScreen({super.key});

  @override
  State<PracticeDailyChestsScreen> createState() =>
      _PracticeDailyChestsScreenState();
}

class _PracticeDailyChestsScreenState extends State<PracticeDailyChestsScreen> {
  final PracticeApiService _api = const PracticeApiService();
  bool _loading = true;
  String? _busyType;
  List<Map<String, dynamic>> _chests = [];

  bool get _isTr => AppStrings.code == 'tr';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getDailyChests();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _chests = ((data?['chests'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    });
  }

  Future<void> _open(String type) async {
    setState(() => _busyType = type);
    final res = await _api.openDailyChest(type);
    if (!mounted) return;
    setState(() => _busyType = null);
    if (res?['success'] == true) {
      PracticeSoundService.onBadgeEarned();
      final label = res?['message']?.toString() ??
          (_isTr ? '15 dk XP Boost kazandın!' : 'You earned a 15-min XP Boost!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(label), backgroundColor: practiceGreen),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isTr
              ? 'Sandık henüz hazır değil.'
              : 'Chest is not ready yet.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isTr ? 'Günün Sandıkları' : 'Daily Chests'),
      ),
      body: _loading
          ? const PracticeMascotLoader()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _isTr
                      ? 'Belirli saatlerde pratik yaparak sandıkları aç ve XP Boost kazan!'
                      : 'Practice at certain times to open chests and earn XP Boosts!',
                  style: const TextStyle(color: practiceMuted, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ..._chests.map(_chestCard),
              ],
            ),
    );
  }

  Widget _chestCard(Map<String, dynamic> c) {
    final type = c['type']?.toString() ?? '';
    final isEarly = type == 'early_bird';
    final emoji = isEarly ? '🌅' : '🦉';
    final title = isEarly
        ? (_isTr ? 'Erken Kuş' : 'Early Bird')
        : (_isTr ? 'Gece Kuşu' : 'Night Owl');
    final available = c['available'] == true;
    final opened = c['opened'] == true;
    final color = isEarly ? practiceOrange : const Color(0xFF7C4DFF);

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
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: practiceInk)),
                const SizedBox(height: 2),
                Text('${c['window'] ?? ''} · ${c['reward_label'] ?? '15 dk XP Boost'}',
                    style: const TextStyle(color: practiceMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (opened)
            Text(_isTr ? 'Açıldı ✓' : 'Opened ✓',
                style: const TextStyle(
                    color: practiceGreen, fontWeight: FontWeight.w700))
          else if (available)
            SizedBox(
              width: 96,
              child: Practice3DButton(
                label: _busyType == type
                    ? '...'
                    : (_isTr ? 'AÇ' : 'OPEN'),
                color: color,
                height: 44,
                onPressed:
                    _busyType == null ? () => _open(type) : null,
              ),
            )
          else
            Flexible(
              child: Text(
                _isTr ? 'Bu saatte pratik yap' : 'Practice in this window',
                textAlign: TextAlign.end,
                style: const TextStyle(color: practiceMuted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
