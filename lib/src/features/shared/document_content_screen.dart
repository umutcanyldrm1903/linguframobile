import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'content_webview_screen.dart';

class DocumentContentScreen extends StatelessWidget {
  const DocumentContentScreen({
    super.key,
    required this.title,
    required this.documentUrl,
    this.previewUrl,
    this.onOpenExternally,
  });

  final String title;
  final String documentUrl;
  final String? previewUrl;
  final Future<void> Function()? onOpenExternally;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      size: 38,
                      color: AppColors.brandDeep,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.t(
                      'This material opens best in a document viewer. You can preview it here or open the original file.',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if ((previewUrl ?? '').trim().isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ContentWebViewScreen(
                          title: title,
                          loadUrl: previewUrl!,
                          externalUrl:
                              onOpenExternally == null ? null : documentUrl,
                          actionLabel: onOpenExternally == null
                              ? null
                              : AppStrings.t('Open Externally'),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.preview_outlined),
                  label: Text(AppStrings.t('Preview Document')),
                ),
              ),
            if ((previewUrl ?? '').trim().isNotEmpty)
              const SizedBox(height: 10),
            if (onOpenExternally != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onOpenExternally,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(AppStrings.t('Open Externally')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
