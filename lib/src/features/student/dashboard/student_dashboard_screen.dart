import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lingufranca_mobile/src/core/localization/app_strings.dart';
import 'package:lingufranca_mobile/src/core/theme/app_colors.dart';
import 'package:lingufranca_mobile/src/features/student/dashboard/student_dashboard_repository.dart';
import 'package:lingufranca_mobile/src/features/student/lessons/student_lessons_repository.dart';
import 'package:lingufranca_mobile/src/features/student/lessons/student_live_lesson_screen.dart';
import 'package:lingufranca_mobile/src/features/student/notifications/student_notifications_screen.dart';
import 'package:lingufranca_mobile/src/features/student/packages/student_packages_screen.dart';
import 'package:lingufranca_mobile/src/features/student/homeworks/student_homeworks_repository.dart';
import 'package:lingufranca_mobile/src/features/student/homeworks/student_homeworks_screen.dart';
import 'package:lingufranca_mobile/src/features/student/instructors/student_instructors_screen.dart';
import 'package:lingufranca_mobile/src/features/student/orders/student_orders_screen.dart';
import 'package:lingufranca_mobile/src/features/student/profile/student_profile_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final StudentDashboardRepository _repository = StudentDashboardRepository();
  late final Future<DashboardPayload?> _future = _repository.fetchDashboard();
  bool _requestingTrial = false;

  String _extractError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
        if (message is Map) {
          return message.values.map((value) => value.toString()).join('\n');
        }
      }
    }
    return AppStrings.t('Something went wrong');
  }

  Future<void> _handleTrialRequest(DashboardPayload? payload) async {
    final phoneDigits = (payload?.phone ?? '').replaceAll(RegExp(r'\D+'), '');
    if (phoneDigits.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('Please add your phone number first.')),
        ),
      );
      _open(context, const StudentProfileScreen());
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.t('Schedule Trial Lesson')),
        content: Text(
          AppStrings.t(
            'You are about to request a one-time free trial lesson from our support team!',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.t('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.t('Confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _requestingTrial = true);
    try {
      final result = await _repository.requestTrialLesson();
      if (!mounted) return;

      final message = result.message.trim().isNotEmpty
          ? result.message.trim()
          : AppStrings.t('Deneme dersi talebiniz alindi.');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      await _showTrialRequestResult(
        message: message,
        supportLink: result.whatsappUrl.trim(),
      );
    } catch (error) {
      if (!mounted) return;
      if (error is DioException && error.response?.statusCode == 401) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_extractError(error))));
    } finally {
      if (mounted) {
        setState(() => _requestingTrial = false);
      }
    }
  }

  Future<void> _showTrialRequestResult({
    required String message,
    required String supportLink,
  }) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.only(top: 40),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  AppStrings.t('Trial lesson request received'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (supportLink.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t('Support Link'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(supportLink),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: supportLink),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.t('Support link copied.'),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(AppStrings.t('Copy Support Link')),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppStrings.t('Done')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;

    return FutureBuilder<DashboardPayload?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_extractError(snapshot.error!)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentDashboardScreen(),
                    ),
                  ),
                  child: Text(AppStrings.t('Try Again')),
                ),
              ],
            ),
          );
        }

        final payload = snapshot.data;
        final plan = payload?.plan;
        final name = payload?.name.isNotEmpty == true
            ? payload!.name
            : AppStrings.t('Welcome');
        final upcoming = payload?.upcoming ?? const <LiveLessonItem>[];
        final hasPlanTitle = plan?.title.trim().isNotEmpty == true;
        final hasCredits = (plan?.lessonsRemaining ?? 0) > 0;
        final showTrialCta = !hasPlanTitle && !hasCredits;

        return ListView(
          padding: EdgeInsets.all(compact ? 14 : 20),
          children: [
            _WelcomeCard(name: name, compact: compact),
            SizedBox(height: compact ? 12 : 16),
            _PlanBar(plan: plan),
            if (showTrialCta) ...[
              SizedBox(height: compact ? 12 : 16),
              _TrialLessonCard(
                requesting: _requestingTrial,
                onSchedule: () => _handleTrialRequest(payload),
                onChooseInstructor: () => _open(
                  context,
                  const StudentInstructorsScreen(standalone: true),
                ),
                compact: compact,
              ),
            ],
            SizedBox(height: compact ? 14 : 18),
            _QuickActionRow(
              compact: compact,
              actions: [
                _QuickAction(
                  label: AppStrings.t('Packages'),
                  icon: Icons.card_membership,
                  onTap: () => _open(context, const StudentPackagesScreen()),
                ),
                _QuickAction(
                  label: AppStrings.t('Payment'),
                  icon: Icons.payment,
                  onTap: () => _open(context, const StudentOrdersScreen()),
                ),
                _QuickAction(
                  label: AppStrings.t('Notifications'),
                  icon: Icons.notifications,
                  onTap: () =>
                      _open(context, const StudentNotificationsScreen()),
                ),
                _QuickAction(
                  label: AppStrings.t('Homeworks'),
                  icon: Icons.assignment,
                  onTap: () => _open(context, const StudentHomeworksScreen()),
                ),
              ],
            ),
            SizedBox(height: compact ? 14 : 18),
            _SectionCard(
              title: AppStrings.t('Library'),
              subtitle: AppStrings.t(
                'Live lessons, instructor selection, package management, and notifications at your fingertips.',
              ),
              compact: compact,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  const _ChipCard(text: 'Vocabulary'),
                  const _ChipCard(text: 'Grammar'),
                  const _ChipCard(text: 'Reading & Writing'),
                  const _ChipCard(text: 'Listening'),
                  const _ChipCard(text: 'IELTS & TOEFL'),
                ],
              ),
            ),
            SizedBox(height: compact ? 12 : 16),
            _SectionCard(
              title: AppStrings.t('Upcoming Lessons'),
              subtitle: AppStrings.t('Active Upcoming Lessons'),
              compact: compact,
              child: upcoming.isEmpty
                  ? Text(
                      AppStrings.t('No lessons found!'),
                      style: const TextStyle(color: AppColors.muted),
                    )
                  : Column(
                      children: [
                        for (final lesson in upcoming.take(3)) ...[
                          _LessonTile(
                            title: lesson.title.isNotEmpty
                                ? lesson.title
                                : lesson.courseTitle,
                            instructor: lesson.instructorName,
                            time: _formatLessonTime(lesson.startTime),
                            onTap: () => _open(
                              context,
                              StudentLiveLessonScreen(lesson: lesson),
                            ),
                          ),
                          if (lesson != upcoming.take(3).last)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
            ),
            SizedBox(height: compact ? 12 : 16),
            _SectionCard(
              title: AppStrings.t('Homeworks'),
              subtitle: AppStrings.t('Homeworks'),
              compact: compact,
              child: FutureBuilder<StudentHomeworksPayload?>(
                future: StudentHomeworksRepository().fetchHomeworks(),
                builder: (context, homeworkSnapshot) {
                  final payload = homeworkSnapshot.data;
                  final active =
                      payload?.active ?? const <StudentHomeworkItem>[];
                  if (homeworkSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (homeworkSnapshot.hasError) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _extractError(homeworkSnapshot.error!),
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StudentHomeworksScreen(),
                              ),
                            ),
                            child: Text(AppStrings.t('Try Again')),
                          ),
                        ),
                      ],
                    );
                  }

                  if (active.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t('No homeworks found!'),
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: () =>
                                _open(context, const StudentHomeworksScreen()),
                            child: Text(AppStrings.t('View All')),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      for (final item in active.take(2)) ...[
                        _HomeworkPreview(item: item),
                        if (item != active.take(2).last)
                          const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              _open(context, const StudentHomeworksScreen()),
                          child: Text(AppStrings.t('View more')),
                        ),
                      ),
                    ],
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

  String _formatLessonTime(DateTime? startTime) {
    if (startTime == null) return '';
    final locale = AppStrings.code;
    final day = DateFormat('d MMM', locale).format(startTime);
    final time = DateFormat('HH:mm', locale).format(startTime);
    return '$day · $time';
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.name, this.compact = false});

  final String name;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t(
              'Nice to see you again, :name!',
            ).replaceAll(':name', name),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 18 : null,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.t(
              'Live lessons, instructor selection, package management, and notifications at your fingertips.',
            ),
            style: TextStyle(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _PlanBar extends StatelessWidget {
  const _PlanBar({this.plan});

  final PlanSummary? plan;

  @override
  Widget build(BuildContext context) {
    final planTitle =
        plan?.title.isNotEmpty == true ? plan!.title : AppStrings.t('No Plan');
    final lessons = plan?.lessonsRemaining ?? 0;
    final cancelRemaining = plan?.cancelRemaining ?? 0;
    final assignedInstructor =
        plan?.assignedInstructorName ?? AppStrings.t('Not Assigned');

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Pill(text: '${AppStrings.t('Plan')}: $planTitle'),
        _Pill(
          text:
              '${AppStrings.t('Credits')}: $lessons ${AppStrings.t('Lessons')}',
        ),
        _Pill(
          text:
              '${AppStrings.t('Cancellation Right')}: $cancelRemaining ${AppStrings.t('Lessons')}',
        ),
        _Pill(text: '${AppStrings.t('Instructor')}: $assignedInstructor'),
      ],
    );
  }
}

class _TrialLessonCard extends StatelessWidget {
  const _TrialLessonCard({
    required this.requesting,
    required this.onSchedule,
    required this.onChooseInstructor,
    this.compact = false,
  });

  final bool requesting;
  final VoidCallback onSchedule;
  final VoidCallback onChooseInstructor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t('Free Trial Lesson'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.t(
              'You are about to request a one-time free trial lesson from our support team!',
            ),
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: requesting ? null : onSchedule,
              child: requesting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppStrings.t('Schedule Trial Lesson')),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onChooseInstructor,
              child: Text(AppStrings.t('Choose Your Instructor')),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({required this.actions, this.compact = false});

  final List<_QuickAction> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = compact ? 2 : (width > 700 ? 4 : 3);
        final spacing = compact ? 8.0 : 12.0;
        final itemWidth = (width - ((columns - 1) * spacing)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions
              .map(
                (action) => _QuickAction(
                  label: action.label,
                  icon: action.icon,
                  onTap: action.onTap,
                  width: itemWidth,
                  compact: compact,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
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
        width: width,
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(compact ? 12 : 14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.brand),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.compact = false,
  });

  final String title;
  final String subtitle;
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
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ChipCard extends StatelessWidget {
  const _ChipCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.title,
    required this.instructor,
    required this.time,
    this.onTap,
  });

  final String title;
  final String instructor;
  final String time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFF1F5F9),
              child: Icon(Icons.play_circle, color: AppColors.brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  Text('Eğitmen: $instructor'),
                  Text(time, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _HomeworkPreview extends StatelessWidget {
  const _HomeworkPreview({required this.item});

  final StudentHomeworkItem item;

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusLabel(item.status);
    final statusColor = statusLabel == AppStrings.t('Completed')
        ? Colors.green
        : AppColors.brand;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(item.title)),
          Text(statusLabel, style: Theme.of(context).textTheme.bodyMedium),
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
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
