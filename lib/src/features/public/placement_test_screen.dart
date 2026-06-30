import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/ui.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showCelebration(
          context,
          title: '${AppStrings.t('Your Level')}: ${result.level}',
          subtitle:
              '${AppStrings.t('Score')}: ${result.score} / ${result.maxScore}',
          icon: Icons.military_tech_rounded,
          color: AppPalette.gold,
        );
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppStrings.t('2-Minute English Level Test'))),
      body: AppGlowBackground(
        accent: AppColors.brand,
        child: SafeArea(
          child: FutureBuilder<List<PlacementQuestion>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return AppLoader(message: AppStrings.t('Loading'));
              }
              if (snapshot.hasError) {
                return AppErrorState(
                  message: _placementError(snapshot.error!),
                );
              }

              final questions = snapshot.data ?? const <PlacementQuestion>[];
              if (questions.isEmpty) {
                return AppEmptyState(
                  title: AppStrings.t('No Data Found'),
                  icon: Icons.quiz_rounded,
                );
              }

              if (_result != null) {
                return FutureBuilder<List<dynamic>>(
                  future:
                      Future.wait<dynamic>([_plansFuture, _instructorsFuture]),
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg,
                  AppSpace.lg,
                  AppSpace.lg,
                  AppSpace.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _QuestProgress(
                      step: _step,
                      totalSteps: totalSteps,
                      progress: progress,
                    ),
                    const SizedBox(height: AppSpace.xl),
                    Expanded(
                      child: AnimatedPageEntrance(
                        key: ValueKey<int>(_step),
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
                    ),
                    if (_submitError != null) ...[
                      const SizedBox(height: AppSpace.sm),
                      AppCard(
                        color: AppPalette.danger.withValues(alpha: 0.08),
                        border: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.md,
                          vertical: AppSpace.md,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppPalette.danger,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: Text(
                                _submitError!,
                                style: const TextStyle(
                                  color: AppPalette.danger,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpace.md),
                    Row(
                      children: [
                        if (_step > 0)
                          Expanded(
                            child: AppGhostButton(
                              label: AppStrings.t('Back'),
                              icon: Icons.arrow_back_rounded,
                              onPressed: _submitting
                                  ? null
                                  : () => setState(() => _step = _step - 1),
                            ),
                          ),
                        if (_step > 0) const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: AppButton(
                            label: isContactStep
                                ? AppStrings.t('Get My Result')
                                : AppStrings.t('Next'),
                            icon: isContactStep
                                ? Icons.auto_awesome_rounded
                                : Icons.arrow_forward_rounded,
                            tone: isContactStep
                                ? AppButtonTone.success
                                : AppButtonTone.brand,
                            loading: _submitting,
                            onPressed: _submitting
                                ? null
                                : isContactStep
                                    ? _submit
                                    : _answers[questions[_step].id] == null
                                        ? null
                                        : () =>
                                            setState(() => _step = _step + 1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Quest-style segmented gradient progress bar + ring badge showing step X/N.
class _QuestProgress extends StatelessWidget {
  const _QuestProgress({
    required this.step,
    required this.totalSteps,
    required this.progress,
  });

  final int step;
  final int totalSteps;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          ProgressRing(
            value: progress,
            size: 58,
            stroke: 7,
            gradient: AppGradients.brand,
            center: Text(
              '${step + 1}/$totalSteps',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.flag_rounded,
                      size: 16,
                      color: AppColors.brand,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${AppStrings.t('Step')} ${step + 1} / $totalSteps',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                _SegmentedBar(total: totalSteps, current: step),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented gradient bar: filled segments are gradient, the rest are tracks.
class _SegmentedBar extends StatelessWidget {
  const _SegmentedBar({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(total, (index) {
        final filled = index <= current;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == total - 1 ? 0 : 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              height: 8,
              decoration: BoxDecoration(
                gradient: filled ? AppGradients.brand : null,
                color: filled ? null : AppPalette.line,
                borderRadius: AppRadius.pill,
                boxShadow: filled
                    ? AppShadows.glow(AppColors.brand, opacity: 0.22)
                    : null,
              ),
            ),
          ),
        );
      }),
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
        GradientHero(
          gradient: AppGradients.hero,
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  question.prompt,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Expanded(
          child: ListView.separated(
            itemCount: question.options.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpace.md),
            itemBuilder: (context, index) {
              final option = question.options[index];
              final isSelected = selected == option.id;
              return AppCard(
                onTap: () => onSelect(option.id),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.lg,
                ),
                border: !isSelected,
                color: isSelected ? null : Colors.white,
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.brand.withValues(alpha: 0.14),
                          AppColors.brand.withValues(alpha: 0.06),
                        ],
                      )
                    : null,
                shadow: isSelected
                    ? AppShadows.glow(AppColors.brand, opacity: 0.20)
                    : null,
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                            isSelected ? AppGradients.brand : null,
                        color: isSelected ? null : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : AppPalette.line,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.check_rounded
                            : Icons.circle_outlined,
                        size: isSelected ? 16 : 14,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        option.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.brandDeep
                              : AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
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
        GradientHero(
          gradient: AppGradients.success,
          glowColor: AppPalette.success,
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  AppStrings.t(
                    'Leave contact info to get a matching trial lesson plan.',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        AppCard(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.t('Full name'),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.all(AppRadius.sm),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppStrings.t('Email'),
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.all(AppRadius.sm),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: AppStrings.t('Phone (WhatsApp)'),
                  prefixIcon: const Icon(Icons.chat_outlined),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.all(AppRadius.sm),
                  ),
                ),
              ),
            ],
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
          ? 'Akıcılık ve cevap uzatma'
          : 'Fluency and answer expansion';
    }
    return AppStrings.code == 'tr'
        ? 'Gündelik speaking ritmi'
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
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.xl,
        AppSpace.lg,
        AppSpace.xxl,
      ),
      child: StaggeredReveal(
        children: [
          // Hero level card.
          GradientHero(
            gradient: AppGradients.hero,
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t('Your Level').toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.level,
                          style: const TextStyle(
                            fontSize: 44,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.military_tech_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                AppStatPill(
                  icon: Icons.stars_rounded,
                  label:
                      '${AppStrings.t('Score')}: ${result.score} / ${result.maxScore}',
                ),
                const SizedBox(height: AppSpace.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: AppRadius.all(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.route_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${AppStrings.t('Recommended Track')}: ${result.recommendedTrack}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        result.summary,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.nextStep,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          // Primary weak area.
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  icon: Icons.center_focus_strong_rounded,
                  title: AppStrings.code == 'tr'
                      ? 'Ana zayıf alan'
                      : 'Primary weak area',
                ),
                Text(
                  weakArea,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          // Matching plan.
          AppCard(
            child: loadingConversion
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpace.lg),
                    child: AppLoader(),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        icon: Icons.workspace_premium_rounded,
                        title: AppStrings.code == 'tr'
                            ? 'Sana uygun plan'
                            : 'Plan that fits you',
                      ),
                      Text(
                        plan?.displayTitle.isNotEmpty == true
                            ? plan!.displayTitle
                            : (plan?.title.isNotEmpty == true
                                ? plan!.title
                                : AppStrings.t('Plan will appear here')),
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        plan == null
                            ? AppStrings.code == 'tr'
                                ? 'Plan verisi hazır olduğunda burada gözükür.'
                                : 'The matching plan will appear here önce plan data is available.'
                            : '${plan.lessonsTotal} ${AppStrings.code == 'tr' ? 'ders' : 'lessons'} • ${plan.lessonDuration}${AppStrings.code == 'tr' ? ' dk' : ' min'} • ${planPayload?.currency ?? ''} ${plan.price.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      if (plan?.tagline.isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(
                          plan!.tagline,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: AppSpace.lg),
          // Matched tutors.
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  icon: Icons.groups_rounded,
                  title: AppStrings.code == 'tr'
                      ? 'Sana uygun 3 tutor'
                      : '3 tutors that fit this result',
                ),
                if (loadingConversion)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpace.lg),
                    child: AppLoader(),
                  )
                else if (tutors.isEmpty)
                  Text(
                    AppStrings.code == 'tr'
                        ? 'Tutor listesi hazır olduğunda burada gözükür.'
                        : 'Tutor picks will appear here önce the list is available.',
                    style: const TextStyle(color: AppColors.muted),
                  )
                else
                  ...tutors.map((tutor) {
                    final tags = tutor.tags.take(2).join(' • ');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.md),
                      child: AppCard(
                        color: AppPalette.cloud,
                        padding: const EdgeInsets.all(AppSpace.md),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: AppGradients.violet,
                                borderRadius: AppRadius.all(AppRadius.sm),
                                boxShadow: AppShadows.glow(
                                  AppPalette.violet,
                                  opacity: 0.26,
                                ),
                              ),
                              child: Text(
                                tutor.name.isNotEmpty
                                    ? tutor.name
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tutor.name,
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tutor.jobTitle.isNotEmpty
                                        ? tutor.jobTitle
                                        : AppStrings.t('Instructor'),
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  if (tags.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      tags,
                                      style: const TextStyle(
                                        color: AppColors.brand,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          AppButton(
            label: AppStrings.t('Schedule Trial Lesson'),
            icon: Icons.event_available_rounded,
            tone: AppButtonTone.success,
            loading: requestingTrial,
            onPressed: requestingTrial ? null : onOpenSchedule,
          ),
          const SizedBox(height: AppSpace.md),
          AppGhostButton(
            label: AppStrings.t('Try Again'),
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
