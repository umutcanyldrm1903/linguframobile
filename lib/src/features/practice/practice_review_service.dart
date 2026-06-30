import 'package:in_app_review/in_app_review.dart';

class PracticeReviewService {
  const PracticeReviewService._();

  static Future<void> requestAfterGreatLesson({
    required bool perfect,
  }) async {
    if (!perfect) return;
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {
      // Native review prompts are best-effort and should never block practice.
    }
  }
}
