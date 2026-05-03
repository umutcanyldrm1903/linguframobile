import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static const _hasSeenAppHomeKey = 'has_seen_app_home_v2';

  static Future<bool> hasSeenAppHome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenAppHomeKey) ?? false;
  }

  static Future<void> markAppHomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenAppHomeKey, true);
  }
}
