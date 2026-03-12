import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../catalog/student_course_catalog_screen.dart';
import '../lessons/student_course_detail_screen.dart';
import 'student_library_repository.dart';

class StudentLibraryScreen extends StatefulWidget {
  const StudentLibraryScreen({super.key});

  @override
  State<StudentLibraryScreen> createState() => _StudentLibraryScreenState();
}

class _StudentLibraryScreenState extends State<StudentLibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCatalog(BuildContext context, {String? search, String? mainCategory, String? title}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentCourseCatalogScreen(
          initialSearch: search,
          mainCategory: mainCategory,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('Library'))),
      body: FutureBuilder<LibraryPayload?>(
        future: StudentLibraryRepository().fetchLibrary(),
        builder: (context, snapshot) {
          final payload = snapshot.data;
          final categories = payload?.categories ?? const <LibraryCategory>[];
          final courses = payload?.popularCourses ?? const <LibraryCourse>[];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categories.isEmpty && courses.isEmpty) {
            return Center(child: Text(AppStrings.t('No Data!')));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(AppStrings.t('Library'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                AppStrings.t('Ders içeriklerine hızlı erişim.'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  final query = value.trim();
                  if (query.isEmpty) return;
                  _openCatalog(context, search: query, title: query);
                },
                decoration: InputDecoration(
                  hintText: AppStrings.t('Search'),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              if (categories.isNotEmpty)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: categories
                      .map(
                        (category) => _LibraryChip(
                          label: category.name,
                          onTap: () => _openCatalog(
                            context,
                            mainCategory: category.slug,
                            title: category.name,
                          ),
                        ),
                      )
                      .toList(),
                ),
              if (courses.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionCard(
                  title: AppStrings.t('Popular Courses'),
                  child: Column(
                    children: courses
                        .map(
                          (course) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ContentTile(
                              title: course.title,
                              subtitle: course.instructorName,
                              imageUrl: course.thumbnail,
                              rating: course.rating,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentCourseDetailScreen(
                                    title: course.title,
                                    instructor: course.instructorName,
                                    rating: course.rating,
                                    reviews: 0,
                                    progress: 0,
                                    courseSlug: course.slug,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LibraryChip extends StatelessWidget {
  const _LibraryChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.brand.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ContentTile extends StatelessWidget {
  const _ContentTile({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.rating,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final double rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hasImage
                  ? Image.network(
                      imageUrl,
                      width: 56,
                      height: 56,
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted)),
                  if (rating > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${rating.toStringAsFixed(1)} / 5',
                      style: const TextStyle(color: AppColors.brand),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: const Color(0xFFE2E8F0),
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book, color: AppColors.muted),
    );
  }
}
