import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/zoom_join_url.dart';
import '../../zoom/zoom_meeting_service.dart';
import 'instructor_lessons_repository.dart';

class InstructorLessonsScreen extends StatelessWidget {
  const InstructorLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InstructorLessonsPayload?>(
      future: InstructorLessonsRepository().fetchLessons(),
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
                    MaterialPageRoute(builder: (_) => const InstructorLessonsScreen()),
                  ),
                  child: Text(AppStrings.t('Try Again')),
                ),
              ],
            ),
          );
        }

        final payload = snapshot.data;
        final upcoming = payload?.upcoming ?? const <InstructorLessonItem>[];
        final past = payload?.past ?? const <InstructorLessonItem>[];

        if (upcoming.isEmpty && past.isEmpty) {
          return Center(child: Text(AppStrings.t('No lessons found!')));
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(AppStrings.t('Lessons'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (upcoming.isNotEmpty) ...[
              Text(AppStrings.t('Upcoming'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...upcoming.map(
                (lesson) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LessonCard(lesson: lesson, isUpcoming: true),
                ),
              ),
            ],
            if (past.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(AppStrings.t('Past'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...past.map(
                (lesson) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LessonCard(lesson: lesson, isUpcoming: false),
                ),
              ),
            ],
          ],
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
    final statusColor = isUpcoming ? AppColors.brand : Colors.green;
    final canJoin = isUpcoming && lesson.status == 'started' && _canJoinNow(lesson);
    final canStart = isUpcoming &&
        !lesson.isPending &&
        lesson.status != 'started' &&
        _canStartNow(lesson);
    final startLabel = lesson.startTime != null
        ? DateFormat('dd MMM yyyy · HH:mm').format(lesson.startTime!.toLocal())
        : '';
    final subtitle = '${lesson.studentName} · $startLabel';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: statusColor.withOpacity(0.2),
            child: Icon(Icons.play_circle, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.title.isNotEmpty ? lesson.title : AppStrings.t('Lesson'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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

                      final joined = await ZoomMeetingService.joinMeeting(
                        meetingId: meetingId,
                        password: passcode,
                      );
                      if (joined) return;

                      final url = tryParseZoomJoinUrl(rawJoinUrl);
                      if (url == null) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.t('Links is broke or some thing went wrong'),
                            ),
                          ),
                        );
                        return;
                      }

                      final ok = await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.t('Links is broke or some thing went wrong'),
                            ),
                          ),
                        );
                      }
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppStrings.t('Something went wrong'))),
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
