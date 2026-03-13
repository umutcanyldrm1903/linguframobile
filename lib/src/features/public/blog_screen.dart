import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/url_resolver.dart';
import 'blog_detail_screen.dart';
import 'public_page_scaffold.dart';
import 'public_repository.dart';

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PublicPageShell(
        title: AppStrings.t('Blog'),
        breadcrumb: '${AppStrings.t('Home')}  >  ${AppStrings.t('Blog')}',
        description: AppStrings.t(
          'Read learning tips, platform updates and practical English guidance.',
        ),
        icon: Icons.article_outlined,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompactPublicLayout(context) ? 14 : 18,
            ),
            child: Text(
              AppStrings.t('Latest Post'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
            ),
          ),
          FutureBuilder<List<PublicBlogPost>>(
            future: PublicRepository().fetchBlogPosts(),
            builder: (context, snapshot) {
              final posts = snapshot.data ?? const [];
              if (posts.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompactPublicLayout(context) ? 14 : 18,
                  ),
                  child: Text(AppStrings.t('No latest post yet')),
                );
              }
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompactPublicLayout(context) ? 14 : 18,
                ),
                child: Column(
                  children: posts
                      .map(
                        (post) => _BlogCard(
                          post: post,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlogDetailScreen(slug: post.slug),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  const _BlogCard({required this.post, required this.onTap});

  final PublicBlogPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactPublicLayout(context);
    final dateLabel = _formatDate(post.dateLabel);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: EdgeInsets.only(bottom: compact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(compact ? 22 : 18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: compact ? 0.08 : 0.06),
              blurRadius: compact ? 24 : 16,
              offset: Offset(0, compact ? 10 : 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(compact ? 22 : 18),
              ),
              child: _PostImage(imageUrl: post.imageUrl),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 18 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (post.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      post.excerpt,
                      style:
                          const TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.t('Read More'),
                    style: TextStyle(
                      color: AppColors.brandDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) {
      return '';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat('dd MMMM yyyy', 'tr_TR').format(parsed);
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl.trim();
    final isAsset = trimmed.startsWith('assets/');
    final resolved = isAsset ? trimmed : resolveWebUrl(trimmed);

    if (!isAsset && resolved.isNotEmpty) {
      return Image.network(
        resolved,
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, __, ___) => _fallbackImage(),
      );
    }
    if (trimmed.isNotEmpty) {
      return Image.asset(
        trimmed,
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return Image.asset(
      'assets/web/blog_post01.jpg',
      height: 190,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}
