import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

class PracticeRadioLessonScreen extends StatefulWidget {
  const PracticeRadioLessonScreen({super.key});

  @override
  State<PracticeRadioLessonScreen> createState() =>
      _PracticeRadioLessonScreenState();
}

class _PracticeRadioLessonScreenState extends State<PracticeRadioLessonScreen> {
  final PracticeApiService _api = const PracticeApiService();
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  bool _loading = true;
  bool _audioLoading = false;
  bool _submitting = false;
  List<Map<String, dynamic>> _items = const [];
  Map<String, dynamic>? _radio;
  List<Map<String, dynamic>> _questions = const [];
  int _questionIndex = 0;
  String? _selectedAnswer;
  final List<Map<String, dynamic>> _answers = [];
  Map<String, dynamic>? _result;
  double _speed = 1;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-US');
    _loadList();
  }

  Future<void> _loadList() async {
    await _player.stop();
    await _tts.stop();
    setState(() => _loading = true);
    final data = await _api.getRadio();
    if (!mounted) return;
    setState(() {
      _items = _asList(data?['items']);
      _radio = null;
      _loading = false;
    });
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final id = _asInt(item['id']);
    if (id <= 0) return;
    setState(() => _loading = true);
    final data = await _api.getRadioLesson(id);
    if (!mounted) return;
    final rawItem = data?['item'];
    final detail = rawItem is Map
        ? Map<String, dynamic>.from(rawItem)
        : <String, dynamic>{};
    final content = _asMap(detail['content']);
    setState(() {
      _radio = detail;
      _questions = _asList(content['questions']);
      _questionIndex = 0;
      _selectedAnswer = null;
      _answers.clear();
      _result = null;
      _loading = false;
    });
    final audioUrl = '${content['audio_url'] ?? ''}'.trim();
    if (audioUrl.isNotEmpty) {
      setState(() => _audioLoading = true);
      try {
        await _player.setUrl(audioUrl);
      } on Object {
        // Transcript TTS remains available when remote audio cannot load.
      }
      if (mounted) setState(() => _audioLoading = false);
    }
  }

  Future<void> _toggleAudio() async {
    final content = _asMap(_radio?['content']);
    final audioUrl = '${content['audio_url'] ?? ''}'.trim();
    final transcript =
        '${content['transcript'] ?? content['body'] ?? ''}'.trim();
    if (audioUrl.isNotEmpty && _player.audioSource != null) {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.setSpeed(_speed);
        await _player.play();
      }
      if (mounted) setState(() {});
      return;
    }
    if (transcript.isNotEmpty) {
      await _tts.setSpeechRate(_speed == .75 ? .38 : .5);
      await _tts.speak(transcript);
    }
  }

  Future<void> _submitAnswer() async {
    final answer = _selectedAnswer;
    if (answer == null) return;
    final question = _questions[_questionIndex];
    _answers.add({
      'question_id': _asInt(question['id']),
      'answer': answer,
    });
    if (_questionIndex + 1 < _questions.length) {
      setState(() {
        _questionIndex++;
        _selectedAnswer = null;
      });
      return;
    }

    final id = _asInt(_radio?['id']);
    setState(() => _submitting = true);
    final result = await _api.completeRadio(id, answers: _answers);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _result = result;
    });
    if (result?['passed'] == true) {
      PracticeSoundService.playComplete();
    } else {
      PracticeSoundService.onWrong();
    }
  }

  Future<void> _completeWithoutQuestions() async {
    final id = _asInt(_radio?['id']);
    setState(() => _submitting = true);
    final result = await _api.completeRadio(id);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _result = result;
    });
    PracticeSoundService.playComplete();
  }

  @override
  void dispose() {
    _player.dispose();
    _tts.stop();
    super.dispose();
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
          '${_radio?['title'] ?? 'Dinleme Stüdyosu'}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: _radio == null
            ? null
            : IconButton(
                onPressed: _loadList,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
      body: _loading
          ? const Center(
              child: MascotLoading(message: 'Yayın hazırlanıyor...'),
            )
          : _radio == null
              ? _buildList()
              : _buildLesson(),
    );
  }

  Widget _buildList() {
    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'Aktif dinleme içeriği bulunamadı.',
          style: TextStyle(
            color: practiceMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        const Row(
          children: [
            PracticeMascot(size: 106, mood: PracticeMascotMood.happy),
            SizedBox(width: 12),
            Expanded(
              child: PracticeSpeechBubble(
                text: 'Yayını dinle, hızını ayarla ve soruları çöz.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        for (final item in _items)
          InkWell(
            onTap: () => _open(item),
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
                  const CircleAvatar(
                    radius: 29,
                    backgroundColor: Color(0xFFE8F8F5),
                    child: Icon(
                      Icons.radio_rounded,
                      color: practiceBlue,
                      size: 31,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['title'] ?? 'Dinleme'}',
                          style: const TextStyle(
                            color: practiceInk,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${item['description'] ?? ''}',
                          style: const TextStyle(
                            color: practiceMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item['xp_reward'] ?? 15} XP',
                    style: const TextStyle(
                      color: practiceBlue,
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

  Widget _buildLesson() {
    if (_result != null) return _buildResult();
    final content = _asMap(_radio?['content']);
    final transcript =
        '${content['transcript'] ?? content['body'] ?? ''}'.trim();
    final hasAudio = '${content['audio_url'] ?? ''}'.trim().isNotEmpty ||
        transcript.isNotEmpty;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: practiceBlue.withValues(alpha: .3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.graphic_eq_rounded,
                      color: practiceBlue,
                      size: 64,
                    ),
                    const SizedBox(height: 10),
                    PracticePrimaryButton(
                      label: _audioLoading
                          ? 'SES YÜKLENİYOR...'
                          : (_player.playing ? 'DURAKLAT' : 'DİNLE'),
                      color: practiceBlue,
                      onPressed:
                          hasAudio && !_audioLoading ? _toggleAudio : null,
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<double>(
                      segments: const [
                        ButtonSegment(value: .75, label: Text('Yavaş')),
                        ButtonSegment(value: 1, label: Text('Normal')),
                      ],
                      selected: {_speed},
                      onSelectionChanged: (selection) async {
                        final speed = selection.first;
                        setState(() => _speed = speed);
                        if (_player.audioSource != null) {
                          await _player.setSpeed(speed);
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (transcript.isNotEmpty) ...[
                const SizedBox(height: 16),
                ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: const Text(
                    'Transcript',
                    style: TextStyle(
                      color: practiceInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                      child: Text(
                        transcript,
                        style: const TextStyle(
                          color: practiceMuted,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_questions.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Soru ${_questionIndex + 1}/${_questions.length}',
                  style: const TextStyle(
                    color: practiceBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_questions[_questionIndex]['question_text'] ?? ''}',
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 21,
                    height: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                for (final option
                    in _stringList(_questions[_questionIndex]['options']))
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
                              ? practiceBlue.withValues(alpha: .12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedAnswer == option
                                ? practiceBlue
                                : practiceLine,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          option,
                          style: const TextStyle(
                            color: practiceInk,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: PracticePrimaryButton(
            label: _submitting
                ? 'KAYDEDİLİYOR...'
                : (_questions.isEmpty
                    ? 'YAYINI TAMAMLA'
                    : (_questionIndex + 1 == _questions.length
                        ? 'TESTİ BİTİR'
                        : 'SONRAKİ SORU')),
            color: practiceBlue,
            onPressed: _submitting
                ? null
                : (_questions.isEmpty
                    ? _completeWithoutQuestions
                    : (_selectedAnswer == null ? null : _submitAnswer)),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final passed = _result?['passed'] == true ||
        (_questions.isEmpty && _result?['completed'] == true);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PracticeMascot(
              size: 140,
              mood: passed
                  ? PracticeMascotMood.excited
                  : PracticeMascotMood.thinking,
            ),
            const SizedBox(height: 16),
            Text(
              passed ? 'Yayın tamamlandı!' : 'Bir kez daha dinle',
              style: const TextStyle(
                color: practiceInk,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '%${_asInt(_result?['score'])} başarı · +${_asInt(_result?['xp_awarded'])} XP',
              style: const TextStyle(
                color: practiceMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            PracticePrimaryButton(
              label: passed ? 'YAYINLARA DÖN' : 'TEKRAR DENE',
              color: practiceBlue,
              onPressed: passed ? _loadList : () => _open(_radio!),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _asMap(Object? value) {
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) {
          if (item is Map) return '${item['label'] ?? item['value'] ?? ''}';
          return '$item';
        })
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
