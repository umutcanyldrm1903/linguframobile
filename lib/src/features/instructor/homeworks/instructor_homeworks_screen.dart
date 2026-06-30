import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../shared/content_preview_launcher.dart';
import '../students/instructor_students_repository.dart';
import 'instructor_homeworks_repository.dart';

class InstructorHomeworksScreen extends StatefulWidget {
  const InstructorHomeworksScreen({
    super.key,
    this.repository,
    this.studentsRepository,
  });

  final InstructorHomeworksRepository? repository;
  final InstructorStudentsRepository? studentsRepository;

  @override
  State<InstructorHomeworksScreen> createState() =>
      _InstructorHomeworksScreenState();
}

class _InstructorHomeworksScreenState extends State<InstructorHomeworksScreen> {
  late Future<InstructorHomeworksPayload?> _homeworksFuture;
  List<InstructorStudent> _students = const [];
  bool _studentsLoading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _homeworksFuture = _fetchHomeworks();
    _loadStudents();
  }

  Future<InstructorHomeworksPayload?> _fetchHomeworks() {
    return (widget.repository ?? InstructorHomeworksRepository())
        .fetchHomeworks();
  }

  Future<void> _loadStudents() async {
    if (_studentsLoading) return;
    setState(() => _studentsLoading = true);
    try {
      final students =
          await (widget.studentsRepository ?? InstructorStudentsRepository())
              .fetchStudents();
      if (!mounted) return;
      setState(() => _students = students);
    } catch (_) {
      // no-op
    } finally {
      if (mounted) {
        setState(() => _studentsLoading = false);
      }
    }
  }

  void _reload() {
    setState(() {
      _homeworksFuture = _fetchHomeworks();
    });
  }

  Future<void> _createHomework() async {
    if (_studentsLoading) return;
    if (_students.isEmpty) {
      await _loadStudents();
    }
    if (!mounted) return;
    if (_students.isEmpty) {
      _snack(AppStrings.t('No assigned students yet.'));
      return;
    }

    final form = await _openHomeworkDialog();
    if (form == null) return;

    setState(() => _saving = true);
    try {
      await (widget.repository ?? InstructorHomeworksRepository())
          .createHomework(
        studentId: form.studentId!,
        title: form.title,
        description: form.description,
        dueAt: form.dueAt,
      );
      if (!mounted) return;
      _snack(AppStrings.t('Homework created.'));
      _reload();
    } catch (e) {
      _snack(_errorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _editHomework(InstructorHomeworkItem homework) async {
    final form = await _openHomeworkDialog(existing: homework);
    if (form == null) return;

    setState(() => _saving = true);
    try {
      await (widget.repository ?? InstructorHomeworksRepository())
          .updateHomework(
        id: homework.id,
        title: form.title,
        description: form.description,
        dueAt: form.dueAt,
      );
      if (!mounted) return;
      _snack(AppStrings.t('Updated successfully'));
      _reload();
    } catch (e) {
      _snack(_errorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _archiveHomework(InstructorHomeworkItem homework) async {
    if (_saving) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.t('Archive')),
        content: Text(AppStrings.t('Are you sure?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.t('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.t('Confirm')),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await (widget.repository ?? InstructorHomeworksRepository())
          .archiveHomework(homework.id);
      if (!mounted) return;
      _snack(AppStrings.t('Homework archived.'));
      _reload();
    } catch (e) {
      _snack(_errorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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

  Future<void> _reviewHomework(InstructorHomeworkItem homework) async {
    final submission = homework.submission;
    if (submission == null) {
      _snack(AppStrings.t('No submission found for this homework.'));
      return;
    }

    String selectedStatus =
        submission.status.isNotEmpty ? submission.status : 'submitted';
    String noteValue = submission.instructorNote;

    final payload = await showDialog<_ReviewFormValue>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(AppStrings.t('Review Submission')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppStrings.t('Student')}: ${homework.studentName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (submission.studentNote.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.t('Student Note'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(submission.studentNote),
                  ],
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('Status'),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'submitted',
                        child: Text('Submitted'),
                      ),
                      DropdownMenuItem(
                        value: 'reviewed',
                        child: Text('Reviewed'),
                      ),
                      DropdownMenuItem(
                        value: 'needs_revision',
                        child: Text('Revision Requested'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => selectedStatus = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: noteValue,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: AppStrings.t('Instructor Feedback'),
                    ),
                    onChanged: (value) => noteValue = value,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppStrings.t('Cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    _ReviewFormValue(
                      status: selectedStatus,
                      note: noteValue.trim(),
                    ),
                  );
                },
                child: Text(AppStrings.t('Save')),
              ),
            ],
          );
        },
      ),
    );

    if (payload == null) return;

    setState(() => _saving = true);
    try {
      await (widget.repository ?? InstructorHomeworksRepository())
          .reviewHomework(
        id: homework.id,
        status: payload.status,
        instructorNote: payload.note,
      );
      if (!mounted) return;
      _snack(AppStrings.t('Homework review updated.'));
      _reload();
    } catch (e) {
      _snack(_errorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<_HomeworkFormValue?> _openHomeworkDialog({
    InstructorHomeworkItem? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descriptionCtrl = TextEditingController(
      text: existing?.description ?? '',
    );
    DateTime? dueAt = existing?.dueAt;
    int? selectedStudentId =
        existing == null && _students.isNotEmpty ? _students.first.id : null;
    String? validation;

    final result = await showDialog<_HomeworkFormValue>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: dueAt ?? now,
                firstDate: now.subtract(const Duration(days: 365)),
                lastDate: now.add(const Duration(days: 730)),
              );
              if (picked == null) return;
              setModalState(() {
                dueAt = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  dueAt?.hour ?? 12,
                  dueAt?.minute ?? 0,
                );
              });
            }

            return AlertDialog(
              title: Text(
                existing == null
                    ? AppStrings.t('Create Homework')
                    : AppStrings.t('Update Homework'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (existing == null)
                      DropdownButtonFormField<int>(
                        initialValue: selectedStudentId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: AppStrings.t('Student'),
                        ),
                        items: _students
                            .map(
                              (student) => DropdownMenuItem<int>(
                                value: student.id,
                                child: Text(student.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          setModalState(() {
                            selectedStudentId = value;
                          });
                        },
                      ),
                    if (existing == null) const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration:
                          InputDecoration(labelText: AppStrings.t('Title')),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionCtrl,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: AppStrings.t('Description'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dueAt == null
                                ? AppStrings.t('No deadline')
                                : DateFormat('dd.MM.yyyy').format(dueAt!),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: pickDate,
                          icon: const Icon(Icons.date_range),
                          label: Text(AppStrings.t('Date')),
                        ),
                      ],
                    ),
                    if (validation != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          validation!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppStrings.t('Cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) {
                      setModalState(
                          () => validation = AppStrings.t('Title is required'));
                      return;
                    }
                    if (existing == null && selectedStudentId == null) {
                      setModalState(() =>
                          validation = AppStrings.t('Please select a student'));
                      return;
                    }
                    Navigator.of(context).pop(
                      _HomeworkFormValue(
                        studentId: selectedStudentId,
                        title: title,
                        description: descriptionCtrl.text.trim(),
                        dueAt: dueAt,
                      ),
                    );
                  },
                  child: Text(existing == null
                      ? AppStrings.t('Create')
                      : AppStrings.t('Update')),
                ),
              ],
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    descriptionCtrl.dispose();
    return result;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        if (msg is Map) {
          return msg.values.map((value) => value.toString()).join('\n');
        }
        return msg.toString();
      }
      if (error.message != null) return error.message!;
    }
    return AppStrings.t('Something went wrong');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppStrings.t('Homeworks')),
        actions: [
          IconButton(
            onPressed: _saving ? null : _createHomework,
            icon: const Icon(Icons.add_rounded),
            tooltip: AppStrings.t('Create'),
          ),
        ],
      ),
      body: AppGlowBackground(
        child: FutureBuilder<InstructorHomeworksPayload?>(
          future: _homeworksFuture,
          builder: (context, snapshot) {
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

            final payload = snapshot.data;
            if (payload == null) {
              return AppEmptyState(
                title: AppStrings.t('No Data Found'),
                icon: Icons.assignment_outlined,
              );
            }

            return AnimatedPageEntrance(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.xl),
                children: [
                  GradientHero(
                    glowColor: AppColors.accent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.assignment_rounded,
                                color: Colors.white, size: 26),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: Text(
                                AppStrings.t('Homeworks'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.t(
                              'Assign homework to your students and track submissions.'),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                              label:
                                  '${AppStrings.t('Homeworks')}: ${payload.active.length}',
                            ),
                            AppStatPill(
                              icon: Icons.inventory_2_rounded,
                              label:
                                  '${AppStrings.t('Archived')}: ${payload.archived.length}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  SectionHeader(
                    title:
                        '${AppStrings.t('Homeworks')} (${payload.active.length})',
                    icon: Icons.pending_actions_rounded,
                  ),
                  if (payload.active.isEmpty)
                    AppEmptyState(
                      title: AppStrings.t('No homeworks found!'),
                      icon: Icons.assignment_outlined,
                    )
                  else
                    StaggeredReveal(
                      children: payload.active
                          .map(
                            (hw) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpace.md),
                              child: _HomeworkTile(
                                homework: hw,
                                onEdit:
                                    _saving ? null : () => _editHomework(hw),
                                onArchive: _saving
                                    ? null
                                    : () => _archiveHomework(hw),
                                onReview:
                                    _saving ? null : () => _reviewHomework(hw),
                                onOpenAttachment: hw.attachmentPath.isEmpty
                                    ? null
                                    : () => _openContent(
                                          title: hw.attachmentName.isNotEmpty
                                              ? hw.attachmentName
                                              : AppStrings.t('Homework File'),
                                          rawUrl: hw.attachmentPath,
                                        ),
                                onOpenSubmission: hw.submission?.submissionPath
                                            .isNotEmpty ==
                                        true
                                    ? () => _openContent(
                                          title: hw.submission!.submissionName
                                                  .isNotEmpty
                                              ? hw.submission!.submissionName
                                              : AppStrings.t('Submission'),
                                          rawUrl:
                                              hw.submission!.submissionPath,
                                        )
                                    : null,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  const SizedBox(height: AppSpace.lg),
                  SectionHeader(
                    title:
                        '${AppStrings.t('Archived')} (${payload.archived.length})',
                    icon: Icons.inventory_2_rounded,
                  ),
                  if (payload.archived.isEmpty)
                    AppEmptyState(
                      title: AppStrings.t('No archived homeworks found!'),
                      icon: Icons.inventory_2_outlined,
                    )
                  else
                    StaggeredReveal(
                      children: payload.archived
                          .map(
                            (hw) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpace.md),
                              child: _HomeworkTile(
                                homework: hw,
                                onEdit:
                                    _saving ? null : () => _editHomework(hw),
                                onReview:
                                    _saving ? null : () => _reviewHomework(hw),
                                onOpenAttachment: hw.attachmentPath.isEmpty
                                    ? null
                                    : () => _openContent(
                                          title: hw.attachmentName.isNotEmpty
                                              ? hw.attachmentName
                                              : AppStrings.t('Homework File'),
                                          rawUrl: hw.attachmentPath,
                                        ),
                                onOpenSubmission: hw.submission?.submissionPath
                                            .isNotEmpty ==
                                        true
                                    ? () => _openContent(
                                          title: hw.submission!.submissionName
                                                  .isNotEmpty
                                              ? hw.submission!.submissionName
                                              : AppStrings.t('Submission'),
                                          rawUrl:
                                              hw.submission!.submissionPath,
                                        )
                                    : null,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeworkTile extends StatelessWidget {
  const _HomeworkTile({
    required this.homework,
    this.onEdit,
    this.onArchive,
    this.onReview,
    this.onOpenAttachment,
    this.onOpenSubmission,
  });

  final InstructorHomeworkItem homework;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onReview;
  final VoidCallback? onOpenAttachment;
  final VoidCallback? onOpenSubmission;

  @override
  Widget build(BuildContext context) {
    final status = homework.status.toLowerCase();
    final statusColor = switch (status) {
      'reviewed' => AppPalette.success,
      'needs_revision' => AppPalette.streak,
      'submitted' => AppColors.brand,
      'archived' => AppColors.muted,
      _ => AppColors.brandDeep,
    };
    final statusIcon = switch (status) {
      'reviewed' => Icons.verified_rounded,
      'needs_revision' => Icons.error_outline_rounded,
      'submitted' => Icons.assignment_turned_in_rounded,
      'archived' => Icons.inventory_2_rounded,
      _ => Icons.assignment_rounded,
    };

    final dueLabel = homework.dueAt == null
        ? '-'
        : DateFormat('dd.MM.yyyy HH:mm').format(homework.dueAt!.toLocal());
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homework.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: 6,
                      children: [
                        AppStatPill(
                          icon: Icons.person_rounded,
                          label: homework.studentName,
                          color: AppColors.brand,
                          onLight: true,
                        ),
                        AppStatPill(
                          icon: Icons.event_rounded,
                          label: dueLabel,
                          color: AppPalette.violet,
                          onLight: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                        return;
                      }
                      if (value == 'review') {
                        onReview?.call();
                        return;
                      }
                      if (value == 'archive') {
                        onArchive?.call();
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Text(AppStrings.t('Edit')),
                        ),
                        if (homework.submission != null)
                          PopupMenuItem<String>(
                            value: 'review',
                            child: Text(AppStrings.t('Review Submission')),
                          ),
                        if (onArchive != null)
                          PopupMenuItem<String>(
                            value: 'archive',
                            child: Text(AppStrings.t('Archive')),
                          ),
                      ];
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      homework.statusLabel.isEmpty
                          ? homework.status
                          : homework.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (homework.submission != null) ...[
            const SizedBox(height: AppSpace.md),
            _SubmissionNote(
              icon: Icons.upload_file_rounded,
              label:
                  '${AppStrings.t('Submitted')}: ${homework.submission!.submittedAt == null ? '-' : DateFormat('dd.MM.yyyy HH:mm').format(homework.submission!.submittedAt!.toLocal())}',
            ),
            if (homework.submission!.studentNote.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              _SubmissionNote(
                icon: Icons.sticky_note_2_rounded,
                label:
                    '${AppStrings.t('Student Note')}: ${homework.submission!.studentNote}',
              ),
            ],
            if (homework.submission!.instructorNote.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              _SubmissionNote(
                icon: Icons.rate_review_rounded,
                label:
                    '${AppStrings.t('Instructor Feedback')}: ${homework.submission!.instructorNote}',
                color: AppPalette.success,
              ),
            ],
          ],
          if (homework.description.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              homework.description.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (onOpenAttachment != null || onOpenSubmission != null) ...[
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                if (onOpenAttachment != null)
                  AppGhostButton(
                    label: AppStrings.t('Homework File'),
                    onPressed: onOpenAttachment,
                    icon: Icons.description_rounded,
                    expand: false,
                  ),
                if (onOpenSubmission != null)
                  AppGhostButton(
                    label: AppStrings.t('Submission'),
                    onPressed: onOpenSubmission,
                    icon: Icons.assignment_turned_in_rounded,
                    color: AppPalette.success,
                    expand: false,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SubmissionNote extends StatelessWidget {
  const _SubmissionNote({
    required this.icon,
    required this.label,
    this.color = AppColors.muted,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color == AppColors.muted ? AppColors.muted : AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeworkFormValue {
  const _HomeworkFormValue({
    required this.studentId,
    required this.title,
    required this.description,
    required this.dueAt,
  });

  final int? studentId;
  final String title;
  final String description;
  final DateTime? dueAt;
}

class _ReviewFormValue {
  const _ReviewFormValue({
    required this.status,
    required this.note,
  });

  final String status;
  final String note;
}
