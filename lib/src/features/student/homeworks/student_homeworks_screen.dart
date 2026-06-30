import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../shared/content_preview_launcher.dart';
import 'student_homeworks_repository.dart';

class StudentHomeworksScreen extends StatefulWidget {
  const StudentHomeworksScreen({
    super.key,
    this.repository,
  });

  final StudentHomeworksRepository? repository;

  @override
  State<StudentHomeworksScreen> createState() => _StudentHomeworksScreenState();
}

class _StudentHomeworksScreenState extends State<StudentHomeworksScreen> {
  late Future<StudentHomeworksPayload?> _future;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future =
        (widget.repository ?? StudentHomeworksRepository()).fetchHomeworks();
  }

  Future<void> _reload({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _future = (widget.repository ?? StudentHomeworksRepository())
            .fetchHomeworks();
      });
      return;
    }

    final payload = await (widget.repository ?? StudentHomeworksRepository())
        .fetchHomeworks();
    if (!mounted) return;
    setState(() {
      _future = Future<StudentHomeworksPayload?>.value(payload);
    });
  }

  Future<void> _openHomework(StudentHomeworkItem item) async {
    final shouldReload = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HomeworkDetailSheet(
        item: item,
        onOpenAttachment: () => _openContent(
          title: item.attachmentName.isNotEmpty
              ? item.attachmentName
              : AppStrings.t('Homework File'),
          rawUrl: item.attachmentPath,
        ),
        onOpenSubmission: item.submission == null
            ? null
            : () => _openContent(
                  title: item.submission!.submissionName.isNotEmpty
                      ? item.submission!.submissionName
                      : AppStrings.t('My Submission'),
                  rawUrl: item.submission!.submissionPath,
                ),
        onSubmit: () => _submitHomework(item),
      ),
    );

    if (shouldReload == true) {
      await _reload(silent: true);
    }
  }

  Future<void> _openContent({
    required String title,
    required String rawUrl,
  }) async {
    await openContentPreview(
      context,
      title: title,
      rawUrl: rawUrl,
    );
  }

  Future<bool> _submitHomework(StudentHomeworkItem item) async {
    if (_submitting) return false;

    final draft = await showModalBottomSheet<_SubmissionDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SubmissionSheet(item: item),
    );

    if (draft == null) return false;

    setState(() => _submitting = true);
    try {
      await (widget.repository ?? StudentHomeworksRepository()).submitHomework(
        homeworkId: item.id,
        filePath: draft.filePath,
        fileName: draft.fileName,
        note: draft.note,
      );
      if (!mounted) return false;
      final isFirstSubmission = item.submission == null;
      _showSnack(
        isFirstSubmission
            ? AppStrings.t('Homework submitted.')
            : AppStrings.t('Submission updated.'),
      );
      showCelebration(
        context,
        title: isFirstSubmission
            ? AppStrings.t('Homework submitted.')
            : AppStrings.t('Submission updated.'),
        subtitle: item.title,
        icon: Icons.cloud_done_rounded,
        color: AppPalette.success,
      );
      return true;
    } catch (error) {
      _showSnack(_errorMessage(error));
      return false;
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message is Map) {
          return message.values.map((value) => value.toString()).join('\n');
        }
        if (message != null) {
          return message.toString();
        }
      }
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }
    return AppStrings.t('Something went wrong');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(AppStrings.t('Homeworks'))),
      body: AppGlowBackground(
        child: FutureBuilder<StudentHomeworksPayload?>(
          future: _future,
          builder: (context, snapshot) {
            final payload = snapshot.data;
            final active = payload?.active ?? const <StudentHomeworkItem>[];
            final archived = payload?.archived ?? const <StudentHomeworkItem>[];

            if (snapshot.connectionState == ConnectionState.waiting) {
              return AppLoader(message: AppStrings.t('Homeworks'));
            }

            if (snapshot.hasError) {
              return AppErrorState(
                message: AppStrings.t('Something went wrong'),
                onRetry: _reload,
                retryLabel: AppStrings.t('Try Again'),
              );
            }

            if (active.isEmpty && archived.isEmpty) {
              return AppEmptyState(
                title: AppStrings.t('No homeworks found!'),
                message: AppStrings.t(
                  'Open homework details, upload your work and track instructor feedback.',
                ),
                icon: Icons.assignment_outlined,
              );
            }

            return RefreshIndicator(
              onRefresh: () => _reload(silent: true),
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.xl),
                children: [
                  AnimatedPageEntrance(
                    child: _HomeworksHero(
                      active: active.length,
                      archived: archived.length,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  if (active.isNotEmpty) ...[
                    SectionHeader(
                      title: AppStrings.t('Homeworks'),
                      subtitle: AppStrings.t(
                        'Open homework details, upload your work and track instructor feedback.',
                      ),
                      icon: Icons.assignment_rounded,
                    ),
                    StaggeredReveal(
                      children: [
                        for (final item in active)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.md),
                            child: _HomeworkCard(
                              item: item,
                              onTap: () => _openHomework(item),
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (archived.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.sm),
                    SectionHeader(
                      title: AppStrings.t('Archived'),
                      icon: Icons.inventory_2_outlined,
                    ),
                    StaggeredReveal(
                      children: [
                        for (final item in archived)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.md),
                            child: _HomeworkCard(
                              item: item,
                              onTap: () => _openHomework(item),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeworksHero extends StatelessWidget {
  const _HomeworksHero({
    required this.active,
    required this.archived,
  });

  final int active;
  final int archived;

  @override
  Widget build(BuildContext context) {
    return GradientHero(
      gradient: AppGradients.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_rounded,
                  color: Colors.white, size: 26),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  AppStrings.t('Homeworks'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            AppStrings.t(
              'Open homework details, upload your work and track instructor feedback.',
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              AppStatPill(
                icon: Icons.pending_actions_rounded,
                label: '$active ${AppStrings.t('Homeworks')}',
              ),
              if (archived > 0)
                AppStatPill(
                  icon: Icons.inventory_2_outlined,
                  label: '$archived ${AppStrings.t('Archived')}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard({
    required this.item,
    required this.onTap,
  });

  final StudentHomeworkItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusMeta(item);
    final dueLabel = _dueLabel(item);
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: Icon(Icons.assignment_rounded, color: status.color),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Icon(Icons.event_rounded, size: 15, color: AppColors.muted),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  dueLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (item.instructorName.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Row(
              children: [
                Icon(Icons.person_rounded, size: 15, color: AppColors.muted),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    '${AppStrings.t('Instructor')}: ${item.instructorName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpace.md),
          Align(
            alignment: Alignment.centerLeft,
            child: AppStatPill(
              icon: status.icon,
              label: status.label,
              color: status.color,
              onLight: true,
            ),
          ),
        ],
      ),
    );
  }

  String _dueLabel(StudentHomeworkItem item) {
    if (item.submission?.submittedAt != null) {
      final formatted = DateFormat('dd MMM yyyy, HH:mm')
          .format(item.submission!.submittedAt!);
      return '${AppStrings.t('Submitted')}: $formatted';
    }
    if (item.dueAt == null) {
      return AppStrings.t('No deadline');
    }
    final formatted = DateFormat('dd MMM yyyy, HH:mm').format(item.dueAt!);
    return '${AppStrings.t('Date')}: $formatted';
  }
}

class _HomeworkDetailSheet extends StatelessWidget {
  const _HomeworkDetailSheet({
    required this.item,
    required this.onOpenAttachment,
    required this.onOpenSubmission,
    required this.onSubmit,
  });

  final StudentHomeworkItem item;
  final Future<void> Function() onOpenAttachment;
  final Future<void> Function()? onOpenSubmission;
  final Future<bool> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final status = _statusMeta(item);
    final submission = item.submission;
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: AppSpace.xxxl),
        padding: const EdgeInsets.fromLTRB(
            AppSpace.xl, AppSpace.lg, AppSpace.xl, AppSpace.xxl),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  AppStatPill(
                    icon: status.icon,
                    label: status.label,
                    color: status.color,
                    onLight: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              AppCard(
                color: AppPalette.cloud,
                child: Column(
                  children: [
                    _InfoRow(
                      label: AppStrings.t('Instructor'),
                      value: item.instructorName.isEmpty
                          ? '-'
                          : item.instructorName,
                    ),
                    _InfoRow(
                      label: AppStrings.t('End Date'),
                      value: item.dueAt == null
                          ? AppStrings.t('No deadline')
                          : DateFormat('dd MMM yyyy, HH:mm')
                              .format(item.dueAt!),
                    ),
                  ],
                ),
              ),
              if (item.description.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpace.lg),
                SectionHeader(
                  title: AppStrings.t('Description'),
                  icon: Icons.notes_rounded,
                ),
                Text(
                  item.description.trim(),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: AppSpace.xl),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  if (item.attachmentPath.isNotEmpty)
                    AppGhostButton(
                      onPressed: onOpenAttachment,
                      expand: false,
                      icon: Icons.description_outlined,
                      label: item.attachmentName.isNotEmpty
                          ? item.attachmentName
                          : AppStrings.t('Homework File'),
                    ),
                  if (submission?.submissionPath.isNotEmpty == true)
                    AppGhostButton(
                      onPressed: onOpenSubmission,
                      expand: false,
                      color: AppPalette.success,
                      icon: Icons.upload_file,
                      label: submission!.submissionName.isNotEmpty
                          ? submission.submissionName
                          : AppStrings.t('My Submission'),
                    ),
                ],
              ),
              if (submission != null) ...[
                const SizedBox(height: AppSpace.xl),
                SectionHeader(
                  title: AppStrings.t('Submission Details'),
                  icon: Icons.fact_check_outlined,
                ),
                AppCard(
                  color: AppPalette.cloud,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        label: AppStrings.t('Status'),
                        value: _submissionStatusText(submission.status),
                      ),
                      if (submission.submittedAt != null)
                        _InfoRow(
                          label: AppStrings.t('Submitted'),
                          value: DateFormat('dd MMM yyyy, HH:mm')
                              .format(submission.submittedAt!),
                        ),
                      if (submission.studentNote.trim().isNotEmpty)
                        _NoteBlock(
                          title: AppStrings.t('Your Note'),
                          text: submission.studentNote,
                        ),
                      if (submission.instructorNote.trim().isNotEmpty)
                        _NoteBlock(
                          title: AppStrings.t('Instructor Feedback'),
                          text: submission.instructorNote,
                        ),
                      if (submission.reviewedAt != null)
                        _InfoRow(
                          label: AppStrings.t('Reviewed'),
                          value: DateFormat('dd MMM yyyy, HH:mm')
                              .format(submission.reviewedAt!),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.xxl),
              AppButton(
                tone: AppButtonTone.brand,
                icon: Icons.cloud_upload_outlined,
                onPressed: () async {
                  final shouldReload = await onSubmit();
                  if (shouldReload && context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                label: submission == null
                    ? AppStrings.t('Upload Submission')
                    : AppStrings.t('Update Submission'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: AppPalette.line,
          borderRadius: AppRadius.pill,
        ),
      ),
    );
  }
}

class _SubmissionSheet extends StatefulWidget {
  const _SubmissionSheet({required this.item});

  final StudentHomeworkItem item;

  @override
  State<_SubmissionSheet> createState() => _SubmissionSheetState();
}

class _SubmissionSheetState extends State<_SubmissionSheet> {
  late final TextEditingController _noteController;
  String? _filePath;
  String? _fileName;
  String? _validation;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: widget.item.submission?.studentNote ?? '',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: false,
        allowMultiple: false,
      );

      final selected =
          result == null || result.files.isEmpty ? null : result.files.first;
      if (selected == null || selected.path == null) return;

      setState(() {
        _filePath = selected.path;
        _fileName = selected.name;
        _validation = null;
      });
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingSubmission =
        widget.item.submission?.submissionPath.isNotEmpty == true;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: AppSpace.xxxl),
        padding: EdgeInsets.fromLTRB(
          AppSpace.xl,
          AppSpace.lg,
          AppSpace.xl,
          AppSpace.xxl + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            const SizedBox(height: AppSpace.lg),
            Text(
              hasExistingSubmission
                  ? AppStrings.t('Update Submission')
                  : AppStrings.t('Upload Submission'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
            ),
            const SizedBox(height: AppSpace.md),
            AppGhostButton(
              onPressed: _picking ? null : _pickFile,
              icon: _picking ? Icons.hourglass_top_rounded : Icons.attach_file,
              label: _picking
                  ? AppStrings.t('Choose file')
                  : (_fileName ??
                      (hasExistingSubmission
                          ? AppStrings.t('Keep current file')
                          : AppStrings.t('Choose file'))),
            ),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: _noteController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: AppStrings.t('Note'),
                hintText: AppStrings.t('Add note for your instructor'),
              ),
            ),
            if (_validation != null) ...[
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 16, color: AppPalette.danger),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Text(
                      _validation!,
                      style: const TextStyle(
                        color: AppPalette.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            AppButton(
              tone: AppButtonTone.success,
              icon: Icons.check_rounded,
              onPressed: () {
                if (!hasExistingSubmission &&
                    (_filePath == null || _filePath!.trim().isEmpty)) {
                  setState(() {
                    _validation = AppStrings.t('Please choose a file');
                  });
                  return;
                }

                Navigator.of(context).pop(
                  _SubmissionDraft(
                    filePath: _filePath,
                    fileName: _fileName,
                    note: _noteController.text.trim(),
                  ),
                );
              },
              label: AppStrings.t('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBlock extends StatelessWidget {
  const _NoteBlock({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpace.sm),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.all(AppRadius.sm),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(text),
        ],
      ),
    );
  }
}

class _SubmissionDraft {
  const _SubmissionDraft({
    required this.filePath,
    required this.fileName,
    required this.note,
  });

  final String? filePath;
  final String? fileName;
  final String note;
}

class _HomeworkStatusMeta {
  const _HomeworkStatusMeta({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

_HomeworkStatusMeta _statusMeta(StudentHomeworkItem item) {
  if (item.isArchived) {
    return _HomeworkStatusMeta(
      label: AppStrings.t('Archived'),
      color: AppColors.muted,
      icon: Icons.inventory_2_outlined,
    );
  }

  final submissionStatus = item.submission?.status.toLowerCase() ?? '';
  switch (submissionStatus) {
    case 'reviewed':
      return _HomeworkStatusMeta(
        label: AppStrings.t('Reviewed'),
        color: AppPalette.success,
        icon: Icons.verified_rounded,
      );
    case 'needs_revision':
      return _HomeworkStatusMeta(
        label: AppStrings.t('Revision Requested'),
        color: AppPalette.danger,
        icon: Icons.error_outline_rounded,
      );
    case 'submitted':
      return _HomeworkStatusMeta(
        label: AppStrings.t('Submitted'),
        color: AppColors.brand,
        icon: Icons.cloud_done_rounded,
      );
    default:
      return _HomeworkStatusMeta(
        label: AppStrings.t('Pending'),
        color: AppPalette.warning,
        icon: Icons.schedule_rounded,
      );
  }
}

String _submissionStatusText(String status) {
  switch (status.toLowerCase()) {
    case 'reviewed':
      return AppStrings.t('Reviewed');
    case 'needs_revision':
      return AppStrings.t('Revision Requested');
    case 'submitted':
      return AppStrings.t('Submitted');
    default:
      return AppStrings.t('Pending');
  }
}
