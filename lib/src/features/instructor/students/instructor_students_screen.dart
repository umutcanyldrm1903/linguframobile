import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import 'instructor_students_repository.dart';

class InstructorStudentsScreen extends StatelessWidget {
  const InstructorStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InstructorStudent>>(
      future: InstructorStudentsRepository().fetchStudents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppLoader(message: AppStrings.t('Students'));
        }

        if (snapshot.hasError) {
          return AppErrorState(
            message: AppStrings.t('Something went wrong'),
            retryLabel: AppStrings.t('Try Again'),
            onRetry: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const InstructorStudentsScreen()),
            ),
          );
        }

        final students = snapshot.data ?? const <InstructorStudent>[];
        if (students.isEmpty) {
          return AppEmptyState(
            title: AppStrings.t('No assigned students yet.'),
            icon: Icons.people_alt_rounded,
          );
        }

        return AnimatedPageEntrance(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.xl),
            children: [
              GradientHero(
                gradient: AppGradients.hero,
                glowColor: AppColors.accent,
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: AppRadius.all(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpace.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.t('Students'),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          AnimatedCounter(
                            value: students.length,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              SectionHeader(
                title: AppStrings.t('Students'),
                icon: Icons.school_rounded,
              ),
              StaggeredReveal(
                children: [
                  for (final student in students)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.md),
                      child: _StudentTile(student: student),
                    ),
                ],
              ),
            ],
          ),
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
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandDeep.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: (() {
              final initial =
                  student.name.isNotEmpty ? student.name.substring(0, 1) : '?';
              final label = Text(
                initial.toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.brandDeep,
                  fontWeight: FontWeight.w800,
                ),
              );
              if (student.imageUrl.isEmpty) {
                return label;
              }
              return ClipOval(
                child: Image.network(
                  student.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  errorBuilder: (_, __, ___) => SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(child: label),
                  ),
                ),
              );
            })(),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                if (student.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    student.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (student.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    student.phone,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}
