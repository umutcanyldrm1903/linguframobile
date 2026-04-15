import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../shared/trial_lesson_gate.dart';
import '../student/instructors/instructor_repository.dart';
import 'public_repository.dart';

String _placementError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
      if (message is Map) {
        return message.values.map((value) => value.toString()).join('\n');
      }
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
        }
      }
    }
  }
  return AppStrings.t('Something went wrong');
}

class PlacementTestScreen extends StatefulWidget {
  const PlacementTestScreen({super.key});

  @override
  State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends State<PlacementTestScreen> {
  final PublicRepository _repository = PublicRepository();
  final InstructorRepository _instructorRepository = InstructorRepository();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  late Future<List<PlacementQuestion>> _future;
  late Future<PlanPayload?> _plansFuture;
  late Future<List<InstructorSummary>> _instructorsFuture;
  final Map<String, String> _answers = {};
  int _step = 0;
  bool _submitting = false;
  bool _requestingTrial = false;
  PlacementResult? _result;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchPlacementQuestions();
    _plansFuture = _repository.fetchStudentPlans();
    _instructorsFuture = _instructorRepository.fetchInstructors();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestTrialLesson() async {
    await requestTrialLessonWithLoginGate(
      context,
      submitRequest: () async {
        final result = await _repository.requestTrialLesson();
        return TrialLessonActionResult(
          message: result.message,
          supportUrl: result.whatsappUrl,
        );
      },
      onLoadingChanged: (value) {
        if (!mounted) return;
        setState(() => _requestingTrial = value);
      },
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final result = await _repository.submitPlacementTest(
        answers: _answers,
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = _placementError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('2-Minute English Level Test'))),
      body: FutureBuilder<List<PlacementQuestion>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _placementError(snapshot.error!),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final questions = snapshot.data ?? const <PlacementQuestion>[];
          if (questions.isEmpty) {
            return Center(child: Text(AppStrings.t('No Data Found')));
          }

          if (_result != null) {
            return FutureBuilder<List<dynamic>>(
              future: Future.wait<dynamic>([_plansFuture, _instructorsFuture]),
              builder: (context, conversionSnapshot) {
                final planPayload = conversionSnapshot.data != null &&
                        conversionSnapshot.data!.isNotEmpty
                    ? conversionSnapshot.data![0] as PlanPayload?
                    : null;
                final instructors = conversionSnapshot.data != null &&
                        conversionSnapshot.data!.length > 1
                    ? conversionSnapshot.data![1] as List<InstructorSummary>
                    : const <InstructorSummary>[];
                return _PlacementResultView(
                  result: _result!,
                  planPayload: planPayload,
                  instructors: instructors,
                  loadingConversion: conversionSnapshot.connectionState ==
                      ConnectionState.waiting,
                  onRetry: () {
                    setState(() {
                      _result = null;
                      _answers.clear();
                      _step = 0;
                      _submitError = null;
                    });
                  },
                  onOpenSchedule: _requestTrialLesson,
                  requestingTrial: _requestingTrial,
                );
              },
            );
          }

          final totalSteps = questions.length + 1;
          final isContactStep = _step == questions.length;
          final progress = (_step + 1) / totalSteps;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${_step + 1} / $totalSteps',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE3EBF7),
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: isContactStep
                      ? _ContactStep(
                          nameCtrl: _nameCtrl,
                          emailCtrl: _emailCtrl,
                          phoneCtrl: _phoneCtrl,
                        )
                      : _QuestionStep(
                          question: questions[_step],
                          selected: _answers[questions[_step].id],
                          onSelect: (option) {
                            setState(() {
                              _answers[questions[_step].id] = option;
                            });
                          },
                        ),
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _submitError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => setState(() => _step = _step - 1),
                          child: Text(AppStrings.t('Back')),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitting
                            ? null
                            : isContactStep
                                ? _submit
                                : _answers[questions[_step].id] == null
                                    ? null
                                    : () => setState(() => _step = _step + 1),
                        child: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isContactStep
                                    ? AppStrings.t('Get My Result')
                                    : AppStrings.t('Next'),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuestionStep extends StatelessWidget {
  const _QuestionStep({
    required this.question,
    required this.selected,
    required this.onSelect,
  });

  final PlacementQuestion question;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.prompt,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            itemCount: question.options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final option = question.options[index];
              final isSelected = selected == option.id;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelect(option.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE9F6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brand
                          : const Color(0xFFD9E3F2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? AppColors.brand
                            : const Color(0xFF94A3B8),
                      ),
                      Expanded(
                        child: Text(
                          option.label,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContactStep extends StatelessWidget {
  const _ContactStep({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
  });

  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          AppStrings.t(
            'Leave contact info to get a matching trial lesson plan.',
          ),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: AppStrings.t('Full name'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: AppStrings.t('Email'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: AppStrings.t('Phone (WhatsApp)'),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _PlacementResultView extends StatelessWidget {
  const _PlacementResultView({
    required this.result,
    required this.planPayload,
    required this.instructors,
    required this.loadingConversion,
    required this.onRetry,
    required this.onOpenSchedule,
    required this.requestingTrial,
  });

  final PlacementResult result;
  final PlanPayload? planPayload;
  final List<InstructorSummary> instructors;
  final bool loadingConversion;
  final VoidCallback onRetry;
  final VoidCallback onOpenSchedule;
  final bool requestingTrial;

  String _weakArea() {
    final track = result.recommendedTrack.toLowerCase();
    final summary = result.summary.toLowerCase();
    if (track.contains('ielts') || track.contains('toefl')) {
      return AppStrings.code == 'tr'
          ? 'Uzun cevap yapisi ve linking words'
          : 'Long-answer structure and linking words';
    }
    if (track.contains('business')) {
      return AppStrings.code == 'tr'
          ? 'Toplanti update dili ve netlik'
          : 'Meeting updates and clarity';
    }
    if (summary.contains('fluency') || summary.contains('speaking')) {
      return AppStrings.code == 'tr'
          ? 'Akicilik ve cevap uzatma'
          : 'Fluency and answer expansion';
    }
    return AppStrings.code == 'tr'
        ? 'Gundelik speaking ritmi'
        : 'Everyday speaking rhythm';
  }

  StudentPlan? _recommendedPlan() {
    final plans = planPayload?.plans ?? const <StudentPlan>[];
    if (plans.isEmpty) return null;
    final track = result.recommendedTrack.toLowerCase();
    final filtered = plans.where((plan) {
      final bag =
          '${plan.title} ${plan.displayTitle} ${plan.subtitle} ${plan.tagline}'
              .toLowerCase();
      if (track.contains('ielts') || track.contains('toefl')) {
        return bag.contains('ielts') ||
            bag.contains('toefl') ||
            bag.contains('exam');
      }
      if (track.contains('business')) {
        return bag.contains('business');
      }
      if (track.contains('travel')) {
        return bag.contains('travel');
      }
      return bag.contains('speaking') || bag.contains('general');
    }).toList();
    final pool = filtered.isNotEmpty ? filtered : plans;
    pool.sort((a, b) {
      final scoreA = (a.featured ? 100 : 0) + a.lessonsTotal;
      final scoreB = (b.featured ? 100 : 0) + b.lessonsTotal;
      return scoreB.compareTo(scoreA);
    });
    return pool.first;
  }

  List<InstructorSummary> _matchedTutors() {
    if (instructors.isEmpty) return const <InstructorSummary>[];
    final track = result.recommendedTrack.toLowerCase();
    final ranked = List<InstructorSummary>.from(instructors)
      ..sort((a, b) => _scoreTutor(b, track).compareTo(_scoreTutor(a, track)));
    return ranked.take(3).toList(growable: false);
  }

  int _scoreTutor(InstructorSummary instructor, String track) {
    final bag =
        '${instructor.name} ${instructor.jobTitle} ${instructor.shortBio} ${instructor.bio} ${instructor.tags.join(' ')}'
            .toLowerCase();
    var score = (instructor.avgRating * 10).round() + instructor.courseCount;
    if (track.contains('ielts') || track.contains('toefl')) {
      if (bag.contains('ielts') ||
          bag.contains('toefl') ||
          bag.contains('exam')) {
        score += 40;
      }
    } else if (track.contains('business')) {
      if (bag.contains('business')) score += 40;
    } else if (track.contains('travel')) {
      if (bag.contains('travel')) score += 40;
    } else {
      if (bag.contains('speaking') || bag.contains('general')) score += 40;
    }
    if (bag.contains('turkish')) score += 4;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final weakArea = _weakArea();
    final plan = _recommendedPlan();
    final tutors = _matchedTutors();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD9E4F4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t('Your Level'),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  result.level,
                  style: const TextStyle(
                    fontSize: 42,
                    color: AppColors.brandDeep,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${AppStrings.t('Score')}: ${result.score} / ${result.maxScore}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                Text(
                  '${AppStrings.t('Recommended Track')}: ${result.recommendedTrack}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(result.summary),
                const SizedBox(height: 4),
                Text(result.nextStep),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD9E4F4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.code == 'tr'
                      ? 'Ana zayif alan'
                      : 'Primary weak area',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  weakArea,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD9E4F4)),
            ),
            child: loadingConversion
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.code == 'tr'
                            ? 'Sana uygun plan'
                            : 'Plan that fits you',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        plan?.displayTitle.isNotEmpty == true
                            ? plan!.displayTitle
                            : (plan?.title.isNotEmpty == true
                                ? plan!.title
                                : AppStrings.t('Plan will appear here')),
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        plan == null
                            ? AppStrings.code == 'tr'
                                ? 'Plan verisi hazir oldugunda burada gozukur.'
                                : 'The matching plan will appear here once plan data is available.'
                            : '${plan.lessonsTotal} ${AppStrings.code == 'tr' ? 'ders' : 'lessons'} • ${plan.lessonDuration}${AppStrings.code == 'tr' ? ' dk' : ' min'} • ${planPayload?.currency ?? ''} ${plan.price.toStringAsFixed(0)}',
                      ),
                      if (plan?.tagline.isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(plan!.tagline),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD9E4F4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.code == 'tr'
                      ? 'Sana uygun 3 tutor'
                      : '3 tutors that fit this result',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (loadingConversion)
                  const Center(child: CircularProgressIndicator())
                else if (tutors.isEmpty)
                  Text(
                    AppStrings.code == 'tr'
                        ? 'Tutor listesi hazir oldugunda burada gozukur.'
                        : 'Tutor picks will appear here once the list is available.',
                  )
                else
                  ...tutors.map((tutor) {
                    final tags = tutor.tags.take(2).join(' • ');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD9E4F4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tutor.name,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tutor.jobTitle.isNotEmpty
                                  ? tutor.jobTitle
                                  : AppStrings.t('Instructor'),
                            ),
                            if (tags.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(tags),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: requestingTrial ? null : onOpenSchedule,
            child: requestingTrial
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppStrings.t('Schedule Trial Lesson')),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetry,
            child: Text(AppStrings.t('Try Again')),
          ),
        ],
      ),
    );
  }
}
