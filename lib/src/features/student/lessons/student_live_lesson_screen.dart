import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/zoom_join_url.dart';
import '../../zoom/zoom_meeting_service.dart';
import 'student_lessons_repository.dart';

class StudentLiveLessonScreen extends StatelessWidget {
  const StudentLiveLessonScreen({super.key, this.lesson});

  final LiveLessonItem? lesson;

  @override
  Widget build(BuildContext context) {
    final joinState = _deriveJoinState(lesson);
    final canJoin = joinState == _LessonJoinState.canJoin;

    final buttonLabel = switch (joinState) {
      _LessonJoinState.canJoin => AppStrings.t('Derse Katil'),
      _LessonJoinState.pending => AppStrings.t('Reservation is pending.'),
      _LessonJoinState.notStarted => AppStrings.t('Lesson is not started yet'),
      _LessonJoinState.finished => AppStrings.t('Lesson is finished'),
      _LessonJoinState.unknown => AppStrings.t('Loading'),
    };

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('Online Lesson'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HeroCard(lesson: lesson),
          const SizedBox(height: 16),
          _StatusCard(lesson: lesson),
          const SizedBox(height: 16),
          _MeetingCard(lesson: lesson, revealCredentials: canJoin),
          const SizedBox(height: 16),
          const _RulesCard(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canJoin
                  ? () async {
                      final meetingId = (lesson!.meetingId ?? '').trim();
                      final passcode = (lesson!.password ?? '').trim();
                      final joined = await ZoomMeetingService.joinMeeting(
                        meetingId: meetingId,
                        password: passcode,
                      );
                      if (joined) return;

                      final uri = tryParseZoomJoinUrl(lesson!.joinUrl ?? '');
                      if (uri == null) {
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

                      final opened = await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.t('Links is broke or some thing went wrong'),
                            ),
                          ),
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.video_call),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LessonJoinState { unknown, pending, notStarted, canJoin, finished }

_LessonJoinState _deriveJoinState(LiveLessonItem? lesson) {
  if (lesson == null) return _LessonJoinState.unknown;
  final status = lesson.status.toLowerCase();

  if (lesson.isCompleted || status == 'completed') return _LessonJoinState.finished;
  if (lesson.isPending || status == 'pending') return _LessonJoinState.pending;
  if (status.startsWith('cancelled')) return _LessonJoinState.finished;

  // Prefer the backend's can_join guard. It already bakes in:
  // - time window (start - 15min -> end)
  // - host-start / access checks for private lessons
  // - credential visibility rules (join_url/meeting_id/password can be nulled)
  if (lesson.canJoin) return _LessonJoinState.canJoin;

  final raw = lesson.joinUrl?.trim() ?? '';
  if (raw.isEmpty) return _LessonJoinState.notStarted;

  final start = lesson.startTime;
  final end = lesson.computedEndTime;
  if (start == null || end == null) return _LessonJoinState.notStarted;

  final now = DateTime.now();
  if (!now.isBefore(end)) return _LessonJoinState.finished;

  final startWindow = start.subtract(const Duration(minutes: 15));

  if (now.isBefore(startWindow)) return _LessonJoinState.notStarted;
  return _LessonJoinState.notStarted;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({this.lesson});

  final LiveLessonItem? lesson;

  @override
  Widget build(BuildContext context) {
    final title = lesson?.title.isNotEmpty == true ? lesson!.title : 'Canlı Ders';
    final instructor = lesson?.instructorName ?? '';
    final dateLabel = _formatDate(lesson?.startTime);
    final timeLabel = _formatTime(lesson?.startTime);
    final meta = [
      if (instructor.isNotEmpty) 'Eğitmen: $instructor',
      if (dateLabel.isNotEmpty || timeLabel.isNotEmpty)
        '${dateLabel.isNotEmpty ? dateLabel : ''}${dateLabel.isNotEmpty && timeLabel.isNotEmpty ? ' · ' : ''}$timeLabel',
    ].where((value) => value.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand, Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Icon(Icons.school, color: AppColors.brand),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                for (final item in meta)
                  Text(item, style: const TextStyle(color: AppColors.ink)),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.4),
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
    final startLabel = _formatTime(lesson?.startTime);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Zoom Toplantısı',
              style: TextStyle(fontWeight: FontWeight.w700)),
          if (!revealCredentials) ...[
            const SizedBox(height: 10),
            Text(
              AppStrings.t('Lesson is not started yet'),
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 10),
          _InfoRow(label: 'Meeting ID', value: meetingId),
          _InfoRow(label: 'Şifre', value: password),
          _InfoRow(
            label: 'Başlangıç',
            value: startLabel.isEmpty ? '-' : '$startLabel (TR)',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Ders Kuralları', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          _Rule(text: 'Ders başlamadan 5 dk önce hazır olun.'),
          _Rule(text: 'Mikrofon ve kamera kontrolü yapın.'),
          _Rule(text: 'Ders sonunda kısa geri bildirim bırakın.'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.brand),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return '';
  return DateFormat('dd MMMM yyyy', 'tr_TR').format(value);
}

String _formatTime(DateTime? value) {
  if (value == null) return '';
  return DateFormat('HH:mm').format(value);
}
