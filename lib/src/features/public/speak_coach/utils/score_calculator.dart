class AudioAnalysis {
  const AudioAnalysis({
    required this.clarity,
    required this.rhythm,
    required this.confidence,
    required this.rewrittenTranscript,
    required this.errorTagScores,
  });

  final int clarity;
  final int rhythm;
  final int confidence;
  final String rewrittenTranscript;
  final Map<String, int> errorTagScores;
}

class ScoreCalculator {
  static AudioAnalysis analyzeRecording({
    required int streak,
    required int weeklySessions,
    required int elapsedSeconds,
    required double maxAmplitude,
    required String practiceModeId,
    required String transcript,
    required String focusLine,
  }) {
    final cleanedTranscript = _normalizeTranscript(transcript);
    final rewritten = rewriteTranscript(cleanedTranscript);
    final transcriptTokens = _tokens(cleanedTranscript);
    final focusTokens = _tokens(_normalizeTranscript(focusLine));

    final amplitudeBoost = ((maxAmplitude + 60) / 2).round().clamp(0, 18);
    final durationBoost = (elapsedSeconds / 6).round().clamp(0, 6);
    final pacePenalty = elapsedSeconds < 2 ? 8 : 0;
    final repetitionPenalty = _repetitionPenalty(transcriptTokens);
    final lexicalBonus = _lexicalDiversityBonus(transcriptTokens);
    final focusSimilarity = _focusSimilarity(transcriptTokens, focusTokens);

    final base = switch (practiceModeId) {
      'speed' => 74,
      'clarity' => 81,
      _ => 77,
    };

    final clarity = (base +
            (streak % 6) +
            durationBoost +
            amplitudeBoost +
            lexicalBonus +
            (focusSimilarity ~/ 8) -
            repetitionPenalty -
            pacePenalty)
        .clamp(55, 97);

    final rhythm = (base +
            (weeklySessions % 5) +
            1 +
            durationBoost +
            (amplitudeBoost ~/ 2) +
            (elapsedSeconds >= 4 ? 4 : 0) -
            (repetitionPenalty ~/ 2))
        .clamp(52, 96);

    final confidence = ((clarity * 0.45 + rhythm * 0.3 + (50 + lexicalBonus * 5) * 0.25)
            .round())
        .clamp(50, 97);

    return AudioAnalysis(
      clarity: clarity,
      rhythm: rhythm,
      confidence: confidence,
      rewrittenTranscript: rewritten,
      errorTagScores: classifyErrorTagScores(
        transcript: cleanedTranscript,
        rewritten: rewritten,
        clarityScore: clarity,
        rhythmScore: rhythm,
      ),
    );
  }

  static String rewriteTranscript(String transcript) {
    final cleaned = _normalizeTranscript(transcript);
    if (cleaned.isEmpty) return '';
    final first = cleaned.substring(0, 1).toUpperCase();
    final rest = cleaned.length > 1 ? cleaned.substring(1) : '';
    final normalized = '$first$rest';
    if (normalized.endsWith('.') ||
        normalized.endsWith('!') ||
        normalized.endsWith('?')) {
      return normalized;
    }
    return '$normalized.';
  }

  static Map<String, int> classifyErrorTagScores({
    required String transcript,
    required String rewritten,
    required int clarityScore,
    required int rhythmScore,
  }) {
    final scores = <String, int>{};
    final raw = transcript.trim();
    final pronunciationScore =
        (100 - ((clarityScore + rhythmScore) ~/ 2)).clamp(15, 95);

    if (raw.isEmpty || clarityScore < 88 || rhythmScore < 86) {
      scores['pronunciation'] = pronunciationScore;
    }

    if (raw.isNotEmpty) {
      final first = raw.substring(0, 1);
      final hasCapitalIssue = first == first.toLowerCase();
      final hasPunctuationIssue =
          !raw.endsWith('.') && !raw.endsWith('!') && !raw.endsWith('?');
      if (hasCapitalIssue || hasPunctuationIssue) {
        scores['grammar'] = (hasCapitalIssue && hasPunctuationIssue) ? 72 : 62;
      }
    }

    final fillers = ['thing', 'stuff', 'very very', 'like', 'umm', 'uh'];
    final lowerRaw = raw.toLowerCase();
    final lowerRewrite = rewritten.toLowerCase();
    final hasFiller = fillers.any(lowerRaw.contains);
    if (hasFiller || (lowerRaw.isNotEmpty && lowerRaw != lowerRewrite)) {
      final rewriteGap = (lowerRaw.length - lowerRewrite.length).abs();
      scores['word_choice'] = (55 + rewriteGap).clamp(42, 86);
    }

    if (scores.isEmpty) {
      scores['pronunciation'] = pronunciationScore;
    }
    return scores;
  }

  static String _normalizeTranscript(String transcript) {
    return transcript.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<String> _tokens(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
  }

  static int _repetitionPenalty(List<String> tokens) {
    if (tokens.length < 4) return 0;
    var repeated = 0;
    for (var i = 1; i < tokens.length; i++) {
      if (tokens[i] == tokens[i - 1]) repeated++;
    }
    return (repeated * 3).clamp(0, 18);
  }

  static int _lexicalDiversityBonus(List<String> tokens) {
    if (tokens.isEmpty) return 0;
    final unique = tokens.toSet().length;
    final ratio = unique / tokens.length;
    return (ratio * 10).round().clamp(0, 8);
  }

  static int _focusSimilarity(List<String> transcript, List<String> focus) {
    if (transcript.isEmpty || focus.isEmpty) return 0;
    final transcriptSet = transcript.toSet();
    final focusSet = focus.toSet();
    final overlap = transcriptSet.intersection(focusSet).length;
    return ((overlap / focusSet.length) * 100).round().clamp(0, 100);
  }
}
