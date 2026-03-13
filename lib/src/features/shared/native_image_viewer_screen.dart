import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';

class NativeImageViewerScreen extends StatelessWidget {
  const NativeImageViewerScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.onOpenExternally,
  });

  final String title;
  final String imageUrl;
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
      body: InteractiveViewer(
        minScale: 0.8,
        maxScale: 4,
        child: Center(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image_outlined, size: 56),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.t('This image could not be previewed here.'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: onOpenExternally,
                      icon: const Icon(Icons.open_in_new),
                      label: Text(AppStrings.t('Open Externally')),
                    ),
                  ],
                ),
              );
            },
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              final total = progress.expectedTotalBytes;
              final value = total == null
                  ? null
                  : progress.cumulativeBytesLoaded / total;
              return Center(child: CircularProgressIndicator(value: value));
            },
          ),
        ),
      ),
    );
  }
}
