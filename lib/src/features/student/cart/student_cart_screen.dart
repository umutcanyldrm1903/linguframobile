import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
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
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  AppStrings.t('Payment Gateway'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              ...gateways.map(
                (gateway) => ListTile(
                  leading: gateway.logo.trim().isEmpty
                      ? const Icon(Icons.account_balance_wallet_outlined)
                      : Image.network(
                          gateway.logo,
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.account_balance_wallet_outlined),
                        ),
                  title: Text(gateway.name),
                  onTap: () => Navigator.pop(context, gateway),
                ),
              ),
            ],
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

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('Cart'))),
      body: RefreshIndicator(
        onRefresh: () => _load(silent: true),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              AppStrings.t('Cart'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (total.isNotEmpty)
              Text(
                '${AppStrings.t('Total')}: $total',
                style: const TextStyle(fontWeight: FontWeight.w800),
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
                child: _CartTile(
                  course: course,
                  onTap: () => _openCourse(course),
                  onRemove: () => _remove(course.slug),
                ),
              ),
            ),
            if (!_loading && items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton.icon(
                  onPressed: _checkingOut ? null : _checkout,
                  icon: const Icon(Icons.payment),
                  label: Text(
                    _checkingOut
                        ? AppStrings.t('Submitting')
                        : AppStrings.t('Proceed to checkout'),
                  ),
                ),
              ),
          ],
        ),
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
                  Text(
                    course.priceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandDeep,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: AppColors.muted),
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
      child: const Icon(Icons.shopping_cart, color: AppColors.muted),
    );
  }
}
