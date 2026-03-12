import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage.dart';

final appCurrencyProvider = StateProvider<String>((ref) => AppCurrency.code);

class AppCurrency {
  AppCurrency._();

  static String _code = 'TRY';

  static String get code => _code;

  static Future<void> load() async {
    final saved = await SecureStorage.getCurrencyCode();
    final trimmed = (saved ?? '').trim();
    if (trimmed.isNotEmpty) {
      _code = trimmed.toUpperCase();
    }
  }

  static Future<void> set(WidgetRef ref, String code) async {
    final next = code.trim().toUpperCase();
    if (next.isEmpty) return;
    _code = next;
    await SecureStorage.setCurrencyCode(next);
    ref.read(appCurrencyProvider.notifier).state = _code;
  }
}

