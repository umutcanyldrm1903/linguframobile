import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(
        title: Text(AppStrings.t('Homeworks')),
        actions: [
          IconButton(
            onPressed: _saving ? null : _createHomework,
            icon: const Icon(Icons.add),
            tooltip: AppStrings.t('Create'),
          ),
        ],
      ),
      body: FutureBuilder<InstructorHomeworksPayload?>(
        future: _homeworksFuture,
        builder: (context, snapshot) {
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

          final payload = snapshot.data;
          if (payload == null) {
            return Center(child: Text(AppStrings.t('No Data Found')));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                AppStrings.t('Homeworks'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.t(
                    'Assign homework to your students and track submissions.'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title:
                    '${AppStrings.t('Homeworks')} (${payload.active.length})',
              ),
              const SizedBox(height: 8),
              if (payload.active.isEmpty)
                _EmptyCard(text: AppStrings.t('No homeworks found!'))
              else
                ...payload.active.map(
                  (hw) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HomeworkTile(
                      homework: hw,
                      onEdit: _saving ? null : () => _editHomework(hw),
                      onArchive: _saving ? null : () => _archiveHomework(hw),
                      onReview: _saving ? null : () => _reviewHomework(hw),
                      onOpenAttachment: hw.attachmentPath.isEmpty
                          ? null
                          : () => _openContent(
                                title: hw.attachmentName.isNotEmpty
                                    ? hw.attachmentName
                                    : AppStrings.t('Homework File'),
                                rawUrl: hw.attachmentPath,
                              ),
                      onOpenSubmission:
                          hw.submission?.submissionPath.isNotEmpty == true
                              ? () => _openContent(
                                    title:
                                        hw.submission!.submissionName.isNotEmpty
                                            ? hw.submission!.submissionName
                                            : AppStrings.t('Submission'),
                                    rawUrl: hw.submission!.submissionPath,
                                  )
                              : null,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              _SectionTitle(
                title:
                    '${AppStrings.t('Archived')} (${payload.archived.length})',
              ),
              const SizedBox(height: 8),
              if (payload.archived.isEmpty)
                _EmptyCard(text: AppStrings.t('No archived homeworks found!'))
              else
                ...payload.archived.map(
                  (hw) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HomeworkTile(
                      homework: hw,
                      onEdit: _saving ? null : () => _editHomework(hw),
                      onReview: _saving ? null : () => _reviewHomework(hw),
                      onOpenAttachment: hw.attachmentPath.isEmpty
                          ? null
                          : () => _openContent(
                                title: hw.attachmentName.isNotEmpty
                                    ? hw.attachmentName
                                    : AppStrings.t('Homework File'),
                                rawUrl: hw.attachmentPath,
                              ),
                      onOpenSubmission:
                          hw.submission?.submissionPath.isNotEmpty == true
                              ? () => _openContent(
                                    title:
                                        hw.submission!.submissionName.isNotEmpty
                                            ? hw.submission!.submissionName
                                            : AppStrings.t('Submission'),
                                    rawUrl: hw.submission!.submissionPath,
                                  )
                              : null,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
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
      'reviewed' => Colors.green,
      'needs_revision' => Colors.deepOrange,
      'submitted' => AppColors.brand,
      'archived' => Colors.blueGrey,
      _ => AppColors.brandDeep,
    };

    final dueLabel = homework.dueAt == null
        ? '-'
        : DateFormat('dd.MM.yyyy HH:mm').format(homework.dueAt!.toLocal());

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: statusColor.withValues(alpha: 0.15),
                child: Icon(Icons.assignment, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(homework.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('${AppStrings.t('Student')}: ${homework.studentName}'),
                    const SizedBox(height: 2),
                    Text('${AppStrings.t('End Date')}: $dueLabel'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                  Text(
                    homework.statusLabel.isEmpty
                        ? homework.status
                        : homework.statusLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
          if (homework.submission != null) ...[
            const SizedBox(height: 10),
            Text(
              '${AppStrings.t('Submitted')}: ${homework.submission!.submittedAt == null ? '-' : DateFormat('dd.MM.yyyy HH:mm').format(homework.submission!.submittedAt!.toLocal())}',
              style: const TextStyle(color: AppColors.muted),
            ),
            if (homework.submission!.studentNote.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${AppStrings.t('Student Note')}: ${homework.submission!.studentNote}',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
            if (homework.submission!.instructorNote.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${AppStrings.t('Instructor Feedback')}: ${homework.submission!.instructorNote}',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ],
          if (homework.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              homework.description.trim(),
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
          if (onOpenAttachment != null || onOpenSubmission != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onOpenAttachment != null)
                  OutlinedButton(
                    onPressed: onOpenAttachment,
                    child: Text(AppStrings.t('Homework File')),
                  ),
                if (onOpenSubmission != null)
                  OutlinedButton(
                    onPressed: onOpenSubmission,
                    child: Text(AppStrings.t('Submission')),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(text),
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
