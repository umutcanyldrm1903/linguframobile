import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(title: Text(AppStrings.t('Reports'))),
      body: FutureBuilder<InstructorReportsPayload?>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppStrings.t('Something went wrong')),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _reload,
                    child: Text(AppStrings.t('Try Again')),
                  ),
                ],
              ),
            );
          }

          final payload = snapshot.data;
          if (payload == null) {
            return Center(child: Text(AppStrings.t('No report data yet.')));
          }

          final metrics = payload.metrics;

          final cards = [
            _StatData(
              title: AppStrings.t('Total Lessons'),
              value: metrics.totalLessons.toString(),
            ),
            _StatData(
              title: AppStrings.t('Upcoming Lessons'),
              value: metrics.upcomingLessons.toString(),
            ),
            _StatData(
              title: AppStrings.t('Completed'),
              value: metrics.completed.toString(),
            ),
            _StatData(
              title: AppStrings.t('No Show'),
              value: metrics.noShow.toString(),
            ),
            _StatData(
              title: AppStrings.t('Late'),
              value: metrics.late.toString(),
            ),
            _StatData(
              title: AppStrings.t('Cancelled by Teacher'),
              value: metrics.cancelledByTeacher.toString(),
            ),
            _StatData(
              title: AppStrings.t('Cancelled by Student'),
              value: metrics.cancelledByStudent.toString(),
            ),
            _StatData(
              title: AppStrings.t('Active Students'),
              value: payload.studentsCount.toString(),
            ),
          ];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                payload.title.isEmpty ? AppStrings.t('Reports') : payload.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                payload.subtitle.isEmpty
                    ? AppStrings.t('Track your lesson performance and attendance.')
                    : payload.subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              GridView.builder(
                itemCount: cards.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return _StatCard(title: card.title, value: card.value);
                },
              ),
              const SizedBox(height: 16),
              _MonthlyChart(monthly: payload.monthly),
            ],
          );
        },
      ),
    );
  }
}

class _StatData {
  const _StatData({required this.title, required this.value});

  final String title;
  final String value;
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

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.monthly});

  final List<InstructorMonthlyReport> monthly;

  @override
  Widget build(BuildContext context) {
    if (monthly.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(AppStrings.t('No report data yet.')),
      );
    }

    final visible = monthly.take(6).toList().reversed.toList(growable: false);
    final maxTotal = visible.fold<int>(
      0,
      (maxValue, item) => item.total > maxValue ? item.total : maxValue,
    );
    final divisor = maxTotal <= 0 ? 1 : maxTotal;

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
          Text(
            AppStrings.t('Monthly Summary'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
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
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: AppColors.brandDeep,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatMonth(item.month),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          ...visible.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(_formatMonth(item.month))),
                  Text(
                    '${AppStrings.t('Total Lessons')}: ${item.total}  '
                    '${AppStrings.t('Completed')}: ${item.completed}  '
                    '${AppStrings.t('No Show')}: ${item.noShow}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
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
