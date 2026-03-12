import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';

class AppStrings {
  AppStrings._();

  static Map<String, dynamic> _data = {};
  static String _code = AppConfig.locale.split('_').first;

  static String get code => _code;

  static Future<void> load({String? code}) async {
    final saved = await SecureStorage.getLanguageCode();
    final target = (code ?? saved ?? AppConfig.locale.split('_').first).toLowerCase();
    _code = target;
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
    final value = _data[key];
    if (value == null) return key;
    return value.toString();
  }
}
