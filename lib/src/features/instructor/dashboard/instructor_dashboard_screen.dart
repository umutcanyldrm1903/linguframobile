import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
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
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InstructorDashboardScreen()),
                  ),
                  child: Text(AppStrings.t('Try Again')),
                ),
              ],
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
            Container(
              padding: EdgeInsets.all(compact ? 14 : 20),
              decoration: BoxDecoration(
                color: AppColors.brandDeep,
                borderRadius: BorderRadius.circular(compact ? 14 : 18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppStrings.t('Welcome')}, $name!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 18 : null,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.t('Manage packages and track your progress'),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 12 : 16),
            _StatGrid(stats: stats, compact: compact),
            SizedBox(height: compact ? 12 : 16),
            _SectionCard(
              title: AppStrings.t('Upcoming Lessons'),
              compact: compact,
              child: upcoming.isEmpty
                  ? Text(AppStrings.t('No lessons found!'))
                  : Column(
                      children: upcoming
                          .map(
                            (lesson) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _LessonTile(lesson: lesson),
                            ),
                          )
                          .toList(),
                    ),
            ),
            SizedBox(height: compact ? 12 : 16),
            _SectionCard(
              title: AppStrings.t('Quick Contact'),
              compact: compact,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      compact ? 2 : (constraints.maxWidth > 700 ? 4 : 3);
                  final spacing = compact ? 8.0 : 12.0;
                  final itemWidth =
                      (constraints.maxWidth - ((columns - 1) * spacing)) /
                          columns;

                  final items = <_QuickAction>[
                    _QuickAction(
                      label: AppStrings.t('Messages'),
                      icon: Icons.chat_bubble_outline,
                      onTap: () =>
                          _open(context, const InstructorMessagesScreen()),
                    ),
                    _QuickAction(
                      label: AppStrings.t('Homeworks'),
                      icon: Icons.assignment,
                      onTap: () =>
                          _open(context, const InstructorHomeworksScreen()),
                    ),
                    _QuickAction(
                      label: AppStrings.t('Reports'),
                      icon: Icons.bar_chart,
                      onTap: () =>
                          _open(context, const InstructorReportsScreen()),
                    ),
                    _QuickAction(
                      label: AppStrings.t('User Guide'),
                      icon: Icons.help_outline,
                      onTap: () =>
                          _open(context, const InstructorGuideScreen()),
                    ),
                    _QuickAction(
                      label: AppStrings.t('Library'),
                      icon: Icons.menu_book,
                      onTap: () =>
                          _open(context, const InstructorLibraryScreen()),
                    ),
                    _QuickAction(
                      label: AppStrings.t('Agreement'),
                      icon: Icons.description,
                      onTap: () =>
                          _open(context, const InstructorAgreementScreen()),
                    ),
                    _QuickAction(
                      label: AppStrings.t('Instructions'),
                      icon: Icons.rule_folder,
                      onTap: () =>
                          _open(context, const InstructorInstructionsScreen()),
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
                            onTap: item.onTap,
                            width: itemWidth,
                            compact: compact,
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
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
      children: [
        _StatCard(
            title: AppStrings.t('Lessons'), value: totalLessons.toString()),
        _StatCard(
            title: AppStrings.t('Active Students'),
            value: activeStudents.toString()),
        _StatCard(
            title: AppStrings.t('Upcoming Lessons'),
            value: upcoming.toString()),
        _StatCard(
            title: AppStrings.t('Ratings'), value: rating.toStringAsFixed(1)),
      ],
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.compact = false,
  });

  final String title;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
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
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFEFF6FF),
          child: Icon(Icons.play_circle, color: AppColors.brandDeep),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.title.isNotEmpty ? lesson.title : AppStrings.t('Lesson'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text('${AppStrings.t('Student')}: ${lesson.studentName}'),
              Text(timeLabel, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        ElevatedButton(
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
                          content: Text(AppStrings.t('Something went wrong'))),
                    );
                  }
                }
              : null,
          child: Text(
            canJoin
                ? AppStrings.t('Join My Class')
                : (lesson.isPending
                    ? AppStrings.t('Reservation is pending.')
                    : (canStart
                        ? AppStrings.t('Start Lesson')
                        : AppStrings.t('Lesson is not started yet'))),
          ),
        ),
      ],
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
    this.width,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double? width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width ?? 140,
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          color: AppColors.brand.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(compact ? 12 : 14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.brandDeep),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
