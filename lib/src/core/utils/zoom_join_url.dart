class ZoomMeetingCredentials {
  const ZoomMeetingCredentials({
    required this.meetingId,
    required this.password,
  });

  final String meetingId;
  final String password;
}

Uri? tryParseZoomJoinUrl(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;

  Uri? uri = Uri.tryParse(value);
  if (uri == null) return null;

  if (!uri.hasScheme) {
    uri = Uri.tryParse('https://$value');
    if (uri == null) return null;
  }

  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'zoommtg') return uri;
  if (scheme != 'https' && scheme != 'http') return null;

  final host = uri.host.toLowerCase();
  if (host.isEmpty) return null;

  final isZoomHost = host == 'zoom.us' ||
      host.endsWith('.zoom.us') ||
      host == 'zoom.com' ||
      host.endsWith('.zoom.com');
  if (!isZoomHost) return null;

  return uri;
}

ZoomMeetingCredentials? tryParseZoomMeetingCredentials(String raw) {
  final uri = tryParseZoomJoinUrl(raw);
  if (uri == null) return null;

  String meetingId = '';
  String password = '';

  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'zoommtg') {
    meetingId = (uri.queryParameters['confno'] ?? '').trim();
    password = (uri.queryParameters['pwd'] ?? '').trim();
  } else {
    final segments = uri.pathSegments;
    final joinIndex =
        segments.indexWhere((segment) => segment == 'j' || segment == 'wc');
    if (joinIndex != -1 && joinIndex + 1 < segments.length) {
      meetingId = segments[joinIndex + 1].trim();
    }
    password = (uri.queryParameters['pwd'] ?? '').trim();
  }

  meetingId = meetingId.replaceAll(RegExp(r'[^0-9]'), '');
  if (meetingId.isEmpty) {
    return null;
  }

  return ZoomMeetingCredentials(
    meetingId: meetingId,
    password: password,
  );
}

Uri? tryBuildZoomBrowserUri(String raw) {
  final uri = tryParseZoomJoinUrl(raw);
  if (uri == null) return null;

  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'http' || scheme == 'https') {
    return uri;
  }

  if (scheme != 'zoommtg') return null;

  final host = uri.host.isNotEmpty ? uri.host : 'zoom.us';
  final meetingId = (uri.queryParameters['confno'] ?? '').trim();
  if (meetingId.isEmpty) return null;

  final query = <String, String>{};
  final password = (uri.queryParameters['pwd'] ?? '').trim();
  if (password.isNotEmpty) {
    query['pwd'] = password;
  }

  return Uri.https(host, '/j/$meetingId', query.isEmpty ? null : query);
}
