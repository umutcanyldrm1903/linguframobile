import 'package:flutter/material.dart';

import '../practice_api_service.dart';
import 'practice_visuals.dart';

class PracticeHubScreen extends StatefulWidget {
  const PracticeHubScreen({super.key});

  @override
  State<PracticeHubScreen> createState() => _PracticeHubScreenState();
}

class _PracticeHubScreenState extends State<PracticeHubScreen> {
  final PracticeApiService _api = const PracticeApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _cards = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getHub();
    final raw = data?['recommendations'];
    if (!mounted) return;
    setState(() {
      _cards = raw is List
          ? raw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false)
          : _fallbackCards();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF9AA0A6),
        centerTitle: true,
        title: const Text(
          'Tekrar merkezi',
          style: TextStyle(
            color: Color(0xFFB0B0B0),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: PracticeMascot(size: 110))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PracticeMascot(
                        size: 108,
                        mood: PracticeMascotMood.proud,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: PracticeSpeechBubble(
                          text: 'Zayıf alanlarını bugün burada kapatalım.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _HubCard(
                    title: 'Karakterlerle konuş',
                    subtitle:
                        'Lingu, Mina, Efe, Zara veya Bao ile sesli pratik yap.',
                    count: 5,
                    onTap: () =>
                        Navigator.pushNamed(context, '/practice/characters'),
                  ),
                  _HubCard(
                    title: 'AI konuşma koçu',
                    subtitle:
                        'Yanlış cevabını açıkla veya roleplay senaryosu başlat.',
                    count: 0,
                    onTap: () =>
                        Navigator.pushNamed(context, '/practice/ai-coach'),
                  ),
                  for (final card in _cards)
                    _HubCard(
                      title: '${card['title'] ?? 'Pratik'}',
                      subtitle: '${card['subtitle'] ?? ''}',
                      count: _asInt(card['count']),
                      onTap: () => _openRoute('${card['route'] ?? ''}'),
                    ),
                ],
              ),
      ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 0),
    );
  }

  void _openRoute(String route) {
    final normalized = route.replaceAll('-', '/');
    final mobileRoute = switch (route) {
      '/practice-mistakes' => '/practice/mistakes',
      '/practice-words' => '/practice/weak-words',
      '/practice-quests' => '/practice/daily-quests',
      '/practice-weekly-quests' => '/practice/weekly-quests',
      '/practice-hearts' => '/practice/hearts',
      '/practice-path' => '/practice/path',
      '/practice-lesson-intro' => '/practice/lesson',
      '/practice-daily-chests' => '/practice/daily-chests',
      '/practice-streak-milestones' => '/practice/streak-milestones',
      '/practice-streak-wager' => '/practice/streak-wager',
      '/practice-characters' => '/practice/characters',
      '/practice-character-call' => '/practice/character-call',
      '/practice-ai-coach' => '/practice/ai-coach',
      _ => normalized.startsWith('/practice') ? normalized : '/practice',
    };
    Navigator.pushNamed(context, mobileRoute);
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  List<Map<String, dynamic>> _fallbackCards() => const [
        {
          'title': 'Hatalarımı çalış',
          'subtitle': 'Yanlış yaptığın soruları tekrar çöz.',
          'route': '/practice-mistakes',
          'count': 2,
        },
        {
          'title': 'Zayıf kelimeler',
          'subtitle': 'Aralıklı tekrar ile kelimeleri güçlendir.',
          'route': '/practice-words',
          'count': 4,
        },
        {
          'title': 'Günlük hedef',
          'subtitle': 'Görev sandığını tamamla.',
          'route': '/practice-quests',
          'count': 1,
        },
      ];
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: practiceBlue.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: practiceBlue, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: practiceInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: practiceMuted,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (count > 0)
              Text(
                '$count',
                style: const TextStyle(
                  color: practiceOrange,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
