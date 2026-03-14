import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
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
      _showSnack(
        item.submission == null
            ? AppStrings.t('Homework submitted.')
            : AppStrings.t('Submission updated.'),
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
      appBar: AppBar(title: Text(AppStrings.t('Homeworks'))),
      body: FutureBuilder<StudentHomeworksPayload?>(
        future: _future,
        builder: (context, snapshot) {
          final payload = snapshot.data;
          final active = payload?.active ?? const <StudentHomeworkItem>[];
          final archived = payload?.archived ?? const <StudentHomeworkItem>[];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppStrings.t('Something went wrong')),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _reload,
                    child: Text(AppStrings.t('Try Again')),
                  ),
                ],
              ),
            );
          }

          if (active.isEmpty && archived.isEmpty) {
            return Center(child: Text(AppStrings.t('No homeworks found!')));
          }

          return RefreshIndicator(
            onRefresh: () => _reload(silent: true),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  AppStrings.t('Homeworks'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.t(
                    'Open homework details, upload your work and track instructor feedback.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...active.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HomeworkCard(
                      item: item,
                      onTap: () => _openHomework(item),
                    ),
                  ),
                ),
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.t('Archived'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  ...archived.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HomeworkCard(
                        item: item,
                        onTap: () => _openHomework(item),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: status.color.withValues(alpha: 0.15),
              child: Icon(Icons.assignment, color: status.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(dueLabel, style: Theme.of(context).textTheme.bodyMedium),
                  if (item.instructorName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${AppStrings.t('Instructor')}: ${item.instructorName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                const Icon(Icons.chevron_right),
              ],
            ),
          ],
        ),
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

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 32),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: AppStrings.t('Instructor'),
                value: item.instructorName.isEmpty ? '-' : item.instructorName,
              ),
              _InfoRow(
                label: AppStrings.t('End Date'),
                value: item.dueAt == null
                    ? AppStrings.t('No deadline')
                    : DateFormat('dd MMM yyyy, HH:mm').format(item.dueAt!),
              ),
              if (item.description.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  AppStrings.t('Description'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  item.description.trim(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (item.attachmentPath.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: onOpenAttachment,
                      icon: const Icon(Icons.description_outlined),
                      label: Text(
                        item.attachmentName.isNotEmpty
                            ? item.attachmentName
                            : AppStrings.t('Homework File'),
                      ),
                    ),
                  if (submission?.submissionPath.isNotEmpty == true)
                    OutlinedButton.icon(
                      onPressed: onOpenSubmission,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        submission!.submissionName.isNotEmpty
                            ? submission.submissionName
                            : AppStrings.t('My Submission'),
                      ),
                    ),
                ],
              ),
              if (submission != null) ...[
                const SizedBox(height: 20),
                Text(
                  AppStrings.t('Submission Details'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final shouldReload = await onSubmit();
                    if (shouldReload && context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    submission == null
                        ? AppStrings.t('Upload Submission')
                        : AppStrings.t('Update Submission'),
                  ),
                ),
              ),
            ],
          ),
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
        margin: const EdgeInsets.only(top: 32),
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasExistingSubmission
                  ? AppStrings.t('Update Submission')
                  : AppStrings.t('Upload Submission'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: _picking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file),
              label: Text(
                _fileName ??
                    (hasExistingSubmission
                        ? AppStrings.t('Keep current file')
                        : AppStrings.t('Choose file')),
              ),
            ),
            const SizedBox(height: 12),
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
              const SizedBox(height: 10),
              Text(
                _validation!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
                child: Text(AppStrings.t('Save')),
              ),
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
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
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
  });

  final String label;
  final Color color;
}

_HomeworkStatusMeta _statusMeta(StudentHomeworkItem item) {
  if (item.isArchived) {
    return _HomeworkStatusMeta(
      label: AppStrings.t('Archived'),
      color: Colors.blueGrey,
    );
  }

  final submissionStatus = item.submission?.status.toLowerCase() ?? '';
  switch (submissionStatus) {
    case 'reviewed':
      return _HomeworkStatusMeta(
        label: AppStrings.t('Reviewed'),
        color: Colors.green,
      );
    case 'needs_revision':
      return _HomeworkStatusMeta(
        label: AppStrings.t('Revision Requested'),
        color: Colors.deepOrange,
      );
    case 'submitted':
      return _HomeworkStatusMeta(
        label: AppStrings.t('Submitted'),
        color: AppColors.brand,
      );
    default:
      return _HomeworkStatusMeta(
        label: AppStrings.t('Pending'),
        color: AppColors.brandDeep,
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
