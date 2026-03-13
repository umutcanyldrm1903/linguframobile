import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../shared/content_preview_launcher.dart';
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
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  late Future<List<PlacementQuestion>> _future;
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
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String raw) async {
    final value = raw.trim();
    if (value.isEmpty) return;
    await openContentPreview(
      context,
      title: AppStrings.t('Open Link'),
      rawUrl: value,
      browserActionLabel: AppStrings.t('Open Externally'),
    );
  }

  Future<void> _requestTrialLesson() async {
    final token = await SecureStorage.getToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    final role = await SecureStorage.getRole();
    if (!mounted) return;

    if (role == 'instructor') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.t('Student Login'))));
      return;
    }

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.t('Schedule Trial Lesson')),
          content: Text(
            AppStrings.t(
              'You are about to request a one-time free trial lesson from our support team!',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.t('Cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppStrings.t('Confirm')),
            ),
          ],
        );
      },
    );

    if (shouldSubmit != true || !mounted) return;

    setState(() => _requestingTrial = true);
    try {
      final response = await _repository.requestTrialLesson();
      if (!mounted) return;

      final message = response.message.trim().isNotEmpty
          ? response.message.trim()
          : AppStrings.t('Deneme dersi talebiniz alindi.');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      if (response.whatsappUrl.trim().isNotEmpty) {
        await _openUrl(response.whatsappUrl);
      }
    } catch (error) {
      if (!mounted) return;
      if (error is DioException && error.response?.statusCode == 401) {
        Navigator.pushNamed(context, '/login');
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_placementError(error))));
    } finally {
      if (mounted) {
        setState(() => _requestingTrial = false);
      }
    }
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
            return _PlacementResultView(
              result: _result!,
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
              onOpenWhatsapp: _result!.whatsappUrl.trim().isEmpty
                  ? null
                  : () => _openUrl(_result!.whatsappUrl),
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
                      Radio<String>(
                        value: option.id,
                        groupValue: selected,
                        onChanged: (value) {
                          if (value != null) onSelect(value);
                        },
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
    required this.onRetry,
    required this.onOpenSchedule,
    required this.requestingTrial,
    this.onOpenWhatsapp,
  });

  final PlacementResult result;
  final VoidCallback onRetry;
  final VoidCallback onOpenSchedule;
  final bool requestingTrial;
  final VoidCallback? onOpenWhatsapp;

  @override
  Widget build(BuildContext context) {
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
          if (onOpenWhatsapp != null)
            OutlinedButton(
              onPressed: onOpenWhatsapp,
              child: Text(AppStrings.t('Send via WhatsApp')),
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
