import 'package:flutter/material.dart';

import '../practice_api_service.dart';
import 'practice_visuals.dart';

class PracticePlacementScreen extends StatefulWidget {
  const PracticePlacementScreen({
    super.key,
    this.guest = false,
    this.popOnFinish = false,
    this.onGuestSignIn,
    this.onGuestHome,
  });

  /// Misafir (girişsiz) mod: sunucu çağrıları atlanır, seviye yerel skordan
  /// hesaplanır. İlk açılış "hızlı başlangıç" akışı için kullanılır.
  final bool guest;

  /// Bitişte "/practice" yerine sadece geri dön (çağıran ekran yönlendirir).
  final bool popOnFinish;

  /// Misafir sonuç ekranındaki "Giriş yap" eylemi (XP/seriyi kaydet).
  final VoidCallback? onGuestSignIn;

  /// Misafir sonuç ekranındaki "Ana ekrana geç" eylemi (hub'a git).
  final VoidCallback? onGuestHome;

  @override
  State<PracticePlacementScreen> createState() =>
      _PracticePlacementScreenState();
}

class _PracticePlacementScreenState extends State<PracticePlacementScreen> {
  final PracticeApiService _api = const PracticeApiService();

  final List<_PlacementQuestion> _questions = const [
    _PlacementQuestion(
      prompt: 'Choose the correct translation: Merhaba',
      answer: 'Hello',
      options: ['Hello', 'Good night', 'Thank you'],
    ),
    _PlacementQuestion(
      prompt: 'Complete: I ___ a student.',
      answer: 'am',
      options: ['am', 'is', 'are'],
    ),
    _PlacementQuestion(
      prompt: 'Choose the natural sentence.',
      answer: 'I would like water.',
      options: ['I would like water.', 'I am water.', 'Water go.'],
    ),
    _PlacementQuestion(
      prompt: 'Past tense of go?',
      answer: 'went',
      options: ['goed', 'went', 'goes'],
    ),
    _PlacementQuestion(
      prompt: 'Best question form:',
      answer: 'Where are you from?',
      options: [
        'Where are you from?',
        'Where you are from?',
        'From where you?'
      ],
    ),
  ];

  int _index = 0;
  int _score = 0;
  String? _selected;
  bool _done = false;
  bool _submitting = false;
  String? _serverLevel;
  String? _serverStart;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (widget.guest) return; // misafir: sunucu durumu yok, yerel akış
    final data = await _api.getPlacementStatus();
    final result = data?['result'];
    if (!mounted) return;
    if (data?['has_result'] == true && result is Map) {
      setState(() {
        _done = true;
        _serverLevel = '${result['level'] ?? ''}';
        _serverStart = result['recommended_unit_order'] != null
            ? 'Ünite ${result['recommended_unit_order']}'
            : null;
        _score = _intOf(result['score']);
      });
    }
  }

  void _choose(String value) {
    if (_selected != null) return;
    final correct = value == _questions[_index].answer;
    setState(() {
      _selected = value;
      if (correct) _score++;
    });
  }

  Future<void> _next() async {
    if (_index + 1 >= _questions.length) {
      setState(() {
        _done = true;
        _submitting = !widget.guest;
      });
      if (widget.guest) return; // yerel seviye getter'ı sonucu verir
      final data = await _api.completePlacement({
        'correct_count': _score,
        'total_count': _questions.length,
      });
      if (!mounted) return;
      setState(() {
        _submitting = false;
        if (data != null) {
          _serverLevel = '${data['level'] ?? ''}';
          _serverStart = data['recommended_unit_order'] != null
              ? 'Ünite ${data['recommended_unit_order']}'
              : null;
        }
      });
      return;
    }
    setState(() {
      _index++;
      _selected = null;
    });
  }

  int _intOf(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  String get _level {
    if ((_serverLevel ?? '').isNotEmpty) return _serverLevel!;
    if (_score >= 5) return 'B1';
    if (_score >= 3) return 'A2';
    return 'A1';
  }

  String get _start {
    if ((_serverStart ?? '').isNotEmpty) return _serverStart!;
    if (_score >= 5) return 'Günlük konuşma - Ünite 3';
    if (_score >= 3) return 'Temel cümleler - Ünite 2';
    return 'Sıfırdan başla - Ünite 1';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _done ? 1.0 : (_index + 1) / _questions.length;
    // Misafir sonuç ekranı kendi iki butonunu (Giriş yap / Ana ekrana geç)
    // taşır; o durumda alttaki tek buton gizlenir.
    final hideBottomButton = _done && widget.guest;
    return Scaffold(
      backgroundColor: practiceKraft,
      appBar: AppBar(
        backgroundColor: practiceKraft,
        elevation: 0,
        foregroundColor: practiceInk,
        title: Text(
          widget.guest ? 'Hızlı başlangıç' : 'Seviye belirleme',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            children: [
              PracticeProgressBar(value: progress, height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _done
                      ? _PlacementResult(
                          key: const ValueKey('result'),
                          level: _level,
                          start: _start,
                          score: _score,
                          total: _questions.length,
                          guest: widget.guest,
                          onSignIn: widget.onGuestSignIn,
                          onHome: widget.onGuestHome,
                        )
                      : _PlacementQuestionView(
                          key: ValueKey(_index),
                          question: _questions[_index],
                          selected: _selected,
                          onChoose: _choose,
                        ),
                ),
              ),
              if (!hideBottomButton)
                PracticePrimaryButton(
                  label: _submitting
                      ? '...'
                      : (_done ? 'YOLA BAŞLA' : 'DEVAM ET'),
                  onPressed: _submitting
                      ? null
                      : (_done
                          ? () {
                              if (widget.popOnFinish) {
                                Navigator.of(context).maybePop();
                              } else {
                                Navigator.pushReplacementNamed(
                                    context, '/practice');
                              }
                            }
                          : (_selected == null ? null : _next)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlacementQuestion {
  const _PlacementQuestion({
    required this.prompt,
    required this.answer,
    required this.options,
  });

  final String prompt;
  final String answer;
  final List<String> options;
}

class _PlacementQuestionView extends StatelessWidget {
  const _PlacementQuestionView({
    required this.question,
    required this.selected,
    required this.onChoose,
    super.key,
  });

  final _PlacementQuestion question;
  final String? selected;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 28),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PracticeMascot(size: 102, mood: PracticeMascotMood.thinking),
            const SizedBox(width: 12),
            Expanded(child: PracticeSpeechBubble(text: question.prompt)),
          ],
        ),
        const SizedBox(height: 28),
        for (final option in question.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlacementOption(
              text: option,
              selected: selected == option,
              correct: option == question.answer,
              answered: selected != null,
              onTap: () => onChoose(option),
            ),
          ),
      ],
    );
  }
}

class _PlacementOption extends StatelessWidget {
  const _PlacementOption({
    required this.text,
    required this.selected,
    required this.correct,
    required this.answered,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool correct;
  final bool answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = answered && correct
        ? practiceGreen
        : (selected ? practiceRed : practicePaper);
    final textColor =
        answered && (correct || selected) ? Colors.white : practiceInk;
    return InkWell(
      onTap: answered ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 70),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected || correct && answered ? color : practiceLine,
            width: 2,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PlacementResult extends StatelessWidget {
  const _PlacementResult({
    required this.level,
    required this.start,
    required this.score,
    required this.total,
    this.guest = false,
    this.onSignIn,
    this.onHome,
    super.key,
  });

  final String level;
  final String start;
  final int score;
  final int total;
  final bool guest;
  final VoidCallback? onSignIn;
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) {
    return PracticeConfettiOverlay(
      active: true,
      child: ListView(
        padding: const EdgeInsets.only(top: 22, bottom: 12),
        children: [
          const Center(
            child: PracticeMascot(size: 108, mood: PracticeMascotMood.excited),
          ),
          const SizedBox(height: 14),
          Text(
            guest ? 'Hızlı başlangıç tamam!' : 'Başlangıç noktan hazır',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: practiceInk,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$score / $total doğru',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: practiceMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          _ResultCard(
            icon: Icons.school_rounded,
            title: 'Tahmini seviye',
            value: level,
            color: practiceBlue,
          ),
          _ResultCard(
            icon: Icons.menu_book_rounded,
            title: 'Önerilen başlangıç',
            value: start,
            color: practiceGreen,
          ),
          if (guest) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              decoration: BoxDecoration(
                color: practicePaper,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: practiceLine, width: 2),
              ),
              child: Column(
                children: [
                  const Icon(Icons.bookmark_added_rounded,
                      color: practiceOrange, size: 30),
                  const SizedBox(height: 8),
                  const Text(
                    'XP ve serini kaydet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: practiceInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bu seviyeden devam etmek, defterinde XP ve seri biriktirmek '
                    'için giriş yap. İstersen önce ana ekranı keşfet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: practiceMuted,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PracticePrimaryButton(
                    label: 'GİRİŞ YAP',
                    onPressed: onSignIn,
                  ),
                  const SizedBox(height: 10),
                  Practice3DButton(
                    label: 'ANA EKRANA GEÇ',
                    outlined: true,
                    onPressed: onHome,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: color.withValues(alpha: .16),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: practiceMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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
