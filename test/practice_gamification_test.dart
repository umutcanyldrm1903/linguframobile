import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingufranca_mobile/src/features/practice/screens/practice_game_widgets.dart';
import 'package:lingufranca_mobile/src/features/practice/screens/practice_visuals.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PracticeShakeWidget', () {
    testWidgets('renders child and shake() runs without error', (tester) async {
      final key = GlobalKey<PracticeShakeWidgetState>();
      await tester.pumpWidget(
        _host(PracticeShakeWidget(key: key, child: const Text('Soru'))),
      );
      expect(find.text('Soru'), findsOneWidget);

      key.currentState!.shake();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));
      // Sarsma bittikten sonra çocuk hâlâ yerinde, hata yok.
      expect(find.text('Soru'), findsOneWidget);
    });
  });

  group('AnswerFeedbackBar', () {
    testWidgets('shows message and Continue triggers callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(
          AnswerFeedbackBar(
            correct: true,
            message: 'Harika!',
            correctAnswer: '',
            explanation: '',
            continueLabel: 'DEVAM',
            onContinue: () => tapped = true,
          ),
        ),
      );
      // slideY animasyonunun oturması için ilerlet.
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Harika!'), findsOneWidget);
      expect(find.text('DEVAM'), findsOneWidget);

      await tester.tap(find.text('DEVAM'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('wrong answer shows correct answer line', (tester) async {
      await tester.pumpWidget(
        _host(
          AnswerFeedbackBar(
            correct: false,
            message: 'Yanlis oldu.',
            correctAnswer: 'apple',
            explanation: '',
            continueLabel: 'DEVAM ET',
            onContinue: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('apple'), findsOneWidget);
    });
  });

  group('PracticeXpGoalSelector', () {
    testWidgets('tapping a goal calls onSelect with its XP', (tester) async {
      int? picked;
      await tester.pumpWidget(
        _host(PracticeXpGoalSelector(
          selectedGoal: 20,
          onSelect: (xp) => picked = xp,
        )),
      );
      expect(find.text('Orta'), findsOneWidget);
      expect(find.text('Çılgın'), findsOneWidget);

      await tester.tap(find.text('Çılgın'));
      await tester.pump();
      expect(picked, 50);
    });
  });

  group('PracticeMotivationToast', () {
    testWidgets('shows message and calls onDone after lifetime',
        (tester) async {
      var done = false;
      await tester.pumpWidget(
        _host(PracticeMotivationToast(
          message: '3 soru kaldi!',
          onDone: () => done = true,
        )),
      );
      await tester.pump();
      expect(find.textContaining('3 soru'), findsOneWidget);

      // Toast ~2800ms sonra onDone çağırır.
      await tester.pump(const Duration(milliseconds: 3000));
      expect(done, isTrue);
    });
  });

  group('XpFloater', () {
    testWidgets('renders +N XP when triggered', (tester) async {
      await tester.pumpWidget(
        _host(const XpFloater(amount: 15, trigger: 1)),
      );
      await tester.pump();
      expect(find.textContaining('+15 XP'), findsOneWidget);
      // flutter_animate'in gecikmeli (then) zamanlayıcılarını akıt.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('hidden when trigger is 0', (tester) async {
      await tester.pumpWidget(_host(const XpFloater(amount: 10, trigger: 0)));
      await tester.pump();
      expect(find.textContaining('XP'), findsNothing);
    });
  });

  group('HeartsCounter', () {
    testWidgets('shows current heart count', (tester) async {
      await tester.pumpWidget(_host(const HeartsCounter(hearts: 3, max: 5)));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('shows broken heart when empty', (tester) async {
      await tester.pumpWidget(_host(const HeartsCounter(hearts: 0, max: 5)));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byIcon(Icons.heart_broken_rounded), findsOneWidget);
    });
  });

  group('ComboBadge', () {
    testWidgets('hidden below 2', (tester) async {
      await tester.pumpWidget(_host(const ComboBadge(count: 1)));
      await tester.pump();
      expect(
        find.byIcon(Icons.local_fire_department_rounded),
        findsNothing,
      );
    });

    testWidgets('visible at 2+', (tester) async {
      await tester.pumpWidget(_host(const ComboBadge(count: 5)));
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.byIcon(Icons.local_fire_department_rounded),
        findsOneWidget,
      );
    });
  });

  group('Practice3DButton', () {
    testWidgets('fires onPressed when enabled', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(Practice3DButton(label: 'TAP', onPressed: () => tapped = true)),
      );
      await tester.tap(find.text('TAP'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tapped, isTrue);
    });

    testWidgets('does not fire when disabled', (tester) async {
      await tester.pumpWidget(
        _host(const Practice3DButton(label: 'NOPE', onPressed: null)),
      );
      await tester.tap(find.text('NOPE'), warnIfMissed: false);
      await tester.pump();
      // Hiçbir callback yok; sadece çökme olmadığını doğrula.
      expect(find.text('NOPE'), findsOneWidget);
    });
  });

  group('PracticeProgressBar', () {
    testWidgets('renders at 0, mid and full', (tester) async {
      for (final v in [0.0, 0.5, 1.0]) {
        await tester.pumpWidget(_host(PracticeProgressBar(value: v)));
        await tester.pump();
        expect(find.byType(PracticeProgressBar), findsOneWidget);
      }
    });
  });

  group('PracticeMascot (akıllı kalem)', () {
    testWidgets('renders and keeps animating without error', (tester) async {
      await tester.pumpWidget(_host(const PracticeMascot(size: 100)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(PracticeMascot), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('all moods build without error', (tester) async {
      for (final mood in PracticeMascotMood.values) {
        await tester.pumpWidget(_host(PracticeMascot(size: 90, mood: mood)));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(PracticeMascot), findsOneWidget);
      }
    });

    testWidgets('loader shows the mascot', (tester) async {
      await tester.pumpWidget(_host(const PracticeMascotLoader()));
      await tester.pump();
      expect(find.byType(PracticeMascot), findsOneWidget);
    });
  });
}
