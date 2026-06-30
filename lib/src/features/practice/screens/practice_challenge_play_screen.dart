import 'package:flutter/material.dart';

import 'practice_content_play_screen.dart';

class PracticeChallengePlayScreen extends StatelessWidget {
  const PracticeChallengePlayScreen({super.key});

  @override
  Widget build(BuildContext context) => const PracticeContentPlayScreen(
        kind: PracticeContentKind.challenge,
      );
}
