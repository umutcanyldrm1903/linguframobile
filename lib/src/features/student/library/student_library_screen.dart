import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared/content_preview_launcher.dart';
import 'student_library_repository.dart';

class StudentLibraryScreen extends StatefulWidget {
  const StudentLibraryScreen({super.key});

  @override
  State<StudentLibraryScreen> createState() => _StudentLibraryScreenState();
}

class _StudentLibraryScreenState extends State<StudentLibraryScreen> {
  final StudentLibraryRepository _repo = StudentLibraryRepository();
  late Future<StudentLibraryPayload?> _future;
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchLibrary();
  }

  Future<void> _load({String? category, bool silent = false}) async {
    final nextCategory = category ?? '';
    if (!silent) {
      setState(() {
        _selectedCategory = nextCategory;
        _future = _repo.fetchLibrary(category: nextCategory);
      });
      return;
    }

    final payload = await _repo.fetchLibrary(category: nextCategory);
    if (!mounted) return;
    setState(() {
      _selectedCategory = nextCategory;
      _future = Future<StudentLibraryPayload?>.value(payload);
    });
  }

  Future<void> _openFile(StudentLibraryItem item) async {
    await openContentPreview(
      context,
      title: item.fileName.isNotEmpty ? item.fileName : item.title,
      rawUrl: item.filePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('Library'))),
      body: FutureBuilder<StudentLibraryPayload?>(
        future: _future,
        builder: (context, snapshot) {
          final payload = snapshot.data;
          final categories =
              payload?.categories ?? const <StudentLibraryCategory>[];
          final items = payload?.items ?? const <StudentLibraryItem>[];
          final selectedCategory =
              payload?.selectedCategory ?? _selectedCategory;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppStrings.t('Something went wrong')),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _load(category: selectedCategory),
                    child: Text(AppStrings.t('Try Again')),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _load(category: selectedCategory, silent: true),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  AppStrings.t('Library'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.t(
                    'Access the materials shared directly by your instructor.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                if (categories.isEmpty)
                  _EmptyState(
                    icon: Icons.folder_open_outlined,
                    text: AppStrings.t('No materials shared yet.'),
                  )
                else if (selectedCategory.isEmpty)
                  _CategoryGrid(
                    categories: categories,
                    onSelect: (category) => _load(category: category),
                  )
                else ...[
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _load(category: ''),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(AppStrings.t('Back to categories')),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          categories
                                  .firstWhere(
                                    (item) => item.slug == selectedCategory,
                                    orElse: () => StudentLibraryCategory(
                                      name: selectedCategory,
                                      slug: selectedCategory,
                                    ),
                                  )
                                  .name
                                  .isNotEmpty
                              ? categories
                                  .firstWhere(
                                    (item) => item.slug == selectedCategory,
                                    orElse: () => StudentLibraryCategory(
                                      name: selectedCategory,
                                      slug: selectedCategory,
                                    ),
                                  )
                                  .name
                              : selectedCategory,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    _EmptyState(
                      icon: Icons.search_off_outlined,
                      text: AppStrings.t('No items in this category.'),
                    )
                  else
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LibraryItemCard(
                          item: item,
                          onTap: () => _openFile(item),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.onSelect,
  });

  final List<StudentLibraryCategory> categories;
  final ValueChanged<String> onSelect;

  static const _palette = <Color>[
    Color(0xFFDbe7F5),
    Color(0xFFF6E9E2),
    Color(0xFFF5CFD1),
    Color(0xFFF2D9AE),
    Color(0xFFE7F3DD),
    Color(0xFFF5D6E4),
    Color(0xFFF6D7D7),
    Color(0xFFD5E8ED),
    Color(0xFFD7EAD9),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        final color = _palette[index % _palette.length];
        return InkWell(
          onTap: () => onSelect(category.slug),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.folder_outlined,
                    color: AppColors.brandDeep,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandDeep,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LibraryItemCard extends StatelessWidget {
  const _LibraryItemCard({
    required this.item,
    required this.onTap,
  });

  final StudentLibraryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconForType(item.fileType),
                    color: AppColors.brandDeep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 4),
                      if (item.description.trim().isNotEmpty)
                        Text(
                          item.description.trim(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (item.fileName.isNotEmpty) _MetaPill(label: item.fileName),
                if (item.instructorName.isNotEmpty)
                  _MetaPill(
                    label:
                        '${AppStrings.t('Instructor')}: ${item.instructorName}',
                  ),
                if (item.createdAt != null)
                  _MetaPill(
                    label: DateFormat('dd MMM yyyy').format(item.createdAt!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'mp4':
      case 'mov':
      case 'webm':
        return Icons.play_circle_outline;
      default:
        return Icons.attach_file;
    }
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brand.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: AppColors.brandDeep, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
