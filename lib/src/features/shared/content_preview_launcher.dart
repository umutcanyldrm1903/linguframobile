import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_strings.dart';
import '../../core/utils/content_uri.dart';
import 'content_webview_screen.dart';
import 'document_content_screen.dart';
import 'native_image_viewer_screen.dart';
import 'native_pdf_viewer_screen.dart';
import 'native_video_player_screen.dart';

Future<void> openContentPreview(
  BuildContext context, {
  required String title,
  required String rawUrl,
  String? browserActionLabel,
}) async {
  final externalUri = tryResolveWebUri(rawUrl);
  if (externalUri == null) {
    _showSnack(context, AppStrings.t('Link not found.'));
    return;
  }

  Future<void> openExternally() async {
    final opened =
        await launchUrl(externalUri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _showSnack(context, AppStrings.t('Could not open link.'));
    }
  }

  final previewType = detectContentPreviewType(rawUrl);
  final embeddedUri = tryBuildEmbeddedContentUri(rawUrl);

  Widget screen;
  switch (previewType) {
    case ContentPreviewType.pdf:
      screen = NativePdfViewerScreen(
        title: title,
        pdfUrl: externalUri.toString(),
        onOpenExternally: openExternally,
      );
      break;
    case ContentPreviewType.video:
      screen = NativeVideoPlayerScreen(
        title: title,
        videoUrl: externalUri.toString(),
        onOpenExternally: openExternally,
      );
      break;
    case ContentPreviewType.image:
      screen = NativeImageViewerScreen(
        title: title,
        imageUrl: externalUri.toString(),
        onOpenExternally: openExternally,
      );
      break;
    case ContentPreviewType.office:
      screen = DocumentContentScreen(
        title: title,
        documentUrl: externalUri.toString(),
        previewUrl: embeddedUri?.toString(),
        onOpenExternally: openExternally,
      );
      break;
    case ContentPreviewType.web:
      screen = ContentWebViewScreen(
        title: title,
        loadUrl: (embeddedUri ?? externalUri).toString(),
        externalUrl: externalUri.toString(),
        actionLabel: browserActionLabel ?? AppStrings.t('Open in Browser'),
      );
      break;
  }

  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => screen),
  );
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
