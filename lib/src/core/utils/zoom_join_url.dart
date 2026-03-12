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

