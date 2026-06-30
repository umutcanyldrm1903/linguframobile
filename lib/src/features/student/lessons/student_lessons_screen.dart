import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import 'student_live_lesson_screen.dart';
import 'student_lessons_repository.dart';

class StudentLessonsScreen extends StatefulWidget {
  const StudentLessonsScreen({super.key});

  @override
  State<StudentLessonsScreen> createState() => _StudentLessonsScreenState();
}

class _StudentLessonsScreenState extends State<StudentLessonsScreen> {
  final _repo = StudentLessonsRepository();
  late Future<LiveLessonsResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchLiveLessons();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repo.fetchLiveLessons();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LiveLessonsResponse>(
      future: _future,
      builder: (context, snapshot) {
        final upcomingCount = snapshot.data?.upcoming.length ?? 0;
        final pastCount = snapshot.data?.past.length ?? 0;
        final total = upcomingCount + pastCount;

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.xl,
                  AppSpace.md,
                  AppSpace.xl,
                  0,
                ),
                child: AnimatedPageEntrance(
                  child: GradientHero(
                    gradient: AppGradients.hero,
                    padding: const EdgeInsets.all(AppSpace.xl),
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
                            Icons.videocam_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.t('My Lessons'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${AppStrings.t('Total')}: $total',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        AppStatPill(
                          icon: Icons.event_available_rounded,
                          label: '$upcomingCount',
                          color: AppPalette.gold,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              TabBar(
                labelColor: AppColors.ink,
                indicatorColor: AppColors.brand,
                tabs: [
                  Tab(text: AppStrings.t('Upcoming')),
                  Tab(text: AppStrings.t('Past Lessons')),
                ],
              ),
              Expanded(child: _buildBody(snapshot)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<LiveLessonsResponse> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return AppLoader(message: AppStrings.t('Dersler hazirlaniyor...'));
    }

    if (snapshot.hasError) {
      return AppErrorState(
        message: _extractError(snapshot.error),
        onRetry: () => _refresh(),
      );
    }

    final data = snapshot.data;
    if (data == null) {
      return AppEmptyState(
        title: AppStrings.t('No lessons found!'),
        icon: Icons.videocam_off_rounded,
      );
    }

    return TabBarView(
      children: [
        _LessonList(
          items: data.upcoming,
          emptyMessage: AppStrings.t('No upcoming lessons found.'),
          onRefresh: () => _refresh(),
          onOpenDetail: _openDetail,
          onOpenLive: _openLive,
          isUpcoming: true,
        ),
        _LessonList(
          items: data.past,
          emptyMessage: AppStrings.t('No past lessons found.'),
          onRefresh: () => _refresh(),
          onOpenDetail: _openDetail,
          onOpenLive: _openLive,
          isUpcoming: false,
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, LiveLessonItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentLiveLessonScreen(lesson: item),
      ),
    );
  }

  void _openLive(BuildContext context, LiveLessonItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentLiveLessonScreen(lesson: item),
      ),
    );
  }
}

class _LessonList extends StatelessWidget {
  const _LessonList({
    required this.items,
    required this.emptyMessage,
    required this.onRefresh,
    required this.onOpenDetail,
    required this.onOpenLive,
    required this.isUpcoming,
  });

  final List<LiveLessonItem> items;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final bool isUpcoming;
  final void Function(BuildContext, LiveLessonItem) onOpenDetail;
  final void Function(BuildContext, LiveLessonItem) onOpenLive;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppEmptyState(
        title: emptyMessage,
        icon: isUpcoming
            ? Icons.event_busy_rounded
            : Icons.history_rounded,
        actionLabel: AppStrings.t('Try Again'),
        onAction: () => onRefresh(),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpace.xl),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpace.md),
        itemBuilder: (context, index) {
          final lesson = items[index];
          final joinable = _canJoinNow(lesson);
          return AnimatedPageEntrance(
            delay: Duration(milliseconds: 45 * index),
            child: _LessonCard(
              item: lesson,
              isUpcoming: isUpcoming,
              onTap: () => onOpenDetail(context, lesson),
              onJoin: joinable ? () => onOpenLive(context, lesson) : null,
            ),
          );
        },
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.item,
    required this.onTap,
    required this.isUpcoming,
    this.onJoin,
  });

  final LiveLessonItem item;
  final VoidCallback onTap;
  final bool isUpcoming;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final statusLabel = isUpcoming
        ? (item.isPending ? AppStrings.t('Pending') : AppStrings.t('Upcoming'))
        : AppStrings.t('Completed');
    final statusColor = isUpcoming
        ? (item.isPending ? AppPalette.warning : AppColors.brand)
        : AppPalette.success;
    final statusIcon = isUpcoming
        ? (item.isPending
            ? Icons.hourglass_bottom_rounded
            : Icons.schedule_rounded)
        : Icons.check_circle_rounded;

    final joinLabel = _joinButtonLabel(item, onJoin != null);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
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
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(item),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              AppStatPill(
                icon: statusIcon,
                label: statusLabel,
                color: statusColor,
                onLight: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: AppGhostButton(
                  label: AppStrings.t('Details'),
                  onPressed: onTap,
                  icon: Icons.info_outline_rounded,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              if (isUpcoming)
                Expanded(
                  child: AppButton(
                    label: joinLabel,
                    onPressed: onJoin,
                    tone: AppButtonTone.success,
                    icon: Icons.videocam_rounded,
                    height: 52,
                  ),
                )
              else
                Expanded(
                  child: AppButton(
                    label: 'Pratik Yap',
                    onPressed: () =>
                        Navigator.pushNamed(context, '/practice'),
                    tone: AppButtonTone.violet,
                    icon: Icons.auto_awesome_rounded,
                    height: 52,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitle(LiveLessonItem item) {
    final dateLabel = _formatDate(item.startTime);
    final timeLabel = _formatTime(item.startTime);
    final parts = [
      if (item.instructorName.isNotEmpty)
        '${AppStrings.t('Instructor')}: ${item.instructorName}',
      if (dateLabel.isNotEmpty) dateLabel,
      if (timeLabel.isNotEmpty) timeLabel,
    ];
    return parts.join(' - ');
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    return DateFormat('dd MMMM yyyy', _localeName()).format(value);
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '';
    return DateFormat('HH:mm', _localeName()).format(value);
  }
}

bool _canJoinNow(LiveLessonItem lesson) {
  final raw = lesson.joinUrl?.trim() ?? '';
  if (raw.isEmpty) return false;
  if (lesson.isPending) return false;
  if (lesson.isCompleted) return false;

  final status = lesson.status.toLowerCase();
  if (status.startsWith('cancelled')) return false;

  final start = lesson.startTime;
  final end = lesson.computedEndTime;
  if (start == null || end == null) return false;
  final now = DateTime.now();
  if (!now.isBefore(end)) return false;
  final startWindow = start.subtract(const Duration(minutes: 15));
  if (now.isBefore(startWindow)) return false;
  if (lesson.kind == 'student' && status != 'started') return false;
  return true;
}

String _joinButtonLabel(LiveLessonItem lesson, bool enabled) {
  if (enabled) return AppStrings.t('Join Lesson');
  if (lesson.isPending) return AppStrings.t('Reservation is pending.');
  final status = lesson.status.toLowerCase();
  if (lesson.isCompleted ||
      status == 'completed' ||
      status.startsWith('cancelled')) {
    return AppStrings.t('Lesson is finished');
  }
  final start = lesson.startTime;
  final end = lesson.computedEndTime;
  final now = DateTime.now();
  if (start != null &&
      now.isBefore(start.subtract(const Duration(minutes: 15)))) {
    return AppStrings.t('Lesson is not started yet');
  }
  if (lesson.kind == 'student' && status != 'started') {
    return AppStrings.t('Lesson is not started yet');
  }
  if (end != null && now.isAfter(end)) {
    return AppStrings.t('Lesson is finished');
  }
  return AppStrings.t('Unavailable');
}

String _extractError(Object? error) {
  if (error is Exception) {
    return error.toString().replaceAll('Exception: ', '');
  }
  return AppStrings.t('An unexpected error occurred. Please try again.');
}

String _localeName() => AppStrings.code == 'tr' ? 'tr_TR' : 'en_US';
