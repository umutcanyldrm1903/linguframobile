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
