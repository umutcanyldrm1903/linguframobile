import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/url_resolver.dart';
import 'public_page_scaffold.dart';
import 'public_repository.dart';

class BlogDetailScreen extends StatefulWidget {
  const BlogDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  late final Future<PublicBlogDetail?> _future =
      PublicRepository().fetchBlogDetail(widget.slug);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<PublicBlogDetail?>(
        future: _future,
        builder: (context, snapshot) {
          final detail = snapshot.data;
          return PublicPageShell(
            title: AppStrings.t('Blog Details'),
            breadcrumb: '${AppStrings.t('Home')}  >  ${AppStrings.t('Blog')}',
            description: AppStrings.t(
              'Read the full post with metadata and the original article image.',
            ),
            icon: Icons.chrome_reader_mode_outlined,
            children: [
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (detail == null)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompactPublicLayout(context) ? 14 : 18,
                  ),
                  child: Text(AppStrings.t('No Data Found')),
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompactPublicLayout(context) ? 14 : 18,
                  ),
                  child: _BlogDetailCard(detail: detail),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BlogDetailCard extends StatelessWidget {
  const _BlogDetailCard({required this.detail});

  final PublicBlogDetail detail;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactPublicLayout(context);
    final formattedDate = _formatBlogDate(detail.createdAt);
    final body = _stripBlogHtml(detail.description);

    return Container(
      padding: EdgeInsets.all(compact ? 18 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 24 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: compact ? 0.07 : 0.05),
            blurRadius: compact ? 20 : 14,
            offset: Offset(0, compact ? 10 : 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.imageUrl.trim().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 20 : 18),
              child: _DetailImage(imageUrl: detail.imageUrl),
            ),
          const SizedBox(height: 14),
          Text(
            detail.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _MetaChip(
                icon: Icons.calendar_today,
                label: formattedDate,
              ),
              if (detail.author.isNotEmpty)
                _MetaChip(
                  icon: Icons.person_outline,
                  label: detail.author,
                ),
              if (detail.category.isNotEmpty)
                _MetaChip(
                  icon: Icons.category_outlined,
                  label: detail.category,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.ink,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatBlogDate(String raw) {
  if (raw.isEmpty) return '';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return DateFormat('dd MMMM yyyy', 'tr_TR').format(parsed);
}

String _stripBlogHtml(String input) {
  return input.replaceAll(RegExp('<[^>]*>'), '').trim();
}

class _DetailImage extends StatelessWidget {
  const _DetailImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl.trim();
    final isAsset = trimmed.startsWith('assets/');
    if (isAsset) {
      return Image.asset(
        trimmed,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    final resolved = resolveWebUrl(trimmed);
    return Image.network(
      resolved,
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, __, ___) => Container(
        height: 220,
        color: Colors.white,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.muted),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
