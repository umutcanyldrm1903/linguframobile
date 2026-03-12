import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(title: Text(AppStrings.t('Wishlist'))),
      body: RefreshIndicator(
        onRefresh: () => _load(silent: true),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              AppStrings.t('Wishlist'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
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
                child: _CourseTile(
                  course: course,
                  onTap: () => _openCourse(course.slug),
                  onRemove: () => _remove(course.slug),
                ),
              ),
            ),
          ],
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
                        const Icon(Icons.star,
                            size: 16, color: AppColors.brand),
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
              icon: const Icon(Icons.favorite, color: AppColors.brand),
              tooltip: AppStrings.t('Remove'),
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
