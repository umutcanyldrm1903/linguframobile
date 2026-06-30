import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

class PracticeMatchMadnessScreen extends StatefulWidget {
  const PracticeMatchMadnessScreen({super.key});

  @override
  State<PracticeMatchMadnessScreen> createState() =>
      _PracticeMatchMadnessScreenState();
}

class _PracticeMatchMadnessScreenState
    extends State<PracticeMatchMadnessScreen> {
  final PracticeApiService _api = const PracticeApiService();
  final Random _random = Random();

  int _totalSeconds = 45;
  int _seconds = 45;
  int _xpAwarded = 0;
  String? _sessionToken;
  int? _selectedLeft;
  int? _selectedRight;
  bool _loading = true;
  bool _finished = false;
  bool _submitting = false;
  Timer? _timer;
  List<_MatchPair> _pairs = const [];
  List<_MatchItem> _leftItems = const [];
  List<_MatchItem> _rightItems = const [];
  final Set<int> _matchedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _timer?.cancel();
    setState(() {
      _loading = true;
      _finished = false;
      _submitting = false;
      _matchedIds.clear();
      _selectedLeft = null;
      _selectedRight = null;
      _xpAwarded = 0;
    });
    final data = await _api.getMatchMadness();
    if (!mounted) return;
    final raw = data?['pairs'];
    final pairs = raw is List
        ? raw
            .whereType<Map>()
            .map((item) => _MatchPair.fromMap(Map<String, dynamic>.from(item)))
            .where((item) =>
                item.id > 0 && item.left.isNotEmpty && item.right.isNotEmpty)
            .toList(growable: false)
        : const <_MatchPair>[];
    final duration = _asInt(data?['duration_seconds'], fallback: 45);
    setState(() {
      _pairs = pairs;
      _leftItems = pairs
          .map((pair) => _MatchItem(pair.id, pair.left))
          .toList(growable: false)
        ..shuffle(_random);
      _rightItems = pairs
          .map((pair) => _MatchItem(pair.id, pair.right))
          .toList(growable: false)
        ..shuffle(_random);
      _sessionToken = '${data?['session_token'] ?? ''}';
      _totalSeconds = duration;
      _seconds = duration;
      _loading = false;
    });
    if (pairs.isNotEmpty && _sessionToken!.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _finished) return;
        if (_seconds <= 1) {
          setState(() => _seconds = 0);
          _finish();
        } else {
          setState(() => _seconds--);
        }
      });
    }
  }

  void _selectLeft(int id) {
    if (_finished || _matchedIds.contains(id)) return;
    setState(() => _selectedLeft = id);
    _tryMatch();
  }

  void _selectRight(int id) {
    if (_finished || _matchedIds.contains(id)) return;
    setState(() => _selectedRight = id);
    _tryMatch();
  }

  void _tryMatch() {
    final left = _selectedLeft;
    final right = _selectedRight;
    if (left == null || right == null) return;
    if (left == right) {
      setState(() {
        _matchedIds.add(left);
        _selectedLeft = null;
        _selectedRight = null;
      });
      PracticeSoundService.onCorrect();
      if (_matchedIds.length == _pairs.length) {
        _finish();
      }
    } else {
      setState(() {
        _selectedLeft = null;
        _selectedRight = null;
      });
      PracticeSoundService.onWrong();
    }
  }

  Future<void> _finish() async {
    if (_finished || _submitting) return;
    _timer?.cancel();
    final token = _sessionToken;
    setState(() => _submitting = true);
    final response = token == null || token.isEmpty
        ? null
        : await _api.completeMatchMadness(token, _matchedIds.toList());
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _finished = true;
      _xpAwarded = _asInt(response?['xp_awarded']);
    });
    PracticeSoundService.playComplete();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        title: Text(isTr ? 'Hızlı Eşleştirme' : 'Match Madness'),
        backgroundColor: const Color(0xFFF6FAFF),
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: MascotLoading(message: 'Kelimeler hazırlanıyor...'),
            )
          : _pairs.isEmpty
              ? _EmptyMatch(onRetry: _load)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _HudBox(
                              icon: Icons.timer_rounded,
                              value: '$_seconds',
                              label: isTr ? 'saniye' : 'seconds',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _HudBox(
                              icon: Icons.bolt_rounded,
                              value: '${_matchedIds.length}/${_pairs.length}',
                              label: isTr ? 'eşleşme' : 'matches',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value:
                              _totalSeconds == 0 ? 0 : _seconds / _totalSeconds,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            practiceGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_finished)
                        Expanded(
                          child: _MatchResult(
                            matched: _matchedIds.length,
                            total: _pairs.length,
                            xp: _xpAwarded,
                            onReplay: _load,
                          ),
                        )
                      else
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: ListView(
                                  children: [
                                    for (final item in _leftItems)
                                      _WordTile(
                                        text: item.text,
                                        selected: _selectedLeft == item.id,
                                        matched: _matchedIds.contains(item.id),
                                        onTap: () => _selectLeft(item.id),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ListView(
                                  children: [
                                    for (final item in _rightItems)
                                      _WordTile(
                                        text: item.text,
                                        selected: _selectedRight == item.id,
                                        matched: _matchedIds.contains(item.id),
                                        onTap: () => _selectRight(item.id),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}

class _MatchPair {
  const _MatchPair(this.id, this.left, this.right);

  final int id;
  final String left;
  final String right;

  factory _MatchPair.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'];
    final id = rawId is num ? rawId.toInt() : int.tryParse('$rawId') ?? 0;
    return _MatchPair(id, '${map['left'] ?? ''}', '${map['right'] ?? ''}');
  }
}

class _MatchItem {
  const _MatchItem(this.id, this.text);

  final int id;
  final String text;
}

class _EmptyMatch extends StatelessWidget {
  const _EmptyMatch({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PracticeMascot(
              size: 110,
              mood: PracticeMascotMood.thinking,
            ),
            const SizedBox(height: 14),
            const Text(
              'Eşleştirme için yeterli kelime bulunamadı.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: practiceInk,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            PracticePrimaryButton(label: 'TEKRAR DENE', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _MatchResult extends StatelessWidget {
  const _MatchResult({
    required this.matched,
    required this.total,
    required this.xp,
    required this.onReplay,
  });

  final int matched;
  final int total;
  final int xp;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PracticeMascot(
            size: 130,
            mood: PracticeMascotMood.excited,
          ),
          const SizedBox(height: 12),
          Text(
            '$matched / $total eşleşme',
            style: const TextStyle(
              color: practiceInk,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+$xp XP sunucuya kaydedildi',
            style: const TextStyle(
              color: practiceMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          PracticePrimaryButton(label: 'YENİDEN OYNA', onPressed: onReplay),
        ],
      ),
    );
  }
}

class _HudBox extends StatelessWidget {
  const _HudBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brand),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.text,
    required this.selected,
    required this.matched,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool matched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedOpacity(
        opacity: matched ? 0.28 : 1,
        duration: const Duration(milliseconds: 180),
        child: InkWell(
          onTap: matched ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? practiceBlue : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? practiceBlue : const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
