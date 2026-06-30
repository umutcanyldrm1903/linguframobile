import 'package:flutter/material.dart';

import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import '../practice_trial_lesson_cta.dart';
import 'practice_visuals.dart';

class PracticeMistakesScreen extends StatefulWidget {
  const PracticeMistakesScreen({super.key});

  @override
  State<PracticeMistakesScreen> createState() => _PracticeMistakesScreenState();
}

class _PracticeMistakesScreenState extends State<PracticeMistakesScreen> {
  final PracticeApiService _api = const PracticeApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getMistakes();
    final raw = data?['mistakes'];
    if (!mounted) return;
    setState(() {
      _items = raw is List
          ? raw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false)
          : _fallback();
      _loading = false;
    });
  }

  Future<void> _resolve(int id) async {
    if (id > 0) {
      final res = await _api.resolveMistake(id);
      if (!mounted) return;
      // Backend başarısızsa ekrandan SİLME (sunucuda duruyorken çözülmüş
      // gösterme).
      if (res == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşaretlenemedi, tekrar dene.')),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() => _items.removeWhere((item) => _asInt(item['id']) == id));
    PracticeSoundService.onCorrect();
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
          'Hatalar',
          style: TextStyle(
            color: Color(0xFFB0B0B0),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: PracticeMascot(size: 110))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PracticeMascot(
                        size: 108,
                        mood: _items.isEmpty
                            ? PracticeMascotMood.excited
                            : PracticeMascotMood.thinking,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PracticeSpeechBubble(
                          text: _items.isEmpty
                              ? 'Açık hata kalmadi!'
                              : 'Bu hatalari cozelim ve mastery kazanalim.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const PracticeTrialLessonCta(
                    compact: true,
                    source: 'practice_mistakes',
                    sourceLabel: 'Hatalarını',
                  ),
                  const SizedBox(height: 16),
                  if (_items.isEmpty)
                    const _EmptyPanel()
                  else
                    for (final item in _items)
                      _MistakeCard(
                        item: item,
                        onResolve: () => _resolve(_asInt(item['id'])),
                      ),
                ],
              ),
      ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 0),
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  List<Map<String, dynamic>> _fallback() => const [
        {
          'id': 0,
          'question_text': 'Complete: I would like ___ coffee.',
          'user_answer': 'many',
          'correct_answer': 'some',
          'explanation': 'Coffee burada sayılamayan isim gibi kullanılır.',
        }
      ];
}

class _MistakeCard extends StatelessWidget {
  const _MistakeCard({required this.item, required this.onResolve});

  final Map<String, dynamic> item;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item['question_text'] ?? item['prompt'] ?? 'Soru'}',
            style: const TextStyle(
              color: practiceInk,
              fontSize: 18,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _AnswerLine(
            label: 'Sen',
            value: '${item['user_answer'] ?? '-'}',
            color: const Color(0xFFFF5964),
          ),
          _AnswerLine(
            label: 'Doğru',
            value: '${item['correct_answer'] ?? item['answer'] ?? '-'}',
            color: practiceGreen,
          ),
          if ('${item['explanation'] ?? ''}'.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${item['explanation']}',
              style: const TextStyle(
                color: practiceMuted,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          PracticePrimaryButton(
            label: 'COZDUM',
            color: practiceGreen,
            onPressed: onResolve,
          ),
        ],
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  const _AnswerLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: practiceInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return PracticeConfettiOverlay(
      active: true,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF2FFE9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: practiceGreen.withValues(alpha: .35)),
        ),
        child: const Text(
          'Bugün hatalar temiz. Ders yoluna dönup yeni XP kazanabilirsin.',
          style: TextStyle(
            color: practiceInk,
            fontSize: 17,
            height: 1.35,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
