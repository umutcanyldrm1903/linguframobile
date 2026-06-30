import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../payment/payment_processing_screen.dart';
import '../catalog/student_course_detail_screen.dart';
import 'student_cart_repository.dart';

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

class StudentCartScreen extends StatefulWidget {
  const StudentCartScreen({super.key, this.autoCheckout = false});

  final bool autoCheckout;

  @override
  State<StudentCartScreen> createState() => _StudentCartScreenState();
}

class _StudentCartScreenState extends State<StudentCartScreen> {
  final _repo = StudentCartRepository();
  bool _loading = true;
  bool _checkingOut = false;
  bool _autoCheckoutTriggered = false;
  CartPayload? _payload;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final currency = await SecureStorage.getCurrencyCode();
      final payload = await _repo.fetchCart(currency: currency);
      if (!mounted) return;
      setState(() {
        _payload = payload;
        _loading = false;
      });

      if (widget.autoCheckout &&
          !_autoCheckoutTriggered &&
          payload.courses.isNotEmpty) {
        _autoCheckoutTriggered = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _checkout();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
    }
  }

  Future<void> _remove(String slug) async {
    try {
      await _repo.removeFromCart(slug);
      if (!mounted) return;
      await _load(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Item removed from cart!'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
    }
  }

  Future<void> _openCourse(CartCourseItem course) async {
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
    if (!mounted) return;
    await _load(silent: true);
  }

  Future<void> _checkout() async {
    if (_checkingOut) return;

    final items = _payload?.courses ?? const <CartCourseItem>[];
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.t('Cart is empty!'))));
      return;
    }

    setState(() => _checkingOut = true);
    try {
      final gateways = await _repo.fetchPaymentGateways();
      if (!mounted) return;
      if (gateways.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('Payment Gateway'))),
        );
        return;
      }

      final selected = await _pickGateway(gateways);
      if (!mounted || selected == null) return;

      final currency = await SecureStorage.getCurrencyCode();
      final init = await _repo.startCheckout(
        gateway: selected.key,
        currency: currency,
      );

      if (!mounted) return;
      final paymentUrl = init?.paymentUrl.trim() ?? '';
      final invoiceId = init?.invoiceId.trim() ?? '';
      if (paymentUrl.isEmpty || invoiceId.isEmpty) {
        throw Exception('Invalid payment initialization response.');
      }

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentProcessingScreen(
            invoiceId: invoiceId,
            paymentUrl: paymentUrl,
          ),
        ),
      );

      if (!mounted) return;
      if (result == true) {
        await showCelebration(
          context,
          title: AppStrings.t('Payment Success.'),
          icon: Icons.verified_rounded,
          color: AppPalette.success,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('Payment Success.'))),
        );
      } else if (result == false) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.t('Payment Fail'))));
      }

      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  Future<CartPaymentGateway?> _pickGateway(List<CartPaymentGateway> gateways) {
    return showModalBottomSheet<CartPaymentGateway>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: AppSpace.lg),
                  decoration: BoxDecoration(
                    color: AppPalette.line,
                    borderRadius: AppRadius.pill,
                  ),
                ),
                SectionHeader(
                  title: AppStrings.t('Payment Gateway'),
                  icon: Icons.account_balance_wallet_rounded,
                ),
                ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: gateways.map(
                    (gateway) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.sm),
                      child: AppCard(
                        onTap: () => Navigator.pop(context, gateway),
                        padding: const EdgeInsets.all(AppSpace.md),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: gateway.logo.trim().isEmpty
                                  ? const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: AppColors.brand,
                                    )
                                  : Image.network(
                                      gateway.logo,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons
                                            .account_balance_wallet_outlined,
                                        color: AppColors.brand,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Text(
                                gateway.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload;
    final items = payload?.courses ?? const <CartCourseItem>[];
    final total = payload?.totalAmount ?? '';
    final qty = payload?.totalQty ?? items.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppStrings.t('Cart'))),
      body: AppGlowBackground(
        child: RefreshIndicator(
          onRefresh: () => _load(silent: true),
          child: _loading
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    AppLoader(),
                  ],
                )
              : (items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        AppEmptyState(
                          icon: Icons.shopping_cart_outlined,
                          title: AppStrings.t('No Data Found'),
                          message: AppStrings.t('Cart is empty!'),
                          actionLabel: AppStrings.t('Browse Courses'),
                          onAction: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(AppSpace.xl),
                      children: [
                        AnimatedPageEntrance(
                          child: _CartSummaryHero(
                            total: total,
                            qty: qty,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xl),
                        SectionHeader(
                          title: AppStrings.t('Cart'),
                          subtitle:
                              '$qty ${AppStrings.t('Courses')}',
                          icon: Icons.shopping_bag_rounded,
                        ),
                        StaggeredReveal(
                          children: [
                            for (final course in items)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpace.md,
                                ),
                                child: _CartTile(
                                  course: course,
                                  onTap: () => _openCourse(course),
                                  onRemove: () => _remove(course.slug),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.sm),
                        AppButton(
                          label: _checkingOut
                              ? AppStrings.t('Submitting')
                              : AppStrings.t('Proceed to checkout'),
                          icon: Icons.lock_rounded,
                          tone: AppButtonTone.success,
                          loading: _checkingOut,
                          onPressed: _checkingOut ? null : _checkout,
                        ),
                      ],
                    )),
        ),
      ),
    );
  }
}

/// Toplam tutarı öne çıkaran gradyanlı özet kartı.
class _CartSummaryHero extends StatelessWidget {
  const _CartSummaryHero({required this.total, required this.qty});

  final String total;
  final int qty;

  @override
  Widget build(BuildContext context) {
    return GradientHero(
      gradient: AppGradients.hero,
      glowColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppStatPill(
                icon: Icons.shopping_bag_rounded,
                label: '$qty',
              ),
              const SizedBox(width: AppSpace.sm),
              AppStatPill(
                icon: Icons.shopping_cart_rounded,
                label: AppStrings.t('Cart'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            AppStrings.t('Total'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            total.isEmpty ? '—' : total,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 30,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({
    required this.course,
    required this.onTap,
    required this.onRemove,
  });

  final CartCourseItem course;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = course.thumbnail.trim().isNotEmpty;
    final hasRating = course.rating > 0;

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
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      course.priceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandDeep,
                        fontSize: 15,
                      ),
                    ),
                    if (hasRating)
                      AppStatPill(
                        icon: Icons.star_rounded,
                        label: course.rating.toStringAsFixed(1),
                        color: AppPalette.gold,
                        onLight: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppPalette.danger),
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
      decoration: BoxDecoration(
        gradient: AppGradients.sky,
        borderRadius: AppRadius.all(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.shopping_cart_rounded, color: AppColors.muted),
    );
  }
}
