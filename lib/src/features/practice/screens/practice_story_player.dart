import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_characters.dart';
import 'practice_game_widgets.dart';
import 'practice_visuals.dart';

/// Dallanan diyaloglu hikâye oynatıcı.
/// Karakter avatarlarıyla konuşma satırları + seçimle dallanma.
class PracticeStoryPlayerScreen extends StatefulWidget {
  const PracticeStoryPlayerScreen({super.key});

  @override
  State<PracticeStoryPlayerScreen> createState() =>
      _PracticeStoryPlayerScreenState();
}

class _PracticeStoryPlayerScreenState extends State<PracticeStoryPlayerScreen> {
  final PracticeApiService _api = const PracticeApiService();

  bool _loading = true;
  List<Map<String, dynamic>> _stories = [];
  Map<String, dynamic>? _active; // açık hikâye detayı
  List<Map<String, dynamic>> _parts = [];
  List<Map<String, dynamic>> _questions = [];
  final List<Map<String, dynamic>> _shown = []; // ekranda görünen satırlar
  final List<Map<String, dynamic>> _answers = [];
  int _index = 0;
  int _questionIndex = 0;
  String? _selectedAnswer;
  bool _showQuestions = false;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    final data = await _api.getStories();
    final raw = data?['items'] ?? data?['stories'];
    if (!mounted) return;
    setState(() {
      _stories = _asList(raw);
      if (_stories.isEmpty) _stories = _fallbackStories();
      _loading = false;
    });
  }

  Future<void> _open(Map<String, dynamic> story) async {
    final id = _asInt(story['id']);
    setState(() => _loading = true);
    Map<String, dynamic>? detail;
    if (id > 0) {
      final data = await _api.getStory(id);
      final item = data?['item'];
      final story = data?['story'];
      final raw = item ?? story;
      detail = raw is Map ? Map<String, dynamic>.from(raw) : data;
    }
    if (!mounted) return;
    final parts = _partsOf(detail ?? story);
    final questions = _questionsOf(detail ?? story);
    setState(() {
      _active = detail ?? story;
      _parts = parts.isEmpty ? _fallbackParts() : parts;
      _questions = questions;
      _shown
        ..clear()
        ..add(_parts.first);
      _answers.clear();
      _index = 0;
      _questionIndex = 0;
      _selectedAnswer = null;
      _showQuestions = false;
      _loading = false;
    });
  }

  void _advance([int? next]) {
    final target = next ?? _index + 1;
    if (target >= _parts.length) {
      if (_questions.isNotEmpty) {
        setState(() {
          _showQuestions = true;
          _selectedAnswer = null;
        });
      } else {
        _finish();
      }
      return;
    }
    setState(() {
      _index = target;
      _shown.add(_parts[target]);
    });
  }

  Future<void> _finish() async {
    final id = _asInt(_active?['id']);
    setState(() => _completing = true);
    final result = id > 0
        ? await _api.completeStory(id, answers: _answers)
        : <String, dynamic>{'passed': true, 'xp_awarded': 0};
    if (!mounted) return;
    setState(() => _completing = false);
    if (result?['passed'] != true && _questions.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hikaye testi %${_asInt(result?['score'])}. En az %60 gerekiyor.',
          ),
        ),
      );
      return;
    }
    await PracticeSoundService.playComplete();
    if (!mounted) return;
    await showRewardPopup(
      context,
      title:
          AppStrings.code == 'tr' ? 'Hikaye tamamlandı!' : 'Story completed!',
      xp: _asInt(result?['xp_awarded']),
    );
    if (!mounted) return;
    setState(() => _active = null); // listeye dön
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
        title: Text(
          _active != null
              ? '${_active!['title'] ?? (AppStrings.code == 'tr' ? 'Hikaye' : 'Story')}'
              : (AppStrings.code == 'tr' ? 'Hikayeler' : 'Stories'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: _active != null
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() => _active = null),
              )
            : null,
      ),
      body: _loading
          ? Center(
              child: MascotLoading(
                message: AppStrings.code == 'tr'
                    ? 'Hikayeler yükleniyor...'
                    : 'Loading stories...',
              ),
            )
          : _active == null
              ? _buildList()
              : _buildPlayer(),
    );
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        for (final story in _stories)
          InkWell(
            onTap: () => _open(story),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: practiceLine, width: 2),
              ),
              child: Row(
                children: [
                  PracticeCharacterAvatar(
                    character:
                        practiceCharacterByName('${story['speaker'] ?? ''}'),
                    size: 54,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${story['title'] ?? (AppStrings.code == 'tr' ? 'Hikaye' : 'Story')}',
                          style: const TextStyle(
                            color: practiceInk,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${story['description'] ?? story['subtitle'] ?? (AppStrings.code == 'tr' ? 'Kısa diyalog' : 'Short dialogue')}',
                          style: const TextStyle(
                            color: practiceMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${story['xp_reward'] ?? 15} XP',
                    style: const TextStyle(
                      color: practiceOrange,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlayer() {
    if (_showQuestions) return _buildQuestion();
    final current = _parts[_index];
    final choices = _choicesOf(current);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            children: [
              for (final part in _shown) _DialogueLine(part: part),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: choices.isNotEmpty
              ? Column(
                  children: [
                    for (final choice in choices)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Practice3DButton(
                          label: '${choice['text'] ?? '...'}',
                          color: practiceBlue,
                          onPressed: () {
                            final next = _asInt(choice['next'], fallback: -1);
                            _advance(next >= 0 ? next : null);
                          },
                        ),
                      ),
                  ],
                )
              : Practice3DButton(
                  label: _completing
                      ? '...'
                      : (_index + 1 >= _parts.length
                          ? (AppStrings.code == 'tr' ? 'BITIR' : 'FINISH')
                          : (AppStrings.code == 'tr' ? 'DEVAM' : 'CONTINUE')),
                  onPressed: _completing ? null : () => _advance(),
                ),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    final question = _questions[_questionIndex];
    final options = _stringList(question['options']);
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_questionIndex + 1) / _questions.length,
          minHeight: 8,
          backgroundColor: practiceLine,
          valueColor: const AlwaysStoppedAnimation(practicePurple),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            children: [
              const PracticeMascot(
                size: 106,
                mood: PracticeMascotMood.thinking,
              ),
              const SizedBox(height: 16),
              Text(
                '${question['question_text'] ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: practiceInk,
                  fontSize: 22,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => setState(() => _selectedAnswer = option),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedAnswer == option
                            ? practicePurple.withValues(alpha: .12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedAnswer == option
                              ? practicePurple
                              : practiceLine,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(
                          color: practiceInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Practice3DButton(
            label: _completing
                ? 'KAYDEDİLİYOR...'
                : (_questionIndex + 1 == _questions.length
                    ? 'HİKAYEYİ BİTİR'
                    : 'SONRAKİ SORU'),
            color: practicePurple,
            onPressed: _selectedAnswer == null || _completing
                ? null
                : () async {
                    _answers.add({
                      'question_id': _asInt(question['id']),
                      'answer': _selectedAnswer,
                    });
                    if (_questionIndex + 1 >= _questions.length) {
                      await _finish();
                    } else {
                      setState(() {
                        _questionIndex++;
                        _selectedAnswer = null;
                      });
                    }
                  },
          ),
        ),
      ],
    );
  }

  // ---- parsing helpers ----

  List<Map<String, dynamic>> _partsOf(Map<String, dynamic> story) {
    for (final key in ['parts', 'scenes', 'lines', 'dialogue']) {
      final v = story[key];
      if (v is List) return _asList(v);
    }
    final content = story['content'];
    if (content is Map) {
      for (final key in ['parts', 'scenes', 'lines']) {
        final v = content[key];
        if (v is List) return _asList(v);
      }
    }
    return const [];
  }

  List<Map<String, dynamic>> _choicesOf(Map<String, dynamic> part) {
    final v = part['choices'] ?? part['options'];
    return v is List ? _asList(v) : const [];
  }

  List<Map<String, dynamic>> _questionsOf(Map<String, dynamic> story) {
    final direct = story['questions'];
    if (direct is List) return _asList(direct);
    final content = story['content'];
    if (content is Map && content['questions'] is List) {
      return _asList(content['questions']);
    }
    return const [];
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) {
          if (item is Map) {
            return '${item['label'] ?? item['value'] ?? ''}';
          }
          return '$item';
        })
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  // ---- fallback content (backend boşsa) ----

  List<Map<String, dynamic>> _fallbackStories() => [
        {
          'id': 0,
          'title': 'Kafede sipariş',
          'description': 'Mina ile kısa bir kafe diyaloğu',
          'speaker': 'Mina',
          'xp_reward': 15,
        },
      ];

  List<Map<String, dynamic>> _fallbackParts() => [
        {'speaker': 'Mina', 'text': 'Hi! What would you like to order?'},
        {
          'speaker': 'Sen',
          'text': 'Ne söylersin?',
          'choices': [
            {'text': 'I would like a coffee, please.', 'next': 2},
            {'text': 'Coffee me now.', 'next': 2},
          ],
        },
        {'speaker': 'Mina', 'text': 'Great choice! Anything else?'},
        {'speaker': 'Sen', 'text': 'No, thank you. That is all.'},
        {'speaker': 'Mina', 'text': 'Perfect. Have a nice day!'},
      ];
}

class _DialogueLine extends StatelessWidget {
  const _DialogueLine({required this.part});

  final Map<String, dynamic> part;

  @override
  Widget build(BuildContext context) {
    final speaker = '${part['speaker'] ?? part['character'] ?? 'Lingu'}';
    final text = '${part['text'] ?? part['line'] ?? part['content'] ?? ''}';
    final mine =
        speaker.toLowerCase() == 'sen' || speaker.toLowerCase() == 'you';
    final character = practiceCharacterByName(speaker);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: mine ? TextDirection.rtl : TextDirection.ltr,
        children: [
          if (!mine)
            PracticeCharacterAvatar(character: character, size: 48)
          else
            const SizedBox(width: 48),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: mine ? practiceBlue : const Color(0xFFF3F5F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!mine)
                    Text(
                      speaker,
                      style: TextStyle(
                        color: character.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    text,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: mine ? Colors.white : practiceInk,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
