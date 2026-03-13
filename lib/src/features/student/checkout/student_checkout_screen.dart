import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../payment/iyzico_native_payment_screen.dart';
import '../../payment/payment_processing_screen.dart';
import '../../public/public_repository.dart';
import 'student_payment_repository.dart';

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

class StudentCheckoutScreen extends StatefulWidget {
  const StudentCheckoutScreen({
    super.key,
    required this.plan,
    required this.currency,
  });

  final StudentPlan plan;
  final String currency;

  @override
  State<StudentCheckoutScreen> createState() => _StudentCheckoutScreenState();
}

class _StudentCheckoutScreenState extends State<StudentCheckoutScreen> {
  bool _submitting = false;

  bool _shouldUseNativeIyzico() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<bool> _ensureLoggedIn() async {
    final token = await SecureStorage.getToken();
    if (!mounted) return false;
    if (token != null && token.isNotEmpty) return true;

    final goLogin = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppStrings.t('Login required')),
            content: Text(AppStrings.t('Please login first')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppStrings.t('Cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppStrings.t('Login')),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) return false;
    if (goLogin) {
      Navigator.pushNamed(context, '/login');
    }
    return false;
  }

  Future<void> _pay() async {
    if (_submitting) return;
    if (!await _ensureLoggedIn()) return;
    setState(() => _submitting = true);
    try {
      final plan = widget.plan;
      final title = plan.displayTitle.isNotEmpty
          ? plan.displayTitle
          : (plan.title.isNotEmpty ? plan.title : 'Plan');
      final priceLabel = _formatPrice(plan.price, widget.currency);

      if (_shouldUseNativeIyzico()) {
        if (!mounted) return;
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => IyzicoNativePaymentScreen(
              planKey: plan.key,
              planTitle: title,
              currency: widget.currency,
              priceLabel: priceLabel,
            ),
          ),
        );
        if (!mounted) return;

        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.t('Payment Success.'))),
          );
        } else if (result == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.t('Payment Fail'))),
          );
        }
        return;
      }

      final init = await StudentPaymentRepository().startPlanPayment(
        plan.key,
        currency: widget.currency,
      );

      final url = init?.paymentUrl ?? '';
      if (url.isEmpty) {
        throw Exception('missing_url');
      }

      if (!mounted) return;
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentProcessingScreen(
            invoiceId: init?.invoiceId ?? '',
            paymentUrl: url,
          ),
        ),
      );
      if (!mounted) return;
      if (result == true) {
        final status = await StudentPaymentRepository()
            .fetchOrderStatus(init?.invoiceId ?? '');
        if (!mounted) return;
        final isSuccess = status?.isSuccess ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSuccess
                  ? AppStrings.t('Payment Success.')
                  : AppStrings.t('Payment is pending.'),
            ),
          ),
        );
      } else if (result == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('Payment Fail'))),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final title = plan.displayTitle.isNotEmpty
        ? plan.displayTitle
        : (plan.title.isNotEmpty ? plan.title : 'Plan');
    final priceLabel = _formatPrice(plan.price, widget.currency);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('Payment'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(AppStrings.t('Payment'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(AppStrings.t('Choose your plan and pay securely with Iyzico.'),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          _PackageSummary(
            title: title,
            lessons: plan.lessonsTotal,
            months: plan.durationMonths,
            priceLabel: priceLabel,
          ),
          const SizedBox(height: 16),
          _OrderSummary(
            title: title,
            totalLabel: priceLabel,
          ),
          const SizedBox(height: 12),
          _Agreement(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _pay,
              child: Text(_submitting
                  ? AppStrings.t('Submitting')
                  : AppStrings.t('Make Payment')),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price, String currency) {
    final symbol = _currencySymbol(currency);
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 0,
      locale: 'tr_TR',
    );
    return formatter.format(price);
  }

  String _currencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'TRY':
        return 'TRY ';
      case 'USD':
        return '\$';
      case 'EUR':
        return 'EUR ';
      default:
        return '$code ';
    }
  }
}

class _PackageSummary extends StatelessWidget {
  const _PackageSummary({
    required this.title,
    required this.lessons,
    required this.months,
    required this.priceLabel,
  });

  final String title;
  final int lessons;
  final int months;
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFF1F5F9),
            child: Icon(Icons.card_membership, color: AppColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '$lessons ${AppStrings.t('Lessons')} · $months ${AppStrings.t('Months')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(priceLabel, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.title, required this.totalLabel});

  final String title;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.t('Order Summary'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _SummaryRow(label: AppStrings.t('Package'), value: title),
          _SummaryRow(label: AppStrings.t('Total'), value: totalLabel),
        ],
      ),
    );
  }
}

class _Agreement extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_box_outline_blank, color: AppColors.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.t(
                'By clicking Send, you accept the Terms of Use and Privacy Policy.',
              ),
              style: const TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}


