import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/storage/secure_storage.dart';
import 'zoom_repository.dart';

enum ZoomJoinFailureReason {
  sdkNotAvailable,
  invalidMeeting,
  credentialsMissing,
  initializationFailed,
  permissionDenied,
  joinFailed,
}

class ZoomJoinResult {
  const ZoomJoinResult._({
    required this.isSuccess,
    this.failureReason,
    this.message,
  });

  const ZoomJoinResult.success() : this._(isSuccess: true);

  const ZoomJoinResult.failure(
    ZoomJoinFailureReason reason, {
    String? message,
  }) : this._(
          isSuccess: false,
          failureReason: reason,
          message: message,
        );

  final bool isSuccess;
  final ZoomJoinFailureReason? failureReason;
  final String? message;
}

class ZoomMeetingService {
  static const MethodChannel _channel =
      MethodChannel('lingufranca/zoom_meeting');

  static bool _isSupportedPlatform() {
    if (kIsWeb) return false;
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  static Future<ZoomJoinResult> joinMeeting({
    required String meetingId,
    String? password,
    String? displayName,
  }) async {
    final trimmedMeetingId = meetingId.trim();
    if (trimmedMeetingId.isEmpty) {
      return const ZoomJoinResult.failure(ZoomJoinFailureReason.invalidMeeting);
    }
    if (!_isSupportedPlatform()) {
      return const ZoomJoinResult.failure(
          ZoomJoinFailureReason.sdkNotAvailable);
    }

    try {
      final jwt = await ZoomRepository().fetchSdkJwt();
      if (jwt == null || jwt.isEmpty) {
        return const ZoomJoinResult.failure(
          ZoomJoinFailureReason.credentialsMissing,
        );
      }

      final storedName = (await SecureStorage.getUserName())?.trim() ?? '';
      final name = (displayName?.trim().isNotEmpty == true)
          ? displayName!.trim()
          : (storedName.isNotEmpty ? storedName : 'Lingufranca');

      final initialized =
          await _channel.invokeMapMethod<String, dynamic>('initialize', {
        'jwtToken': jwt,
      });
      if (initialized?['status']?.toString() != 'initialized') {
        return ZoomJoinResult.failure(
          ZoomJoinFailureReason.initializationFailed,
          message: initialized?['message']?.toString(),
        );
      }

      final joined =
          await _channel.invokeMapMethod<String, dynamic>('joinMeeting', {
        'meetingId': trimmedMeetingId,
        'password': (password ?? '').trim(),
        'displayName': name,
      });
      if (joined?['status']?.toString() == 'joined') {
        return const ZoomJoinResult.success();
      }

      return ZoomJoinResult.failure(
        ZoomJoinFailureReason.joinFailed,
        message: joined?['message']?.toString(),
      );
    } on PlatformException catch (error) {
      return ZoomJoinResult.failure(
        _mapErrorCode(error.code),
        message: error.message,
      );
    } catch (_) {
      return const ZoomJoinResult.failure(ZoomJoinFailureReason.joinFailed);
    }
  }

  static ZoomJoinFailureReason _mapErrorCode(String code) {
    switch (code) {
      case 'sdk_not_available':
      case 'zoom_not_initialized':
      case 'zoom_service_missing':
        return ZoomJoinFailureReason.sdkNotAvailable;
      case 'missing_meeting_id':
      case 'invalid_meeting_id':
        return ZoomJoinFailureReason.invalidMeeting;
      case 'missing_jwt':
        return ZoomJoinFailureReason.credentialsMissing;
      case 'permission_denied':
        return ZoomJoinFailureReason.permissionDenied;
      case 'zoom_init_failed':
      case 'zoom_auth_failed':
        return ZoomJoinFailureReason.initializationFailed;
      default:
        return ZoomJoinFailureReason.joinFailed;
    }
  }
}
