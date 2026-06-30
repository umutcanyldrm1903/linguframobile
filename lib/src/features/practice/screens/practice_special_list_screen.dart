import 'package:flutter/material.dart';

import 'practice_visuals.dart';

class PracticeSpecialListScreen extends StatelessWidget {
  const PracticeSpecialListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.auto_stories_rounded,
        'Hikayeler',
        'Diyalog ve anlama soruları',
        '/practice/story',
        practiceBlue
      ),
      (
        Icons.radio_rounded,
        'Radio',
        'Transcript ve dinleme dersi',
        '/practice/radio',
        practiceOrange
      ),
      (
        Icons.explore_rounded,
        'Macera',
        'Senaryo içinde doğru aksiyon',
        '/practice/adventure',
        practiceGreen
      ),
      (
        Icons.timer_rounded,
        'Challenge',
        'Süreli oyunlu pratik',
        '/practice/challenge',
        practicePurple
      ),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: practiceInk,
        centerTitle: true,
        title: const Text('Özel İçerikler',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          for (final item in items)
            _SpecialCard(
              icon: item.$1,
              title: item.$2,
              subtitle: item.$3,
              route: item.$4,
              color: item.$5,
            ),
        ],
      ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 0),
    );
  }
}

class _SpecialCard extends StatelessWidget {
  const _SpecialCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: .35), width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 42),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: practiceInk,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: practiceMuted, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
