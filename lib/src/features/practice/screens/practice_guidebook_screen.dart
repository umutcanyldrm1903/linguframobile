import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../practice_api_service.dart';
import '../practice_tts_service.dart';
import 'practice_characters.dart';
import 'practice_guidebook_content.dart';
import 'practice_visuals.dart';

/// Defter bazlı dilbilgisi rehberi.
class PracticeGuidebookScreen extends StatefulWidget {
  const PracticeGuidebookScreen({super.key, this.initialUnit = 0});

  final int initialUnit;

  @override
  State<PracticeGuidebookScreen> createState() =>
      _PracticeGuidebookScreenState();
}

class _PracticeGuidebookScreenState extends State<PracticeGuidebookScreen> {
  final PracticeApiService _api = const PracticeApiService();
  List<GuidebookUnit> _units = practiceGuidebook;
  late int _selected =
      widget.initialUnit.clamp(0, practiceGuidebook.length - 1);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getGuidebook();
    final raw = data?['units'];
    if (!mounted || raw is! List || raw.isEmpty) return;
    final parsed = raw.whereType<Map>().map((u) {
      final m = Map<String, dynamic>.from(u);
      final phrases = (m['phrases'] is List)
          ? (m['phrases'] as List).whereType<Map>().map((p) {
              final pm = Map<String, dynamic>.from(p);
              return GuidebookKeyPhrase(
                phrase: '${pm['phrase'] ?? ''}',
                meaning: '${pm['meaning'] ?? ''}',
              );
            }).toList()
          : <GuidebookKeyPhrase>[];
      return GuidebookUnit(
        unit: '${m['unit'] ?? ''}',
        title: '${m['title'] ?? ''}',
        tipTitle: '${m['tip_title'] ?? ''}',
        tip: '${m['tip'] ?? ''}',
        phrases: phrases,
      );
    }).toList();
    if (parsed.isEmpty) return;
    setState(() {
      _units = parsed;
      _selected = _selected.clamp(0, _units.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unit = _units[_selected];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: practiceInk,
        centerTitle: true,
        title: Text(AppStrings.code == 'tr' ? 'Rehber' : 'Guide',
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          // Ünite seçici
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _units.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = i == _selected;
                return ChoiceChip(
                  label: Text(_units[i].unit),
                  selected: selected,
                  onSelected: (_) => setState(() => _selected = i),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              PracticeCharacterAvatar(
                character: practiceCharacters.first,
                size: 72,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  unit.title,
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Gramer ipucu
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDDE8F7), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, color: practiceBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        unit.tipTitle,
                        style: const TextStyle(
                          color: practiceInk,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  unit.tip,
                  style: const TextStyle(
                    color: practiceMuted,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            AppStrings.code == 'tr' ? 'Anahtar cümleler' : 'Key phrases',
            style: const TextStyle(
              color: practiceInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (final phrase in unit.phrases)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: practiceLine, width: 2),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => PracticeTtsService.speak(phrase.phrase),
                    icon: const Icon(Icons.volume_up_rounded,
                        color: practiceBlue),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phrase.phrase,
                          style: const TextStyle(
                            color: practiceInk,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          phrase.meaning,
                          style: const TextStyle(
                            color: practiceMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
