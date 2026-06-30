import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static const _hasSeenAppHomeKey = 'has_seen_app_home_v2';
  static const _dailyGoalKey = 'practice_daily_goal_xp';
  static const _doubleOrNothingKey = 'practice_double_or_nothing_active';
  static const _lastSpinDateKey = 'practice_last_spin_date';

  static Future<bool> hasSeenAppHome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenAppHomeKey) ?? false;
  }

  static Future<void> markAppHomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenAppHomeKey, true);
  }

  /// Pratik günlük XP hedefi (varsayılan 20).
  static Future<int> dailyGoalXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyGoalKey) ?? 20;
  }

  static Future<void> setDailyGoalXp(int xp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalKey, xp);
  }

  /// Double or Nothing bahsi aktif mi.
  static Future<bool> doubleOrNothingActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_doubleOrNothingKey) ?? false;
  }

  static Future<void> setDoubleOrNothingActive(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_doubleOrNothingKey, active);
  }

  /// Günlük Şans Çarkı — son çevrilme tarihi (YYYY-MM-DD).
  static Future<String?> getLastSpinDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSpinDateKey);
  }

  static Future<void> setLastSpinDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSpinDateKey, date);
  }
}
