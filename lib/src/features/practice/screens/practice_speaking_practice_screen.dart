import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import '../practice_trial_lesson_cta.dart';
import 'practice_visuals.dart';

class PracticeSpeakingPracticeScreen extends StatefulWidget {
  const PracticeSpeakingPracticeScreen({super.key});

  @override
  State<PracticeSpeakingPracticeScreen> createState() =>
      _PracticeSpeakingPracticeScreenState();
}

class _PracticeSpeakingPracticeScreenState
    extends State<PracticeSpeakingPracticeScreen> {
  final PracticeApiService _api = const PracticeApiService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final AudioRecorder _recorder = AudioRecorder();
  final TextEditingController _spokenController = TextEditingController();
  List<String> _targets = [
    'I would like a coffee, please.',
    'Could you tell me where the train station is?',
    'I have a reservation for tonight.',
  ];

  int _targetIndex = 0;
  bool _listening = false;
  bool _submitting = false;
  bool _speechReady = false;
  bool _recordingAudio = false;
  bool _audioSubmitting = false;
  double _soundLevel = 0;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Map<String, dynamic>? _analysis;
  List<Map<String, dynamic>> _history = [];
  String _status = '';

  String get _target => _targets[_targetIndex];

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(.44);
    _loadPrompts();
    _loadHistory();
  }

  Future<void> _loadPrompts() async {
    final data = await _api.getSpeakingPrompts();
    final raw = data?['items'];
    if (!mounted || raw is! List) return;
    final prompts = raw
        .whereType<Map>()
        .map((item) => '${item['text'] ?? ''}'.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (prompts.isNotEmpty) {
      setState(() {
        _targets = prompts;
        _targetIndex = 0;
      });
    }
  }

  Future<void> _loadHistory() async {
    final data = await _api.getSpeakingHistory();
    if (!mounted) return;
    final raw = data?['attempts'];
    setState(() {
      _history = raw is List
          ? raw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : [];
    });
  }

  @override
  void dispose() {
    _spokenController.dispose();
    _speech.stop();
    _tts.stop();
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _listening = false;
          _soundLevel = 0;
        });
      }
      return;
    }

    final ready = _speechReady ||
        await _speech.initialize(
          onStatus: (status) {
            if (status == 'done' && mounted) {
              setState(() {
                _listening = false;
                _soundLevel = 0;
              });
            }
          },
        );
    if (!ready) {
      setState(() => _status = 'Mikrofon izni veya STT hazır değil.');
      return;
    }

    setState(() {
      _speechReady = true;
      _listening = true;
      _status = 'Dinliyorum...';
    });
    await _speech.listen(
      localeId: 'en_US',
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      onSoundLevelChange: (level) {
        if (mounted) setState(() => _soundLevel = level);
      },
      onResult: (result) {
        _spokenController.text = result.recognizedWords;
        _spokenController.selection = TextSelection.collapsed(
          offset: _spokenController.text.length,
        );
      },
    );
  }

  Future<void> _listenTarget() async {
    await _tts.stop();
    await _tts.speak(_target);
  }

  Future<void> _toggleAiAudioRecording() async {
    if (kIsWeb) {
      setState(() {
        _status =
            'Tarayıcıda AI ses dosyası analizi yerine mikrofon STT kullanılır.';
      });
      await _toggleListening();
      return;
    }

    if (_recordingAudio) {
      final path = await _recorder.stop();
      await _amplitudeSubscription?.cancel();
      if (!mounted) return;
      setState(() {
        _recordingAudio = false;
        _audioSubmitting = true;
        _soundLevel = 0;
        _status = 'Ses AI tarafından analiz ediliyor...';
      });
      if (path == null || path.isEmpty) {
        setState(() {
          _audioSubmitting = false;
          _status = 'Ses kaydı oluşturulamadı.';
        });
        return;
      }
      final data = await _api.submitSpeakingAudioAttempt(
        targetText: _target,
        filePath: path,
      );
      if (!mounted) return;
      final rawAnalysis = data?['analysis'];
      setState(() {
        _audioSubmitting = false;
        _spokenController.text = '${data?['transcript'] ?? ''}';
        _analysis =
            rawAnalysis is Map ? Map<String, dynamic>.from(rawAnalysis) : null;
        _status = data == null
            ? 'AI ses analizi yapılamadı. Backend anahtarını kontrol et.'
            : 'Gerçek ses dosyası analiz edildi.';
      });
      if (data != null) unawaited(_loadHistory());
      final score = _asInt(_analysis?['overall_score']);
      if (score >= 70) {
        PracticeSoundService.onCorrect();
      } else {
        PracticeSoundService.onWrong();
      }
      return;
    }

    await _speech.stop();
    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      setState(() => _status = 'Mikrofon izni verilmedi.');
      return;
    }
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/practice_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
      path: path,
    );
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((amplitude) {
      if (mounted) setState(() => _soundLevel = amplitude.current);
    });
    if (!mounted) return;
    setState(() {
      _recordingAudio = true;
      _status = 'AI analizi için kayıt yapılıyor. Bitince tekrar dokun.';
    });
  }

  Future<void> _submit() async {
    final spoken = _spokenController.text.trim();
    if (spoken.isEmpty) {
      setState(() => _status = 'Önce cümleyi söyle veya yaz.');
      return;
    }
    setState(() {
      _submitting = true;
      _status = '';
    });
    final data = await _api.submitSpeakingAttempt({
      'target_text': _target,
      'spoken_text': spoken,
    });
    final attempt = data?['attempt'];
    final directAnalysis = data?['analysis'];
    Object? analysis = directAnalysis;
    if (analysis is! Map && attempt is Map) {
      final feedback = attempt['feedback'];
      if (feedback is Map) {
        analysis = feedback['analysis'];
      }
    }
    // Kelime bazli detay submit yaniti vermediyse pronunciation servisinden al.
    if (analysis is! Map) {
      final pron = await _api.analyzePronunciation({
        'target_text': _target,
        'spoken_text': spoken,
      });
      final pronAnalysis = pron?['analysis'];
      if (pronAnalysis is Map) analysis = pronAnalysis;
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _analysis = analysis is Map ? Map<String, dynamic>.from(analysis) : null;
      _status = data == null ? 'Bağlantı yok, sonuç kaydedilemedi.' : '';
    });
    if (data != null) unawaited(_loadHistory());
    final score = _asInt(_analysis?['overall_score']);
    if (score >= 70) {
      PracticeSoundService.onCorrect();
    } else {
      PracticeSoundService.onWrong();
    }
  }

  void _nextTarget() {
    setState(() {
      _targetIndex = (_targetIndex + 1) % _targets.length;
      _spokenController.clear();
      _analysis = null;
      _status = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final score = _asInt(_analysis?['overall_score']);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF9AA0A6),
        centerTitle: true,
        title: const Text(
          'Konuşma',
          style: TextStyle(
            color: Color(0xFFB0B0B0),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PracticeMascot(
                        size: 108,
                        mood: score >= 80
                            ? PracticeMascotMood.excited
                            : PracticeMascotMood.thinking,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: PracticeSpeechBubble(
                          text: 'Cümleyi söyle, kelime kelime skorunu görelim.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _TargetCard(
                    target: _target,
                    onListen: _listenTarget,
                  ),
                  const SizedBox(height: 14),
                  _VoiceMeter(
                    active: _listening || _recordingAudio,
                    level: _soundLevel,
                  ),
                  const SizedBox(height: 12),
                  PracticePrimaryButton(
                    label: _audioSubmitting
                        ? 'AI ANALİZ EDİYOR...'
                        : (_recordingAudio
                            ? 'KAYDI BİTİR VE ANALİZ ET'
                            : 'AI SES ANALİZİ'),
                    color: _recordingAudio ? practiceOrange : practicePurple,
                    onPressed:
                        _audioSubmitting ? null : _toggleAiAudioRecording,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _spokenController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Söyle veya buraya yaz...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide:
                            const BorderSide(color: practiceLine, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide:
                            const BorderSide(color: practiceLine, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PracticePrimaryButton(
                          label: _listening ? 'DURDUR' : 'MIKROFON',
                          color: _listening ? practiceOrange : practiceBlue,
                          onPressed: () => _toggleListening(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PracticePrimaryButton(
                          label: _submitting ? 'SKOR...' : 'SKORLA',
                          onPressed: _submitting ? null : () => _submit(),
                        ),
                      ),
                    ],
                  ),
                  if (_status.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: practiceMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (_analysis != null) ...[
                    const SizedBox(height: 18),
                    _ScorePanel(analysis: _analysis!),
                    const SizedBox(height: 14),
                    const PracticeTrialLessonCta(
                      compact: true,
                      source: 'practice_speaking',
                      sourceLabel: 'Konuşmanı',
                    ),
                  ],
                  if (_history.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const Text(
                      'Geçmiş denemeler',
                      style: TextStyle(
                        color: practiceInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final attempt in _history.take(8))
                      _HistoryRow(attempt: attempt),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: PracticePrimaryButton(
                label: 'SONRAKİ CÜMLE',
                color: practiceBlue,
                onPressed: _nextTarget,
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
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.target,
    required this.onListen,
  });

  final String target;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE8F7), width: 2),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onListen,
            icon: const Icon(Icons.volume_up_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              target,
              style: const TextStyle(
                color: practiceInk,
                fontSize: 20,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceMeter extends StatelessWidget {
  const _VoiceMeter({
    required this.active,
    required this.level,
  });

  final bool active;
  final double level;

  @override
  Widget build(BuildContext context) {
    final normalized = ((level + 2) / 12).clamp(0.06, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active
            ? practiceBlue.withValues(alpha: .08)
            : const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: practiceLine),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.mic_rounded : Icons.mic_none_rounded,
            color: active ? practiceBlue : practiceMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: active ? normalized : 0,
                minHeight: 10,
                backgroundColor: practiceLine,
                valueColor: const AlwaysStoppedAnimation(practiceBlue),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            active ? 'Dinleniyor' : 'Hazır',
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

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({required this.analysis});

  final Map<String, dynamic> analysis;

  @override
  Widget build(BuildContext context) {
    final words = analysis['words'];
    final score = _asInt(analysis['overall_score']);
    return PracticeConfettiOverlay(
      active: score >= 85,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: practiceLine, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$score%',
                  style: TextStyle(
                    color: score >= 70 ? practiceGreen : practiceOrange,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Telaffuz skoru',
                    style: TextStyle(
                      color: practiceInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${analysis['tip'] ?? ''}',
              style: const TextStyle(
                color: practiceMuted,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            if (words is List)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in words.whereType<Map>())
                    _WordChip(
                      word: '${item['target'] ?? ''}',
                      status: '${item['status'] ?? 'missing'}',
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word, required this.status});

  final String word;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'correct' => practiceGreen,
      'close' => practiceBlue,
      'weak' => practiceOrange,
      _ => const Color(0xFFFF5964),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(
        word,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.attempt});

  final Map<String, dynamic> attempt;

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final score = _asInt(attempt['score']);
    final color = score >= 70 ? practiceGreen : practiceOrange;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: .14),
            child: Text(
              '$score',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${attempt['target_text'] ?? attempt['spoken_text'] ?? ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
