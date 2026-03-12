import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: () => _load(silent: true),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: AppStrings.t('Search'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _load();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_loading && items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: Center(
                  child: Text(
                    AppStrings.t('No Data Found'),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              ),
            ...items.map(
              (course) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CatalogCourseTile(
                  course: course,
                  onTap: () => _openCourse(course),
                  onWishlist: () => _toggleWishlist(course.slug),
                  onCart: () => _addToCart(course.slug),
                ),
              ),
            ),
          ],
        ),
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasImage
                  ? Image.network(
                      course.thumbnail,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.instructorName,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (rating > 0) ...[
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.brand,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          course.priceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: onWishlist,
                  icon: const Icon(Icons.favorite_border),
                  color: AppColors.brand,
                  tooltip: AppStrings.t('Wishlist'),
                ),
                IconButton(
                  onPressed: onCart,
                  icon: const Icon(Icons.add_shopping_cart),
                  color: AppColors.muted,
                  tooltip: AppStrings.t('Cart'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFE2E8F0),
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book, color: AppColors.muted),
    );
  }
}
