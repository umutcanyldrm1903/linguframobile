import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../catalog/student_course_detail_screen.dart';
import 'student_wishlist_repository.dart';

String _errorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is Map) {
        return message.values.map((value) => value.toString()).join('\n');
      }
      if (message != null) {
        return message.toString();
      }
    }
  }
  return AppStrings.t('Something went wrong');
}

class StudentWishlistScreen extends StatefulWidget {
  const StudentWishlistScreen({super.key});

  @override
  State<StudentWishlistScreen> createState() => _StudentWishlistScreenState();
}

class _StudentWishlistScreenState extends State<StudentWishlistScreen> {
  final _repo = StudentWishlistRepository();
  bool _loading = true;
  List<CourseListItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final items = await _repo.fetchWishlist();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on DioException catch (e) {
      // API returns 404 when empty.
      if (e.response?.statusCode == 404) {
        if (!mounted) return;
        setState(() {
          _items = const [];
          _loading = false;
        });
        return;
      }
      rethrow;
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _remove(String slug) async {
    try {
      await _repo.toggleWishlist(slug);
      if (!mounted) return;
      setState(() {
        _items = _items.where((c) => c.slug != slug).toList(growable: false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Removed from wishlist'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(e))),
      );
    }
  }

  Future<void> _openCourse(String slug) async {
    final trimmed = slug.trim();
    if (trimmed.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentCatalogCourseDetailScreen(slug: trimmed),
      ),
    );
    if (!mounted) return;
    await _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppStrings.t('Wishlist'))),
      body: AppGlowBackground(
        accent: AppPalette.heart,
        child: RefreshIndicator(
          onRefresh: () => _load(silent: true),
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.xl),
            children: [
              AnimatedPageEntrance(
                child: GradientHero(
                  gradient: AppGradients.violet,
                  glowColor: AppPalette.heart,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.t('Wishlist'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppStrings.t('Saved courses'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                            if (!_loading && items.isNotEmpty) ...[
                              const SizedBox(height: AppSpace.md),
                              AppStatPill(
                                icon: Icons.favorite_rounded,
                                label: '${items.length}',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpace.huge),
                  child: AppLoader(),
                ),
              if (!_loading && items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
                  child: AppEmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: AppStrings.t('No Data Found'),
                    message: AppStrings.t('Saved courses'),
                    actionLabel: AppStrings.t('Browse Courses'),
                    onAction: () => Navigator.of(context).maybePop(),
                  ),
                ),
              if (!_loading && items.isNotEmpty)
                StaggeredReveal(
                  children: [
                    for (final course in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.md),
                        child: _CourseTile(
                          course: course,
                          onTap: () => _openCourse(course.slug),
                          onRemove: () => _remove(course.slug),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    required this.course,
    required this.onTap,
    required this.onRemove,
  });

  final CourseListItem course;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = course.thumbnail.trim().isNotEmpty;
    final rating = course.rating;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.all(AppRadius.sm),
            child: hasImage
                ? Image.network(
                    course.thumbnail,
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  course.instructorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    if (rating > 0) ...[
                      AppStatPill(
                        icon: Icons.star_rounded,
                        label: rating.toStringAsFixed(1),
                        color: AppPalette.gold,
                        onLight: true,
                      ),
                      const SizedBox(width: AppSpace.sm),
                    ],
                    Expanded(
                      child: Text(
                        course.priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.favorite_rounded, color: AppPalette.heart),
            tooltip: AppStrings.t('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 68,
      height: 68,
      decoration: const BoxDecoration(
        gradient: AppGradients.sky,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book_rounded, color: AppColors.muted),
    );
  }
}
