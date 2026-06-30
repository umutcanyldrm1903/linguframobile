import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../cart/student_cart_screen.dart';
import 'student_catalog_repository.dart';

String _detailErrorMessage(Object error) {
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

class StudentCatalogCourseDetailScreen extends StatefulWidget {
  const StudentCatalogCourseDetailScreen({
    super.key,
    required this.slug,
    this.fallbackTitle,
  });

  final String slug;
  final String? fallbackTitle;

  @override
  State<StudentCatalogCourseDetailScreen> createState() =>
      _StudentCatalogCourseDetailScreenState();
}

class _StudentCatalogCourseDetailScreenState
    extends State<StudentCatalogCourseDetailScreen> {
  final StudentCatalogRepository _repository = StudentCatalogRepository();

  bool _loading = true;
  bool _actionLoading = false;
  CatalogCourseDetail? _detail;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final currency = await SecureStorage.getCurrencyCode();
      final detail = await _repository.fetchCourseDetail(
        widget.slug,
        currency: currency,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
        _error = detail == null ? AppStrings.t('No Data Found') : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _detailErrorMessage(error);
      });
    }
  }

  Future<void> _addToCart({bool showSuccess = true}) async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);

    try {
      await _repository.addToCart(widget.slug);
      if (!mounted) return;
      if (showSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('Added to cart successfully!'))),
        );
      }
    } catch (error) {
      final message = _detailErrorMessage(error);
      final lower = message.toLowerCase();
      final alreadyInCart =
          lower.contains('already added') ||
          lower.contains('zaten') ||
          lower.contains('already in cart');
      if (!alreadyInCart && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
      if (!alreadyInCart) rethrow;
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _goCheckout() async {
    try {
      await _addToCart(showSuccess: false);
    } catch (_) {
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StudentCartScreen(autoCheckout: true),
      ),
    );
    if (!mounted) return;
    await _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final title = detail?.title.trim().isNotEmpty == true
        ? detail!.title
        : (widget.fallbackTitle ?? AppStrings.t('Course Details'));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: false,
      body: AppGlowBackground(
        child: _loading
            ? AppLoader(message: AppStrings.t('Course Details'))
            : (_error != null
                  ? AppErrorState(
                      message: _error!,
                      onRetry: _load,
                      retryLabel: AppStrings.t('Try Again'),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.lg,
                        AppSpace.lg,
                        AppSpace.lg,
                        AppSpace.xxxl,
                      ),
                      children: [
                        AnimatedPageEntrance(
                          child: _Header(detail: detail!),
                        ),
                        const SizedBox(height: AppSpace.lg),
                        AnimatedPageEntrance(
                          delay: const Duration(milliseconds: 90),
                          child: _Description(text: detail.description),
                        ),
                        const SizedBox(height: AppSpace.lg),
                        AnimatedPageEntrance(
                          delay: const Duration(milliseconds: 160),
                          child: _Curriculum(curriculums: detail.curriculums),
                        ),
                      ],
                    )),
      ),
      bottomNavigationBar: _loading || detail == null
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.sm,
                AppSpace.lg,
                AppSpace.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppGhostButton(
                      label: AppStrings.t('Add To Cart'),
                      icon: Icons.add_shopping_cart,
                      onPressed: _actionLoading ? null : _addToCart,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: AppButton(
                      label: AppStrings.t('Proceed to checkout'),
                      icon: Icons.payment,
                      tone: AppButtonTone.brand,
                      loading: _actionLoading,
                      onPressed: _actionLoading ? null : _goCheckout,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail});

  final CatalogCourseDetail detail;

  @override
  Widget build(BuildContext context) {
    final hasImage = detail.thumbnail.trim().isNotEmpty;
    final instructor = detail.instructorName.trim().isNotEmpty
        ? detail.instructorName
        : AppStrings.t('Instructor');
    final price = detail.discountLabel.trim().isNotEmpty
        ? detail.discountLabel
        : detail.priceLabel;

    return GradientHero(
      gradient: AppGradients.hero,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.all(AppRadius.md),
            child: hasImage
                ? Image.network(
                    detail.thumbnail,
                    width: double.infinity,
                    height: 190,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            detail.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  instructor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              if (detail.rating > 0)
                AppStatPill(
                  icon: Icons.star_rounded,
                  label: detail.rating.toStringAsFixed(1),
                  color: AppPalette.gold,
                ),
              if (detail.reviewsCount > 0)
                AppStatPill(
                  icon: Icons.reviews_outlined,
                  label: '${detail.reviewsCount} ${AppStrings.t('Reviews')}',
                ),
              if (detail.students > 0)
                AppStatPill(
                  icon: Icons.group_outlined,
                  label: '${detail.students} ${AppStrings.t('Students')}',
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              price,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: 190,
      color: Colors.white.withValues(alpha: 0.16),
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book, color: Colors.white70, size: 34),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final hasText = text.trim().isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: AppStrings.t('Description'),
            icon: Icons.subject_rounded,
          ),
          Text(
            hasText ? text : AppStrings.t('No description'),
            style: const TextStyle(height: 1.5, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _Curriculum extends StatelessWidget {
  const _Curriculum({required this.curriculums});

  final List<CatalogCurriculum> curriculums;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: AppStrings.t('Curriculum'),
            icon: Icons.menu_book_rounded,
          ),
          if (curriculums.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              child: Text(
                AppStrings.t('No Data Found'),
                style: const TextStyle(color: AppColors.muted),
              ),
            )
          else
            StaggeredReveal(
              children: [
                for (final section in curriculums)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: _ChapterTile(
                      section: section,
                      iconForType: _iconForType,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'quiz':
        return Icons.quiz;
      case 'live':
        return Icons.video_call;
      case 'document':
        return Icons.description;
      default:
        return Icons.play_circle_outline;
    }
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({required this.section, required this.iconForType});

  final CatalogCurriculum section;
  final IconData Function(String type) iconForType;

  @override
  Widget build(BuildContext context) {
    final items = section.items.take(6).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.cloud,
        borderRadius: AppRadius.all(AppRadius.sm),
        border: Border.all(color: AppPalette.line, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            0,
            AppSpace.md,
            AppSpace.md,
          ),
          collapsedIconColor: AppColors.brand,
          iconColor: AppColors.brand,
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.12),
              borderRadius: AppRadius.all(AppRadius.sm),
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              size: 18,
              color: AppColors.brand,
            ),
          ),
          title: Text(
            section.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          children: [
            if (items.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.t('No Data Found'),
                  style: const TextStyle(color: AppColors.muted),
                ),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: Row(
                    children: [
                      Icon(
                        iconForType(item.type),
                        size: 17,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          item.title.trim().isNotEmpty
                              ? item.title
                              : item.type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.ink),
                        ),
                      ),
                      if (item.duration.trim().isNotEmpty)
                        Text(
                          item.duration,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
