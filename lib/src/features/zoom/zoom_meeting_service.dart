import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/storage/secure_storage.dart';
import 'zoom_repository.dart';

class ZoomMeetingService {
  static const MethodChannel _channel = MethodChannel('lingufranca/zoom_meeting');

  static bool _isSupportedPlatform() {
    if (kIsWeb) return false;
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  static Future<bool> joinMeeting({
    required String meetingId,
    String? password,
    String? displayName,
  }) async {
    final trimmedMeetingId = meetingId.trim();
    if (trimmedMeetingId.isEmpty) return false;
    if (!_isSupportedPlatform()) return false;

    try {
      final jwt = await ZoomRepository().fetchSdkJwt();
      if (jwt == null || jwt.isEmpty) return false;

      final storedName = (await SecureStorage.getUserName())?.trim() ?? '';
      final name = (displayName?.trim().isNotEmpty == true)
          ? displayName!.trim()
          : (storedName.isNotEmpty ? storedName : 'Lingufranca');

      final initialized = await _channel.invokeMethod<bool>('initialize', {
        'jwtToken': jwt,
      });
      if (initialized != true) return false;

      final joined = await _channel.invokeMethod<bool>('joinMeeting', {
        'meetingId': trimmedMeetingId,
        'password': (password ?? '').trim(),
        'displayName': name,
      });
      return joined == true;
    } catch (_) {
      return false;
    }
  }
}
