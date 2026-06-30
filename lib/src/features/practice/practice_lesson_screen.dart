import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';
import 'practice_api_service.dart';
import 'practice_premium_offer_service.dart';
import 'practice_repository.dart';
import 'practice_sound_service.dart';
import 'screens/practice_game_widgets.dart';
import 'screens/practice_question_widgets.dart';
import 'screens/practice_session_screen.dart';
import 'screens/practice_visuals.dart';

class PracticeLessonScreen extends StatefulWidget {
  const PracticeLessonScreen({super.key, required this.lesson});

  final PracticeLesson lesson;

  @override
  State<PracticeLessonScreen> createState() => _PracticeLessonScreenState();
}

class _PracticeLessonScreenState extends State<PracticeLessonScreen> {
  static const PracticeRepository _repository = PracticeRepository();
  final PracticeApiService _api = const PracticeApiService();

  final GlobalKey<PracticeShakeWidgetState> _shakeKey = GlobalKey();

  List<PracticeQuestion>? _questions;
  int _index = 0;
  int _correct = 0;

  // Oyunlaştırma durumu
  int _hearts = 5;
  final int _maxHearts = 5;
  int _combo = 0;
  int _xpTrigger = 0;
  String? _motivation;
  final Stopwatch _watch = Stopwatch();

  String? _answerValue;
  bool _answered = false;
  bool _submitting = false;
  bool _isCorrect = false;
  String? _correctAnswer;
  String _explanation = '';
  String? _feedback;
  String? _loadError;

  bool _showCountdown = true;

  /// Premium (Sınırsız Can) aktifse can tüketilmez ve can-bitti kilidi açılmaz.
  bool _unlimited = false;

  @override
  void initState() {
    super.initState();
    _watch.start();
    unawaited(_loadHearts());
    unawaited(_loadPremium().then<void>((_) {}));
    unawaited(_load());
  }

  Future<void> _loadHearts() async {
    final stats = await _repository.fetchStats();
    if (!mounted) return;
    setState(() => _hearts = stats.hearts.clamp(0, _maxHearts));
  }

  Future<bool> _loadPremium() async {
    final data = await _api.getPremiumStatus();
    if (!mounted || data == null) return false;
    final nested = data['premium'];
    final isPremium = data['is_premium'] == true ||
        (nested is Map && nested['is_premium'] == true);
    setState(() => _unlimited = isPremium);
    return isPremium;
  }

  Future<void> _load() async {
    setState(() {
      _questions = null;
      _loadError = null;
    });
    final isDemo = widget.lesson.id.startsWith('demo-');
    if (!isDemo) {
      final started = await _repository.startLesson(widget.lesson);
      if (!started) {
        if (!mounted) return;
        setState(() {
          _questions = const [];
          _loadError =
              'Ders başlatılamadı. Oturumunu ve bağlantını kontrol edip tekrar dene.';
        });
        return;
      }
    }
    final questions = await _repository.loadLessonQuestions(widget.lesson);
    if (!mounted) return;
    setState(() {
      _questions = questions;
      if (questions.isEmpty) {
        _loadError =
            'Bu dersin soruları sunucudan alınamadı. Lütfen tekrar dene.';
      }
    });
  }

  Future<void> _check() async {
    final questions = _questions;
    if (questions == null || _answered || _submitting) return;
    final value = _answerValue;
    if (value == null) return;
    final question = questions[_index];

    setState(() => _submitting = true);
    final result = await _repository.answerQuestion(
      question.id.toString(),
      lessonId: widget.lesson.id,
      answer: value,
    );

    bool correct;
    String correctAnswer;
    String explanation;

    // match_pairs ve flashcard backend tek-string doğrulamasıyla tam uyumlu
    // olmadığından bu tipler için lokal değerlendirme yapılır.
    if (question.type == 'match_pairs') {
      correct = _localCorrect(question, value);
      correctAnswer = '';
      explanation = question.explanation;
    } else if (question.type == 'vocabulary_flashcard') {
      correct = true; // cezasız tanıma egzersizi
      correctAnswer = question.answer;
      explanation = question.explanation;
    } else if (result != null) {
      correct = result['is_correct'] == true;
      correctAnswer = '${result['correct_answer'] ?? ''}';
      explanation = '${result['explanation'] ?? ''}';
    } else {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cevap sunucuda doğrulanamadı. Bağlantını kontrol edip tekrar dene.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _answered = true;
      _isCorrect = correct;
      _correctAnswer = correctAnswer.isNotEmpty ? correctAnswer : value;
      _explanation = explanation;
      _feedback = correct ? _correctMessage() : _wrongMessage();
      if (correct) {
        _correct++;
        _combo++;
        _xpTrigger++;
      } else {
        _combo = 0;
        if (!_unlimited) _hearts = (_hearts - 1).clamp(0, _maxHearts);
      }
    });

    if (correct) {
      PracticeSoundService.onCorrect();
      playComboSound(_combo);
    } else {
      PracticeSoundService.onWrong();
      _shakeKey.currentState?.shake();
    }
  }

  void _checkMotivation() {
    final total = _questions?.length ?? 0;
    final remaining = total - _index;
    final isTr = AppStrings.code == 'tr';
    String? msg;
    if (total >= 6 && _index == total ~/ 2) {
      msg = isTr
          ? 'Yarısını geçtin! Harika gidiyorsun 💪'
          : 'Halfway there! You\'re doing great 💪';
    } else if (remaining == 3 && total > 4) {
      msg =
          isTr ? '3 soru kaldı! Neredeyse bitti 🎯' : '3 to go! Almost done 🎯';
    } else if (remaining == 1 && total > 2) {
      msg = isTr ? 'Son soru! Göster kendini ⭐' : 'Last öne! Show your best ⭐';
    }
    if (msg != null) setState(() => _motivation = msg);
  }

  bool _localCorrect(PracticeQuestion question, String value) {
    if (question.type == 'match_pairs') {
      final defs = {for (final pair in question.pairs) pair[0]: pair[1]};
      final entries = value.split(',').where((e) => e.isNotEmpty).toList();
      if (entries.length != defs.length) return false;
      for (final entry in entries) {
        final kv = entry.split('=');
        if (kv.length != 2 || defs[kv[0]] != kv[1]) return false;
      }
      return true;
    }
    final answer = question.answer.trim().toLowerCase();
    // Cevap bilinmiyorsa "doğru" SAYMA (eski sürüm true dönüyordu → çevrimdışı/
    // hata durumunda yanlış cevap doğru görünebiliyordu, istismara açıktı).
    if (answer.isEmpty) return false;
    return value.trim().toLowerCase() == answer;
  }

  /// Devam butonu: can bittiyse kilit akışı, değilse ilerle.
  Future<void> _continue() async {
    if (!_unlimited && _hearts <= 0) {
      await _handleOutOfHearts();
      return;
    }
    await _advance();
  }

  Future<void> _handleOutOfHearts() async {
    final choice = await showOutOfHeartsSheet(context);
    if (!mounted) return;
    if (choice == 'refill') {
      final data = await _api.refillHearts();
      if (!mounted) return;
      // Backend başarısızsa SAHTE yerel dolum yapma (eski sürüm hearts=max
      // yapıyordu — sunucuda değişmeden "doldu" gösteriyordu).
      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.code == 'tr'
                ? 'Can doldurulamadı — yeterli coin olmayabilir.'
                : 'Could not refill — you may not have enough coins.'),
          ),
        );
        return;
      }
      setState(() => _hearts =
          _repository.parseStats(data['stats']).hearts.clamp(0, _maxHearts));
      if (_hearts > 0) await _advance();
    } else if (choice == 'practice') {
      await _practiceForHeart();
    } else if (choice == 'premium') {
      await PracticePremiumOfferService.instance.openPremiumPage(
        context,
        trigger: PracticePremiumTrigger.hearts,
      );
      if (!mounted) return;
      final activated = await _loadPremium();
      if (activated && mounted) await _advance();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  /// Kısa bir tekrar pratiğiyle 1 can kazandırır, sonra derse devam eder.
  Future<void> _practiceForHeart() async {
    final questions = await _repository.loadAdaptiveQuestions(limit: 3);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionScreen(
          title: 'Tekrar pratiği',
          questions: questions,
          enforceHearts: false,
          onComplete: (correct, total) async => '+1 can kazandın!',
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _hearts = _hearts <= 0 ? 1 : _hearts);
    await _advance();
  }

  Future<void> _advance() async {
    final questions = _questions!;
    if (_index + 1 >= questions.length) {
      _watch.stop();
      // Tamamlamayı sunucuya yaz ve BEKLE; sonuç ekranı XP'yi sunucudan okuduğu
      // için önce kaydın işlenmesi gerek (eski sürüm unawaited'di → API
      // başarısız olsa bile XP/konfeti gösteriliyordu).
      setState(() => _submitting = true);
      final completion = await _repository.completeLesson(
        widget.lesson,
        correct: _correct,
        total: questions.length,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      if (completion == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ders sonucu kaydedilemedi. Bağlantını kontrol edip tekrar dene.',
            ),
          ),
        );
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        '/practice/result',
        arguments: PracticeResultArgs(
          lesson: widget.lesson,
          correct: _correct,
          total: questions.length,
          duration: _watch.elapsed,
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _answerValue = null;
      _answered = false;
      _isCorrect = false;
      _correctAnswer = null;
      _explanation = '';
      _feedback = null;
    });
    _checkMotivation();
  }

  String _correctMessage() {
    final isTr = AppStrings.code == 'tr';
    final items = isTr
        ? ['Harika!', 'Doğru!', 'Süper!', 'Çok iyi!']
        : ['Great!', 'Correct!', 'Nice!', 'Well done!'];
    return items[_correct % items.length];
  }

  String _wrongMessage() {
    return AppStrings.code == 'tr'
        ? 'Yanlış oldu. Doğru cevabı incele ve devam et.'
        : 'Not quite. Review the correct answer and continue.';
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';

    if (_showCountdown) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LessonCountdown(
            onFinished: () {
              if (mounted) setState(() => _showCountdown = false);
            },
          ),
        ),
      );
    }

    final questions = _questions;
    if (questions == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6FAFF),
        body: PracticeMascotLoader(),
      );
    }
    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6FAFF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF6FAFF),
          elevation: 0,
          foregroundColor: AppColors.ink,
          title: Text(widget.lesson.title),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: practiceBlue,
                  size: 54,
                ),
                const SizedBox(height: 14),
                Text(
                  _loadError ??
                      (isTr
                          ? 'Bu derste henüz soru yok.'
                          : 'No questions in this lesson yet.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: practiceMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(isTr ? 'Tekrar dene' : 'Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = questions[_index];
    final progress = (_index + 1) / questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6FAFF),
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(widget.lesson.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: HeartsCounter(hearts: _hearts, max: _maxHearts),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
              child: Column(
                children: [
                  PracticeProgressBar(value: progress, height: 14),
                  SizedBox(
                    height: 40,
                    child: Center(child: ComboBadge(count: _combo)),
                  ),
                  Expanded(
                    child: PracticeShakeWidget(
                      key: _shakeKey,
                      child: AnimatedSwitcher(
                        duration: AppMotion.normal,
                        child: PracticeQuestionView(
                          key: ValueKey(_index),
                          question: question,
                          value: _answerValue,
                          answered: _answered,
                          isCorrect: _isCorrect,
                          correctAnswer: _correctAnswer,
                          onChanged: (value) {
                            if (_answered) return;
                            setState(() => _answerValue = value);
                            PracticeSoundService.onTap();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_answered)
                    AnswerFeedbackBar(
                      correct: _isCorrect,
                      message: _feedback ?? '',
                      correctAnswer: _isCorrect ? '' : (_correctAnswer ?? ''),
                      explanation: _explanation,
                      continueLabel: _hearts <= 0
                          ? (isTr ? 'CANLARI DOLDUR' : 'REFILL HEARTS')
                          : (_index + 1 >= questions.length
                              ? (isTr ? 'SONUCU GÖSTER' : 'SHOW RESULT')
                              : (isTr ? 'DEVAM ET' : 'CONTINUE')),
                      onContinue: _continue,
                    )
                  else
                    Practice3DButton(
                      label:
                          _submitting ? '...' : (isTr ? 'KONTROL ET' : 'CHECK'),
                      onPressed:
                          (_answerValue == null || _submitting) ? null : _check,
                    ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 130,
              child: IgnorePointer(
                child: Center(
                  child: XpFloater(amount: 10, trigger: _xpTrigger),
                ),
              ),
            ),
            if (_motivation != null)
              Positioned(
                left: 0,
                right: 0,
                top: 16,
                child: IgnorePointer(
                  child: Center(
                    child: PracticeMotivationToast(
                      key: ValueKey(_motivation),
                      message: _motivation!,
                      onDone: () {
                        if (mounted) setState(() => _motivation = null);
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PracticeResultArgs {
  const PracticeResultArgs({
    required this.lesson,
    required this.correct,
    required this.total,
    this.duration,
  });

  final PracticeLesson lesson;
  final int correct;
  final int total;
  final Duration? duration;
}
