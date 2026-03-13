import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import 'student_course_repository.dart';
import 'student_learning_screen.dart';
import 'student_live_lesson_screen.dart';

class StudentCourseDetailScreen extends StatefulWidget {
  const StudentCourseDetailScreen({
    super.key,
    required this.title,
    required this.instructor,
    required this.rating,
    required this.reviews,
    required this.progress,
    this.hasLive = false,
    this.courseSlug,
  });

  final String title;
  final String instructor;
  final double rating;
  final int reviews;
  final double progress;
  final bool hasLive;
  final String? courseSlug;

  @override
  State<StudentCourseDetailScreen> createState() =>
      _StudentCourseDetailScreenState();
}

class _StudentCourseDetailScreenState extends State<StudentCourseDetailScreen> {
  final _repo = StudentCourseRepository();
  Future<CourseDetailPayload?>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.courseSlug != null && widget.courseSlug!.isNotEmpty) {
      _future = _load();
    }
  }

  Future<CourseDetailPayload?> _load() async {
    final slug = widget.courseSlug;
    if (slug == null || slug.isEmpty) return null;
    final course = await _repo.fetchCourse(slug);
    final progress = await _repo.fetchProgress(slug);

    List<CourseReviewItem> reviews = const [];
    try {
      reviews = await _repo.fetchReviews(slug);
    } catch (_) {
      reviews = const [];
    }

    final lessonId = course.firstLessonId;
    List<QnaQuestion> questions = const [];
    if (lessonId != null) {
      try {
        questions = await _repo.fetchQuestions(slug: slug, lessonId: lessonId);
      } catch (_) {
        questions = const [];
      }
    }

    return CourseDetailPayload(
      course: course,
      progress: progress,
      reviews: reviews,
      questions: questions,
      lessonId: lessonId,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _handleAskQuestion(
    BuildContext context,
    String slug,
    int lessonId,
  ) async {
    final result = await _showAskQuestionSheet(context);
    if (result == null) return;

    try {
      await _repo.createQuestion(
        slug: slug,
        lessonId: lessonId,
        question: result.question,
        description: result.description,
      );
      if (!context.mounted) return;
      await _refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Question submitted.'))),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
    }
  }

  Future<_QuestionFormResult?> _showAskQuestionSheet(BuildContext context) {
    final questionController = TextEditingController();
    final descriptionController = TextEditingController();

    return showModalBottomSheet<_QuestionFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.t('Ask Question'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: questionController,
                decoration: InputDecoration(
                  labelText: AppStrings.t('Question'),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: AppStrings.t('Description'),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final question = questionController.text.trim();
                    final description = descriptionController.text.trim();
                    if (question.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.t('Question is required.')),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(
                      context,
                      _QuestionFormResult(
                        question: question,
                        description: description,
                      ),
                    );
                  },
                  child: Text(AppStrings.t('Submit')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _errorMessage(Object? error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return AppStrings.t('An unexpected error occurred. Please try again.');
  }

  void _openLearning(
    BuildContext context, {
    required CourseLearning? course,
    CourseItem? initialItem,
  }) {
    if (course == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppStrings.t('Course content could not be loaded.'))),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentLearningScreen(
          course: course,
          initialItem: initialItem,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      return _buildScaffold(
        context,
        title: widget.title,
        instructor: widget.instructor,
        rating: widget.rating,
        reviews: widget.reviews,
        progress: widget.progress,
        description: '',
        chapters: const [],
        hasLive: widget.hasLive,
        reviewItems: const [],
        questions: const [],
        lessonId: null,
        course: null,
      );
    }

    return FutureBuilder<CourseDetailPayload?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _buildScaffold(
            context,
            title: widget.title,
            instructor: widget.instructor,
            rating: widget.rating,
            reviews: widget.reviews,
            progress: widget.progress,
            description: '',
            chapters: const [],
            hasLive: widget.hasLive,
            reviewItems: const [],
            questions: const [],
            lessonId: null,
            course: null,
          );
        }

        final payload = snapshot.data!;
        final reviewCount = payload.reviews.isNotEmpty
            ? payload.reviews.length
            : widget.reviews;
        return _buildScaffold(
          context,
          title: payload.course.title.isNotEmpty
              ? payload.course.title
              : widget.title,
          instructor: payload.course.instructorName.isNotEmpty
              ? payload.course.instructorName
              : widget.instructor,
          rating: widget.rating,
          reviews: reviewCount,
          progress: payload.progress,
          description: payload.course.description,
          chapters: payload.course.chapters,
          hasLive: widget.hasLive,
          reviewItems: payload.reviews,
          questions: payload.questions,
          lessonId: payload.lessonId,
          course: payload.course,
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required String title,
    required String instructor,
    required double rating,
    required int reviews,
    required double progress,
    required String description,
    required List<CourseChapter> chapters,
    required bool hasLive,
    required List<CourseReviewItem> reviewItems,
    required List<QnaQuestion> questions,
    required int? lessonId,
    required CourseLearning? course,
  }) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(title: Text(AppStrings.t('Course Details'))),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: _HeaderCard(
                title: title,
                instructor: instructor,
                rating: rating,
                reviews: reviews,
                progress: progress,
                hasLive: hasLive,
                onContinue: course != null
                    ? () => _openLearning(context, course: course)
                    : null,
              ),
            ),
            TabBar(
              labelColor: AppColors.ink,
              indicatorColor: AppColors.brand,
              tabs: [
                Tab(text: AppStrings.t('Overview')),
                Tab(text: AppStrings.t('Curriculum')),
                Tab(text: AppStrings.t('Reviews')),
                Tab(text: AppStrings.t('Q&A')),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(description: description),
                  _CurriculumTab(
                    chapters: chapters,
                    onItemTap: course != null
                        ? (item) => _openLearning(
                              context,
                              course: course,
                              initialItem: item,
                            )
                        : null,
                  ),
                  _ReviewsTab(reviews: reviewItems),
                  _QnaTab(
                    questions: questions,
                    onAsk: widget.courseSlug != null &&
                            widget.courseSlug!.isNotEmpty &&
                            lessonId != null
                        ? () => _handleAskQuestion(
                              context,
                              widget.courseSlug!,
                              lessonId,
                            )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseDetailPayload {
  const CourseDetailPayload({
    required this.course,
    required this.progress,
    required this.reviews,
    required this.questions,
    required this.lessonId,
  });

  final CourseLearning course;
  final double progress;
  final List<CourseReviewItem> reviews;
  final List<QnaQuestion> questions;
  final int? lessonId;
}

class _QuestionFormResult {
  const _QuestionFormResult(
      {required this.question, required this.description});

  final String question;
  final String description;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.instructor,
    required this.rating,
    required this.reviews,
    required this.progress,
    required this.hasLive,
    this.onContinue,
  });

  final String title;
  final String instructor;
  final double rating;
  final int reviews;
  final double progress;
  final bool hasLive;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(Icons.menu_book, color: AppColors.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${AppStrings.t('Instructor')}: $instructor',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(text: AppStrings.t('General English')),
              _Tag(text: AppStrings.t('Speaking Lessons')),
              _Tag(text: AppStrings.t('Business English')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, size: 18, color: AppColors.brand),
              const SizedBox(width: 4),
              Text(
                '$rating / 5',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Text(
                '${AppStrings.t('Reviews')}: $reviews',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}% ${AppStrings.t('Completed')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onContinue,
                  child: Text(AppStrings.t('Continue Lesson')),
                ),
              ),
              if (hasLive) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentLiveLessonScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brand,
                      side: const BorderSide(color: AppColors.brand),
                    ),
                    child: Text(AppStrings.t('Join Live Lesson')),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final hasDescription = description.trim().isNotEmpty;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Section(
          title: AppStrings.t('Course Description'),
          child: Text(
            hasDescription
                ? description
                : AppStrings.t(
                    'This course will help you build a strong foundation in speaking, vocabulary, and daily communication.',
                  ),
            style: const TextStyle(height: 1.5),
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: AppStrings.t('What You Will Learn'),
          child: Column(
            children: [
              _Bullet(
                text:
                    AppStrings.t('Fluent speaking and accurate pronunciation'),
              ),
              _Bullet(
                text: AppStrings.t('Daily and business English expressions'),
              ),
              _Bullet(
                text: AppStrings.t('Exam-focused strategies and confidence'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: AppStrings.t('Requirements'),
          child: Column(
            children: [
              _Bullet(text: AppStrings.t('Basic English knowledge')),
              _Bullet(text: AppStrings.t('Microphone and stable internet')),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurriculumTab extends StatelessWidget {
  const _CurriculumTab({required this.chapters, this.onItemTap});

  final List<CourseChapter> chapters;
  final ValueChanged<CourseItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return Center(child: Text(AppStrings.t('No curriculum found.')));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: chapters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final chapter = chapters[index];
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
            children: chapter.items
                .map(
                  (lesson) => ListTile(
                    leading: Icon(
                      lesson.type == 'quiz'
                          ? Icons.quiz
                          : lesson.type == 'live'
                              ? Icons.video_call
                              : lesson.type == 'document'
                                  ? Icons.description
                                  : Icons.play_circle_outline,
                      color: AppColors.brand,
                    ),
                    title: Text(
                      lesson.title.isNotEmpty
                          ? lesson.title
                          : AppStrings.t('Content'),
                    ),
                    trailing: Text(
                      lesson.duration.isNotEmpty
                          ? lesson.duration
                          : lesson.type,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: onItemTap == null ? null : () => onItemTap!(lesson),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.reviews});

  final List<CourseReviewItem> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Center(child: Text(AppStrings.t('No reviews yet.')));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return _ReviewTile(
          name: review.name,
          rating: review.rating.round(),
          comment: review.review,
          avatar: review.avatar,
        );
      },
    );
  }
}

class _QnaTab extends StatelessWidget {
  const _QnaTab({required this.questions, this.onAsk});

  final List<QnaQuestion> questions;
  final VoidCallback? onAsk;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (onAsk != null)
          ElevatedButton.icon(
            onPressed: onAsk,
            icon: const Icon(Icons.question_answer),
            label: Text(AppStrings.t('Ask Question')),
          )
        else
          Text(
            AppStrings.t('You must select a lesson before asking a question.'),
            style: const TextStyle(color: AppColors.muted),
          ),
        const SizedBox(height: 12),
        if (questions.isEmpty)
          Text(AppStrings.t('No questions yet.'))
        else
          ...questions.map((item) => _QnaTile(question: item)),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

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
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.brand),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.name,
    required this.rating,
    required this.comment,
    this.avatar,
  });

  final String name;
  final int rating;
  final String comment;
  final String? avatar;

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
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF1F5F9),
                child: (avatar != null && avatar!.isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          avatar!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(Icons.person, color: AppColors.muted),
                          ),
                        ),
                      )
                    : const Icon(Icons.person, color: AppColors.muted),
              ),
              const SizedBox(width: 10),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star,
                size: 16,
                color:
                    index < rating ? AppColors.brand : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(comment),
        ],
      ),
    );
  }
}

class _QnaTile extends StatelessWidget {
  const _QnaTile({required this.question});

  final QnaQuestion question;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        title: Text(
          question.question,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(question.userName),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (question.description.isNotEmpty) Text(question.description),
                const SizedBox(height: 10),
                if (question.replies.isEmpty)
                  Text(AppStrings.t('No replies yet.'))
                else
                  ...question.replies.map(
                    (reply) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.reply,
                              size: 18, color: AppColors.brand),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reply.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(reply.reply),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
