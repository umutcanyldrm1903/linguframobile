import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class PracticeWidgetService {
  const PracticeWidgetService._();

  static Future<void> update({
    required int streak,
    required int xp,
    required int hearts,
  }) async {
    if (kIsWeb) return;

    await HomeWidget.saveWidgetData<String>('practice_title', 'Günlük Pratik');
    await HomeWidget.saveWidgetData<String>(
      'practice_subtitle',
      '$streak gün seri • $xp XP • $hearts can',
    );
    await HomeWidget.saveWidgetData<int>('practice_streak', streak);
    await HomeWidget.saveWidgetData<int>('practice_xp', xp);
    await HomeWidget.saveWidgetData<int>('practice_hearts', hearts);
    await HomeWidget.updateWidget(
      androidName: 'PracticeWidgetProvider',
      iOSName: 'PracticeWidget',
    );
  }

  static Future<void> updateFromMap(Map<String, dynamic> stats) {
    return update(
      streak: _asInt(stats['streak'] ?? stats['current_streak']),
      xp: _asInt(stats['total_xp']),
      hearts: _asInt(stats['hearts'] ?? stats['current_hearts'], fallback: 5),
    );
  }

  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}
