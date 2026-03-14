import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/utils/zoom_join_url.dart';
import 'zoom_meeting_service.dart';

Future<void> openLiveLessonSession(
  BuildContext context, {
  required String title,
  required String joinUrl,
  String? meetingId,
  String? password,
  String? displayName,
}) async {
  final parsedCredentials = tryParseZoomMeetingCredentials(joinUrl);
  final resolvedMeetingId = (meetingId ?? '').trim().isNotEmpty
      ? (meetingId ?? '').trim()
      : (parsedCredentials?.meetingId ?? '');
  final resolvedPassword = (password ?? '').trim().isNotEmpty
      ? (password ?? '').trim()
      : (parsedCredentials?.password ?? '');

  if (resolvedMeetingId.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.t('The lesson link is invalid or unavailable.'),
        ),
      ),
    );
    return;
  }

  final result = await ZoomMeetingService.joinMeeting(
    meetingId: resolvedMeetingId,
    password: resolvedPassword,
    displayName: displayName,
  );
  if (result.isSuccess) {
    return;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_messageForFailure(result)),
      ),
    );
  }
}

String _messageForFailure(ZoomJoinResult result) {
  if ((result.message ?? '').trim().isNotEmpty) {
    return result.message!.trim();
  }

  switch (result.failureReason) {
    case ZoomJoinFailureReason.sdkNotAvailable:
      return AppStrings.t(
          'Zoom native support is not available on this device.');
    case ZoomJoinFailureReason.invalidMeeting:
      return AppStrings.t('The lesson link is invalid or unavailable.');
    case ZoomJoinFailureReason.credentialsMissing:
      return AppStrings.t('Zoom SDK credentials are missing.');
    case ZoomJoinFailureReason.initializationFailed:
      return AppStrings.t('Zoom could not start. Please try again.');
    case ZoomJoinFailureReason.permissionDenied:
      return AppStrings.t(
          'Camera and microphone permissions are required to join the lesson.');
    case ZoomJoinFailureReason.joinFailed:
    case null:
      return AppStrings.t('Zoom could not join the lesson. Please try again.');
  }
}
