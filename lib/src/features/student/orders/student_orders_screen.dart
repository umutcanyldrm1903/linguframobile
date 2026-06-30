import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../shared/content_preview_launcher.dart';
import 'student_orders_repository.dart';

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

class StudentOrdersScreen extends StatefulWidget {
  const StudentOrdersScreen({super.key});

  @override
  State<StudentOrdersScreen> createState() => _StudentOrdersScreenState();
}

class _StudentOrdersScreenState extends State<StudentOrdersScreen> {
  final _repo = StudentOrdersRepository();
  bool _loading = true;
  List<OrderListItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final items = await _repo.fetchOrders();
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
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(e))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(e))),
      );
    }
  }

  Future<void> _openInvoice(String invoiceId) async {
    final token = await SecureStorage.getToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Please login first'))),
      );
      return;
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/download-invoice/$invoiceId')
        .replace(queryParameters: {'bearer_token': token});
    await openContentPreview(
      context,
      title: '${AppStrings.t('Invoice')} $invoiceId',
      rawUrl: uri.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final paidCount = items
        .where((o) =>
            o.paymentStatus.toLowerCase() == 'paid' ||
            o.status.toLowerCase() == 'completed')
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppStrings.t('Orders'))),
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
                          icon: Icons.receipt_long_rounded,
                          title: AppStrings.t('No Data Found'),
                          message: AppStrings.t('Orders'),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(AppSpace.xl),
                      children: [
                        AnimatedPageEntrance(
                          child: _OrdersHero(
                            total: items.length,
                            paid: paidCount,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xl),
                        SectionHeader(
                          title: AppStrings.t('Orders'),
                          subtitle:
                              '${items.length} ${AppStrings.t('Invoice')}',
                          icon: Icons.receipt_long_rounded,
                        ),
                        StaggeredReveal(
                          children: [
                            for (final order in items)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpace.md,
                                ),
                                child: _OrderTile(
                                  order: order,
                                  onInvoice: () =>
                                      _openInvoice(order.invoiceId),
                                ),
                              ),
                          ],
                        ),
                      ],
                    )),
        ),
      ),
    );
  }
}

/// Sipariş geçmişini öne çıkaran gradyanlı özet kartı.
class _OrdersHero extends StatelessWidget {
  const _OrdersHero({required this.total, required this.paid});

  final int total;
  final int paid;

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
              const Icon(Icons.receipt_long_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  AppStrings.t('Orders'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          AnimatedCounter(
            value: total,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.t('Invoice'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              AppStatPill(
                icon: Icons.verified_rounded,
                label: '$paid ${AppStrings.t('Paid')}',
                color: AppPalette.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    required this.onInvoice,
  });

  final OrderListItem order;
  final VoidCallback onInvoice;

  @override
  Widget build(BuildContext context) {
    final paymentStatus = order.paymentStatus.toLowerCase();
    final status = order.status.toLowerCase();
    final isPaid = paymentStatus == 'paid' || status == 'completed';
    final statusColor = isPaid ? AppPalette.success : AppPalette.warning;
    final amount = _AmountParts.from(order.paidAmountLabel);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${AppStrings.t('Invoice')}: ${order.invoiceId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              AppStatPill(
                icon: isPaid
                    ? Icons.check_circle_rounded
                    : Icons.schedule_rounded,
                label: isPaid ? AppStrings.t('Paid') : order.paymentStatus,
                color: statusColor,
                onLight: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          if (amount != null)
            AnimatedCounter(
              value: amount.value,
              prefix: amount.prefix,
              suffix: amount.suffix,
              fractionDigits: amount.fractionDigits,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: AppColors.brandDeep,
              ),
            )
          else
            Text(
              order.paidAmountLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: AppColors.brandDeep,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            '${AppStrings.t('Method')}: ${order.paymentMethod}',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          AppGhostButton(
            label: AppStrings.t('Download Invoice'),
            icon: Icons.picture_as_pdf_rounded,
            expand: false,
            onPressed: onInvoice,
          ),
        ],
      ),
    );
  }
}

/// Para etiketinden (örn. "$49.00", "₺199") gerçek sayıyı ayrıştırır;
/// sembol/biçim korunarak [AnimatedCounter]'a verilir. Ayrıştırılamazsa null.
class _AmountParts {
  const _AmountParts({
    required this.value,
    required this.prefix,
    required this.suffix,
    required this.fractionDigits,
  });

  final double value;
  final String prefix;
  final String suffix;
  final int fractionDigits;

  static _AmountParts? from(String label) {
    final match = RegExp(r'[\d.,]*\d').firstMatch(label);
    if (match == null) return null;
    final raw = match.group(0)!;
    // Sadece basamak ve nokta/virgül içeren parçayı normalize et.
    var normalized = raw;
    final lastDot = normalized.lastIndexOf('.');
    final lastComma = normalized.lastIndexOf(',');
    if (lastComma > lastDot) {
      // Virgül ondalık ayırıcı (örn. 1.234,56) -> noktayı kaldır, virgülü noktaya çevir.
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // Nokta ondalık ayırıcı (örn. 1,234.56) -> virgülleri kaldır.
      normalized = normalized.replaceAll(',', '');
    }
    final value = double.tryParse(normalized);
    if (value == null) return null;

    final prefix = label.substring(0, match.start);
    final suffix = label.substring(match.end);
    final dotIndex = normalized.indexOf('.');
    final fractionDigits =
        dotIndex == -1 ? 0 : (normalized.length - dotIndex - 1);

    return _AmountParts(
      value: value,
      prefix: prefix,
      suffix: suffix,
      fractionDigits: fractionDigits.clamp(0, 2),
    );
  }
}
