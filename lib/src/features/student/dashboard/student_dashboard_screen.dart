import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lingufranca_mobile/src/core/localization/app_strings.dart';
import 'package:lingufranca_mobile/src/core/theme/app_colors.dart';
import 'package:lingufranca_mobile/src/core/ui/ui.dart';
import 'package:lingufranca_mobile/src/features/practice/practice_entry_invite.dart';
import 'package:lingufranca_mobile/src/features/student/dashboard/student_dashboard_repository.dart';
import 'package:lingufranca_mobile/src/features/student/lessons/student_lessons_repository.dart';
import 'package:lingufranca_mobile/src/features/student/lessons/student_live_lesson_screen.dart';
import 'package:lingufranca_mobile/src/features/student/notifications/student_notifications_screen.dart';
import 'package:lingufranca_mobile/src/features/student/packages/student_packages_screen.dart';
import 'package:lingufranca_mobile/src/features/student/homeworks/student_homeworks_repository.dart';
import 'package:lingufranca_mobile/src/features/student/homeworks/student_homeworks_screen.dart';
import 'package:lingufranca_mobile/src/features/student/instructors/student_instructors_screen.dart';
import 'package:lingufranca_mobile/src/features/student/reports/student_reports_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final StudentDashboardRepository _repository = StudentDashboardRepository();
  late final Future<DashboardPayload?> _future = _repository.fetchDashboard();
  bool _requestingTrial = false;
  Timer? _lessonClock;

  @override
  void initState() {
    super.initState();
    _lessonClock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _lessonClock?.cancel();
    super.dispose();
  }

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
          content: Text(
            AppStrings.t(
              'Trial lesson request will continue without a phone number.',
            ),
          ),
        ),
      );
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
          : AppStrings.t('Deneme dersi talebiniz alındı.');

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
                      color: AppPalette.line,
                      borderRadius: AppRadius.pill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppGradients.success,
                        borderRadius: AppRadius.all(AppRadius.sm),
                        boxShadow:
                            AppShadows.glow(AppPalette.success, opacity: 0.30),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        AppStrings.t('Trial lesson request received'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (supportLink.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.lg),
                  AppCard(
                    color: AppPalette.cloud,
                    padding: const EdgeInsets.all(AppSpace.lg),
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
                  const SizedBox(height: AppSpace.md),
                  AppGhostButton(
                    label: AppStrings.t('Copy Support Link'),
                    icon: Icons.copy_outlined,
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
                  ),
                ],
                const SizedBox(height: 10),
                AppButton(
                  label: AppStrings.t('Done'),
                  tone: AppButtonTone.success,
                  onPressed: () => Navigator.of(context).pop(),
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
          return const AppLoader(message: 'Panel hazirlaniyor...');
        }

        if (snapshot.hasError) {
          return AppErrorState(
            message: _extractError(snapshot.error!),
            retryLabel: AppStrings.t('Try Again'),
            onRetry: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const StudentDashboardScreen(),
              ),
            ),
          );
        }

        final payload = snapshot.data;
        final plan = payload?.plan;
        final name = payload?.name.isNotEmpty == true
            ? payload!.name
            : AppStrings.t('Welcome');
        final upcoming = _futureLessons(
          payload?.upcoming ?? const <LiveLessonItem>[],
        );
        final hasPlanTitle = plan?.title.trim().isNotEmpty == true;
        final hasCredits = (plan?.lessonsRemaining ?? 0) > 0;
        final showTrialCta = !hasPlanTitle && !hasCredits;

        return ListView(
          padding: EdgeInsets.all(compact ? 14 : 20),
          children: [
            StaggeredReveal(
              children: [
                _WelcomeHero(name: name, plan: plan, compact: compact),
                SizedBox(height: compact ? 12 : 16),
                PracticeEntryInvite(
                  compact: compact,
                  title: 'Günlük Pratik',
                  subtitle:
                      'Derslerini oyun modunda pekiştir, XP kazan ve serini koru.',
                  buttonLabel: 'Pratik Yap',
                  bonusLabel: 'Bugün +10 XP',
                  onTap: () => Navigator.pushNamed(context, '/practice'),
                ),
                if (showTrialCta) ...[
                  SizedBox(height: compact ? 12 : 16),
                  _TrialLessonHero(
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
                SectionHeader(
                  title: AppStrings.t('Library'),
                  icon: Icons.grid_view_rounded,
                ),
                _QuickActionGrid(
                  compact: compact,
                  actions: [
                    _QuickAction(
                      label: AppStrings.t('Packages'),
                      icon: Icons.card_membership,
                      gradient: AppGradients.violet,
                      onTap: () =>
                          _open(context, const StudentPackagesScreen()),
                    ),
                    _QuickAction(
                      label: AppStrings.t('Reports'),
                      icon: Icons.bar_chart,
                      gradient: AppGradients.success,
                      onTap: () => _open(context, const StudentReportsScreen()),
                    ),
                    _QuickAction(
                      label: AppStrings.t('Notifications'),
                      icon: Icons.notifications,
                      gradient: AppGradients.streak,
                      onTap: () =>
                          _open(context, const StudentNotificationsScreen()),
                    ),
                    _QuickAction(
                      label: AppStrings.t('Homeworks'),
                      icon: Icons.assignment,
                      gradient: AppGradients.gold,
                      onTap: () =>
                          _open(context, const StudentHomeworksScreen()),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 14 : 18),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: AppStrings.t('Library'),
                        subtitle: AppStrings.t(
                          'Live lessons, instructor selection, package management, and notifications at your fingertips.',
                        ),
                        icon: Icons.local_library_rounded,
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: const [
                          _TopicChip(text: 'Vocabulary'),
                          _TopicChip(text: 'Grammar'),
                          _TopicChip(text: 'Reading & Writing'),
                          _TopicChip(text: 'Listening'),
                          _TopicChip(text: 'IELTS & TOEFL'),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 12 : 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: AppStrings.t('Upcoming Lessons'),
                        subtitle: AppStrings.t('Active Upcoming Lessons'),
                        icon: Icons.event_available_rounded,
                      ),
                      if (upcoming.isEmpty)
                        Text(
                          AppStrings.t('No lessons found!'),
                          style: const TextStyle(color: AppColors.muted),
                        )
                      else
                        Column(
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
                    ],
                  ),
                ),
                SizedBox(height: compact ? 12 : 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: AppStrings.t('Homeworks'),
                        icon: Icons.assignment_rounded,
                        actionLabel: AppStrings.t('View more'),
                        onAction: () =>
                            _open(context, const StudentHomeworksScreen()),
                      ),
                      FutureBuilder<StudentHomeworksPayload?>(
                        future: StudentHomeworksRepository().fetchHomeworks(),
                        builder: (context, homeworkSnapshot) {
                          final payload = homeworkSnapshot.data;
                          final active =
                              payload?.active ?? const <StudentHomeworkItem>[];
                          if (homeworkSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: AppLoader(
                                message: 'Odevler hazirlaniyor...',
                              ),
                            );
                          }

                          if (homeworkSnapshot.hasError) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _extractError(homeworkSnapshot.error!),
                                  style:
                                      const TextStyle(color: AppColors.muted),
                                ),
                                const SizedBox(height: 10),
                                AppGhostButton(
                                  label: AppStrings.t('Try Again'),
                                  icon: Icons.refresh_rounded,
                                  expand: false,
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const StudentHomeworksScreen(),
                                    ),
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
                                  style:
                                      const TextStyle(color: AppColors.muted),
                                ),
                                const SizedBox(height: 10),
                                AppGhostButton(
                                  label: AppStrings.t('View All'),
                                  icon: Icons.arrow_forward_rounded,
                                  expand: false,
                                  onPressed: () => _open(
                                    context,
                                    const StudentHomeworksScreen(),
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
                            ],
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

  List<LiveLessonItem> _futureLessons(List<LiveLessonItem> lessons) {
    final now = DateTime.now();
    final filtered = lessons.where((lesson) {
      final start = _localTime(lesson.startTime);
      if (start == null) return true;
      return start.isAfter(now);
    }).toList(growable: false);

    return [...filtered]..sort((a, b) {
        final aStart = _localTime(a.startTime);
        final bStart = _localTime(b.startTime);
        if (aStart == null && bStart == null) return 0;
        if (aStart == null) return 1;
        if (bStart == null) return -1;
        return aStart.compareTo(bStart);
      });
  }

  DateTime? _localTime(DateTime? value) {
    if (value == null) return null;
    return value.isUtc ? value.toLocal() : value;
  }

  String _formatLessonTime(DateTime? startTime) {
    final local = _localTime(startTime);
    if (local == null) return '';
    final locale = AppStrings.code;
    final day = DateFormat('d MMM', locale).format(local);
    final time = DateFormat('HH:mm', locale).format(local);
    return '$day - $time';
  }
}

/// Karşılama "kahraman" kartı — selam + gerçek plan/kredi özetleri (pill'ler).
class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.name, this.plan, this.compact = false});

  final String name;
  final PlanSummary? plan;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planTitle =
        plan?.title.isNotEmpty == true ? plan!.title : AppStrings.t('No Plan');
    final lessons = plan?.lessonsRemaining ?? 0;
    final cancelRemaining = plan?.cancelRemaining ?? 0;
    final assignedInstructor =
        plan?.assignedInstructorName ?? AppStrings.t('Not Assigned');

    return GradientHero(
      gradient: AppGradients.hero,
      glowColor: Colors.white,
      padding: EdgeInsets.all(compact ? 18 : AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: const Icon(Icons.waving_hand_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  AppStrings.t(
                    'Nice to see you again, :name!',
                  ).replaceAll(':name', name),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 18 : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.t(
              'Live lessons, instructor selection, package management, and notifications at your fingertips.',
            ),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.92)),
          ),
          SizedBox(height: compact ? 14 : AppSpace.lg),
          // Gerçek plan değerleri — uydurma sayı yok.
          if (lessons > 0 || cancelRemaining > 0)
            Wrap(
              spacing: AppSpace.lg,
              runSpacing: AppSpace.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _HeroCounter(
                  icon: Icons.confirmation_number_rounded,
                  value: lessons,
                  label: AppStrings.t('Credits'),
                ),
                _HeroCounter(
                  icon: Icons.event_busy_rounded,
                  value: cancelRemaining,
                  label: AppStrings.t('Cancellation Right'),
                ),
              ],
            ),
          SizedBox(height: compact ? 12 : 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppStatPill(
                icon: Icons.card_membership_rounded,
                label: '${AppStrings.t('Plan')}: $planTitle',
              ),
              AppStatPill(
                icon: Icons.person_rounded,
                label: '${AppStrings.t('Instructor')}: $assignedInstructor',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Gradyan zeminde gerçek sayıyı animasyonla gösteren mini blok.
class _HeroCounter extends StatelessWidget {
  const _HeroCounter({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCounter(
              value: value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Ücretsiz deneme dersi CTA'sı — altın gradyanlı kahraman kartı.
class _TrialLessonHero extends StatelessWidget {
  const _TrialLessonHero({
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
    return GradientHero(
      gradient: AppGradients.gold,
      glowColor: Colors.white,
      padding: EdgeInsets.all(compact ? 18 : AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  AppStrings.t('Free Trial Lesson'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.t(
              'You are about to request a one-time free trial lesson from our support team!',
            ),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.95)),
          ),
          SizedBox(height: compact ? 14 : AppSpace.lg),
          AppButton(
            label: AppStrings.t('Schedule Trial Lesson'),
            tone: AppButtonTone.neutral,
            icon: Icons.event_available_rounded,
            loading: requesting,
            onPressed: requesting ? null : onSchedule,
          ),
          const SizedBox(height: AppSpace.sm),
          AppGhostButton(
            label: AppStrings.t('Choose Your Instructor'),
            icon: Icons.school_rounded,
            color: Colors.white,
            onPressed: onChooseInstructor,
          ),
        ],
      ),
    );
  }
}

/// Hızlı erişim ızgarası — gradyan ikon çipli AppCard'lar.
class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions, this.compact = false});

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
                (action) => SizedBox(
                  width: itemWidth,
                  child: _QuickAction(
                    label: action.label,
                    icon: action.icon,
                    gradient: action.gradient,
                    onTap: action.onTap,
                    compact: compact,
                  ),
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
    required this.gradient,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: AppRadius.all(AppRadius.sm),
              boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.18),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              fontSize: compact ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kütüphane konu etiketi (statik, seçilemez) — markalı çip görünümü.
class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.10),
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.brand,
        ),
      ),
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
    return AppCard(
      onTap: onTap,
      color: AppPalette.cloud,
      padding: const EdgeInsets.all(12),
      radius: AppRadius.md,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: AppRadius.all(AppRadius.sm),
              boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.22),
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                ),
                Text(
                  'Egitmen: $instructor',
                  style: const TextStyle(color: AppColors.muted),
                ),
                if (time.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 14, color: AppColors.brand),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
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
        ? AppPalette.success
        : statusLabel == AppStrings.t('Archived')
            ? AppColors.muted
            : AppPalette.warning;
    final statusIcon = statusLabel == AppStrings.t('Completed')
        ? Icons.check_circle_rounded
        : statusLabel == AppStrings.t('Archived')
            ? Icons.inventory_2_rounded
            : Icons.schedule_rounded;
    return AppCard(
      color: AppPalette.cloud,
      padding: const EdgeInsets.all(12),
      radius: AppRadius.md,
      child: Row(
        children: [
          Icon(statusIcon, size: 18, color: statusColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          AppStatPill(
            icon: statusIcon,
            label: statusLabel,
            color: statusColor,
            onLight: true,
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
}
