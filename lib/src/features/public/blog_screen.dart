import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/url_resolver.dart';
import 'blog_detail_screen.dart';
import 'public_footer.dart';
import 'public_header.dart';
import 'public_repository.dart';

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const PublicHeader(),
          _HeroBanner(
            title: AppStrings.t('Blog'),
            breadcrumb: '${AppStrings.t('Home')}  >  ${AppStrings.t('Blog')}',
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              AppStrings.t('Latest Post'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<PublicBlogPost>>(
            future: PublicRepository().fetchBlogPosts(),
            builder: (context, snapshot) {
              final posts = snapshot.data ?? const [];
              if (posts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(AppStrings.t('No latest post yet')),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
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
          const SizedBox(height: 16),
          const PublicFooter(),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: _PostImage(imageUrl: post.imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
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
                      style: const TextStyle(color: AppColors.muted, height: 1.4),
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

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.title, required this.breadcrumb});

  final String title;
  final String breadcrumb;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D5B90),
            Color(0xFF0B466F),
            Color(0xFF082C46),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.10,
            child: Image.asset('assets/web/banner_bg.png', fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  breadcrumb,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
