import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
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
    final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!opened) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('Orders'))),
      body: RefreshIndicator(
        onRefresh: () => _load(silent: true),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(AppStrings.t('Orders'),
                style: Theme.of(context).textTheme.titleLarge),
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
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderTile(
                  order: order,
                  onInvoice: () => _openInvoice(order.invoiceId),
                ),
              ),
            ),
          ],
        ),
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
    final badgeColor = isPaid ? const Color(0xFF22C55E) : AppColors.brand;

    return Container(
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
            children: [
              Expanded(
                child: Text(
                  '${AppStrings.t('Invoice')}: ${order.invoiceId}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isPaid ? AppStrings.t('Paid') : order.paymentStatus,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.paidAmountLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.brandDeep,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${AppStrings.t('Method')}: ${order.paymentMethod}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onInvoice,
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(AppStrings.t('Download Invoice')),
            ),
          ),
        ],
      ),
    );
  }
}
