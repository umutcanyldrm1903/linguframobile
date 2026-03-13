import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

import '../../core/localization/app_strings.dart';

class NativePdfViewerScreen extends StatelessWidget {
  const NativePdfViewerScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
    required this.onOpenExternally,
  });

  final String title;
  final String pdfUrl;
  final Future<void> Function() onOpenExternally;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: onOpenExternally,
            icon: const Icon(Icons.open_in_new),
            tooltip: AppStrings.t('Open Externally'),
          ),
        ],
      ),
      body: PDF(
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onError: (_) {},
        onPageError: (_, __) {},
      ).fromUrl(
        pdfUrl,
        placeholder: (progress) => Center(
          child: CircularProgressIndicator(value: progress / 100),
        ),
        errorWidget: (error) => _PdfErrorState(
          message: error.toString(),
          onOpenExternally: onOpenExternally,
        ),
      ),
    );
  }
}

class _PdfErrorState extends StatelessWidget {
  const _PdfErrorState({
    required this.message,
    required this.onOpenExternally,
  });

  final String message;
  final Future<void> Function() onOpenExternally;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              AppStrings.t('This document could not be previewed here.'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onOpenExternally,
              icon: const Icon(Icons.open_in_new),
              label: Text(AppStrings.t('Open Externally')),
            ),
          ],
        ),
      ),
    );
  }
}
