import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/url_resolver.dart';
import 'public_footer.dart';
import 'public_header.dart';
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
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const PublicHeader(),
              _HeroBanner(
                title: AppStrings.t('Blog Details'),
                breadcrumb: '${AppStrings.t('Home')}  >  ${AppStrings.t('Blog')}',
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (detail == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(AppStrings.t('No Data Found')),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (detail.imageUrl.trim().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
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
                            label: _formatDate(detail.createdAt),
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
                      const SizedBox(height: 12),
                      Text(
                        _stripHtml(detail.description),
                        style: const TextStyle(
                          color: AppColors.ink,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              const PublicFooter(),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd MMMM yyyy', 'tr_TR').format(parsed);
  }

  String _stripHtml(String input) {
    return input.replaceAll(RegExp('<[^>]*>'), '').trim();
  }
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
