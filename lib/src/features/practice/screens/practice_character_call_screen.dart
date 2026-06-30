import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../practice_api_service.dart';
import '../practice_premium_offer_service.dart';
import 'practice_characters.dart';
import 'practice_visuals.dart';

class PracticeCharacterCallScreen extends StatefulWidget {
  const PracticeCharacterCallScreen({super.key});

  @override
  State<PracticeCharacterCallScreen> createState() =>
      _PracticeCharacterCallScreenState();
}

class _PracticeCharacterCallScreenState
    extends State<PracticeCharacterCallScreen> {
  final PracticeApiService _api = const PracticeApiService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _message = TextEditingController();
  final List<Map<String, String>> _messages = [];

  int? _sessionId;
  bool _loading = false;
  bool _listening = false;
  bool _speechReady = false;
  bool _talking = false;
  bool _routeArgumentsRead = false;
  bool _voiceSelected = false;
  double _soundLevel = 0;
  String _scenario = 'Cafe order';
  String _characterName = 'Lingu';

  @override
  void initState() {
    super.initState();
    _tts.setStartHandler(() {
      if (mounted) setState(() => _talking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _talking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _talking = false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgumentsRead) return;
    _routeArgumentsRead = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      final name = '${arguments['character_name'] ?? ''}'.trim();
      final scenario = '${arguments['scenario'] ?? ''}'.trim();
      if (name.isNotEmpty) _characterName = name;
      if (scenario.isNotEmpty) _scenario = scenario;
    }
    unawaited(_configureTts());
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _message.dispose();
    super.dispose();
  }

  Future<void> _configureTts({String language = 'en-US'}) async {
    try {
      await _tts.awaitSpeakCompletion(false);
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        const [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ],
        IosTextToSpeechAudioMode.spokenAudio,
      );
      await _tts.setLanguage(language);
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(language == 'tr-TR' ? 0.42 : 0.34);
      await _tts.setPitch(_pitchForCharacter(_characterName));
      if (!_voiceSelected && language == 'en-US') {
        await _selectClearEnglishVoice();
      }
    } on Object {
      // Some devices do not expose a selectable TTS voice. The chat still works.
    }
  }

  Future<void> _selectClearEnglishVoice() async {
    final voices = await _tts.getVoices;
    if (voices is! List) return;

    final parsed = voices
        .whereType<Map>()
        .map((voice) => voice.map((key, value) => MapEntry('$key', '$value')))
        .where((voice) {
      final locale = (voice['locale'] ?? voice['language'] ?? '').toString();
      return locale.toLowerCase().replaceAll('_', '-').startsWith('en-us');
    }).toList(growable: false);

    if (parsed.isEmpty) return;
    final preferred = parsed.firstWhere(
      (voice) {
        final name = (voice['name'] ?? '').toString().toLowerCase();
        return name.contains('samantha') ||
            name.contains('ava') ||
            name.contains('alex') ||
            name.contains('google') ||
            name.contains('enhanced') ||
            name.contains('premium');
      },
      orElse: () => parsed.first,
    );

    final name = preferred['name'];
    final locale = preferred['locale'] ?? preferred['language'];
    if (name == null || locale == null) return;
    await _tts.setVoice({'name': name, 'locale': locale});
    _voiceSelected = true;
  }

  double _pitchForCharacter(String name) {
    return switch (name.toLowerCase()) {
      'mina' => 1.08,
      'zara' => 1.04,
      'bao' => 0.92,
      'efe' => 0.98,
      _ => 1.0,
    };
  }

  String _speechLanguageFor(String text) {
    final lower = text.toLowerCase();
    final hasTurkishChars = RegExp('[çğıöşü]').hasMatch(lower);
    final looksTurkish = hasTurkishChars ||
        lower.contains('merhaba') ||
        lower.contains('teşekkür') ||
        lower.contains('premium') && lower.contains('devam');
    return looksTurkish ? 'tr-TR' : 'en-US';
  }

  String _clearSpeechText(String text) {
    return text
        .replaceAll(RegExp(r'[*_`#>]+'), ' ')
        .replaceAll(RegExp(r"[^\w\s.,!?;:'’-]", unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _speak(String text) async {
    final value = _clearSpeechText(text);
    if (value.isEmpty) return;
    await _tts.stop();
    await _configureTts(language: _speechLanguageFor(value));
    await _tts.speak(value);
  }

  Future<void> _start() async {
    setState(() => _loading = true);
    final data = await _api.startVideoCall({
      'scenario': _scenario,
      'character_name': _characterName,
    });
    if (!mounted) return;

    if (data?['premium_required'] == true) {
      setState(() => _loading = false);
      await PracticePremiumOfferService.instance.showOffer(
        context,
        trigger: PracticePremiumTrigger.characterCall,
      );
      return;
    }

    final rawMessages = data?['messages'];
    setState(() {
      _loading = false;
      _sessionId = _asInt(data?['session_id']);
      _scenario = '${data?['scenario'] ?? _scenario}';
      _characterName = '${data?['character_name'] ?? _characterName}';
      _messages
        ..clear()
        ..addAll(rawMessages is List
            ? rawMessages.whereType<Map>().map((item) => {
                  'role': '${item['role'] ?? 'assistant'}',
                  'content': '${item['content'] ?? ''}',
                })
            : [
                {
                  'role': 'assistant',
                  'content':
                      'Hi, I am $_characterName. What would you like to order?',
                },
              ]);
    });
    if (_messages.isNotEmpty) {
      unawaited(_speak(_messages.last['content'] ?? ''));
    }
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty || _loading) return;
    if (_sessionId == null) await _start();
    final sessionId = _sessionId;
    if (sessionId == null) return;

    setState(() {
      _loading = true;
      _messages.add({'role': 'user', 'content': text});
      _message.clear();
    });

    final data = await _api.sendVideoCallMessage({
      'session_id': sessionId,
      'message': text,
    });
    if (!mounted) return;

    if (data?['premium_required'] == true) {
      setState(() {
        _loading = false;
        _messages.add({
          'role': 'assistant',
          'content':
              'Ücretsiz görüşme sınırına ulaştın. Premium ile devam edebilirsin.',
        });
      });
      await PracticePremiumOfferService.instance.showOffer(
        context,
        trigger: PracticePremiumTrigger.characterCall,
      );
      return;
    }

    final reply =
        '${data?['reply'] ?? 'Good try. Say it in one complete sentence.'}';
    setState(() {
      _loading = false;
      _messages.add({'role': 'assistant', 'content': reply});
    });
    unawaited(_speak(reply));
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

    await _tts.stop();
    final ready = _speechReady ||
        await _speech.initialize(
          onStatus: (status) {
            if (!mounted) return;
            if (status == 'done' || status == 'notListening') {
              setState(() {
                _listening = false;
                _soundLevel = 0;
              });
            }
          },
        );
    if (!ready) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mikrofon veya konuşma tanıma hazır değil.'),
        ),
      );
      return;
    }

    setState(() {
      _speechReady = true;
      _listening = true;
      _soundLevel = 0;
    });
    await _speech.listen(
      localeId: 'en_US',
      listenFor: const Duration(seconds: 25),
      pauseFor: const Duration(seconds: 3),
      onSoundLevelChange: (level) {
        if (mounted) setState(() => _soundLevel = level);
      },
      onResult: (result) {
        _message.text = result.recognizedWords;
        _message.selection = TextSelection.collapsed(
          offset: _message.text.length,
        );
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          if (mounted) setState(() => _listening = false);
          unawaited(_send());
        }
      },
    );
  }

  Future<void> _end() async {
    await _speech.stop();
    await _tts.stop();
    final sessionId = _sessionId;
    if (sessionId != null) {
      await _api.endVideoCall({'session_id': sessionId});
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final character = practiceCharacterByName(_characterName);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FBFF),
        elevation: 0,
        foregroundColor: const Color(0xFF9AA0A6),
        centerTitle: true,
        title: const Text(
          'Karakterle Görüş',
          style: TextStyle(
            color: Color(0xFFB0B0B0),
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _end,
            child: const Text('BİTİR'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: practiceLine)),
              ),
              child: Column(
                children: [
                  AnimatedScale(
                    scale: _talking ? 1.08 : 1,
                    duration: const Duration(milliseconds: 220),
                    child: Container(
                      width: 150,
                      height: 150,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: character.color.withValues(alpha: .12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: character.color.withValues(alpha: .38),
                          width: 2,
                        ),
                      ),
                      child: PracticeCharacterAvatar(
                        character: character,
                        size: 130,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _characterName,
                    style: const TextStyle(
                      color: practiceInk,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    _scenario,
                    style: const TextStyle(
                      color: practiceMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _VoiceActivity(
                    active: _listening || _talking,
                    level: _talking ? 6 : _soundLevel,
                    label: _talking
                        ? '$_characterName konuşuyor'
                        : (_listening
                            ? 'Seni dinliyorum'
                            : 'Sesli görüşme hazır'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: PracticePrimaryButton(
                          label:
                              _loading ? 'BAĞLANIYOR...' : 'GÖRÜŞMEYİ BAŞLAT',
                          color: practiceBlue,
                          onPressed: _loading ? null : _start,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(18),
                      children: [
                        for (final message in _messages)
                          _CallBubble(
                            mine: message['role'] == 'user',
                            text: message['content'] ?? '',
                            onReplay: message['role'] == 'assistant'
                                ? () => _speak(message['content'] ?? '')
                                : null,
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Cevabını yaz veya mikrofonla söyle...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide:
                              const BorderSide(color: practiceLine, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _listening ? practiceOrange : practiceBlue,
                    ),
                    onPressed: _loading ? null : _toggleListening,
                    icon: Icon(
                      _listening ? Icons.stop_rounded : Icons.mic_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: practiceGreen),
                    onPressed: _loading ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
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

class _VoiceActivity extends StatelessWidget {
  const _VoiceActivity({
    required this.active,
    required this.level,
    required this.label,
  });

  final bool active;
  final double level;
  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = ((level + 2) / 12).clamp(0.08, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            final distance = (index - 3).abs();
            final height =
                active ? 8 + (30 * normalized * (1 - distance * .12)) : 8.0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 5,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: active ? practiceBlue : practiceLine,
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: practiceMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CallBubble extends StatelessWidget {
  const _CallBubble({
    required this.mine,
    required this.text,
    required this.onReplay,
  });

  final bool mine;
  final String text;
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: mine ? practiceGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          border: mine ? null : Border.all(color: practiceLine, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: mine ? Colors.white : practiceInk,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (onReplay != null) ...[
              const SizedBox(width: 6),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onReplay,
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: practiceBlue,
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
