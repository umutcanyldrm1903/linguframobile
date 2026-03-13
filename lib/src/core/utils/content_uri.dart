import 'url_resolver.dart';

enum ContentPreviewType {
  web,
  pdf,
  office,
  video,
  image,
}

const _documentExtensions = <String>{
  '.pdf',
  '.doc',
  '.docx',
  '.ppt',
  '.pptx',
  '.xls',
  '.xlsx',
};

const _inlineMediaExtensions = <String>{
  '.mp4',
  '.mov',
  '.m4v',
  '.webm',
  '.m3u8',
};

const _imageExtensions = <String>{
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
  '.gif',
};

Uri? tryResolveWebUri(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return null;
  return Uri.tryParse(resolveWebUrl(value));
}

ContentPreviewType detectContentPreviewType(String? raw) {
  final uri = tryResolveWebUri(raw);
  if (uri == null) return ContentPreviewType.web;

  final path = uri.path.toLowerCase();
  if (path.endsWith('.pdf')) {
    return ContentPreviewType.pdf;
  }
  if (_documentExtensions.any(path.endsWith)) {
    return ContentPreviewType.office;
  }
  if (_inlineMediaExtensions.any(path.endsWith)) {
    return ContentPreviewType.video;
  }
  if (_imageExtensions.any(path.endsWith)) {
    return ContentPreviewType.image;
  }

  return ContentPreviewType.web;
}

Uri? tryBuildEmbeddedContentUri(String? raw) {
  final uri = tryResolveWebUri(raw);
  if (uri == null) return null;
  if (!isEmbeddableWebUri(uri)) return uri;

  final path = uri.path.toLowerCase();
  if (_documentExtensions.any(path.endsWith)) {
    return Uri.https('docs.google.com', '/gview', {
      'embedded': '1',
      'url': uri.toString(),
    });
  }

  if (_inlineMediaExtensions.any(path.endsWith)) {
    return uri;
  }

  return uri;
}

bool isEmbeddableWebUri(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  return scheme == 'http' || scheme == 'https';
}
