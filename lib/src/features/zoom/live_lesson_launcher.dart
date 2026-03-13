import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/utils/zoom_join_url.dart';
import '../shared/content_webview_screen.dart';
import 'zoom_meeting_service.dart';

Future<void> openLiveLessonSession(
  BuildContext context, {
  required String title,
  required String joinUrl,
  String? meetingId,
  String? password,
  String? displayName,
}) async {
  final trimmedMeetingId = (meetingId ?? '').trim();
  final trimmedPassword = (password ?? '').trim();
  final trimmedJoinUrl = joinUrl.trim();

  if (trimmedMeetingId.isNotEmpty) {
    final joined = await ZoomMeetingService.joinMeeting(
      meetingId: trimmedMeetingId,
      password: trimmedPassword,
      displayName: displayName,
    );
    if (joined) {
      return;
    }
  }

  final uri = tryParseZoomJoinUrl(trimmedJoinUrl);
  if (uri == null) {
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

  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'http' || scheme == 'https') {
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContentWebViewScreen(
          title: title,
          loadUrl: uri.toString(),
          externalUrl: uri.toString(),
          actionLabel: AppStrings.t('Open in Browser'),
        ),
      ),
    );
    return;
  }

  final browserUri = tryBuildZoomBrowserUri(trimmedJoinUrl);
  if (browserUri != null) {
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContentWebViewScreen(
          title: title,
          loadUrl: browserUri.toString(),
          externalUrl: browserUri.toString(),
          actionLabel: AppStrings.t('Open in Browser'),
        ),
      ),
    );
    return;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.t('The lesson link is invalid or unavailable.'),
        ),
      ),
    );
  }
}
