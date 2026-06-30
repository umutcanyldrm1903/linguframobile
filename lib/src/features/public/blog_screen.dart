import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/ui.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: SectionHeader(
              title: AppStrings.t('Latest Post'),
              icon: Icons.auto_stories_rounded,
            ),
          ),
          FutureBuilder<List<PublicBlogPost>>(
            future: PublicRepository().fetchBlogPosts(),
            builder: (context, snapshot) {
              final posts = snapshot.data ?? const [];
              if (posts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                  child: AppEmptyState(
                    title: AppStrings.t('No latest post yet'),
                    icon: Icons.article_outlined,
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                child: StaggeredReveal(
                  children: posts
                      .map(
                        (post) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.md),
                          child: _BlogCard(
                            post: post,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BlogDetailScreen(slug: post.slug),
                              ),
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
    final dateLabel = _formatDate(post.dateLabel);
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      radius: AppRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            child: _PostImage(imageUrl: post.imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dateLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.10),
                      borderRadius: AppRadius.pill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: AppColors.brandDeep,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            color: AppColors.brandDeep,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpace.md),
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                ),
                if (post.excerpt.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    post.excerpt,
                    style: const TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                ],
                const SizedBox(height: AppSpace.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppGhostButton(
                    label: AppStrings.t('Read More'),
                    onPressed: onTap,
                    expand: false,
                    icon: Icons.arrow_forward_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
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
