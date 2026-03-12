import '../config/app_config.dart';

String resolveWebUrl(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  if (value.startsWith('//')) {
    return 'https:$value';
  }

  if (value.startsWith('/')) {
    return '${AppConfig.webBaseUrl}$value';
  }

  return '${AppConfig.webBaseUrl}/$value';
}

