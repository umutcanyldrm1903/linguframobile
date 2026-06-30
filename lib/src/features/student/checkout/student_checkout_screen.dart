import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('Payment')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppGlowBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.xl, AppSpace.lg, AppSpace.xl, AppSpace.xxxl),
            children: [
              AnimatedPageEntrance(
                child: GradientHero(
                  gradient: AppGradients.hero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_rounded,
                              color: Colors.white, size: 26),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Text(
                              AppStrings.t('Payment'),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        AppStrings.t(
                            'Choose your plan and pay securely with Iyzico.'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      Wrap(
                        spacing: AppSpace.sm,
                        runSpacing: AppSpace.sm,
                        children: [
                          AppStatPill(
                            icon: Icons.verified_user_rounded,
                            label: AppStrings.t('Secure payment'),
                          ),
                          AppStatPill(
                            icon: Icons.favorite_rounded,
                            label: AppStrings.t('Satisfaction guaranteed'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              StaggeredReveal(
                children: [
                  _PackageSummary(
                    title: title,
                    lessons: plan.lessonsTotal,
                    months: plan.durationMonths,
                    priceLabel: priceLabel,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  _OrderSummary(
                    title: title,
                    totalLabel: priceLabel,
                  ),
                  const SizedBox(height: AppSpace.md),
                  _Agreement(),
                  const SizedBox(height: AppSpace.xl),
                  AppButton(
                    label: _submitting
                        ? AppStrings.t('Submitting')
                        : AppStrings.t('Make Payment'),
                    onPressed: _submitting ? null : _pay,
                    loading: _submitting,
                    tone: AppButtonTone.success,
                    icon: Icons.lock_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
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
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: AppRadius.all(AppRadius.sm),
              boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.28),
            ),
            child: const Icon(Icons.card_membership_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  '$lessons ${AppStrings.t('Lessons')} · $months ${AppStrings.t('Months')}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            priceLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.brand,
                ),
          ),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: AppStrings.t('Order Summary'),
            icon: Icons.receipt_long_rounded,
          ),
          _SummaryRow(label: AppStrings.t('Package'), value: title),
          const Divider(height: AppSpace.lg, color: AppPalette.line),
          _SummaryRow(
            label: AppStrings.t('Total'),
            value: totalLabel,
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _Agreement extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppPalette.cloud,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_box_outline_blank, color: AppColors.brand),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              AppStrings.t(
                'By clicking Send, you accept the Terms of Use and Privacy Policy.',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: emphasize
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.brand,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
          ),
        ],
      ),
    );
  }
}


