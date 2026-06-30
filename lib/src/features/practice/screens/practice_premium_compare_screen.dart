import 'package:flutter/material.dart';

import 'practice_visuals.dart';

class PracticePremiumCompareScreen extends StatelessWidget {
  const PracticePremiumCompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Sınırsız can', true, true),
      ('Reklamsiz pratik', false, true),
      ('AI açıklama', 'Günlük limitli', true),
      ('Roleplay / karakter sohbeti', false, true),
      ('Offline paket', 'Sinirli', true),
      ('Gelismis istatistik', false, true),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: practiceInk,
        centerTitle: true,
        title: const Text(
          'Premium Karsilastir',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Row(
            children: const [
              PracticeMascot(size: 104, mood: PracticeMascotMood.proud),
              SizedBox(width: 12),
              Expanded(
                child: PracticeSpeechBubble(
                  text: 'Ücretsiz ve Premium pratik farklarını hızlıca gör.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: practiceLine, width: 2),
            ),
            child: Column(
              children: [
                const _CompareHeader(),
                for (final row in rows)
                  _CompareRow(
                    label: row.$1,
                    free: row.$2,
                    premium: row.$3,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PracticePrimaryButton(
            label: 'PREMIUM SEC',
            color: practiceBlue,
            onPressed: () => Navigator.pushNamed(context, '/practice/premium'),
          ),
        ],
      ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 0),
    );
  }
}

class _CompareHeader extends StatelessWidget {
  const _CompareHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F7FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Ozellik',
              style: TextStyle(
                color: practiceInk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Free',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: practiceInk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Premium',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: practiceInk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.free,
    required this.premium,
  });

  final String label;
  final Object free;
  final Object premium;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: practiceLine)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: practiceInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(child: _Cell(value: free)),
          Expanded(child: _Cell(value: premium, premium: true)),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.value, this.premium = false});

  final Object value;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    if (value is bool) {
      return Icon(
        value == true ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: value == true
            ? (premium ? practiceGreen : practiceBlue)
            : const Color(0xFFC7C7C7),
      );
    }
    return Text(
      '$value',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: practiceMuted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
