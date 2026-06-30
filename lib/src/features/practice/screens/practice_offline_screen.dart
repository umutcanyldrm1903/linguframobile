import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_offline_service.dart';
import '../practice_repository.dart';
import '../practice_widget_service.dart';
import 'practice_session_screen.dart';
import 'practice_visuals.dart';

class PracticeOfflineScreen extends StatefulWidget {
  const PracticeOfflineScreen({super.key});

  @override
  State<PracticeOfflineScreen> createState() => _PracticeOfflineScreenState();
}

class _PracticeOfflineScreenState extends State<PracticeOfflineScreen> {
  final PracticeOfflineService _offline = const PracticeOfflineService();
  static const PracticeRepository _repository = PracticeRepository();
  Map<String, dynamic>? _pack;
  DateTime? _cachedAt;
  int _pending = 0;
  bool _loading = true;
  bool _syncing = false;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait<Object?>([
      _offline.isOnline,
      _offline.cachedPack(),
      _offline.cachedAt(),
      _offline.pendingResults(),
    ]);
    if (!mounted) return;
    setState(() {
      _online = results[0] as bool;
      _pack = results[1] as Map<String, dynamic>?;
      _cachedAt = results[2] as DateTime?;
      _pending = (results[3] as List).length;
      _loading = false;
    });
  }

  Future<void> _download() async {
    setState(() => _loading = true);
    final pack = await _offline.refreshPack();
    final cachedAt = await _offline.cachedAt();
    final stats = pack?['stats'];
    if (stats is Map<String, dynamic>) {
      await PracticeWidgetService.updateFromMap(stats);
    }
    if (!mounted) return;
    setState(() {
      _pack = pack;
      _cachedAt = cachedAt;
      _loading = false;
    });
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    final count = await _offline.syncPendingResults();
    await _load();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count offline sonuç senkronlandı.')),
    );
  }

  Future<void> _startOfflineSession() async {
    final pack = _pack;
    if (pack == null) return;
    final adaptive = _asMap(pack['adaptive']);
    final questions = _repository.parseQuestions(adaptive['questions']);
    final token = '${pack['pack_token'] ?? ''}';
    if (questions.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offline paket geçersiz. Paketi yeniden indir.'),
        ),
      );
      return;
    }

    final answers = <int, Map<String, dynamic>>{};
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionScreen(
          title: 'Offline Pratik',
          questions: questions,
          enforceHearts: false,
          submitAnswers: false,
          onAnswerRecorded: (question, answer, correct) {
            answers[question.id] = {
              'question_id': question.id,
              'answer': answer,
            };
          },
          onComplete: (correct, total) async {
            await _offline.queueOfflineSession(
              packToken: token,
              answers: answers.values.toList(growable: false),
            );
            return 'Sonuç cihazda saklandı. İnternet gelince senkronlanacak.';
          },
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = _asMap(_pack?['adaptive']);
    final questions = _asList(adaptive['questions']);
    final focusAreas = _asList(adaptive['focus_areas']);
    final stats = _asMap(_pack?['stats']);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: practiceInk,
        centerTitle: true,
        title: const Text(
          'Offline Pratik',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(child: MascotLoading(message: 'Paket hazırlanıyor...'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
              children: [
                Row(
                  children: [
                    PracticeMascot(
                      size: 104,
                      mood: _online
                          ? PracticeMascotMood.proud
                          : PracticeMascotMood.thinking,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PracticeSpeechBubble(
                        text: _online
                            ? 'Online moddasın. Ders paketini indirip kesintisiz çalışabilirsin.'
                            : 'Internet yoksa son indirilen paketle pratik yapabilirsin.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _StatusCard(
                  online: _online,
                  cachedAt: _cachedAt,
                  pending: _pending,
                  stats: stats,
                ),
                const SizedBox(height: 14),
                PracticePrimaryButton(
                  label: 'OFFLINE PAKETİ İNDİR',
                  color: practiceGreen,
                  onPressed: () => _download(),
                ),
                if (questions.isNotEmpty &&
                    '${_pack?['pack_token'] ?? ''}'.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  PracticePrimaryButton(
                    label: 'OFFLINE DERSİ BAŞLAT',
                    color: practiceBlue,
                    onPressed: () => _startOfflineSession(),
                  ),
                ],
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _syncing || _pending == 0 ? null : () => _sync(),
                  icon: const Icon(Icons.sync_rounded),
                  label: Text(
                    _syncing ? 'SENKRONLANIYOR' : 'BEKLEYENLERİ SENKRONLA',
                  ),
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  title: 'Adaptif offline sorular',
                  subtitle: '${questions.length} soru hazır',
                ),
                for (final question in questions.take(5))
                  _MiniCard(
                    icon: Icons.quiz_rounded,
                    color: practiceBlue,
                    title:
                        '${question['question'] ?? question['title'] ?? 'Soru'}',
                    subtitle:
                        '${question['type'] ?? 'practice'} • ${question['xp_reward'] ?? 10} XP',
                  ),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: 'Odak alanları',
                  subtitle: focusAreas.isEmpty
                      ? 'Backend performansa göre oluşturur'
                      : '${focusAreas.length} öneri',
                ),
                for (final area in focusAreas.take(4))
                  _MiniCard(
                    icon: Icons.track_changes_rounded,
                    color: practiceOrange,
                    title:
                        '${area['title'] ?? area['label'] ?? area['type'] ?? 'Odak'}',
                    subtitle:
                        '${area['reason'] ?? area['subtitle'] ?? 'Tekrar önceliği'}',
                  ),
              ],
            ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 0),
    );
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
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.online,
    required this.cachedAt,
    required this.pending,
    required this.stats,
  });

  final bool online;
  final DateTime? cachedAt;
  final int pending;
  final Map<String, dynamic> stats;

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
        children: [
          Row(
            children: [
              _Metric(
                icon: online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                label: online ? 'Online' : 'Offline',
                color: online ? practiceGreen : const Color(0xFFFF5964),
              ),
              _Metric(
                icon: Icons.cloud_done_rounded,
                label: cachedAt == null ? 'Paket yok' : _format(cachedAt!),
                color: practiceBlue,
              ),
              _Metric(
                icon: Icons.pending_actions_rounded,
                label: '$pending bekleyen',
                color: practiceOrange,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SmallStat(
                  value: '${stats['streak'] ?? stats['current_streak'] ?? 0}',
                  label: 'Seri',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallStat(
                  value: '${stats['total_xp'] ?? 0}',
                  label: 'XP',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallStat(
                  value: '${stats['hearts'] ?? stats['current_hearts'] ?? 5}',
                  label: 'Can',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _format(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}.${value.month} $hour:$minute';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: practiceInk,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: practiceInk,
              fontSize: 20,
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: practiceInk,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: practiceMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
