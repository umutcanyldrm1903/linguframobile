import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../public/public_repository.dart';
import '../checkout/student_checkout_screen.dart';

class StudentPackagesScreen extends StatefulWidget {
  const StudentPackagesScreen({super.key});

  @override
  State<StudentPackagesScreen> createState() => _StudentPackagesScreenState();
}

class _StudentPackagesScreenState extends State<StudentPackagesScreen> {
  late final Future<PlanPayload?> _future =
      PublicRepository().fetchStudentPlans();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('Packages'))),
      body: FutureBuilder<PlanPayload?>(
        future: _future,
        builder: (context, snapshot) {
          final payload = snapshot.data;
          final plans = payload?.plans ?? const <StudentPlan>[];
          final currency = payload?.currency ?? 'TRY';

          final packageCards = plans.map((plan) {
            final title = plan.displayTitle.isNotEmpty
                ? plan.displayTitle
                : (plan.title.isNotEmpty ? plan.title : 'Plan');
            final subtitle =
                '${plan.lessonsTotal} ${AppStrings.t('Lessons')} - ${plan.durationMonths} ${AppStrings.t('Months')}';
            final features = [
              '${AppStrings.t('Lesson Duration')}: ${plan.lessonDuration} ${AppStrings.t('Minutes')}',
              '${AppStrings.t('Cancellation Right')}: ${plan.cancelTotal}',
              AppStrings.t('Flexible Lesson Scheduling'),
            ];

            final data = _PackageData(
              title: title,
              price: _formatPrice(plan.price, currency),
              subtitle: subtitle,
              badge: plan.label.isNotEmpty ? plan.label : null,
              features: features,
              highlight: plan.featured,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _PackageCard(
                data: data,
                onSelect: () => _open(
                  context,
                  StudentCheckoutScreen(
                    plan: plan,
                    currency: currency,
                  ),
                ),
              ),
            );
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _HeroCard(),
              const SizedBox(height: 18),
              Text(AppStrings.t('Packages'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                AppStrings.t('Choose your plan and pay securely with Iyzico.'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator()),
              if (plans.isEmpty &&
                  snapshot.connectionState != ConnectionState.waiting)
                Text(AppStrings.t('No Data Found')),
              ...packageCards,
              const SizedBox(height: 8),
              _ComparisonCard(),
            ],
          );
        },
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand, Color(0xFFFFB647)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t('Choose Your Plan'),
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.t(
                'Compare course duration, lesson count, and features to pick the package that fits you best.'),
            style: const TextStyle(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _PackageData {
  const _PackageData({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.features,
    this.badge,
    this.highlight = false,
  });

  final String title;
  final String price;
  final String subtitle;
  final List<String> features;
  final String? badge;
  final bool highlight;
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.data, required this.onSelect});

  final _PackageData data;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        data.highlight ? AppColors.brand : const Color(0xFFE2E8F0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text(data.title, style: Theme.of(context).textTheme.titleLarge),
              ),
              if (data.badge != null && data.badge!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(data.badge!,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(data.subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Text(data.price, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Column(
            children: data.features
                .map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 18, color: AppColors.brand),
                        const SizedBox(width: 8),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSelect,
              child: Text(AppStrings.t('Select')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
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
          Text(AppStrings.t('Package'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _ComparisonRow(
              label: AppStrings.t('Lesson Duration'), value: '40 dk'),
          _ComparisonRow(
              label: AppStrings.t('Cancellation Right'),
              value: AppStrings.t('Weekly cancellation right')),
          _ComparisonRow(
              label: AppStrings.t('Support'), value: AppStrings.t('Support')),
          _ComparisonRow(
              label: AppStrings.t('Certificate'),
              value: AppStrings.t('Completion Certificate')),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


