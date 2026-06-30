import 'package:flutter/material.dart';

import 'practice_content_play_screen.dart';

class PracticeSpecialDetailScreen extends StatelessWidget {
  const PracticeSpecialDetailScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PracticeContentPlayScreen(kind: PracticeContentKind.story);
}
