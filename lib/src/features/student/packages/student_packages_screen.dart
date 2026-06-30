import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppStrings.t('Packages'))),
      body: AppGlowBackground(
        child: FutureBuilder<PlanPayload?>(
          future: _future,
          builder: (context, snapshot) {
            final payload = snapshot.data;
            final plans = payload?.plans ?? const <StudentPlan>[];
            final currency = payload?.currency ?? 'TRY';

            if (snapshot.connectionState == ConnectionState.waiting) {
              return AppLoader(message: AppStrings.t('Packages'));
            }

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
                padding: const EdgeInsets.only(bottom: AppSpace.md),
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
              padding: const EdgeInsets.all(AppSpace.xl),
              children: [
                AnimatedPageEntrance(child: const _HeroCard()),
                const SizedBox(height: AppSpace.xl),
                AnimatedPageEntrance(
                  delay: const Duration(milliseconds: 80),
                  child: SectionHeader(
                    icon: Icons.workspace_premium_rounded,
                    title: AppStrings.t('Packages'),
                    subtitle: AppStrings.t(
                        'Choose your plan and pay securely with Iyzico.'),
                  ),
                ),
                if (plans.isEmpty)
                  AppEmptyState(
                    icon: Icons.inventory_2_rounded,
                    title: AppStrings.t('No Data Found'),
                  )
                else
                  StaggeredReveal(children: packageCards),
                const SizedBox(height: AppSpace.sm),
                AnimatedPageEntrance(
                  delay: const Duration(milliseconds: 160),
                  child: const _ComparisonCard(),
                ),
              ],
            );
          },
        ),
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
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return GradientHero(
      gradient: AppGradients.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  AppStrings.t('Choose Your Plan'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            AppStrings.t(
                'Compare lesson duration, package credits, and support options to pick the package that fits you best.'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.35,
            ),
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
    final theme = Theme.of(context);
    final card = AppCard(
      border: !data.highlight,
      shadow: data.highlight
          ? AppShadows.glow(AppColors.brand, opacity: 0.26)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (data.badge != null && data.badge!.isNotEmpty)
                AppStatPill(
                  icon: data.highlight
                      ? Icons.star_rounded
                      : Icons.local_offer_rounded,
                  label: data.badge!,
                  color:
                      data.highlight ? AppPalette.goldDeep : AppColors.brand,
                  onLight: true,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            data.price,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          ...data.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 18, color: AppPalette.success),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      feature,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          AppButton(
            label: AppStrings.t('Select'),
            onPressed: onSelect,
            tone: data.highlight ? AppButtonTone.gold : AppButtonTone.brand,
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );

    if (!data.highlight) return card;

    // Recommended plan -> gradient border + glow ring.
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: AppGradients.gold,
        borderRadius: AppRadius.all(AppRadius.lg + 2),
        boxShadow: AppShadows.glow(AppPalette.goldDeep, opacity: 0.30),
      ),
      child: card,
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.table_chart_rounded,
            title: AppStrings.t('Package'),
          ),
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
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_rounded, size: 16, color: AppPalette.success),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
