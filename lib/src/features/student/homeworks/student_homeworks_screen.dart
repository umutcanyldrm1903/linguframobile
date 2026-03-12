import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import 'student_homeworks_repository.dart';

class StudentHomeworksScreen extends StatelessWidget {
  const StudentHomeworksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('Homeworks'))),
      body: FutureBuilder<StudentHomeworksPayload?>(
        future: StudentHomeworksRepository().fetchHomeworks(),
        builder: (context, snapshot) {
          final payload = snapshot.data;
          final active = payload?.active ?? const <StudentHomeworkItem>[];
          final archived = payload?.archived ?? const <StudentHomeworkItem>[];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (active.isEmpty && archived.isEmpty) {
            return Center(child: Text(AppStrings.t('No homeworks found!')));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                AppStrings.t('Homeworks'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...active.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HomeworkCard(item: item),
                ),
              ),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  AppStrings.t('Archived'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ...archived.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HomeworkCard(item: item),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard({required this.item});

  final StudentHomeworkItem item;

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusLabel(item.status);
    final statusColor =
        statusLabel == AppStrings.t('Completed') ? Colors.green : AppColors.brand;
    final dueLabel = _dueLabel(item);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: statusColor.withOpacity(0.15),
            child: Icon(Icons.assignment, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(dueLabel, style: Theme.of(context).textTheme.bodyMedium),
                if (item.instructorName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${AppStrings.t('Instructor')}: ${item.instructorName}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'submitted':
      case 'completed':
        return AppStrings.t('Completed');
      case 'archived':
        return AppStrings.t('Archived');
      default:
        return AppStrings.t('Pending');
    }
  }

  String _dueLabel(StudentHomeworkItem item) {
    if (item.submission != null) {
      return AppStrings.t('Completed');
    }
    if (item.dueAt == null) {
      return AppStrings.t('No deadline');
    }
    final formatted = DateFormat('dd MMMM yyyy', 'tr_TR').format(item.dueAt!);
    return '${AppStrings.t('Date')}: $formatted';
  }
}
