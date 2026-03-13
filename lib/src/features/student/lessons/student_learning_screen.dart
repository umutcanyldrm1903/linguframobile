import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/content_uri.dart';
import '../../shared/content_webview_screen.dart';
import '../../zoom/live_lesson_launcher.dart';
import 'student_course_repository.dart';
import 'student_quiz_screen.dart';

class StudentLearningScreen extends StatefulWidget {
  const StudentLearningScreen({
    super.key,
    required this.course,
    this.initialItem,
  });

  final CourseLearning course;
  final CourseItem? initialItem;

  @override
  State<StudentLearningScreen> createState() => _StudentLearningScreenState();
}

class _StudentLearningScreenState extends State<StudentLearningScreen> {
  final _repo = StudentCourseRepository();
  int? _loadingItemId;

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openLesson(widget.initialItem!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: widget.course.chapters.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final chapter = widget.course.chapters[index];
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ExpansionTile(
              title: Text(
                chapter.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              children: chapter.items.map(_buildLessonTile).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLessonTile(CourseItem item) {
    final isLoading = _loadingItemId == item.id;
    return ListTile(
      leading: Icon(_iconForType(item.type), color: AppColors.brand),
      title: Text(
        item.title.isNotEmpty ? item.title : AppStrings.t('Content'),
      ),
      subtitle: item.duration.isNotEmpty
          ? Text('${item.duration} dk')
          : Text(item.type.toUpperCase()),
      trailing: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: isLoading ? null : () => _openLesson(item),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'quiz':
        return Icons.quiz;
      case 'live':
        return Icons.video_call;
      case 'document':
        return Icons.description;
      default:
        return Icons.play_circle_outline;
    }
  }

  Future<void> _openLesson(CourseItem item) async {
    if (item.id <= 0) {
      _showSnack(AppStrings.t('Content details could not be found.'));
      return;
    }

    if (item.type == 'quiz') {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentQuizScreen(
            slug: widget.course.slug,
            quizId: item.id,
          ),
        ),
      );
      return;
    }

    setState(() => _loadingItemId = item.id);
    try {
      final info = await _repo.fetchLessonInfo(
        slug: widget.course.slug,
        type: item.type,
        lessonId: item.id,
      );

      final rawUrl = item.type == 'live' ? info.joinUrl : info.fileUrl;
      if (item.type == 'live') {
        if (!mounted) return;
        await openLiveLessonSession(
          context,
          title: info.title.isNotEmpty
              ? info.title
              : (item.title.isNotEmpty
                  ? item.title
                  : AppStrings.t('Live Lesson')),
          joinUrl: rawUrl ?? '',
          meetingId: info.meetingId,
          password: info.password,
        );
        return;
      }

      final externalUri = tryResolveWebUri(rawUrl);
      if (externalUri == null) {
        _showSnack(AppStrings.t('Link not found.'));
        return;
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContentWebViewScreen(
            title: info.title.isNotEmpty
                ? info.title
                : (item.title.isNotEmpty
                    ? item.title
                    : AppStrings.t(
                        item.type == 'live' ? 'Live Lesson' : 'Lesson',
                      )),
            loadUrl:
                (tryBuildEmbeddedContentUri(rawUrl) ?? externalUri).toString(),
            externalUrl: externalUri.toString(),
            actionLabel: AppStrings.t(
              item.type == 'live' ? 'Open Externally' : 'Open in Browser',
            ),
          ),
        ),
      );

      if (!mounted) return;
      if (item.type == 'lesson' || item.type == 'document') {
        await _repo.markLessonComplete(item.id);
      }
    } catch (error) {
      _showSnack(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _loadingItemId = null);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _errorMessage(Object? error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return AppStrings.t('Something went wrong. Please try again.');
  }
}
