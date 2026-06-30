import 'package:flutter/material.dart';

import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

class PracticeWeakWordsScreen extends StatefulWidget {
  const PracticeWeakWordsScreen({super.key});

  @override
  State<PracticeWeakWordsScreen> createState() =>
      _PracticeWeakWordsScreenState();
}

class _PracticeWeakWordsScreenState extends State<PracticeWeakWordsScreen> {
  final PracticeApiService _api = const PracticeApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _words = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getWeakWords();
    final raw = data?['words'];
    if (!mounted) return;
    setState(() {
      _words = raw is List
          ? raw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false)
          : _fallback();
      _loading = false;
    });
  }

  Future<void> _review(Map<String, dynamic> word, bool correct) async {
    final id = _asInt(word['id']);
    if (id > 0) {
      final res = await _api.reviewWord(id, correct: correct);
      if (!mounted) return;
      // Backend başarısızsa listeden SİLME (sunucuyla tutarsız kalmasın).
      if (res == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kaydedilemedi, tekrar dene.')),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      if (correct) {
        _words.removeWhere((item) => _asInt(item['id']) == id);
      }
    });
    correct ? PracticeSoundService.onCorrect() : PracticeSoundService.onWrong();
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
          'Zayıf kelimeler',
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
                      const PracticeMascot(
                        size: 108,
                        mood: PracticeMascotMood.happy,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: PracticeSpeechBubble(
                          text:
                              'Doğru cevapladıkça kelimeler daha seyrek gelir.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  for (final word in _words)
                    _WordReviewCard(
                      word: word,
                      onCorrect: () => _review(word, true),
                      onWrong: () => _review(word, false),
                    ),
                  if (_words.isEmpty)
                    const Text(
                      'Tekrar zamanı gelen zayıf kelime yok.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: practiceMuted,
                        fontWeight: FontWeight.w800,
                      ),
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
          'word': 'coffee',
          'meaning': 'kahve',
          'mastery': 'weak',
          'wrong_count': 2,
        },
        {
          'id': 0,
          'word': 'reservation',
          'meaning': 'rezervasyon',
          'mastery': 'learning',
          'wrong_count': 1,
        },
      ];
}

class _WordReviewCard extends StatelessWidget {
  const _WordReviewCard({
    required this.word,
    required this.onCorrect,
    required this.onWrong,
  });

  final Map<String, dynamic> word;
  final VoidCallback onCorrect;
  final VoidCallback onWrong;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Column(
        children: [
          Text(
            '${word['word'] ?? ''}',
            style: const TextStyle(
              color: practiceInk,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${word['meaning'] ?? 'Anlamını seç'}',
            style: const TextStyle(
              color: practiceMuted,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            minHeight: 12,
            borderRadius: BorderRadius.circular(999),
            value: _masteryValue('${word['mastery'] ?? 'weak'}'),
            backgroundColor: const Color(0xFFE5E5E5),
            valueColor: const AlwaysStoppedAnimation<Color>(practiceGreen),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PracticePrimaryButton(
                  label: 'TEKRAR',
                  color: practiceOrange,
                  onPressed: onWrong,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PracticePrimaryButton(
                  label: 'BILIYORUM',
                  onPressed: onCorrect,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _masteryValue(String mastery) {
    return switch (mastery) {
      'mastered' => 1,
      'good' => .78,
      'learning' => .45,
      'new' => .2,
      _ => .32,
    };
  }
}
