import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PaymentNativeService {
  static const MethodChannel _channel = MethodChannel('lingufranca/iyzico');
  static final StreamController<String> _deepLinks =
      StreamController<String>.broadcast();
  static bool _initialized = false;
  static String? _lastDeepLink;

  static void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method != 'deepLink') return null;

      final args = call.arguments;
      String? url;
      if (args is Map) {
        url = args['url']?.toString();
      }

      final trimmed = (url ?? '').trim();
      if (trimmed.isNotEmpty) {
        _lastDeepLink = trimmed;
        _deepLinks.add(trimmed);
      }
      return null;
    });
  }

  static Stream<String> get deepLinkStream {
    _ensureInitialized();
    return _deepLinks.stream;
  }

  static String? consumeLastDeepLink() {
    _ensureInitialized();
    final value = _lastDeepLink;
    _lastDeepLink = null;
    return value;
  }

  Future<bool> startPayment({
    required String paymentUrl,
    required String invoiceId,
  }) async {
    if (kIsWeb) return false;
    _ensureInitialized();
    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod('startPayment', {
        'url': paymentUrl,
        'invoice_id': invoiceId,
      });
      return result == true;
    } catch (_) {
      return false;
    }
  }
}
