import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../zoom/live_lesson_launcher.dart';
import 'instructor_dashboard_repository.dart';
import '../lessons/instructor_lessons_repository.dart';
import '../agreements/instructor_agreement_screen.dart';
import '../guide/instructor_guide_screen.dart';
import '../homeworks/instructor_homeworks_screen.dart';
import '../instructions/instructor_instructions_screen.dart';
import '../library/instructor_library_screen.dart';
import '../messages/instructor_messages_screen.dart';
import '../reports/instructor_reports_screen.dart';

class InstructorDashboardScreen extends StatelessWidget {
  const InstructorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;

    return FutureBuilder<InstructorDashboardPayload?>(
      future: InstructorDashboardRepository().fetchDashboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppLoader(message: AppStrings.t('Loading'));
        }

        if (snapshot.hasError) {
          return AppErrorState(
            message: AppStrings.t('Something went wrong'),
            retryLabel: AppStrings.t('Try Again'),
            onRetry: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const InstructorDashboardScreen()),
            ),
          );
        }

        final payload = snapshot.data;
        final stats = payload?.stats;
        final upcoming =
            payload?.upcoming ?? const <InstructorUpcomingLesson>[];
        final name = payload?.name.isNotEmpty == true
            ? payload!.name
            : AppStrings.t('Instructor');

        return ListView(
          padding: EdgeInsets.all(compact ? 14 : 20),
          children: [
            StaggeredReveal(
              children: [
                GradientHero(
                  gradient: AppGradients.hero,
                  glowColor: AppColors.accent,
                  padding: EdgeInsets.all(compact ? 18 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: AppRadius.all(AppRadius.sm),
                            ),
                            child: const Icon(Icons.school_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Text(
                              '${AppStrings.t('Welcome')}, $name!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: compact ? 18 : null,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),
                      Text(
                        AppStrings.t(
                            'Manage packages and track your progress'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 12 : 16),
                _StatGrid(stats: stats, compact: compact),
                SizedBox(height: compact ? 12 : 16),
                AppCard(
                  padding: EdgeInsets.all(compact ? 14 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: AppStrings.t('Upcoming Lessons'),
                        icon: Icons.event_rounded,
                      ),
                      if (upcoming.isEmpty)
                        AppEmptyState(
                          title: AppStrings.t('No lessons found!'),
                          icon: Icons.event_busy_rounded,
                        )
                      else
                        Column(
                          children: upcoming
                              .map(
                                (lesson) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _LessonTile(lesson: lesson),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 12 : 16),
                AppCard(
                  padding: EdgeInsets.all(compact ? 14 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: AppStrings.t('Quick Contact'),
                        icon: Icons.bolt_rounded,
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = compact
                              ? 2
                              : (constraints.maxWidth > 700 ? 4 : 3);
                          final spacing = compact ? 8.0 : 12.0;
                          final itemWidth = (constraints.maxWidth -
                                  ((columns - 1) * spacing)) /
                              columns;

                          final items = <_QuickAction>[
                            _QuickAction(
                              label: AppStrings.t('Messages'),
                              icon: Icons.chat_bubble_outline,
                              gradient: AppGradients.brand,
                              onTap: () => _open(
                                  context, const InstructorMessagesScreen()),
                            ),
                            _QuickAction(
                              label: AppStrings.t('Homeworks'),
                              icon: Icons.assignment,
                              gradient: AppGradients.violet,
                              onTap: () => _open(
                                  context, const InstructorHomeworksScreen()),
                            ),
                            _QuickAction(
                              label: AppStrings.t('Reports'),
                              icon: Icons.bar_chart,
                              gradient: AppGradients.success,
                              onTap: () => _open(
                                  context, const InstructorReportsScreen()),
                            ),
                            _QuickAction(
                              label: AppStrings.t('User Guide'),
                              icon: Icons.help_outline,
                              gradient: AppGradients.gold,
                              onTap: () => _open(
                                  context, const InstructorGuideScreen()),
                            ),
                            _QuickAction(
                              label: AppStrings.t('Library'),
                              icon: Icons.menu_book,
                              gradient: AppGradients.pair(
                                  AppPalette.teal, AppColors.brandDeep),
                              onTap: () => _open(
                                  context, const InstructorLibraryScreen()),
                            ),
                            _QuickAction(
                              label: AppStrings.t('Agreement'),
                              icon: Icons.description,
                              gradient: AppGradients.pair(
                                  AppPalette.info, AppColors.brand),
                              onTap: () => _open(context,
                                  const InstructorAgreementScreen()),
                            ),
                            _QuickAction(
                              label: AppStrings.t('Instructions'),
                              icon: Icons.rule_folder,
                              gradient: AppGradients.streak,
                              onTap: () => _open(context,
                                  const InstructorInstructionsScreen()),
                            ),
                          ];

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: items
                                .map(
                                  (item) => _QuickAction(
                                    label: item.label,
                                    icon: item.icon,
                                    gradient: item.gradient,
                                    onTap: item.onTap,
                                    width: itemWidth,
                                    compact: compact,
                                  ),
                                )
                                .toList(growable: false),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats, this.compact = false});

  final InstructorStats? stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final totalLessons = stats?.totalLessons ?? 0;
    final activeStudents = stats?.activeStudents ?? 0;
    final upcoming = stats?.upcomingLessons ?? 0;
    final rating = stats?.avgRating ?? 0.0;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: compact ? 8 : 12,
      crossAxisSpacing: compact ? 8 : 12,
      childAspectRatio: compact ? 1.45 : 1.6,
      children: [
        StatCard(
          icon: Icons.menu_book_rounded,
          label: AppStrings.t('Lessons'),
          value: totalLessons,
          color: AppColors.brand,
        ),
        StatCard(
          icon: Icons.groups_rounded,
          label: AppStrings.t('Active Students'),
          value: activeStudents,
          color: AppPalette.success,
        ),
        StatCard(
          icon: Icons.event_available_rounded,
          label: AppStrings.t('Upcoming Lessons'),
          value: upcoming,
          color: AppPalette.violet,
        ),
        StatCard(
          icon: Icons.star_rounded,
          label: AppStrings.t('Ratings'),
          value: rating,
          fractionDigits: 1,
          color: AppPalette.gold,
        ),
      ],
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson});

  final InstructorUpcomingLesson lesson;

  @override
  Widget build(BuildContext context) {
    final timeLabel = lesson.startTime != null
        ? DateFormat('dd MMM, HH:mm').format(lesson.startTime!.toLocal())
        : '';
    final canJoin = lesson.status == 'started' && _canJoinNow(lesson);
    final canStart =
        !lesson.isPending && lesson.status != 'started' && _canStartNow(lesson);
    return AppCard(
      color: AppPalette.cloud,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: canJoin ? AppGradients.success : AppGradients.brand,
              borderRadius: AppRadius.all(AppRadius.sm),
              boxShadow: AppShadows.glow(
                  canJoin ? AppPalette.success : AppColors.brand,
                  opacity: 0.28),
            ),
            child: const Icon(Icons.play_circle_fill_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title.isNotEmpty
                      ? lesson.title
                      : AppStrings.t('Lesson'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                ),
                Text(
                  '${AppStrings.t('Student')}: ${lesson.studentName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (timeLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: AppStatPill(
                      icon: Icons.schedule_rounded,
                      label: timeLabel,
                      color: AppColors.brand,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppButton(
            expand: false,
            tone: canJoin ? AppButtonTone.success : AppButtonTone.brand,
            icon: canJoin
                ? Icons.videocam_rounded
                : (canStart ? Icons.play_arrow_rounded : null),
            label: canJoin
                ? AppStrings.t('Join My Class')
                : (lesson.isPending
                    ? AppStrings.t('Reservation is pending.')
                    : (canStart
                        ? AppStrings.t('Start Lesson')
                        : AppStrings.t('Lesson is not started yet'))),
            onPressed: (canJoin || canStart)
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

bool _canJoinNow(InstructorUpcomingLesson lesson) {
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

bool _canStartNow(InstructorUpcomingLesson lesson) {
  final start = lesson.startTime;
  if (start == null) return false;
  final end = lesson.computedEndTime;
  final now = DateTime.now();
  if (end != null && !now.isBefore(end)) return false;
  return !now.isBefore(start.subtract(const Duration(minutes: 15)));
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.gradient,
    this.width,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient gradient;
  final double? width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 140,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.all(compact ? 12 : 14),
        radius: AppRadius.md,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: AppRadius.all(AppRadius.sm),
                boxShadow: AppShadows.soft,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
