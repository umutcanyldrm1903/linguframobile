import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_event_logger.dart';

class AppTelemetryService {
  AppTelemetryService._();

  static final AppTelemetryService instance = AppTelemetryService._();
  final Stopwatch _startupWatch = Stopwatch()..start();

  void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      _logCrash(
        type: 'flutter_error',
        message: details.exceptionAsString(),
      );
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _logCrash(
        type: 'platform_error',
        message: error.toString(),
      );
      return false;
    };
  }

  Future<void> markAppReady() async {
    if (!_startupWatch.isRunning) return;
    _startupWatch.stop();
    await AppEventLogger.instance.log(
      'app_startup_timing',
      properties: {
        'startup_ms': '${_startupWatch.elapsedMilliseconds}',
      },
    );
  }

  Future<void> _logCrash({
    required String type,
    required String message,
  }) async {
    await AppEventLogger.instance.log(
      'app_crash_captured',
      properties: {
        'type': type,
        'message': message.length > 240 ? message.substring(0, 240) : message,
      },
    );
  }
}
