import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import 'app_strings.dart';

final appLocaleProvider = StateProvider<String>((ref) => AppStrings.code);

class AppLocale {
  const AppLocale._();

  static Future<void> set(WidgetRef ref, String code) async {
    final target = code.toLowerCase();

    // Update state immediately (synchronous, reactive)
    await AppStrings.load(code: target);
    ref.read(appLocaleProvider.notifier).state = AppStrings.code;

    // Then persist to storage (don't wait for this)
    unawaited(SecureStorage.setLanguageCode(target));
  }
}
