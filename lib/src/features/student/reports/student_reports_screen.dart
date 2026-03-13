import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import 'student_reports_repository.dart';

class StudentReportsScreen extends StatelessWidget {
  const StudentReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('My Reports'))),
      body: FutureBuilder<StudentReportSummary?>(
        future: StudentReportsRepository().fetchReports(),
        builder: (context, snapshot) {
          final summary = snapshot.data;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (summary == null) {
            return Center(child: Text(AppStrings.t('No reports found')));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(AppStrings.t('Reports'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                AppStrings.t('Study Progress Tracker'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _StatCard(
                    title: AppStrings.t('Total Minutes'),
                    value: '${summary.totalMinutes} ${AppStrings.t('Minutes')}',
                  ),
                  _StatCard(
                    title: AppStrings.t('Completed'),
                    value: summary.completedLessons.toString(),
                  ),
                  _StatCard(
                    title: AppStrings.t('Quiz Grade'),
                    value: summary.quizAverage == 0
                        ? '-'
                        : summary.quizAverage.toStringAsFixed(1),
                  ),
                  _StatCard(
                    title: AppStrings.t('Reviews'),
                    value: summary.reviewCount.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Text(AppStrings.t('Analytics')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
