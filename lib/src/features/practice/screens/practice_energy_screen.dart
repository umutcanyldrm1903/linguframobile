import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import 'practice_visuals.dart';

class PracticeEnergyScreen extends StatefulWidget {
  const PracticeEnergyScreen({super.key});

  @override
  State<PracticeEnergyScreen> createState() => _PracticeEnergyScreenState();
}

class _PracticeEnergyScreenState extends State<PracticeEnergyScreen> {
  final PracticeApiService _api = const PracticeApiService();
  Map<String, dynamic> _energy = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getEnergy();
    if (!mounted) return;
    setState(() {
      // API gerçek enerji vermezse SAHTE 72/100 uydurma (eski sürüm öyleydi);
      // boş bırak → gerçek/empty durum gösterilir.
      _energy = data?['energy'] is Map<String, dynamic>
          ? data!['energy'] as Map<String, dynamic>
          : <String, dynamic>{};
      _loading = false;
    });
  }

  Future<void> _refill() async {
    await _api.refillEnergy();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final current = _asInt(_energy['current'] ?? _energy['current_energy']);
    final max = _asInt(_energy['max'] ?? _energy['max_energy'], fallback: 100);
    final progress = (current / max).clamp(0, 1).toDouble();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: practiceInk,
        centerTitle: true,
        title:
            const Text('Enerji', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: MascotLoading(message: 'Enerji yükleniyor...'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
              children: [
                PracticeMascot(
                  size: 126,
                  mood: progress > .2
                      ? PracticeMascotMood.proud
                      : PracticeMascotMood.sad,
                ),
                const SizedBox(height: 18),
                Text(
                  '$current / $max',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 22,
                    value: progress,
                    backgroundColor: const Color(0xFFE5E5E5),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(practicePurple),
                  ),
                ),
                const SizedBox(height: 18),
                PracticePrimaryButton(
                  label: 'ENERJI DOLDUR',
                  color: practicePurple,
                  onPressed: () => _refill(),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/practice/premium'),
                  child: const Text('PREMIUM SINIRSIZ ENERJI'),
                ),
              ],
            ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 0),
    );
  }

  int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}
