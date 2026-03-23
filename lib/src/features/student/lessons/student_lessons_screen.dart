import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
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
        final total = (snapshot.data?.upcoming.length ?? 0) +
            (snapshot.data?.past.length ?? 0);

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    Text(
                      AppStrings.t('My Lessons'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('${AppStrings.t('Total')}: $total'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return _EmptyState(
        message: _extractError(snapshot.error),
        onRetry: () => _refresh(),
      );
    }

    final data = snapshot.data;
    if (data == null) {
      return _EmptyState(message: AppStrings.t('No lessons found!'));
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
      return _EmptyState(message: emptyMessage, onRetry: onRefresh);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final lesson = items[index];
          final joinable = _canJoinNow(lesson);
          return _LessonCard(
            item: lesson,
            isUpcoming: isUpcoming,
            onTap: () => onOpenDetail(context, lesson),
            onJoin: joinable ? () => onOpenLive(context, lesson) : null,
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
        ? (item.isPending ? AppColors.muted : AppColors.brand)
        : Colors.green;

    final joinLabel = _joinButtonLabel(item, onJoin != null);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: statusColor.withValues(alpha: 0.2),
                  child: Icon(Icons.play_circle, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle(item),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brand,
                      side: const BorderSide(color: AppColors.brand),
                    ),
                    child: Text(AppStrings.t('Details')),
                  ),
                ),
                if (isUpcoming) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onJoin,
                      child: Text(joinLabel),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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
    return parts.join(' • ');
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      children: [
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => onRetry!(),
            child: Text(AppStrings.t('Try Again')),
          ),
        ],
      ],
    );
  }
}

String _extractError(Object? error) {
  if (error is Exception) {
    return error.toString().replaceAll('Exception: ', '');
  }
  return AppStrings.t('An unexpected error occurred. Please try again.');
}

String _localeName() => AppStrings.code == 'tr' ? 'tr_TR' : 'en_US';
