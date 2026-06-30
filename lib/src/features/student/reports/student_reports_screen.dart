import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import 'student_reports_repository.dart';

class StudentReportsScreen extends StatelessWidget {
  const StudentReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('My Reports'))),
      body: AppGlowBackground(
        child: FutureBuilder<StudentReportSummary?>(
          future: StudentReportsRepository().fetchReports(),
          builder: (context, snapshot) {
            final summary = snapshot.data;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return AppLoader(message: AppStrings.t('Reports'));
            }

            if (summary == null) {
              return AppEmptyState(
                icon: Icons.insights_rounded,
                title: AppStrings.t('No reports found'),
                message: AppStrings.t('Study Progress Tracker'),
              );
            }

            return AnimatedPageEntrance(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.xl),
                children: [
                  _ReportsHero(summary: summary),
                  const SizedBox(height: AppSpace.xl),
                  SectionHeader(
                    title: AppStrings.t('Reports'),
                    subtitle: AppStrings.t('Study Progress Tracker'),
                    icon: Icons.bar_chart_rounded,
                  ),
                  StaggeredReveal(
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppSpace.md,
                        crossAxisSpacing: AppSpace.md,
                        childAspectRatio: 1.5,
                        children: [
                          StatCard(
                            icon: Icons.schedule_rounded,
                            label: AppStrings.t('Total Minutes'),
                            value: summary.totalMinutes,
                            suffix: ' ${AppStrings.t('Minutes')}',
                            color: AppColors.brand,
                          ),
                          StatCard(
                            icon: Icons.check_circle_rounded,
                            label: AppStrings.t('Completed'),
                            value: summary.completedLessons,
                            color: AppPalette.success,
                          ),
                          _QuizGradeCard(summary: summary),
                          StatCard(
                            icon: Icons.rate_review_rounded,
                            label: AppStrings.t('Reviews'),
                            value: summary.reviewCount,
                            color: AppPalette.violet,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),
                  _MilestonesSection(summary: summary),
                  const SizedBox(height: AppSpace.xl),
                  SectionHeader(
                    title: AppStrings.t('Analytics'),
                    icon: Icons.show_chart_rounded,
                  ),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpace.xxl),
                    child: SizedBox(
                      height: 168,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    AppColors.brand.withValues(alpha: 0.10),
                              ),
                              child: const Icon(
                                Icons.insights_rounded,
                                size: 30,
                                color: AppColors.brand,
                              ),
                            ),
                            const SizedBox(height: AppSpace.md),
                            Text(
                              AppStrings.t('Analytics'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Gradyanlı özet kahramanı — gerçek tamamlanan ders ve süre sayaçları.
class _ReportsHero extends StatelessWidget {
  const _ReportsHero({required this.summary});

  final StudentReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return GradientHero(
      gradient: AppGradients.hero,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t('Study Progress Tracker'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    AppStatPill(
                      icon: Icons.check_circle_rounded,
                      label:
                          '${summary.completedLessons} ${AppStrings.t('Completed')}',
                    ),
                    AppStatPill(
                      icon: Icons.schedule_rounded,
                      label:
                          '${summary.totalMinutes} ${AppStrings.t('Minutes')}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          ProgressRing(
            value: summary.quizAverage.clamp(0, 100) / 100,
            size: 84,
            color: Colors.white,
            trackColor: Colors.white.withValues(alpha: 0.28),
            center: summary.quizAverage == 0
                ? const Icon(Icons.quiz_rounded,
                    color: Colors.white, size: 26)
                : Text(
                    summary.quizAverage.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Quiz ortalaması — alınmamışsa '-' gösterir (sıfır ise sahte değer üretmez).
class _QuizGradeCard extends StatelessWidget {
  const _QuizGradeCard({required this.summary});

  final StudentReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasGrade = summary.quizAverage != 0;
    if (!hasGrade) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppPalette.gold.withValues(alpha: 0.14),
                borderRadius: AppRadius.all(AppRadius.sm),
              ),
              child: const Icon(Icons.quiz_rounded,
                  size: 20, color: AppPalette.goldDeep),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              '-',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppStrings.t('Quiz Grade'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    return StatCard(
      icon: Icons.quiz_rounded,
      label: AppStrings.t('Quiz Grade'),
      value: summary.quizAverage,
      fractionDigits: 1,
      color: AppPalette.goldDeep,
    );
  }
}

/// Gerçek eşikleri aşılan kilometre taşları — sahte ilerleme yok.
class _MilestonesSection extends StatelessWidget {
  const _MilestonesSection({required this.summary});

  final StudentReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      AchievementBadge(
        icon: Icons.play_circle_fill_rounded,
        label: AppStrings.t('Completed'),
        unlocked: summary.completedLessons >= 1,
        color: AppPalette.success,
      ),
      AchievementBadge(
        icon: Icons.military_tech_rounded,
        label: '10 ${AppStrings.t('Completed')}',
        unlocked: summary.completedLessons >= 10,
        color: AppColors.brand,
      ),
      AchievementBadge(
        icon: Icons.timelapse_rounded,
        label: '100 ${AppStrings.t('Minutes')}',
        unlocked: summary.totalMinutes >= 100,
        color: AppPalette.violet,
      ),
      AchievementBadge(
        icon: Icons.rate_review_rounded,
        label: AppStrings.t('Reviews'),
        unlocked: summary.reviewCount >= 1,
        color: AppPalette.gold,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: AppStrings.t('Reports'),
          icon: Icons.emoji_events_rounded,
        ),
        AppCard(
          child: Wrap(
            spacing: AppSpace.lg,
            runSpacing: AppSpace.lg,
            alignment: WrapAlignment.spaceEvenly,
            children: badges,
          ),
        ),
      ],
    );
  }
}
