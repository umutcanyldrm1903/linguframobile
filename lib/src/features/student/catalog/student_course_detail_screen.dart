import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _load,
                            child: Text(AppStrings.t('Try Again')),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _Header(detail: detail!),
                      const SizedBox(height: 14),
                      _Description(text: detail.description),
                      const SizedBox(height: 14),
                      _Curriculum(curriculums: detail.curriculums),
                    ],
                  )),
      bottomNavigationBar: _loading || detail == null
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _actionLoading ? null : _addToCart,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(AppStrings.t('Add To Cart')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _actionLoading ? null : _goCheckout,
                      icon: const Icon(Icons.payment),
                      label: Text(AppStrings.t('Proceed to checkout')),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 12),
          Text(detail.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(instructor, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (detail.rating > 0)
                _Chip(
                  icon: Icons.star,
                  label: detail.rating.toStringAsFixed(1),
                ),
              if (detail.reviewsCount > 0)
                _Chip(
                  icon: Icons.reviews_outlined,
                  label: '${detail.reviewsCount} ${AppStrings.t('Reviews')}',
                ),
              if (detail.students > 0)
                _Chip(
                  icon: Icons.group_outlined,
                  label: '${detail.students} ${AppStrings.t('Students')}',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: AppColors.brandDeep,
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
      color: const Color(0xFFE2E8F0),
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book, color: AppColors.muted, size: 34),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final hasText = text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t('Description'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            hasText ? text : AppStrings.t('No description'),
            style: const TextStyle(height: 1.4),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t('Curriculum'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (curriculums.isEmpty)
            Text(AppStrings.t('No Data Found'))
          else
            ...curriculums.map(
              (section) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    if (section.items.isEmpty)
                      Text(
                        AppStrings.t('No Data Found'),
                        style: const TextStyle(color: AppColors.muted),
                      )
                    else
                      ...section.items
                          .take(6)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    _iconForType(item.type),
                                    size: 16,
                                    color: AppColors.brand,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.title.trim().isNotEmpty
                                          ? item.title
                                          : item.type,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.duration.trim().isNotEmpty)
                                    Text(
                                      item.duration,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brand),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
