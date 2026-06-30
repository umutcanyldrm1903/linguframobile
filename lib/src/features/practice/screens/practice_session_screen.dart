import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import '../practice_premium_offer_service.dart';
import '../practice_repository.dart';
import '../practice_sound_service.dart';
import '../practice_theme.dart';
import 'practice_game_widgets.dart';
import 'practice_powerup_overlay.dart';
import 'practice_question_widgets.dart';
import 'practice_visuals.dart';

typedef PracticeSessionComplete = Future<String?> Function(
  int correct,
  int total,
);

typedef PracticeAnswerRecorded = void Function(
  PracticeQuestion question,
  String answer,
  bool correct,
);

/// Tam oyunlaştırılmış pratik oturumu.
/// • Hint / Shield / 2×XP güç çubuğu
/// • Gerçek zamanlı XP sayacı (app bar)
/// • Combo milestone tam ekran flaşı (5 / 10 / 15+)
/// • Perfect lesson: altın arka plan + 🏆
/// • Mascot mood (excited / sad)
/// • Dinamik continue label
class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({
    required this.title,
    required this.questions,
    required this.onComplete,
    this.enforceHearts = true,
    this.guest = false,
    this.submitAnswers = true,
    this.onAnswerRecorded,
    super.key,
  });

  final String title;
  final List<PracticeQuestion> questions;
  final PracticeSessionComplete onComplete;
  final bool enforceHearts;
  final bool submitAnswers;
  final PracticeAnswerRecorded? onAnswerRecorded;

  /// Giriş gerektirmeyen "misafir tadımlık" modu — iç PracticeTheme'de
  /// giriş kapısını atlar (XP/seri kaydedilmez, sadece deneme).
  final bool guest;

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen>
    with TickerProviderStateMixin {
  static const PracticeRepository _repository = PracticeRepository();
  final PracticeApiService _api = const PracticeApiService();
  final GlobalKey<PracticeShakeWidgetState> _shakeKey = GlobalKey();

  // ── Oturum durumu ──────────────────────────────────────────────────────────
  int _index = 0;
  int _correct = 0;
  int _hearts = 5;
  final int _maxHearts = 5;
  int _combo = 0;
  int _maxCombo = 0;
  int _xpTrigger = 0;
  int _sessionXp = 0;
  String? _answerValue;
  bool _answered = false;
  bool _submitting = false;
  bool _isCorrect = false;
  String? _correctAnswer;
  String _explanation = '';
  String? _motivation;
  bool _finished = false;
  String? _resultMessage;

  /// Premium (Sınırsız Can) aktifse can tüketilmez / can-bitti kilidi açılmaz.
  bool _unlimited = false;

  // ── Power-up stoku ─────────────────────────────────────────────────────────
  int _hints = 3;
  int _shields = 1;
  bool _shieldActive = false;
  bool _xpBoostActive = false;

  // ── Combo flaş ────────────────────────────────────────────────────────────
  bool _showComboFlash = false;
  String _comboFlashText = '';
  Color _comboFlashColor = practiceOrange;
  late final AnimationController _comboCtrl;

  PracticeQuestion get _question => widget.questions[_index];

  @override
  void initState() {
    super.initState();
    _comboCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.enforceHearts) {
      _loadHearts();
      unawaited(_loadPremium().then<void>((_) {}));
    }
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

  @override
  void dispose() {
    _comboCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHearts() async {
    final stats = await _repository.fetchStats();
    if (!mounted) return;
    setState(() => _hearts = stats.hearts.clamp(0, _maxHearts));
  }

  // ── Cevap kontrol ──────────────────────────────────────────────────────────
  Future<void> _check() async {
    if (_answered || _submitting) return;
    final value = _answerValue;
    if (value == null) return;
    final question = _question;
    final lessonId = '${question.meta['lesson_id'] ?? ''}';

    setState(() => _submitting = true);
    Map<String, dynamic>? result;
    if (widget.submitAnswers && question.id > 0 && lessonId.isNotEmpty) {
      result = await _api.answerQuestion(
        question.id.toString(),
        lessonId: lessonId,
        answer: value,
      );
    }
    if (!mounted) return;

    bool correct;
    String correctAnswer;
    String explanation;
    if (result != null) {
      correct = result['is_correct'] == true;
      correctAnswer = '${result['correct_answer'] ?? ''}';
      explanation = '${result['explanation'] ?? ''}';
    } else {
      correct = _localCorrect(question, value);
      correctAnswer = question.answer;
      explanation = question.explanation;
    }

    // Kalkan aktifse yanlışı blokla
    if (!correct && _shieldActive && _shields > 0) {
      _shields--;
      _shieldActive = false;
      correct = true;
      correctAnswer = value;
      explanation = AppStrings.code == 'tr'
          ? '🛡️ Kalkanın seni korudu!'
          : '🛡️ Your shield saved you!';
    }

    final xpGain = _xpBoostActive ? 20 : 10;

    setState(() {
      _submitting = false;
      _answered = true;
      _isCorrect = correct;
      _correctAnswer = correctAnswer.isNotEmpty ? correctAnswer : value;
      _explanation = explanation;
      if (correct) {
        _correct++;
        _combo++;
        if (_combo > _maxCombo) _maxCombo = _combo;
        _xpTrigger++;
        _sessionXp += xpGain;
      } else {
        _combo = 0;
        if (widget.enforceHearts && !_unlimited) {
          _hearts = (_hearts - 1).clamp(0, _maxHearts);
        }
      }
    });

    if (correct) {
      unawaited(PracticeSoundService.onCorrect());
      _triggerComboMilestone(_combo);
    } else {
      unawaited(PracticeSoundService.onWrong());
      _shakeKey.currentState?.shake();
    }
    widget.onAnswerRecorded?.call(question, value, correct);
  }

  void _triggerComboMilestone(int combo) {
    if (combo < 5 || combo % 5 != 0) return;
    final isTr = AppStrings.code == 'tr';
    String text;
    Color color;
    if (combo >= 15) {
      text = isTr ? '🌟 EFSANE! ×$combo' : '🌟 LEGENDARY! ×$combo';
      color = const Color(0xFFFFD700);
    } else if (combo >= 10) {
      text = isTr ? '⚡ DURDURULAMAZ!' : '⚡ UNSTOPPABLE!';
      color = practiceOrange;
    } else {
      text = isTr ? '🔥 GÜZEL! ×$combo' : '🔥 NICE! ×$combo';
      color = const Color(0xFFFF5964);
    }

    setState(() {
      _showComboFlash = true;
      _comboFlashText = text;
      _comboFlashColor = color;
    });
    unawaited(PracticeSoundService.playStreak());
    _comboCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _showComboFlash = false);
    });
  }

  void _checkMotivation() {
    final total = widget.questions.length;
    final remaining = total - _index;
    final isTr = AppStrings.code == 'tr';
    String? msg;
    if (total >= 6 && _index == total ~/ 2) {
      msg = isTr
          ? 'Yarısını geçtin! Harika gidiyorsun 💪'
          : 'Halfway! Great job 💪';
    } else if (remaining == 3 && total > 4) {
      msg =
          isTr ? '3 soru kaldı! Neredeyse bitti 🎯' : '3 to go! Almost done 🎯';
    } else if (remaining == 1 && total > 2) {
      msg = isTr ? 'Son soru! Göster kendini ⭐' : 'Last one! Show your best ⭐';
    }
    if (msg != null) setState(() => _motivation = msg);
  }

  bool _localCorrect(PracticeQuestion question, String value) {
    final answer = question.answer.trim().toLowerCase();
    // Cevap bilinmiyorsa "doğru" sayma (istismar/yanıltma önlenir).
    if (answer.isEmpty) return false;
    return value.trim().toLowerCase() == answer;
  }

  Future<void> _continue() async {
    if (widget.enforceHearts && !_unlimited && _hearts <= 0) {
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
      // Backend başarısızsa SAHTE yerel dolum yapma.
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
      final questions = await _repository.loadAdaptiveQuestions(limit: 3);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PracticeSessionScreen(
            title: 'Tekrar pratigi',
            questions: questions,
            enforceHearts: false,
            onComplete: (c, t) async => '+1 can kazandin!',
          ),
        ),
      );
      if (!mounted) return;
      setState(() => _hearts = _hearts <= 0 ? 1 : _hearts);
      await _advance();
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

  Future<void> _advance() async {
    if (_index + 1 >= widget.questions.length) {
      setState(() => _submitting = true);
      final message =
          await widget.onComplete(_correct, widget.questions.length);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _finished = true;
        _resultMessage = message;
      });
      final isPerfect = _correct == widget.questions.length;
      if (isPerfect) {
        unawaited(PracticeSoundService.onLevelUp());
      } else {
        unawaited(PracticeSoundService.onLessonComplete());
      }
      return;
    }
    setState(() {
      _index++;
      _answerValue = null;
      _answered = false;
      _isCorrect = false;
      _correctAnswer = null;
      _explanation = '';
    });
    _checkMotivation();
  }

  // ── Power-up aksiyonları ──────────────────────────────────────────────────
  Future<void> _useHint() async {
    if (_hints <= 0 || _answered) return;
    setState(() {
      _hints--;
      _answerValue = _question.answer;
    });
    await showPowerUpOverlay(context, type: 'hint');
  }

  Future<void> _activateShield() async {
    if (_shields <= 0 || _shieldActive) return;
    setState(() => _shieldActive = true);
    await showPowerUpOverlay(context, type: 'shield');
  }

  Future<void> _activateBoost() async {
    if (_xpBoostActive) return;
    setState(() => _xpBoostActive = true);
    await showPowerUpOverlay(context, type: 'boost');
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';

    // İçerik yoksa boş listede çökme; dürüst boş durum göster.
    if (widget.questions.isEmpty) {
      return PracticeTheme(
        child: Scaffold(
          backgroundColor: const Color(0xFFF6FAFF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6FAFF),
            elevation: 0,
            foregroundColor: practiceInk,
            title: Text(widget.title),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                isTr
                    ? 'Şu an gösterilecek içerik yok. Lütfen daha sonra tekrar dene.'
                    : 'No content to show right now. Please try again later.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: practiceMuted, fontSize: 16),
              ),
            ),
          ),
        ),
      );
    }

    final isPerfect = _finished && _correct == widget.questions.length;

    return PracticeTheme(
      allowGuest: widget.guest,
      child: Scaffold(
        backgroundColor:
            isPerfect ? const Color(0xFFFFFDE7) : const Color(0xFFF6FAFF),
        appBar: AppBar(
          backgroundColor:
              isPerfect ? const Color(0xFFFFFDE7) : const Color(0xFFF6FAFF),
          elevation: 0,
          foregroundColor: practiceInk,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                // ── Oturum XP sayacı ──
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: practiceYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: practiceYellow, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: Text(
                          '$_sessionXp XP',
                          key: ValueKey(_sessionXp),
                          style: const TextStyle(
                            color: Color(0xFFAA7700),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          actions: widget.enforceHearts
              ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Center(
                      child: HeartsCounter(hearts: _hearts, max: _maxHearts),
                    ),
                  ),
                ]
              : null,
        ),
        body: SafeArea(
          child: _finished
              ? _buildResult(context)
              : Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                      child: Column(
                        children: [
                          // İlerleme çubuğu
                          PracticeProgressBar(
                            value: (_index + 1) / widget.questions.length,
                            height: 14,
                          ),
                          const SizedBox(height: 4),

                          // 🎮 Power-up çubuğu (cevap verilmeden önce)
                          if (!_answered)
                            _PowerUpBar(
                              hints: _hints,
                              shields: _shields,
                              shieldActive: _shieldActive,
                              xpBoostActive: _xpBoostActive,
                              onHint: _useHint,
                              onShield: _activateShield,
                              onBoost: _activateBoost,
                            ),

                          // Combo rozeti
                          SizedBox(
                            height: 34,
                            child: Center(child: ComboBadge(count: _combo)),
                          ),

                          // Soru
                          Expanded(
                            child: PracticeShakeWidget(
                              key: _shakeKey,
                              child: AnimatedSwitcher(
                                duration: AppMotion.normal,
                                child: PracticeQuestionView(
                                  key: ValueKey(_index),
                                  question: _question,
                                  value: _answerValue,
                                  answered: _answered,
                                  isCorrect: _isCorrect,
                                  correctAnswer: _correctAnswer,
                                  onChanged: (v) {
                                    if (_answered) return;
                                    setState(() => _answerValue = v);
                                    unawaited(PracticeSoundService.onTap());
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Cevap feedback / kontrol butonu
                          if (_answered)
                            AnswerFeedbackBar(
                              correct: _isCorrect,
                              message: _isCorrect
                                  ? (isTr ? 'Mükemmel! 🎉' : 'Excellent! 🎉')
                                  : (isTr ? 'Yanlış oldu 😢' : 'Not quite 😢'),
                              correctAnswer:
                                  _isCorrect ? '' : (_correctAnswer ?? ''),
                              explanation: _explanation,
                              continueLabel: _hearts <= 0
                                  ? (isTr ? 'CANLARI DOLDUR' : 'REFILL')
                                  : (_index + 1 >= widget.questions.length
                                      ? (isTr ? 'BİTİR 🏆' : 'FINISH 🏆')
                                      : (isTr ? 'DEVAM ET →' : 'CONTINUE →')),
                              onContinue: _continue,
                            )
                          else
                            Practice3DButton(
                              label: _submitting
                                  ? '...'
                                  : (isTr ? 'KONTROL ET' : 'CHECK'),
                              onPressed: (_answerValue == null || _submitting)
                                  ? null
                                  : _check,
                            ),
                        ],
                      ),
                    ),

                    // XP yukarı uçan badge
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 120,
                      child: IgnorePointer(
                        child: Center(
                          child: XpFloater(
                            amount: _xpBoostActive ? 20 : 10,
                            trigger: _xpTrigger,
                          ),
                        ),
                      ),
                    ),

                    // Motivasyon toast
                    if (_motivation != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 14,
                        child: IgnorePointer(
                          child: Center(
                            child: PracticeMotivationToast(
                              key: ValueKey(_motivation),
                              message: _motivation!,
                              onDone: () {
                                if (mounted) {
                                  setState(() => _motivation = null);
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                    // 🔥 Combo milestone tam ekran flaşı
                    if (_showComboFlash)
                      IgnorePointer(
                        child: Container(
                          color: _comboFlashColor.withValues(alpha: 0.07),
                          alignment: Alignment.center,
                          child: Text(
                            _comboFlashText,
                            style: TextStyle(
                              color: _comboFlashColor,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color:
                                      _comboFlashColor.withValues(alpha: 0.55),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                          )
                              .animate(key: ValueKey(_comboFlashText))
                              .scaleXY(
                                begin: 0.3,
                                end: 1.2,
                                duration: 320.ms,
                                curve: Curves.elasticOut,
                              )
                              .then(delay: 500.ms)
                              .fadeOut(duration: 450.ms),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Sonuç ekranı ──────────────────────────────────────────────────────────
  Widget _buildResult(BuildContext context) {
    final total = widget.questions.length;
    final isPerfect = _correct == total;
    final accuracy = total == 0 ? 0 : (_correct / total * 100).round();
    final isTr = AppStrings.code == 'tr';

    return PracticeConfettiOverlay(
      active: true,
      child: Container(
        decoration: isPerfect
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                ),
              )
            : null,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
          children: [
            // Trophy / Mascot
            Center(
              child: isPerfect
                  ? Text('🏆', style: const TextStyle(fontSize: 110))
                      .animate()
                      .scaleXY(
                          begin: 0.1,
                          end: 1.25,
                          duration: 750.ms,
                          curve: Curves.elasticOut)
                      .then()
                      .scaleXY(begin: 1.25, end: 1.0, duration: 220.ms)
                  : PracticeMascot(
                      size: 120,
                      mood: _correct > total ~/ 2
                          ? PracticeMascotMood.excited
                          : PracticeMascotMood.sad,
                    ),
            ),
            const SizedBox(height: 18),

            // Başlık
            Text(
              isPerfect
                  ? (isTr ? '✨ MÜKEMMEL! ✨' : '✨ PERFECT! ✨')
                  : (isTr ? 'Oturum tamamlandı!' : 'Session complete!'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isPerfect ? const Color(0xFFB8860B) : practiceInk,
                fontSize: isPerfect ? 30 : 26,
                fontWeight: FontWeight.w900,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.35),

            const SizedBox(height: 22),

            // Stat kartları
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    emoji: '✅',
                    label: isTr ? 'Doğru' : 'Correct',
                    value: '$_correct/$total',
                    color: practiceGreen,
                    delay: 100,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    emoji: '🎯',
                    label: isTr ? 'Doğruluk' : 'Accuracy',
                    value: '$accuracy%',
                    color: practiceBlue,
                    delay: 200,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    emoji: '⚡',
                    label: 'XP',
                    value: '+$_sessionXp',
                    color: practiceYellow,
                    delay: 300,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (_maxCombo >= 2)
              _StatCard(
                emoji: '🔥',
                label: isTr ? 'En İyi Seri' : 'Best Combo',
                value: '×$_maxCombo',
                color: practiceOrange,
                delay: 380,
              ),

            if ((_resultMessage ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _resultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: practiceGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],

            const SizedBox(height: 28),

            PracticePrimaryButton(
              label: isTr ? 'BİTİR 🎉' : 'FINISH 🎉',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// İç widget'lar
// ══════════════════════════════════════════════════════════════════════════════

/// Hint / Shield / 2×XP güç çubuğu
class _PowerUpBar extends StatelessWidget {
  const _PowerUpBar({
    required this.hints,
    required this.shields,
    required this.shieldActive,
    required this.xpBoostActive,
    required this.onHint,
    required this.onShield,
    required this.onBoost,
  });

  final int hints;
  final int shields;
  final bool shieldActive;
  final bool xpBoostActive;
  final VoidCallback onHint;
  final VoidCallback onShield;
  final VoidCallback onBoost;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PowerBtn(
            emoji: '💡',
            label: 'x$hints',
            active: hints > 0,
            color: practiceYellow,
            onTap: onHint,
          ),
          const SizedBox(width: 10),
          _PowerBtn(
            emoji: '🛡️',
            label: shieldActive ? 'ON' : 'x$shields',
            active: shields > 0 && !shieldActive,
            glow: shieldActive,
            color: practiceBlue,
            onTap: onShield,
          ),
          const SizedBox(width: 10),
          _PowerBtn(
            emoji: '⚡',
            label: xpBoostActive ? '2X' : 'Boost',
            active: !xpBoostActive,
            glow: xpBoostActive,
            color: practiceOrange,
            onTap: onBoost,
          ),
        ],
      ),
    );
  }
}

class _PowerBtn extends StatelessWidget {
  const _PowerBtn({
    required this.emoji,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
    this.glow = false,
  });

  final String emoji;
  final String label;
  final bool active;
  final bool glow;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget btn = GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.13)
              : Colors.grey.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: glow
                ? color
                : (active
                    ? color.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.25)),
            width: glow ? 2.5 : 1.5,
          ),
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.38),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? color : Colors.grey,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );

    if (glow) {
      btn = btn
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 1400.ms, color: color.withValues(alpha: 0.28));
    }
    return btn;
  }
}

/// Sonuç ekranı stat kartı
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.delay,
  });

  final String emoji;
  final String label;
  final String value;
  final Color color;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.35);
  }
}
