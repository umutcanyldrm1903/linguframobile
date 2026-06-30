import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../practice/practice_entry_invite.dart';
import '../../shared/content_preview_launcher.dart';
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
    final chapters = widget.course.chapters;
    final totalLessons =
        chapters.fold<int>(0, (sum, chapter) => sum + chapter.items.length);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.course.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppGlowBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.xl, AppSpace.lg, AppSpace.xl, AppSpace.xxxl),
            children: [
              AnimatedPageEntrance(
                child: _buildHero(totalLessons, chapters.length),
              ),
              const SizedBox(height: AppSpace.xl),
              SectionHeader(
                title: AppStrings.t('Content'),
                icon: Icons.menu_book_rounded,
              ),
              StaggeredReveal(
                children: [
                  for (var i = 0; i < chapters.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: i == chapters.length - 1 ? 0 : AppSpace.md),
                      child: _ChapterCard(
                        chapter: chapters[i],
                        index: i,
                        loadingItemId: _loadingItemId,
                        iconForType: _iconForType,
                        colorForType: _colorForType,
                        labelForType: _labelForType,
                        onTapItem: _openLesson,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(int totalLessons, int chapterCount) {
    return GradientHero(
      gradient: AppGradients.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: const Icon(Icons.play_lesson_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  widget.course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          if (widget.course.instructorName.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              widget.course.instructorName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              AppStatPill(
                icon: Icons.menu_book_rounded,
                label: '$chapterCount ${AppStrings.t('Chapters')}',
              ),
              AppStatPill(
                icon: Icons.play_circle_outline_rounded,
                label: '$totalLessons ${AppStrings.t('Lessons')}',
              ),
            ],
          ),
        ],
      ),
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

  Color _colorForType(String type) {
    switch (type) {
      case 'quiz':
        return AppPalette.violet;
      case 'live':
        return AppPalette.streak;
      case 'document':
        return AppPalette.info;
      default:
        return AppColors.brand;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'quiz':
        return AppStrings.t('Quiz');
      case 'live':
        return AppStrings.t('Live Lesson');
      case 'document':
        return AppStrings.t('Document');
      default:
        return AppStrings.t('Lesson');
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

      if ((rawUrl ?? '').trim().isEmpty) {
        _showSnack(AppStrings.t('Link not found.'));
        return;
      }

      if (!mounted) return;
      await openContentPreview(
        context,
        title: info.title.isNotEmpty
            ? info.title
            : (item.title.isNotEmpty
                ? item.title
                : AppStrings.t(
                    item.type == 'live' ? 'Live Lesson' : 'Lesson',
                  )),
        rawUrl: rawUrl!,
      );

      if (!mounted) return;
      if (item.type == 'lesson' || item.type == 'document') {
        await _repo.markLessonComplete(item.id);
        if (!mounted) return;
        await _showPracticeInvite(item);
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

  Future<void> _showPracticeInvite(CourseItem item) async {
    final title = item.title.trim().isNotEmpty ? item.title.trim() : 'Bu ders';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpace.sm),
              radius: AppRadius.xxl,
              child: PracticeEntryInvite(
                title: 'Dersi pratikle pekiştir',
                subtitle:
                    '$title tamamlandı. Şimdi aynı konudan kısa pratik yapıp 2x XP kazanabilirsin.',
                buttonLabel: 'Pratiğe Geç',
                bonusLabel: '2x XP',
                icon: Icons.school_rounded,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/practice');
                },
              ),
            ),
          ),
        );
      },
    );
  }

  String _errorMessage(Object? error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return AppStrings.t('Something went wrong. Please try again.');
  }
}

/// Tek bölüm kartı — genişleyebilir ders listesi içeren [AppCard].
class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
    required this.index,
    required this.loadingItemId,
    required this.iconForType,
    required this.colorForType,
    required this.labelForType,
    required this.onTapItem,
  });

  final CourseChapter chapter;
  final int index;
  final int? loadingItemId;
  final IconData Function(String) iconForType;
  final Color Function(String) colorForType;
  final String Function(String) labelForType;
  final ValueChanged<CourseItem> onTapItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      radius: AppRadius.lg,
      child: ClipRRect(
        borderRadius: AppRadius.all(AppRadius.lg),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: index == 0,
            tilePadding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg, vertical: AppSpace.xs),
            childrenPadding: const EdgeInsets.only(
                left: AppSpace.md,
                right: AppSpace.md,
                bottom: AppSpace.md),
            leading: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: AppRadius.all(AppRadius.sm),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            title: Text(
              chapter.title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 15,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${chapter.items.length} ${AppStrings.t('Lessons')}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
            children: [
              for (final item in chapter.items)
                _LessonTile(
                  item: item,
                  isLoading: loadingItemId == item.id,
                  icon: iconForType(item.type),
                  color: colorForType(item.type),
                  typeLabel: labelForType(item.type),
                  onTap: () => onTapItem(item),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ders satırı — tür ikonu/çipi + süre + ilerleme oku.
class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.item,
    required this.isLoading,
    required this.icon,
    required this.color,
    required this.typeLabel,
    required this.onTap,
  });

  final CourseItem item;
  final bool isLoading;
  final IconData icon;
  final Color color;
  final String typeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title =
        item.title.isNotEmpty ? item.title : AppStrings.t('Content');
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: PressableScale(
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md, vertical: AppSpace.md),
          decoration: BoxDecoration(
            color: AppPalette.cloud,
            borderRadius: AppRadius.all(AppRadius.sm),
            border: Border.all(color: AppPalette.line, width: 1.1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppStatPill(
                          icon: icon,
                          label: typeLabel,
                          color: color,
                          onLight: true,
                        ),
                        if (item.duration.isNotEmpty)
                          AppStatPill(
                            icon: Icons.schedule_rounded,
                            label: '${item.duration} dk',
                            color: AppColors.muted,
                            onLight: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right_rounded,
                    color: color.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}
