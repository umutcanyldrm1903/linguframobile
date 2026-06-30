import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

class PracticeAdventurePlayScreen extends StatefulWidget {
  const PracticeAdventurePlayScreen({super.key});

  @override
  State<PracticeAdventurePlayScreen> createState() =>
      _PracticeAdventurePlayScreenState();
}

class _PracticeAdventurePlayScreenState
    extends State<PracticeAdventurePlayScreen> {
  final PracticeApiService _api = const PracticeApiService();

  bool _loading = true;
  bool _submitting = false;
  List<Map<String, dynamic>> _items = const [];
  Map<String, dynamic>? _adventure;
  List<Map<String, dynamic>> _scenes = const [];
  int _sceneIndex = 0;
  int? _selectedChoiceId;
  String _feedback = '';
  final List<int> _choiceIds = [];
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    setState(() => _loading = true);
    final data = await _api.getAdventures();
    if (!mounted) return;
    setState(() {
      _items = _asList(data?['items']);
      _adventure = null;
      _loading = false;
    });
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final id = _asInt(item['id']);
    if (id <= 0) return;
    setState(() => _loading = true);
    final data = await _api.getAdventure(id);
    if (!mounted) return;
    final rawItem = data?['item'];
    final detail = rawItem is Map
        ? Map<String, dynamic>.from(rawItem)
        : <String, dynamic>{};
    final content = _asMap(detail['content']);
    setState(() {
      _adventure = detail;
      _scenes = _asList(content['scenes']);
      _sceneIndex = 0;
      _selectedChoiceId = null;
      _feedback = '';
      _choiceIds.clear();
      _result = null;
      _loading = false;
    });
  }

  void _selectChoice(Map<String, dynamic> choice) {
    if (_selectedChoiceId != null || _submitting) return;
    final id = _asInt(choice['id']);
    if (id <= 0) return;
    final correct = choice['is_correct'] == true ||
        choice['is_correct'] == 1 ||
        choice['is_correct'] == '1';
    setState(() {
      _selectedChoiceId = id;
      _choiceIds.add(id);
      _feedback = '${choice['feedback'] ?? ''}'.trim();
      if (_feedback.isEmpty) {
        _feedback = correct
            ? 'Doğru seçim. Senaryo ilerliyor.'
            : 'Bu seçim uygun değildi. Açıklamayı inceleyip devam et.';
      }
    });
    if (correct) {
      PracticeSoundService.onCorrect();
    } else {
      PracticeSoundService.onWrong();
    }
  }

  Future<void> _continue() async {
    final scene = _scenes[_sceneIndex];
    final choices = _asList(scene['choices']);
    if (choices.isNotEmpty && _selectedChoiceId == null) return;

    final selected = choices.cast<Map<String, dynamic>?>().firstWhere(
          (choice) => _asInt(choice?['id']) == _selectedChoiceId,
          orElse: () => null,
        );
    final nextSceneId = _asInt(selected?['next_scene_id']);
    var nextIndex = _sceneIndex + 1;
    if (nextSceneId > 0) {
      final mapped = _scenes.indexWhere(
        (candidate) => _asInt(candidate['id']) == nextSceneId,
      );
      if (mapped >= 0) nextIndex = mapped;
    }

    if (nextIndex >= _scenes.length) {
      await _finish();
      return;
    }
    setState(() {
      _sceneIndex = nextIndex;
      _selectedChoiceId = null;
      _feedback = '';
    });
  }

  Future<void> _finish() async {
    final id = _asInt(_adventure?['id']);
    if (id <= 0 || _submitting) return;
    setState(() => _submitting = true);
    final result = await _api.completeAdventure(id, choiceIds: _choiceIds);
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
          '${_adventure?['title'] ?? 'Macera'}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: _adventure == null
            ? null
            : IconButton(
                onPressed: _loadList,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
      body: _loading
          ? const Center(
              child: MascotLoading(message: 'Macera hazırlanıyor...'),
            )
          : _adventure == null
              ? _buildList()
              : _buildAdventure(),
    );
  }

  Widget _buildList() {
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Aktif macera içeriği bulunamadı.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: practiceMuted,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        const Row(
          children: [
            PracticeMascot(
              size: 106,
              mood: PracticeMascotMood.excited,
            ),
            SizedBox(width: 12),
            Expanded(
              child: PracticeSpeechBubble(
                text: 'Bir senaryo seç ve kararlarınla ilerle.',
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
                    backgroundColor: Color(0xFFFFF0DF),
                    child: Icon(
                      Icons.explore_rounded,
                      color: practiceOrange,
                      size: 31,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['title'] ?? 'Macera'}',
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
                    '${item['xp_reward'] ?? 20} XP',
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

  Widget _buildAdventure() {
    if (_result != null) {
      final passed = _result?['passed'] == true;
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
                passed ? 'Macera tamamlandı!' : 'Bu rotayı tekrar dene',
                textAlign: TextAlign.center,
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
                label: passed ? 'MACERALARA DÖN' : 'TEKRAR DENE',
                onPressed: passed ? _loadList : () => _open(_adventure!),
              ),
            ],
          ),
        ),
      );
    }

    if (_scenes.isEmpty) {
      return const Center(
        child: Text(
          'Bu maceranın sahneleri henüz hazırlanmadı.',
          style: TextStyle(
            color: practiceMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    final scene = _scenes[_sceneIndex];
    final choices = _asList(scene['choices']);
    final imageUrl = '${scene['image_url'] ?? ''}'.trim();
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_sceneIndex + 1) / _scenes.length,
          minHeight: 8,
          backgroundColor: practiceLine,
          valueColor: const AlwaysStoppedAnimation(practiceOrange),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 190,
                    fit: BoxFit.cover,
                  ),
                ),
              if (imageUrl.isNotEmpty) const SizedBox(height: 16),
              Text(
                '${scene['title'] ?? 'Sahne ${_sceneIndex + 1}'}',
                style: const TextStyle(
                  color: practiceOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${scene['scene_text'] ?? ''}',
                style: const TextStyle(
                  color: practiceInk,
                  fontSize: 22,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              for (final choice in choices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ChoiceButton(
                    choice: choice,
                    selectedId: _selectedChoiceId,
                    onPressed: () => _selectChoice(choice),
                  ),
                ),
              if (_feedback.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: practiceLine),
                  ),
                  child: Text(
                    _feedback,
                    style: const TextStyle(
                      color: practiceInk,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: PracticePrimaryButton(
            label: _submitting
                ? 'KAYDEDİLİYOR...'
                : (_sceneIndex + 1 == _scenes.length
                    ? 'MACERAYI BİTİR'
                    : 'DEVAM'),
            color: practiceOrange,
            onPressed:
                _submitting || (choices.isNotEmpty && _selectedChoiceId == null)
                    ? null
                    : _continue,
          ),
        ),
      ],
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

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.choice,
    required this.selectedId,
    required this.onPressed,
  });

  final Map<String, dynamic> choice;
  final int? selectedId;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final id = _asInt(choice['id']);
    final selected = selectedId == id;
    final locked = selectedId != null;
    final correct = choice['is_correct'] == true ||
        choice['is_correct'] == 1 ||
        choice['is_correct'] == '1';
    final color = !selected
        ? Colors.white
        : (correct ? const Color(0xFFEAF8E2) : const Color(0xFFFFECEA));
    final border =
        !selected ? practiceLine : (correct ? practiceGreen : practiceRed);
    return InkWell(
      onTap: locked ? null : onPressed,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${choice['label'] ?? ''}',
                style: const TextStyle(
                  color: practiceInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (selected)
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: border,
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
