import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import 'instructor_students_repository.dart';

class InstructorStudentsScreen extends StatelessWidget {
  const InstructorStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InstructorStudent>>(
      future: InstructorStudentsRepository().fetchStudents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = snapshot.data ?? const <InstructorStudent>[];
        if (students.isEmpty) {
          return Center(child: Text(AppStrings.t('No assigned students yet.')));
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(AppStrings.t('Students'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...students.map(
              (student) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StudentTile(student: student),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student});

  final InstructorStudent student;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.brandDeep.withOpacity(0.15),
            child: (() {
              final initial =
                  student.name.isNotEmpty ? student.name.substring(0, 1) : '?';
              if (student.imageUrl.isEmpty) {
                return Text(initial);
              }
              return ClipOval(
                child: Image.network(
                  student.imageUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  errorBuilder: (_, __, ___) => SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(child: Text(initial)),
                  ),
                ),
              );
            })(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: Theme.of(context).textTheme.titleLarge),
                if (student.email.isNotEmpty)
                  Text(student.email, style: Theme.of(context).textTheme.bodyMedium),
                if (student.phone.isNotEmpty)
                  Text(student.phone, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}
