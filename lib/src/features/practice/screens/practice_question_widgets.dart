import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/motion/app_motion.dart';
import '../practice_repository.dart';
import '../practice_tts_service.dart';
import 'practice_visuals.dart';

/// Soru tipine göre doğru giriş arayüzünü seçen tek giriş noktası.
///
/// Tüm tipler kullanıcının cevabını tek bir [String]'e indirger ([onChanged]
/// ile parent'a bildirilir); backend `answerQuestion` tek string ile doğrular.
/// [answered] true olduğunda girişler kilitlenir ve [correctAnswer] (server
/// yanıtı) ile doğru/yanlış renklendirme yapılır.
class PracticeQuestionView extends StatelessWidget {
  const PracticeQuestionView({
    required this.question,
    required this.value,
    required this.answered,
    required this.isCorrect,
    required this.correctAnswer,
    required this.onChanged,
    super.key,
  });

  final PracticeQuestion question;
  final String? value;
  final bool answered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String?> onChanged;

  bool get _isChoice => question.options.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionHeader(question: question, answered: answered),
          const SizedBox(height: 18),
          _input(),
        ],
      ),
    );
  }

  Widget _input() {
    switch (question.type) {
      case 'true_false':
        if (_isChoice) return _choice(grid: false);
        return _TrueFalseQuestion(
          value: value,
          answered: answered,
          correctAnswer: correctAnswer,
          onChanged: onChanged,
        );
      case 'image_choice':
        return _choice(grid: true);
      case 'fill_blank':
      case 'grammar_fix':
      case 'image_write':
      case 'translation_to_native':
      case 'translation_from_native':
        return _TextInputQuestion(
          key: ValueKey('text_${question.id}'),
          answered: answered,
          isCorrect: isCorrect,
          correctAnswer: correctAnswer,
          onChanged: onChanged,
        );
      case 'order_sentence':
      case 'word_bank':
        return _WordBuilderQuestion(
          key: ValueKey('builder_${question.id}'),
          words: question.wordBank,
          answered: answered,
          isCorrect: isCorrect,
          correctAnswer: correctAnswer,
          onChanged: onChanged,
        );
      case 'match_pairs':
        return _MatchPairsQuestion(
          key: ValueKey('pairs_${question.id}'),
          pairs: question.pairs,
          answered: answered,
          onChanged: onChanged,
        );
      case 'vocabulary_flashcard':
        return _FlashcardQuestion(
          key: ValueKey('flash_${question.id}'),
          question: question,
          onChanged: onChanged,
        );
      case 'listening_choice':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ListenControl(question: question),
            const SizedBox(height: 14),
            _choice(grid: false),
          ],
        );
      case 'listening_write':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ListenControl(question: question),
            const SizedBox(height: 14),
            _TextInputQuestion(
              key: ValueKey('ltext_${question.id}'),
              answered: answered,
              isCorrect: isCorrect,
              correctAnswer: correctAnswer,
              onChanged: onChanged,
            ),
          ],
        );
      default:
        // multiple_choice, dialogue_select, conversation_complete,
        // grammar_select, synonym_antonym, story_question, radio_question,
        // boss_question, adventure_action, timed_challenge ve bilinmeyen tipler.
        if (_isChoice) return _choice(grid: false);
        return _TextInputQuestion(
          key: ValueKey('text_${question.id}'),
          answered: answered,
          isCorrect: isCorrect,
          correctAnswer: correctAnswer,
          onChanged: onChanged,
        );
    }
  }

  Widget _choice({required bool grid}) {
    return _ChoiceQuestion(
      options: question.options,
      selected: value,
      answered: answered,
      correctAnswer: correctAnswer,
      grid: grid,
      onChanged: onChanged,
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.question, required this.answered});

  final PracticeQuestion question;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final image = question.imageUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: practiceLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PracticeMascot(size: 74, mood: PracticeMascotMood.thinking),
              const SizedBox(width: 12),
              Expanded(
                child: question.glossary.isEmpty
                    ? PracticeSpeechBubble(
                        text: question.prompt.isNotEmpty
                            ? question.prompt
                            : question.questionText,
                      )
                    : _GlossaryBubble(
                        text: question.prompt.isNotEmpty
                            ? question.prompt
                            : question.questionText,
                        glossary: question.glossary,
                      ),
              ),
            ],
          ),
          if (image != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                image,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          if (question.questionText.isNotEmpty &&
              question.questionText != question.prompt) ...[
            const SizedBox(height: 16),
            Text(
              question.questionText,
              style: const TextStyle(
                color: practiceInk,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ],
          if (question.hint.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              question.hint,
              style: const TextStyle(color: practiceMuted, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}

/// Konuşma balonu görünümünde, sözlükteki kelimelere dokununca çeviri gösteren
/// metin (kelime tap-çeviri davranışı).
class _GlossaryBubble extends StatelessWidget {
  const _GlossaryBubble({required this.text, required this.glossary});

  final String text;
  final Map<String, String> glossary;

  @override
  Widget build(BuildContext context) {
    final words = text.split(RegExp(r'(\s+)'));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE2E2E2), width: 2),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final word in words)
            if (word.trim().isEmpty)
              const SizedBox(width: 2)
            else
              _glossaryWord(word),
        ],
      ),
    );
  }

  Widget _glossaryWord(String word) {
    final clean =
        word.replaceAll(RegExp(r'[^\wığüşöçİĞÜŞÖÇ]'), '').toLowerCase();
    final meaning = glossary[clean];
    const baseStyle = TextStyle(
      color: Color(0xFF555555),
      fontSize: 19,
      height: 1.35,
      fontWeight: FontWeight.w700,
    );
    if (meaning == null) {
      return Text(word, style: baseStyle);
    }
    return Tooltip(
      message: meaning,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: false,
      decoration: BoxDecoration(
        color: practiceInk,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
      child: Text(
        word,
        style: baseStyle.copyWith(
          color: practiceBlue,
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
        ),
      ),
    );
  }
}

class _ChoiceQuestion extends StatelessWidget {
  const _ChoiceQuestion({
    required this.options,
    required this.selected,
    required this.answered,
    required this.correctAnswer,
    required this.grid,
    required this.onChanged,
  });

  final List<PracticeQuestionOption> options;
  final String? selected;
  final bool answered;
  final String? correctAnswer;
  final bool grid;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (grid) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
        children: [
          for (final option in options)
            _OptionTile(
              option: option,
              isSelected: selected == option.value,
              isCorrect: answered && correctAnswer == option.value,
              answered: answered,
              showImage: true,
              onTap: () => onChanged(option.value),
            ),
        ],
      );
    }
    return Column(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionTile(
              option: option,
              isSelected: selected == option.value,
              isCorrect: answered && correctAnswer == option.value,
              answered: answered,
              showImage: false,
              onTap: () => onChanged(option.value),
            ),
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.isCorrect,
    required this.answered,
    required this.showImage,
    required this.onTap,
  });

  final PracticeQuestionOption option;
  final bool isSelected;
  final bool isCorrect;
  final bool answered;
  final bool showImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    if (answered && isCorrect) {
      background = const Color(0xFF02C39A);
      foreground = Colors.white;
    } else if (answered && isSelected) {
      background = const Color(0xFFFF5964);
      foreground = Colors.white;
    } else if (isSelected) {
      background = practiceBlue;
      foreground = Colors.white;
    } else {
      background = Colors.white;
      foreground = practiceInk;
    }
    final border = background == Colors.white ? practiceLine : background;
    final image = option.imageUrl;

    final content = showImage
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (image != null)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_outlined, size: 40),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                option.label,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: foreground, fontWeight: FontWeight.w900),
              ),
            ],
          )
        : Text(
            option.label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          );

    final isPlain = background == Colors.white;
    return PressableScale(
      onTap: answered ? null : onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.all(showImage ? 12 : 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPlain ? practiceLine : border,
            width: 2,
          ),
          // 3B alt kenar.
          boxShadow: [
            BoxShadow(
              color: isPlain ? const Color(0xFFE5E5E5) : practiceDarken(border),
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: content,
      ),
    );
  }
}

class _TrueFalseQuestion extends StatelessWidget {
  const _TrueFalseQuestion({
    required this.value,
    required this.answered,
    required this.correctAnswer,
    required this.onChanged,
  });

  final String? value;
  final bool answered;
  final String? correctAnswer;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Row(
      children: [
        Expanded(
          child: _OptionTile(
            option: PracticeQuestionOption(
              label: isTr ? 'Doğru' : 'True',
              value: 'true',
            ),
            isSelected: value == 'true',
            isCorrect: answered && correctAnswer == 'true',
            answered: answered,
            showImage: false,
            onTap: () => onChanged('true'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OptionTile(
            option: PracticeQuestionOption(
              label: isTr ? 'Yanlış' : 'False',
              value: 'false',
            ),
            isSelected: value == 'false',
            isCorrect: answered && correctAnswer == 'false',
            answered: answered,
            showImage: false,
            onTap: () => onChanged('false'),
          ),
        ),
      ],
    );
  }
}

class _TextInputQuestion extends StatefulWidget {
  const _TextInputQuestion({
    required this.answered,
    required this.isCorrect,
    required this.correctAnswer,
    required this.onChanged,
    super.key,
  });

  final bool answered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String?> onChanged;

  @override
  State<_TextInputQuestion> createState() => _TextInputQuestionState();
}

class _TextInputQuestionState extends State<_TextInputQuestion> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final color = !widget.answered
        ? practiceLine
        : (widget.isCorrect ? practiceGreen : const Color(0xFFFF5964));
    return TextField(
      controller: _controller,
      enabled: !widget.answered,
      minLines: 1,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontWeight: FontWeight.w800, color: practiceInk),
      decoration: InputDecoration(
        hintText: isTr ? 'Cevabını yaz…' : 'Type your answer…',
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: color, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: practiceBlue, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
      onChanged: (text) {
        final trimmed = text.trim();
        widget.onChanged(trimmed.isEmpty ? null : trimmed);
      },
    );
  }
}

class _WordBuilderQuestion extends StatefulWidget {
  const _WordBuilderQuestion({
    required this.words,
    required this.answered,
    required this.isCorrect,
    required this.correctAnswer,
    required this.onChanged,
    super.key,
  });

  final List<String> words;
  final bool answered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String?> onChanged;

  @override
  State<_WordBuilderQuestion> createState() => _WordBuilderQuestionState();
}

class _WordBuilderQuestionState extends State<_WordBuilderQuestion> {
  late List<String> _bank;
  final List<String> _chosen = [];

  @override
  void initState() {
    super.initState();
    _bank = List<String>.from(widget.words);
  }

  void _pick(int index) {
    if (widget.answered) return;
    setState(() {
      _chosen.add(_bank.removeAt(index));
    });
    _emit();
  }

  void _remove(int index) {
    if (widget.answered) return;
    setState(() {
      _bank.add(_chosen.removeAt(index));
    });
    _emit();
  }

  void _emit() {
    widget.onChanged(_chosen.isEmpty ? null : _chosen.join(' '));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: practiceLine, width: 2),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _chosen.length; i++)
                _WordChip(
                  label: _chosen[i],
                  filled: true,
                  onTap: () => _remove(i),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _bank.length; i++)
              _WordChip(
                label: _bank[i],
                filled: false,
                onTap: () => _pick(i),
              ),
          ],
        ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? practiceBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: filled ? practiceBlue : practiceLine, width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : practiceInk,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

/// İki kolon eşleştirme. Backend tek-string `practiceAnswerMatches` mantığıyla
/// tam doğrulayamayabileceğinden tamamlanınca "left=right,..." normalize edilmiş
/// string gönderilir; lesson ekranı bu tip için lokal doğruluğu da dikkate alır.
class _MatchPairsQuestion extends StatefulWidget {
  const _MatchPairsQuestion({
    required this.pairs,
    required this.answered,
    required this.onChanged,
    super.key,
  });

  final List<List<String>> pairs;
  final bool answered;
  final ValueChanged<String?> onChanged;

  @override
  State<_MatchPairsQuestion> createState() => _MatchPairsQuestionState();
}

class _MatchPairsQuestionState extends State<_MatchPairsQuestion> {
  late final List<String> _left;
  late final List<String> _right;
  final Map<String, String> _matched = {};
  String? _activeLeft;

  @override
  void initState() {
    super.initState();
    _left = widget.pairs.map((pair) => pair[0]).toList();
    _right = widget.pairs.map((pair) => pair[1]).toList()..shuffle();
  }

  void _tapLeft(String value) {
    if (widget.answered) return;
    setState(() => _activeLeft = _activeLeft == value ? null : value);
  }

  void _tapRight(String value) {
    if (widget.answered || _activeLeft == null) return;
    setState(() {
      _matched[_activeLeft!] = value;
      _activeLeft = null;
    });
    if (_matched.length == _left.length) {
      final joined = _left.map((left) => '$left=${_matched[left]}').join(',');
      widget.onChanged(joined);
    } else {
      widget.onChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              for (final value in _left)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PairTile(
                    label: value,
                    active: _activeLeft == value,
                    done: _matched.containsKey(value),
                    onTap: () => _tapLeft(value),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              for (final value in _right)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PairTile(
                    label: value,
                    active: false,
                    done: _matched.containsValue(value),
                    onTap: () => _tapRight(value),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PairTile extends StatelessWidget {
  const _PairTile({
    required this.label,
    required this.active,
    required this.done,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = done ? practiceGreen : (active ? practiceBlue : Colors.white);
    final foreground = (done || active) ? Colors.white : practiceInk;
    return PressableScale(
      onTap: done ? null : onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color == Colors.white ? practiceLine : color,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

/// Kelime kartı: ön yüz (terim) → "Çevir" → arka yüz (anlam). Cezasız bir
/// tanıma egzersizidir; kart açıldığında "Devam" aktifleşir.
class _FlashcardQuestion extends StatefulWidget {
  const _FlashcardQuestion({
    required this.question,
    required this.onChanged,
    super.key,
  });

  final PracticeQuestion question;
  final ValueChanged<String?> onChanged;

  @override
  State<_FlashcardQuestion> createState() => _FlashcardQuestionState();
}

class _FlashcardQuestionState extends State<_FlashcardQuestion> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final front = widget.question.prompt.isNotEmpty
        ? widget.question.prompt
        : widget.question.questionText;
    final back = widget.question.answer.isNotEmpty
        ? widget.question.answer
        : (widget.question.meta['meaning']?.toString() ??
            (isTr ? 'Anlamı' : 'Meaning'));
    return Column(
      children: [
        PressableScale(
          onTap: () {
            setState(() => _revealed = !_revealed);
            widget.onChanged('known');
          },
          child: AnimatedContainer(
            duration: AppMotion.fast,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: _revealed ? practicePurple : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _revealed ? practicePurple : practiceLine,
                width: 2,
              ),
            ),
            child: Text(
              _revealed ? back : front,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _revealed ? Colors.white : practiceInk,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isTr ? 'Karta dokunup çevir' : 'Tap the card to flip',
          style: const TextStyle(color: practiceMuted),
        ),
      ],
    );
  }
}

/// `meta.audio_url` varsa just_audio ile oynatır; yoksa transcript
/// (question_text) göstererek sorunun yine çözülebilmesini sağlar.
class _ListenControl extends StatefulWidget {
  const _ListenControl({required this.question});

  final PracticeQuestion question;

  @override
  State<_ListenControl> createState() => _ListenControlState();
}

class _ListenControlState extends State<_ListenControl> {
  AudioPlayer? _player;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final url = widget.question.audioUrl;
    if (url != null) {
      _player = AudioPlayer();
      _player!.setUrl(url).then((_) {
        if (mounted) setState(() => _ready = true);
      }).catchError((_) {
        if (mounted) setState(() => _ready = false);
      });
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final player = _player;
    if (player == null) {
      final audioText = widget.question.audioText;
      if (audioText != null) {
        await PracticeTtsService.speak(audioText);
      }
      return;
    }
    try {
      await player.seek(Duration.zero);
      await player.play();
    } on Object {
      // sessizce yut
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    if (_player == null || !_ready) {
      final audioText = widget.question.audioText;
      if (audioText != null) {
        return PressableScale(
          onTap: _play,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: practiceBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.record_voice_over_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  isTr ? 'Dinle' : 'Listen',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Ses yok / yüklenemedi → transcript fallback.
      final transcript = widget.question.questionText;
      if (transcript.isEmpty) {
        return Text(
          isTr ? 'Ses bu derste mevcut değil.' : 'Audio is not available.',
          style: const TextStyle(color: practiceMuted),
        );
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: practiceLine, width: 2),
        ),
        child: Text(
          transcript,
          style: const TextStyle(
            color: practiceInk,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
      );
    }
    return PressableScale(
      onTap: _play,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: practiceBlue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Text(
              isTr ? 'Dinle' : 'Listen',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
