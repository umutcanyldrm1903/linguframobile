class AppConfig {
  static const String appName = 'Lingufranca';
  static const String apiBaseUrl = 'https://www.lingufranca.com/api';
  static const String webBaseUrl = 'https://www.lingufranca.com';
  static const String locale = 'tr_TR';
  static const String timeZone = 'Europe/Istanbul';
  static const String mobileAnalyticsKey = String.fromEnvironment(
    'MOBILE_ANALYTICS_KEY',
    defaultValue: '',
  );
}
