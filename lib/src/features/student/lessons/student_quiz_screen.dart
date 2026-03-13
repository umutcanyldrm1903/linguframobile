import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'student_course_repository.dart';

class StudentQuizScreen extends StatefulWidget {
  const StudentQuizScreen({
    super.key,
    required this.slug,
    required this.quizId,
    this.title,
  });

  final String slug;
  final int quizId;
  final String? title;

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen> {
  final _repo = StudentCourseRepository();
  late Future<QuizDetail> _future;
  final Map<int, int> _answers = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchQuiz(slug: widget.slug, quizId: widget.quizId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuizDetail>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quiz')),
            body: Center(
              child: Text(
                _errorMessage(snapshot.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final quiz = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text(quiz.title.isNotEmpty ? quiz.title : 'Quiz')),
          body: Column(
            children: [
              _QuizHeader(quiz: quiz),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  itemCount: quiz.questions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final question = quiz.questions[index];
                    return _QuestionCard(
                      index: index + 1,
                      question: question,
                      selectedAnswerId: _answers[question.id],
                      onChanged: (answerId) {
                        setState(() {
                          _answers[question.id] = answerId;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: !_canSubmit(quiz) || _submitting
                    ? null
                    : () => _submit(quiz),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Quiz Gönder'),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _canSubmit(QuizDetail quiz) {
    return quiz.questions.every((question) => _answers.containsKey(question.id));
  }

  Future<void> _submit(QuizDetail quiz) async {
    setState(() => _submitting = true);
    try {
      final result = await _repo.submitQuiz(
        slug: widget.slug,
        quizId: widget.quizId,
        answers: _answers,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentQuizResultScreen(
            result: result,
            quizTitle: quiz.title,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _errorMessage(Object? error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}

class _QuizHeader extends StatelessWidget {
  const _QuizHeader({required this.quiz});

  final QuizDetail quiz;

  @override
  Widget build(BuildContext context) {
    final attemptText = '${quiz.attemptUsed}/${quiz.attempt}';
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quiz.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoChip(label: 'Soru', value: quiz.totalQuestions.toString()),
              _InfoChip(label: 'Süre', value: '${quiz.time} dk'),
              _InfoChip(label: 'Deneme', value: attemptText),
              _InfoChip(label: 'Geçme', value: quiz.passMark.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value',
          style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selectedAnswerId,
    required this.onChanged,
  });

  final int index;
  final QuizQuestion question;
  final int? selectedAnswerId;
  final ValueChanged<int> onChanged;

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
          Text(
            '$index. ${question.title}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...question.answers.map(
            (answer) => InkWell(
              onTap: () => onChanged(answer.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selectedAnswerId == answer.id
                      ? const Color(0xFFE9F6FF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedAnswerId == answer.id
                        ? AppColors.brand
                        : const Color(0xFFD9E3F2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selectedAnswerId == answer.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selectedAnswerId == answer.id
                          ? AppColors.brand
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(answer.title)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentQuizResultScreen extends StatelessWidget {
  const StudentQuizResultScreen({
    super.key,
    required this.result,
    required this.quizTitle,
  });

  final QuizResultDetail result;
  final String quizTitle;

  @override
  Widget build(BuildContext context) {
    final passed = result.status.toLowerCase() == 'pass';
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Sonucu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quizTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  passed ? 'Başarılı' : 'Başarısız',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: passed ? Colors.green : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 10),
                _ResultRow(label: 'Puan', value: result.yourMarks.toString()),
                _ResultRow(
                  label: 'Toplam',
                  value: result.totalMarks.toString(),
                ),
                _ResultRow(
                  label: 'Geçme',
                  value: result.passMarks.toString(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Cevaplar',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...result.results.map((item) => _AnswerResultTile(item: item)),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

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

class _AnswerResultTile extends StatelessWidget {
  const _AnswerResultTile({required this.item});

  final QuizAnswerResult item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.question, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(item.answer),
          const SizedBox(height: 6),
          Text(
            item.correct ? 'Doğru' : 'Yanlış',
            style: TextStyle(
              color: item.correct ? Colors.green : Colors.redAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
