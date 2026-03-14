import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';

class AppStrings {
  AppStrings._();

  static Map<String, dynamic> _data = {};
  static String _code = AppConfig.locale.split('_').first;
  static const Set<String> _supported = {'tr', 'en'};

  static const Map<String, String> _trFallback = {
    'Contact Us': 'Bize Ulaşın',
    'View All': 'Hepsini İncele',
    'Please login to comment': 'Yorum yapmak için lütfen giriş yapın',
    'Google Play Link': 'Google Play Bağlantısı',
    'Account': 'Hesap',
    'Watch Our Class Demo': 'Canlı Ders Tanıtımını İzle',
    'Find your Course': 'Size Uygun Programı Bul',
    'Continue Learning': 'Öğrenmeye Devam Et',
    'Live lessons': 'Canlı dersler',
    'Native instructors': 'Native eğitmenler',
    'Flexible schedule': 'Esnek program',
    'The easiest way to learn a language.': 'Dil öğrenmenin en pratik yolu.',
    'Payment Method': 'Ödeme Yöntemi',
    'Follow Us On': 'Bizi Takip Edin',
    'Zoom native support is not available on this device.':
        'Bu cihazda native Zoom destegi kullanilamiyor.',
    'Zoom SDK credentials are missing.': 'Zoom SDK bilgileri eksik.',
    'Zoom could not start. Please try again.':
        'Zoom baslatilamadi. Lutfen tekrar deneyin.',
    'Camera and microphone permissions are required to join the lesson.':
        'Derse katilmak icin kamera ve mikrofon izinleri gerekir.',
    'Zoom could not join the lesson. Please try again.':
        'Zoom derse baglanamadi. Lutfen tekrar deneyin.',
  };

  static String get code => _code;

  static Future<void> load({String? code}) async {
    final saved = await SecureStorage.getLanguageCode();
    final requested = (code ?? saved ?? AppConfig.locale.split('_').first)
        .toLowerCase()
        .trim();
    final target = _supported.contains(requested) ? requested : 'tr';
    _code = target;
    _data = {};
    try {
      final response = await ApiClient.dio.get('/static-language/$target');
      final body = response.data;
      if (body is Map<String, dynamic> && body['data'] is Map) {
        _data = Map<String, dynamic>.from(body['data'] as Map);
      }
    } on DioException {
      // keep fallback map empty
    }
  }

  static String t(String key) {
    final raw = _data[key];
    String text = raw?.toString().trim() ?? '';

    if (text.isEmpty) {
      text = _fallbackFor(key);
    }
    if (text.isEmpty) {
      text = key;
    }

    text = _repairMojibake(text);

    if (_code == 'tr') {
      // Some payloads come from DB in English even when tr is selected.
      text = _trFallback[text] ?? text;
      if (text == key) {
        text = _trFallback[key] ?? key;
      }
    }

    return text;
  }

  static String _fallbackFor(String key) {
    if (_code == 'tr') return _trFallback[key] ?? '';
    return '';
  }

  static String _repairMojibake(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAll('Ã¼', 'ü')
        .replaceAll('Ãœ', 'Ü')
        .replaceAll('Ã¶', 'ö')
        .replaceAll('Ã–', 'Ö')
        .replaceAll('Ã§', 'ç')
        .replaceAll('Ã‡', 'Ç')
        .replaceAll('ÄŸ', 'ğ')
        .replaceAll('Äž', 'Ğ')
        .replaceAll('ÅŸ', 'ş')
        .replaceAll('Åž', 'Ş')
        .replaceAll('Ä±', 'ı')
        .replaceAll('Ä°', 'İ')
        .replaceAll('Â©', '©');
  }
}
