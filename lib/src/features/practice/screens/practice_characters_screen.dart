import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'practice_characters.dart';
import 'practice_visuals.dart';

class PracticeCharactersScreen extends StatelessWidget {
  const PracticeCharactersScreen({super.key});

  static const _scenarios = <String, String>{
    'Lingu': 'Kafede sipariş',
    'Mina': 'Yeni biriyle tanışma',
    'Efe': 'İş görüşmesi',
    'Zara': 'Seyahatte yol tarifi',
    'Bao': 'Restoranda konuşma',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: practiceKraft,
      appBar: AppBar(
        title: const Text('Konuşma Karakterleri'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: practicePaper,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: practiceLine, width: 1.5),
            ),
            child: const Row(
              children: [
                PracticeMascot(
                  size: 92,
                  mood: PracticeMascotMood.excited,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: PracticeSpeechBubble(
                    text:
                        'Bir karakter seç. Yazılı veya sesli konuşma pratiğine başlayalım.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < practiceCharacters.length; index++)
            _CharacterCard(
              character: practiceCharacters[index],
              scenario: _scenarios[practiceCharacters[index].name] ??
                  'Günlük konuşma',
              onTap: () => _openCharacter(
                context,
                practiceCharacters[index],
              ),
            )
                .animate(delay: Duration(milliseconds: index * 70))
                .fadeIn(duration: 260.ms)
                .slideX(begin: .08, end: 0),
        ],
      ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 0),
    );
  }

  void _openCharacter(
    BuildContext context,
    PracticeCharacter character,
  ) {
    Navigator.pushNamed(
      context,
      '/practice/character-call',
      arguments: {
        'character_name': character.name,
        'scenario': _scenarios[character.name] ?? 'Günlük konuşma',
      },
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    required this.scenario,
    required this.onTap,
  });

  final PracticeCharacter character;
  final String scenario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: practicePaper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: character.color.withValues(alpha: .42),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: character.color.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: PracticeCharacterAvatar(
                  character: character,
                  size: 66,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: const TextStyle(
                        color: practiceInk,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      character.persona,
                      style: const TextStyle(
                        color: practiceMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.forum_rounded,
                          color: character.color,
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            scenario,
                            style: TextStyle(
                              color: character.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: practiceMuted,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
