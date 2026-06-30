import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../practice/practice_entry_invite.dart';
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
            body: AppLoader(),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quiz')),
            body: AppErrorState(message: _errorMessage(snapshot.error)),
          );
        }

        final quiz = snapshot.data!;
        final answered = quiz.questions
            .where((q) => _answers.containsKey(q.id))
            .length;
        return Scaffold(
          appBar:
              AppBar(title: Text(quiz.title.isNotEmpty ? quiz.title : 'Quiz')),
          body: AppGlowBackground(
            child: Column(
              children: [
                AnimatedPageEntrance(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpace.xl, AppSpace.lg, AppSpace.xl, 0),
                    child: _QuizHeader(quiz: quiz, answered: answered),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpace.xl, AppSpace.md, AppSpace.xl, AppSpace.xl),
                    itemCount: quiz.questions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpace.md),
                    itemBuilder: (context, index) {
                      final question = quiz.questions[index];
                      return AnimatedPageEntrance(
                        delay: Duration(milliseconds: 60 * index),
                        child: _QuestionCard(
                          index: index + 1,
                          question: question,
                          selectedAnswerId: _answers[question.id],
                          onChanged: (answerId) {
                            setState(() {
                              _answers[question.id] = answerId;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: AppButton(
                label: 'Quiz Gönder',
                icon: Icons.send_rounded,
                loading: _submitting,
                onPressed: !_canSubmit(quiz) || _submitting
                    ? null
                    : () => _submit(quiz),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _canSubmit(QuizDetail quiz) {
    return quiz.questions
        .every((question) => _answers.containsKey(question.id));
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
  const _QuizHeader({required this.quiz, required this.answered});

  final QuizDetail quiz;
  final int answered;

  @override
  Widget build(BuildContext context) {
    final attemptText = '${quiz.attemptUsed}/${quiz.attempt}';
    final total = quiz.totalQuestions > 0
        ? quiz.totalQuestions
        : quiz.questions.length;
    final progress = total > 0 ? answered / total : 0.0;
    return GradientHero(
      glowColor: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    AppStatPill(
                      icon: Icons.help_outline_rounded,
                      label: 'Soru $total',
                    ),
                    AppStatPill(
                      icon: Icons.timer_outlined,
                      label: '${quiz.time} dk',
                    ),
                    AppStatPill(
                      icon: Icons.refresh_rounded,
                      label: 'Deneme $attemptText',
                    ),
                    AppStatPill(
                      icon: Icons.flag_outlined,
                      label: 'Geçme ${quiz.passMark}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          ProgressRing(
            value: progress,
            size: 78,
            color: Colors.white,
            trackColor: Colors.white.withValues(alpha: 0.28),
            center: Text(
              '$answered/$total',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    question.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          ...question.answers.map(
            (answer) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _AnswerOption(
                label: answer.title,
                selected: selectedAnswerId == answer.id,
                onTap: () => onChanged(answer.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md, vertical: AppSpace.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brand.withValues(alpha: 0.10)
              : Colors.white,
          borderRadius: AppRadius.all(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.brand : AppPalette.line,
            width: selected ? 1.6 : 1.2,
          ),
          boxShadow:
              selected ? AppShadows.glow(AppColors.brand, opacity: 0.18) : null,
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? AppColors.brand : AppColors.muted,
              size: 22,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.ink : AppColors.muted,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
    final scoreRatio = result.totalMarks > 0
        ? (result.yourMarks / result.totalMarks).clamp(0.0, 1.0)
        : 0.0;
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Sonucu')),
      body: AppGlowBackground(
        accent: passed ? AppPalette.success : AppPalette.danger,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.xl),
          children: [
            if (passed)
              _PassCelebrationTrigger(title: quizTitle),
            AnimatedPageEntrance(
              child: GradientHero(
                gradient:
                    passed ? AppGradients.success : AppGradients.pair(
                        const Color(0xFFFF6B6B), const Color(0xFFE23B3B)),
                glowColor: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          passed
                              ? Icons.emoji_events_rounded
                              : Icons.sentiment_dissatisfied_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: Text(
                            passed ? 'Başarılı' : 'Başarısız',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      quizTitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ProgressRing(
                          value: scoreRatio.toDouble(),
                          size: 88,
                          color: Colors.white,
                          trackColor: Colors.white.withValues(alpha: 0.28),
                          center: AnimatedCounter(
                            value: result.yourMarks,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.xl),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HeroStatRow(
                                label: 'Puanın',
                                value: result.yourMarks.toString(),
                              ),
                              _HeroStatRow(
                                label: 'Toplam',
                                value: result.totalMarks.toString(),
                              ),
                              _HeroStatRow(
                                label: 'Geçme',
                                value: result.passMarks.toString(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            PracticeEntryInvite(
              title: passed
                  ? 'Harika, şimdi pratikle güçlendir'
                  : 'Yanlışlarını pratikte toparla',
              subtitle: passed
                  ? 'Quiz bitti. Aynı konudan kısa pratik yaparak serini koru ve bonus XP kazan.'
                  : 'Zorlandığın noktaları oyun modunda tekrar et, canlarını kullanmadan hızlan.',
              buttonLabel: passed ? 'Bonus Pratik' : 'Hataları Çalış',
              bonusLabel: passed ? 'Perfect bonus' : 'Tekrar XP',
              icon: passed ? Icons.emoji_events_rounded : Icons.replay_rounded,
              onTap: () => Navigator.pushNamed(context, '/practice'),
            ),
            const SizedBox(height: AppSpace.lg),
            const SectionHeader(
              title: 'Cevaplar',
              icon: Icons.fact_check_outlined,
            ),
            StaggeredReveal(
              children: result.results
                  .map((item) => _AnswerResultTile(item: item))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// PASS durumunda bir kez konfeti kutlaması tetikler (sonuç ekranı stateless).
class _PassCelebrationTrigger extends StatefulWidget {
  const _PassCelebrationTrigger({required this.title});

  final String title;

  @override
  State<_PassCelebrationTrigger> createState() =>
      _PassCelebrationTriggerState();
}

class _PassCelebrationTriggerState extends State<_PassCelebrationTrigger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showCelebration(
        context,
        title: 'Tebrikler!',
        subtitle: 'Quizi başarıyla geçtin.',
        icon: Icons.emoji_events_rounded,
        color: AppPalette.success,
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _HeroStatRow extends StatelessWidget {
  const _HeroStatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
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
    final color = item.correct ? AppPalette.success : AppPalette.danger;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.question,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                AppStatPill(
                  icon: item.correct
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  label: item.correct ? 'Doğru' : 'Yanlış',
                  color: color,
                  onLight: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              item.answer,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
