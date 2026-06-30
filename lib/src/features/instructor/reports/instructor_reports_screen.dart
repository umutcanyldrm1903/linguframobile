import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import 'instructor_reports_repository.dart';

class InstructorReportsScreen extends StatefulWidget {
  const InstructorReportsScreen({super.key});

  @override
  State<InstructorReportsScreen> createState() => _InstructorReportsScreenState();
}

class _InstructorReportsScreenState extends State<InstructorReportsScreen> {
  late Future<InstructorReportsPayload?> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _fetchReports();
  }

  Future<InstructorReportsPayload?> _fetchReports() {
    return InstructorReportsRepository().fetchReports();
  }

  void _reload() {
    setState(() {
      _reportsFuture = _fetchReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppStrings.t('Reports'))),
      body: AppGlowBackground(
        child: FutureBuilder<InstructorReportsPayload?>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AppLoader(message: AppStrings.t('Loading'));
            }

            if (snapshot.hasError) {
              return AppErrorState(
                message: AppStrings.t('Something went wrong'),
                onRetry: _reload,
                retryLabel: AppStrings.t('Try Again'),
              );
            }

            final payload = snapshot.data;
            if (payload == null) {
              return AppEmptyState(
                icon: Icons.insights_rounded,
                title: AppStrings.t('No report data yet.'),
              );
            }

            return _ReportsBody(payload: payload);
          },
        ),
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody({required this.payload});

  final InstructorReportsPayload payload;

  @override
  Widget build(BuildContext context) {
    final metrics = payload.metrics;

    final cards = <_StatData>[
      _StatData(
        title: AppStrings.t('Total Lessons'),
        value: metrics.totalLessons,
        icon: Icons.school_rounded,
        color: AppColors.brand,
      ),
      _StatData(
        title: AppStrings.t('Upcoming Lessons'),
        value: metrics.upcomingLessons,
        icon: Icons.event_available_rounded,
        color: AppPalette.info,
      ),
      _StatData(
        title: AppStrings.t('Completed'),
        value: metrics.completed,
        icon: Icons.check_circle_rounded,
        color: AppPalette.success,
      ),
      _StatData(
        title: AppStrings.t('No Show'),
        value: metrics.noShow,
        icon: Icons.person_off_rounded,
        color: AppPalette.danger,
      ),
      _StatData(
        title: AppStrings.t('Late'),
        value: metrics.late,
        icon: Icons.schedule_rounded,
        color: AppPalette.warning,
      ),
      _StatData(
        title: AppStrings.t('Cancelled by Teacher'),
        value: metrics.cancelledByTeacher,
        icon: Icons.cancel_rounded,
        color: AppPalette.streak,
      ),
      _StatData(
        title: AppStrings.t('Cancelled by Student'),
        value: metrics.cancelledByStudent,
        icon: Icons.event_busy_rounded,
        color: AppPalette.violet,
      ),
      _StatData(
        title: AppStrings.t('Active Students'),
        value: payload.studentsCount,
        icon: Icons.groups_rounded,
        color: AppPalette.teal,
      ),
    ];

    // Gerçek başarı eşiği: 50+ tamamlanan ders (yalnızca gerçek değer).
    final milestone50 = metrics.completed >= 50;
    final milestone100 = metrics.completed >= 100;

    return AnimatedPageEntrance(
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.xl),
        children: [
          GradientHero(
            gradient: AppGradients.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights_rounded,
                        color: Colors.white, size: 26),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        payload.title.isEmpty
                            ? AppStrings.t('Reports')
                            : payload.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
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
                  payload.subtitle.isEmpty
                      ? AppStrings.t(
                          'Track your lesson performance and attendance.')
                      : payload.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpace.lg),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    AppStatPill(
                      icon: Icons.school_rounded,
                      label:
                          '${metrics.totalLessons} ${AppStrings.t('Total Lessons')}',
                    ),
                    AppStatPill(
                      icon: Icons.groups_rounded,
                      label:
                          '${payload.studentsCount} ${AppStrings.t('Active Students')}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          SectionHeader(
            title: AppStrings.t('Reports'),
            subtitle: AppStrings.t(
                'Track your lesson performance and attendance.'),
            icon: Icons.bar_chart_rounded,
          ),
          GridView.builder(
            itemCount: cards.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpace.md,
              mainAxisSpacing: AppSpace.md,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) {
              final card = cards[index];
              return AnimatedPageEntrance(
                delay: Duration(milliseconds: 60 * index),
                child: StatCard(
                  icon: card.icon,
                  label: card.title,
                  value: card.value,
                  color: card.color,
                ),
              );
            },
          ),
          if (milestone50) ...[
            const SizedBox(height: AppSpace.xl),
            SectionHeader(
              title: AppStrings.t('Achievements'),
              icon: Icons.emoji_events_rounded,
            ),
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AchievementBadge(
                    icon: Icons.workspace_premium_rounded,
                    label: '50+ ${AppStrings.t('Completed')}',
                    unlocked: milestone50,
                    color: AppPalette.gold,
                  ),
                  AchievementBadge(
                    icon: Icons.military_tech_rounded,
                    label: '100+ ${AppStrings.t('Completed')}',
                    unlocked: milestone100,
                    color: AppPalette.violet,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpace.xl),
          _MonthlyChart(monthly: payload.monthly),
        ],
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.monthly});

  final List<InstructorMonthlyReport> monthly;

  @override
  Widget build(BuildContext context) {
    if (monthly.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.show_chart_rounded, color: AppColors.muted),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                AppStrings.t('No report data yet.'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final visible = monthly.take(6).toList().reversed.toList(growable: false);
    final maxTotal = visible.fold<int>(
      0,
      (maxValue, item) => item.total > maxValue ? item.total : maxValue,
    );
    final divisor = maxTotal <= 0 ? 1 : maxTotal;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: AppStrings.t('Monthly Summary'),
            icon: Icons.calendar_month_rounded,
          ),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: visible.map((item) {
                final ratio = item.total / divisor;
                final height = 28 + (110 * ratio);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          item.total.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            gradient: AppGradients.brand,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            boxShadow:
                                AppShadows.glow(AppColors.brand, opacity: 0.22),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatMonth(item.month),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          ...visible.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.sm,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.cloud,
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatMonth(item.month),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                      ),
                    ),
                    Wrap(
                      spacing: AppSpace.xs,
                      children: [
                        AppStatPill(
                          icon: Icons.school_rounded,
                          label: '${item.total}',
                          color: AppColors.brand,
                          onLight: true,
                        ),
                        AppStatPill(
                          icon: Icons.check_circle_rounded,
                          label: '${item.completed}',
                          color: AppPalette.success,
                          onLight: true,
                        ),
                        AppStatPill(
                          icon: Icons.person_off_rounded,
                          label: '${item.noShow}',
                          color: AppPalette.danger,
                          onLight: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMonth(String raw) {
    if (!raw.contains('-')) return raw;
    final parts = raw.split('-');
    if (parts.length != 2) return raw;
    final year = parts[0];
    final month = parts[1];
    if (year.length < 4) return raw;
    return '$month/${year.substring(2)}';
  }
}
