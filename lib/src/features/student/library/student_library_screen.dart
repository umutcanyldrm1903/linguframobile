import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('Library')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppGlowBackground(
        child: FutureBuilder<StudentLibraryPayload?>(
          future: _future,
          builder: (context, snapshot) {
            final payload = snapshot.data;
            final categories =
                payload?.categories ?? const <StudentLibraryCategory>[];
            final items = payload?.items ?? const <StudentLibraryItem>[];
            final selectedCategory =
                payload?.selectedCategory ?? _selectedCategory;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return AppLoader(message: AppStrings.t('Library'));
            }

            if (snapshot.hasError) {
              return AppErrorState(
                message: AppStrings.t('Something went wrong'),
                onRetry: () => _load(category: selectedCategory),
                retryLabel: AppStrings.t('Try Again'),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _load(category: selectedCategory, silent: true),
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.xl),
                children: [
                  AnimatedPageEntrance(
                    child: GradientHero(
                      gradient: AppGradients.hero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: AppRadius.all(AppRadius.md),
                                ),
                                child: const Icon(
                                  Icons.local_library_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: AppSpace.md),
                              Expanded(
                                child: Text(
                                  AppStrings.t('Library'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.md),
                          Text(
                            AppStrings.t(
                              'Access the materials shared directly by your instructor.',
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  if (categories.isEmpty)
                    AppEmptyState(
                      icon: Icons.folder_open_outlined,
                      title: AppStrings.t('No materials shared yet.'),
                    )
                  else if (selectedCategory.isEmpty) ...[
                    SectionHeader(
                      title: AppStrings.t('Library'),
                      subtitle: AppStrings.t(
                        'Access the materials shared directly by your instructor.',
                      ),
                      icon: Icons.folder_copy_rounded,
                    ),
                    _CategoryGrid(
                      categories: categories,
                      onSelect: (category) => _load(category: category),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: AppChip(
                            label: AppStrings.t('Back to categories'),
                            selected: false,
                            icon: Icons.arrow_back_rounded,
                            onTap: () => _load(category: ''),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Flexible(
                          child: AppChip(
                            label: _categoryName(categories, selectedCategory),
                            selected: true,
                            icon: Icons.folder_rounded,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.lg),
                    if (items.isEmpty)
                      AppEmptyState(
                        icon: Icons.search_off_outlined,
                        title: AppStrings.t('No items in this category.'),
                      )
                    else
                      StaggeredReveal(
                        children: [
                          for (final item in items)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpace.md),
                              child: _LibraryItemCard(
                                item: item,
                                onTap: () => _openFile(item),
                              ),
                            ),
                        ],
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _categoryName(
    List<StudentLibraryCategory> categories,
    String selectedCategory,
  ) {
    final match = categories.firstWhere(
      (item) => item.slug == selectedCategory,
      orElse: () => StudentLibraryCategory(
        name: selectedCategory,
        slug: selectedCategory,
      ),
    );
    return match.name.isNotEmpty ? match.name : selectedCategory;
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.onSelect,
  });

  final List<StudentLibraryCategory> categories;
  final ValueChanged<String> onSelect;

  static const _gradients = <LinearGradient>[
    AppGradients.brand,
    AppGradients.violet,
    AppGradients.success,
    AppGradients.streak,
    AppGradients.gold,
    AppGradients.night,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpace.md,
        mainAxisSpacing: AppSpace.md,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        final gradient = _gradients[index % _gradients.length];
        return AppCard(
          onTap: () => onSelect(category.slug),
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: AppRadius.all(AppRadius.lg),
                  boxShadow: AppShadows.glow(
                    AppColors.brand,
                    opacity: 0.22,
                  ),
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
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
    final fileColor = _colorForType(item.fileType);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
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
                  color: fileColor.withValues(alpha: 0.14),
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: Icon(
                  _iconForType(item.fileType),
                  color: fileColor,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                    ),
                    if (item.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description.trim(),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              if (item.fileName.isNotEmpty)
                AppStatPill(
                  icon: Icons.insert_drive_file_outlined,
                  label: item.fileName,
                  color: fileColor,
                  onLight: true,
                ),
              if (item.instructorName.isNotEmpty)
                AppStatPill(
                  icon: Icons.person_outline_rounded,
                  label: '${AppStrings.t('Instructor')}: ${item.instructorName}',
                  color: AppColors.brand,
                  onLight: true,
                ),
              if (item.createdAt != null)
                AppStatPill(
                  icon: Icons.calendar_today_outlined,
                  label: DateFormat('dd MMM yyyy').format(item.createdAt!),
                  color: AppPalette.violet,
                  onLight: true,
                ),
            ],
          ),
        ],
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

  Color _colorForType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return AppPalette.danger;
      case 'doc':
      case 'docx':
        return AppPalette.info;
      case 'ppt':
      case 'pptx':
        return AppPalette.streak;
      case 'xls':
      case 'xlsx':
        return AppPalette.success;
      case 'mp4':
      case 'mov':
      case 'webm':
        return AppPalette.violet;
      default:
        return AppColors.brand;
    }
  }
}
