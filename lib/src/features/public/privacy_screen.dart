import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'public_page_scaffold.dart';
import 'public_repository.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<LegalPage?>(
        future: PublicRepository().fetchLegalPage('privacy-policy'),
        builder: (context, snapshot) {
          final page = snapshot.data;
          final title = page?.title.isNotEmpty == true
              ? page!.title
              : AppStrings.t('Privacy Policy');
          final body = _stripHtml(page?.content ?? '');

          return PublicPageShell(
            title: title,
            breadcrumb:
                '${AppStrings.t('Home')}  >  ${AppStrings.t('Privacy Policy')}',
            description: AppStrings.t(
              'See how your account, lesson and communication data is handled in the app.',
            ),
            icon: Icons.shield_outlined,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompactPublicLayout(context) ? 14 : 18,
                ),
                child: _LegalBlock(title: title, body: body),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LegalBlock extends StatelessWidget {
  const _LegalBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactPublicLayout(context);
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 24 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: compact ? 0.07 : 0.05),
            blurRadius: compact ? 18 : 12,
            offset: Offset(0, compact ? 8 : 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body.isEmpty ? AppStrings.t('No Data Found') : body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

String _stripHtml(String html) {
  return html
      .replaceAll(RegExp('<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .trim();
}
