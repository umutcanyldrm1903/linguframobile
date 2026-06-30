import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../zoom/live_lesson_launcher.dart';
import 'student_lessons_repository.dart';

class StudentLiveLessonScreen extends StatelessWidget {
  const StudentLiveLessonScreen({super.key, this.lesson});

  final LiveLessonItem? lesson;

  @override
  Widget build(BuildContext context) {
    final joinState = _deriveJoinState(lesson);
    final canJoin = joinState == _LessonJoinState.canJoin;

    final buttonLabel = switch (joinState) {
      _LessonJoinState.canJoin => AppStrings.t('Join Lesson'),
      _LessonJoinState.pending => AppStrings.t('Reservation is pending.'),
      _LessonJoinState.notStarted => AppStrings.t('Lesson is not started yet'),
      _LessonJoinState.finished => AppStrings.t('Lesson is finished'),
      _LessonJoinState.unknown => AppStrings.t('Loading'),
    };

    final buttonTone = switch (joinState) {
      _LessonJoinState.canJoin => AppButtonTone.success,
      _ => AppButtonTone.neutral,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('Online Lesson')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppGlowBackground(
        accent: AppColors.brand,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.xl),
          children: [
            AnimatedPageEntrance(
              child: _HeroCard(lesson: lesson),
            ),
            const SizedBox(height: AppSpace.lg),
            StaggeredReveal(
              children: [
                _StatusCard(lesson: lesson),
                const SizedBox(height: AppSpace.lg),
                _MeetingCard(lesson: lesson, revealCredentials: canJoin),
                const SizedBox(height: AppSpace.lg),
                const _RulesCard(),
                const SizedBox(height: AppSpace.xl),
                AppButton(
                  label: buttonLabel,
                  tone: buttonTone,
                  icon: Icons.video_call_rounded,
                  onPressed: canJoin
                      ? () async {
                          await openLiveLessonSession(
                            context,
                            title: lesson!.title.isNotEmpty
                                ? lesson!.title
                                : AppStrings.t('Online Lesson'),
                            joinUrl: lesson!.joinUrl ?? '',
                            meetingId: lesson!.meetingId,
                            password: lesson!.password,
                          );
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _LessonJoinState { unknown, pending, notStarted, canJoin, finished }

_LessonJoinState _deriveJoinState(LiveLessonItem? lesson) {
  if (lesson == null) {
    return _LessonJoinState.unknown;
  }
  final status = lesson.status.toLowerCase();

  if (lesson.isCompleted || status == 'completed') {
    return _LessonJoinState.finished;
  }
  if (lesson.isPending || status == 'pending') {
    return _LessonJoinState.pending;
  }
  if (status.startsWith('cancelled')) {
    return _LessonJoinState.finished;
  }

  if (lesson.canJoin) {
    return _LessonJoinState.canJoin;
  }

  final raw = lesson.joinUrl?.trim() ?? '';
  if (raw.isEmpty) {
    return _LessonJoinState.notStarted;
  }

  final start = lesson.startTime;
  final end = lesson.computedEndTime;
  if (start == null || end == null) {
    return _LessonJoinState.notStarted;
  }

  final now = DateTime.now();
  if (!now.isBefore(end)) {
    return _LessonJoinState.finished;
  }

  final startWindow = start.subtract(const Duration(minutes: 15));
  if (now.isBefore(startWindow)) {
    return _LessonJoinState.notStarted;
  }
  return _LessonJoinState.notStarted;
}

/// Maps a join state to a meaningful semantic color + icon.
({Color color, IconData icon}) _statusVisual(_LessonJoinState state) {
  return switch (state) {
    _LessonJoinState.canJoin => (
        color: AppPalette.success,
        icon: Icons.check_circle_rounded,
      ),
    _LessonJoinState.pending => (
        color: AppPalette.warning,
        icon: Icons.hourglass_top_rounded,
      ),
    _LessonJoinState.notStarted => (
        color: AppColors.brand,
        icon: Icons.schedule_rounded,
      ),
    _LessonJoinState.finished => (
        color: AppPalette.danger,
        icon: Icons.event_busy_rounded,
      ),
    _LessonJoinState.unknown => (
        color: AppColors.muted,
        icon: Icons.hourglass_empty_rounded,
      ),
  };
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({this.lesson});

  final LiveLessonItem? lesson;

  @override
  Widget build(BuildContext context) {
    final title = lesson?.title.isNotEmpty == true
        ? lesson!.title
        : AppStrings.t('Live Lesson');
    final instructor = lesson?.instructorName ?? '';
    final dateLabel = _formatDate(lesson?.startTime);
    final timeLabel = _formatTime(lesson?.startTime);

    return GradientHero(
      gradient: AppGradients.hero,
      glowColor: AppPalette.gold,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.all(AppRadius.md),
              boxShadow: AppShadows.glow(AppColors.brandDeep, opacity: 0.25),
            ),
            child: const Icon(Icons.school_rounded,
                color: AppColors.brand, size: 28),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t('Live Lesson'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    if (instructor.isNotEmpty)
                      AppStatPill(
                        icon: Icons.person_rounded,
                        label: instructor,
                      ),
                    if (dateLabel.isNotEmpty)
                      AppStatPill(
                        icon: Icons.calendar_today_rounded,
                        label: dateLabel,
                      ),
                    if (timeLabel.isNotEmpty)
                      AppStatPill(
                        icon: Icons.access_time_rounded,
                        label: timeLabel,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({this.lesson});

  final LiveLessonItem? lesson;

  @override
  Widget build(BuildContext context) {
    final state = _deriveJoinState(lesson);
    final text = switch (state) {
      _LessonJoinState.unknown => AppStrings.t('Loading'),
      _LessonJoinState.pending => AppStrings.t('Reservation is pending.'),
      _LessonJoinState.notStarted => AppStrings.t('Lesson is not started yet'),
      _LessonJoinState.canJoin => AppStrings.t('You can join the lesson'),
      _LessonJoinState.finished => AppStrings.t('Lesson is finished'),
    };
    final visual = _statusVisual(state);

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.14),
              borderRadius: AppRadius.all(AppRadius.sm),
            ),
            child: Icon(visual.icon, color: visual.color),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({this.lesson, required this.revealCredentials});

  final LiveLessonItem? lesson;
  final bool revealCredentials;

  @override
  Widget build(BuildContext context) {
    final meetingId = revealCredentials ? (lesson?.meetingId ?? '-') : '-';
    final password = revealCredentials ? (lesson?.password ?? '-') : '-';
    final startLabel = _formatDateTime(lesson?.startTime);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: AppStrings.t('Zoom Meeting'),
            icon: Icons.videocam_rounded,
          ),
          if (!revealCredentials) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md, vertical: AppSpace.sm),
              decoration: BoxDecoration(
                color: AppPalette.warning.withValues(alpha: 0.12),
                borderRadius: AppRadius.all(AppRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock_rounded,
                      size: 18, color: AppPalette.warning),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      AppStrings.t('Lesson is not started yet'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
          ],
          _InfoRow(
            icon: Icons.tag_rounded,
            label: AppStrings.t('Meeting ID'),
            value: meetingId,
          ),
          _InfoRow(
            icon: Icons.key_rounded,
            label: AppStrings.t('Password'),
            value: password,
          ),
          _InfoRow(
            icon: Icons.event_rounded,
            label: AppStrings.t('Starts At'),
            value: startLabel.isEmpty ? '-' : startLabel,
          ),
        ],
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: AppStrings.t('Lesson Rules'),
            icon: Icons.checklist_rounded,
          ),
          _Rule(
              text:
                  AppStrings.t('Be ready 5 minutes before the lesson starts.')),
          _Rule(
              text: AppStrings.t(
                  'Check your microphone and camera before joining.')),
          _Rule(
              text: AppStrings.t(
                  'Leave a short feedback note after the lesson.')),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.muted),
            const SizedBox(width: AppSpace.sm),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs + 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 19, color: AppPalette.success),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.ink, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

String _localeName() => AppStrings.code == 'tr' ? 'tr_TR' : 'en_US';

String _formatDate(DateTime? value) {
  if (value == null) return '';
  return DateFormat('dd MMMM yyyy', _localeName()).format(value);
}

String _formatTime(DateTime? value) {
  if (value == null) return '';
  return DateFormat('HH:mm', _localeName()).format(value);
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '';
  return DateFormat('dd MMMM yyyy • HH:mm', _localeName()).format(value);
}
