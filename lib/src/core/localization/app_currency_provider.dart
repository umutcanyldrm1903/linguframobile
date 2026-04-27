import 'dart:async';

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

    // Update state first (synchronous, reactive)
    ref.read(appCurrencyProvider.notifier).state = next;
    _code = next;

    // Then persist to storage (don't wait for this)
    unawaited(SecureStorage.setCurrencyCode(next));
  }
}

