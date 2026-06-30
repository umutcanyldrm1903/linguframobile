import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../zoom/live_lesson_launcher.dart';
import 'instructor_lessons_repository.dart';

class InstructorLessonsScreen extends StatelessWidget {
  const InstructorLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InstructorLessonsPayload?>(
      future: InstructorLessonsRepository().fetchLessons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppLoader(message: AppStrings.t('Lessons'));
        }

        if (snapshot.hasError) {
          return AppErrorState(
            message: AppStrings.t('Something went wrong'),
            retryLabel: AppStrings.t('Try Again'),
            onRetry: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const InstructorLessonsScreen()),
            ),
          );
        }

        final payload = snapshot.data;
        final upcoming = payload?.upcoming ?? const <InstructorLessonItem>[];
        final past = payload?.past ?? const <InstructorLessonItem>[];

        if (upcoming.isEmpty && past.isEmpty) {
          return AppEmptyState(
            icon: Icons.video_camera_front_rounded,
            title: AppStrings.t('No lessons found!'),
          );
        }

        return AppGlowBackground(
          child: AnimatedPageEntrance(
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.xl),
              children: [
                GradientHero(
                  gradient: AppGradients.hero,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: AppRadius.all(AppRadius.md),
                        ),
                        child: const Icon(Icons.cast_for_education_rounded,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: AppSpace.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.t('Lessons'),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                AppStatPill(
                                  icon: Icons.upcoming_rounded,
                                  label:
                                      '${upcoming.length} ${AppStrings.t('Upcoming')}',
                                ),
                                AppStatPill(
                                  icon: Icons.history_rounded,
                                  label:
                                      '${past.length} ${AppStrings.t('Past')}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                if (upcoming.isNotEmpty) ...[
                  SectionHeader(
                    title: AppStrings.t('Upcoming'),
                    icon: Icons.event_available_rounded,
                  ),
                  StaggeredReveal(
                    children: [
                      for (final lesson in upcoming)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.md),
                          child: _LessonCard(lesson: lesson, isUpcoming: true),
                        ),
                    ],
                  ),
                ],
                if (past.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.lg),
                  SectionHeader(
                    title: AppStrings.t('Past'),
                    icon: Icons.history_rounded,
                  ),
                  StaggeredReveal(
                    children: [
                      for (final lesson in past)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.md),
                          child: _LessonCard(lesson: lesson, isUpcoming: false),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.isUpcoming});

  final InstructorLessonItem lesson;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context) {
    final statusColor = isUpcoming ? AppColors.brand : AppPalette.success;
    final canJoin =
        isUpcoming && lesson.status == 'started' && _canJoinNow(lesson);
    final canStart = isUpcoming &&
        !lesson.isPending &&
        lesson.status != 'started' &&
        _canStartNow(lesson);
    final startLabel = lesson.startTime != null
        ? DateFormat('dd MMM yyyy · HH:mm').format(lesson.startTime!.toLocal())
        : '';
    final title =
        lesson.title.isNotEmpty ? lesson.title : AppStrings.t('Lesson');
    final actionEnabled = canJoin || canStart;
    final actionLabel = canJoin
        ? AppStrings.t('Join My Class')
        : (lesson.isPending
            ? AppStrings.t('Reservation is pending.')
            : (canStart
                ? AppStrings.t('Start Lesson')
                : AppStrings.t('Lesson is not started yet')));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: AppRadius.all(AppRadius.md),
                ),
                child: Icon(Icons.play_circle_rounded, color: statusColor),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                    ),
                    if (lesson.studentName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.person_rounded,
                              size: 14, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lesson.studentName,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              AppStatPill(
                icon: isUpcoming
                    ? Icons.upcoming_rounded
                    : Icons.check_circle_rounded,
                label: isUpcoming
                    ? AppStrings.t('Upcoming')
                    : AppStrings.t('Past'),
                color: isUpcoming ? AppColors.brand : AppPalette.success,
                onLight: true,
              ),
            ],
          ),
          if (startLabel.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 15, color: AppColors.muted),
                const SizedBox(width: 5),
                Text(
                  startLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpace.md),
          AppButton(
            label: actionLabel,
            tone: canJoin
                ? AppButtonTone.success
                : (canStart ? AppButtonTone.brand : AppButtonTone.neutral),
            icon: canJoin
                ? Icons.videocam_rounded
                : (canStart ? Icons.play_arrow_rounded : null),
            onPressed: actionEnabled
                ? () async {
                    try {
                      String meetingId = lesson.meetingId.trim();
                      String passcode = lesson.password.trim();
                      String rawJoinUrl = (lesson.joinUrl ?? '').trim();

                      if (canStart) {
                        final started = await InstructorLessonsRepository()
                            .startLesson(lesson.id);
                        if (started != null) {
                          meetingId = started.meetingId.trim();
                          passcode = started.password.trim();
                          rawJoinUrl = started.joinUrl.trim();
                        }
                      }

                      if (!context.mounted) return;
                      await openLiveLessonSession(
                        context,
                        title: lesson.title.isNotEmpty
                            ? lesson.title
                            : AppStrings.t('Lesson'),
                        joinUrl: rawJoinUrl,
                        meetingId: meetingId,
                        password: passcode,
                      );
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(AppStrings.t('Something went wrong'))),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

bool _canJoinNow(InstructorLessonItem lesson) {
  final raw = lesson.joinUrl?.trim() ?? '';
  if (raw.isEmpty) return false;
  if (lesson.isPending) return false;
  final start = lesson.startTime;
  final end = lesson.computedEndTime;
  if (start == null || end == null) return false;
  final now = DateTime.now();
  final startWindow = start.subtract(const Duration(minutes: 15));
  if (now.isBefore(startWindow)) return false;
  if (!now.isBefore(end)) return false;
  return true;
}

bool _canStartNow(InstructorLessonItem lesson) {
  final start = lesson.startTime;
  if (start == null) return false;
  final end = lesson.computedEndTime;
  final now = DateTime.now();
  if (end != null && !now.isBefore(end)) return false;
  return !now.isBefore(start.subtract(const Duration(minutes: 15)));
}
