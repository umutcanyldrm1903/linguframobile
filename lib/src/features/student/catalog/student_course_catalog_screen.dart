import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import 'student_catalog_repository.dart';
import 'student_course_detail_screen.dart';

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

class StudentCourseCatalogScreen extends StatefulWidget {
  const StudentCourseCatalogScreen({
    super.key,
    this.initialSearch,
    this.mainCategory,
    this.title,
  });

  final String? initialSearch;
  final String? mainCategory;
  final String? title;

  @override
  State<StudentCourseCatalogScreen> createState() =>
      _StudentCourseCatalogScreenState();
}

class _StudentCourseCatalogScreenState
    extends State<StudentCourseCatalogScreen> {
  final _repo = StudentCatalogRepository();
  late final _searchController = TextEditingController(
    text: widget.initialSearch ?? '',
  );

  bool _loading = true;
  List<CatalogCourseItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final currency = await SecureStorage.getCurrencyCode();
      final items = await _repo.searchCourses(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        mainCategory: widget.mainCategory,
        currency: currency,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        if (!mounted) return;
        setState(() {
          _items = const [];
          _loading = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
    }
  }

  Future<void> _openCourse(CatalogCourseItem course) async {
    final trimmed = course.slug.trim();
    if (trimmed.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentCatalogCourseDetailScreen(
          slug: trimmed,
          fallbackTitle: course.title,
        ),
      ),
    );
  }

  Future<void> _toggleWishlist(String slug) async {
    try {
      await _repo.toggleWishlist(slug);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.t('Success'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
    }
  }

  Future<void> _addToCart(String slug) async {
    try {
      await _repo.addToCart(slug);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Added to cart successfully!'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final title = widget.title?.trim().isNotEmpty == true
        ? widget.title!.trim()
        : AppStrings.t('Courses');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: AppGlowBackground(
        child: RefreshIndicator(
          onRefresh: () => _load(silent: true),
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.xl),
            children: [
              AnimatedPageEntrance(
                child: GradientHero(
                  gradient: AppGradients.hero,
                  glowColor: AppColors.accent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.t('Find your next course'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!_loading && items.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.md),
                        AppStatPill(
                          icon: Icons.menu_book_rounded,
                          label: '${items.length} ${AppStrings.t('Courses')}',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              AnimatedPageEntrance(
                delay: const Duration(milliseconds: 60),
                child: _SearchField(
                  controller: _searchController,
                  onSubmitted: () => _load(),
                  onClear: () {
                    _searchController.clear();
                    _load();
                  },
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpace.huge),
                  child: AppLoader(),
                ),
              if (!_loading && items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
                  child: AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: AppStrings.t('No Data Found'),
                    message: AppStrings.t('Try a different search'),
                  ),
                ),
              if (!_loading && items.isNotEmpty)
                StaggeredReveal(
                  children: [
                    for (final course in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.md),
                        child: _CatalogCourseTile(
                          course: course,
                          onTap: () => _openCourse(course),
                          onWishlist: () => _toggleWishlist(course.slug),
                          onCart: () => _addToCart(course.slug),
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: 2),
      radius: AppRadius.round,
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.brand),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmitted(),
              decoration: InputDecoration(
                hintText: AppStrings.t('Search'),
                border: InputBorder.none,
                hintStyle: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.clear_rounded, color: AppColors.muted),
            tooltip: AppStrings.t('Clear'),
          ),
        ],
      ),
    );
  }
}

class _CatalogCourseTile extends StatelessWidget {
  const _CatalogCourseTile({
    required this.course,
    required this.onTap,
    required this.onWishlist,
    required this.onCart,
  });

  final CatalogCourseItem course;
  final VoidCallback onTap;
  final VoidCallback onWishlist;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    final hasImage = course.thumbnail.trim().isNotEmpty;
    final rating = course.rating;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                if (course.instructorName.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    course.instructorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpace.sm,
                  runSpacing: 6,
                  children: [
                    if (rating > 0)
                      AppStatPill(
                        icon: Icons.star_rounded,
                        label: rating.toStringAsFixed(1),
                        color: AppPalette.gold,
                        onLight: true,
                      ),
                    if (course.priceLabel.trim().isNotEmpty)
                      Text(
                        course.priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandDeep,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          Column(
            children: [
              IconButton(
                onPressed: onWishlist,
                icon: const Icon(Icons.favorite_border_rounded),
                color: AppPalette.heart,
                tooltip: AppStrings.t('Wishlist'),
              ),
              IconButton(
                onPressed: onCart,
                icon: const Icon(Icons.add_shopping_cart_rounded),
                color: AppColors.brand,
                tooltip: AppStrings.t('Cart'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        gradient: AppGradients.sky,
        borderRadius: AppRadius.all(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book_rounded, color: AppColors.brand),
    );
  }
}
