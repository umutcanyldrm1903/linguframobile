import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_config.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared/content_preview_launcher.dart';
import '../students/instructor_students_repository.dart';
import 'instructor_library_repository.dart';

class InstructorLibraryScreen extends StatefulWidget {
  const InstructorLibraryScreen({super.key});

  @override
  State<InstructorLibraryScreen> createState() =>
      _InstructorLibraryScreenState();
}

class _InstructorLibraryScreenState extends State<InstructorLibraryScreen> {
  final InstructorLibraryRepository _repo = InstructorLibraryRepository();
  final InstructorStudentsRepository _studentsRepo =
      InstructorStudentsRepository();

  late Future<InstructorLibraryPayload?> _libraryFuture;
  String _selectedCategory = '';
  List<InstructorStudent> _students = const [];
  bool _studentsLoading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _libraryFuture = _fetchLibrary();
    _loadStudents();
  }

  Future<InstructorLibraryPayload?> _fetchLibrary() {
    return _repo.fetchLibrary();
  }

  Future<void> _loadStudents() async {
    if (_studentsLoading) return;
    setState(() => _studentsLoading = true);
    try {
      final students = await _studentsRepo.fetchStudents();
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
      _libraryFuture = _fetchLibrary();
    });
  }

  Future<void> _createItem() async {
    if (_studentsLoading) return;
    if (_students.isEmpty) {
      await _loadStudents();
    }
    if (!mounted) return;
    if (_students.isEmpty) {
      _snack(AppStrings.t('No assigned students yet.'));
      return;
    }

    final form = await _openLibraryDialog();
    if (form == null) return;

    setState(() => _saving = true);
    try {
      await _repo.createLibraryItem(
        studentId: form.studentId!,
        category: form.category,
        title: form.title,
        description: form.description,
        file: form.file,
      );
      if (!mounted) return;
      _snack(AppStrings.t('Library item uploaded.'));
      _reload();
    } catch (e) {
      _snack(_errorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _editItem(InstructorLibraryItem item) async {
    final form = await _openLibraryDialog(existing: item);
    if (form == null) return;

    setState(() => _saving = true);
    try {
      await _repo.updateLibraryItem(
        id: item.id,
        category: form.category,
        title: form.title,
        description: form.description,
        file: form.file,
      );
      if (!mounted) return;
      _snack(AppStrings.t('Library item updated.'));
      _reload();
    } catch (e) {
      _snack(_errorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteItem(InstructorLibraryItem item) async {
    if (_saving) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.t('Delete')),
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
      await _repo.deleteLibraryItem(item.id);
      if (!mounted) return;
      _snack(AppStrings.t('Library item removed.'));
      _reload();
    } catch (e) {
      _snack(_errorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<_LibraryFormValue?> _openLibraryDialog({
    InstructorLibraryItem? existing,
  }) async {
    final categoryCtrl = TextEditingController(text: existing?.category ?? '');
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descriptionCtrl = TextEditingController(
      text: existing?.description ?? '',
    );
    int? selectedStudentId =
        existing == null && _students.isNotEmpty ? _students.first.id : null;
    LibraryUploadFile? selectedFile;
    String? validation;

    final result = await showDialog<_LibraryFormValue>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(
                existing == null
                    ? AppStrings.t('Add Library Item')
                    : AppStrings.t('Update Library Item'),
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
                      controller: categoryCtrl,
                      decoration:
                          InputDecoration(labelText: AppStrings.t('Category')),
                    ),
                    const SizedBox(height: 12),
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
                            selectedFile?.name ??
                                (existing?.fileName.trim().isNotEmpty == true
                                    ? existing!.fileName
                                    : AppStrings.t('No File Chosen')),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              withData: false,
                              allowMultiple: false,
                              type: FileType.any,
                            );
                            final selected =
                                result == null || result.files.isEmpty
                                    ? null
                                    : result.files.first;
                            if (selected == null || selected.path == null) {
                              return;
                            }
                            setModalState(() {
                              selectedFile = LibraryUploadFile(
                                path: selected.path!,
                                name: selected.name,
                              );
                              validation = null;
                            });
                          },
                          child: Text(AppStrings.t('Choose')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppStrings.t(
                          'You can upload PDF, DOC, worksheet, spreadsheet, presentation, image, video, or other study materials.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                      ),
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
                    final category = categoryCtrl.text.trim();
                    final title = titleCtrl.text.trim();
                    if (existing == null && selectedStudentId == null) {
                      setModalState(() =>
                          validation = AppStrings.t('Please select a student'));
                      return;
                    }
                    if (category.isEmpty) {
                      setModalState(() =>
                          validation = AppStrings.t('Category is required'));
                      return;
                    }
                    if (title.isEmpty) {
                      setModalState(
                          () => validation = AppStrings.t('Title is required'));
                      return;
                    }
                    if (existing == null && selectedFile == null) {
                      setModalState(() =>
                          validation = AppStrings.t('Please upload a file'));
                      return;
                    }
                    Navigator.of(context).pop(
                      _LibraryFormValue(
                        studentId: selectedStudentId,
                        category: category,
                        title: title,
                        description: descriptionCtrl.text.trim(),
                        file: selectedFile,
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

    categoryCtrl.dispose();
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
        title: Text(AppStrings.t('Library')),
        actions: [
          IconButton(
            onPressed: _saving ? null : _createItem,
            icon: const Icon(Icons.add),
            tooltip: AppStrings.t('Create'),
          ),
        ],
      ),
      body: FutureBuilder<InstructorLibraryPayload?>(
        future: _libraryFuture,
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
          if (payload == null || payload.items.isEmpty) {
            return Center(
                child: Text(AppStrings.t('No materials shared yet.')));
          }

          final categories = payload.categories;
          final filteredItems = _selectedCategory.isEmpty
              ? payload.items
              : payload.items
                  .where((item) => item.category == _selectedCategory)
                  .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                AppStrings.t('Library'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.t('Upload materials for your assigned students.'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CategoryChip(
                      label: AppStrings.t('All'),
                      active: _selectedCategory.isEmpty,
                      onTap: () => setState(() => _selectedCategory = ''),
                    ),
                    ...categories.map(
                      (category) => _CategoryChip(
                        label: category,
                        active: category == _selectedCategory,
                        onTap: () =>
                            setState(() => _selectedCategory = category),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              ...filteredItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LibraryItemCard(
                    item: item,
                    onEdit: _saving ? null : () => _editItem(item),
                    onDelete: _saving ? null : () => _deleteItem(item),
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.brand : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.brand : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _LibraryItemCard extends StatelessWidget {
  const _LibraryItemCard({
    required this.item,
    this.onEdit,
    this.onDelete,
  });

  final InstructorLibraryItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final createdAtLabel = item.createdAt == null
        ? '-'
        : DateFormat('dd.MM.yyyy HH:mm').format(item.createdAt!.toLocal());

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
              const Icon(Icons.folder, color: AppColors.brandDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text('${AppStrings.t('Student')}: ${item.studentName}'),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit?.call();
                    return;
                  }
                  if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text(AppStrings.t('Edit')),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(AppStrings.t('Delete')),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaTag(label: '${AppStrings.t('Category')}: ${item.category}'),
              _MetaTag(
                  label:
                      '${AppStrings.t('File Type')}: ${item.fileType.toUpperCase()}'),
              _MetaTag(label: '${AppStrings.t('Created at')}: $createdAtLabel'),
            ],
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(item.description),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => _openFile(context, item),
              child: Text(AppStrings.t('View File')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(
      BuildContext context, InstructorLibraryItem item) async {
    final uri = _resolveUri(item.fileUrl, item.filePath);
    if (uri == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Something went wrong'))),
      );
      return;
    }

    await openContentPreview(
      context,
      title: item.fileName.isNotEmpty ? item.fileName : item.title,
      rawUrl: uri.toString(),
    );
  }

  Uri? _resolveUri(String absoluteUrl, String path) {
    final abs = absoluteUrl.trim();
    if (abs.isNotEmpty) {
      final uri = Uri.tryParse(abs);
      if (uri != null && uri.hasScheme) return uri;
    }

    final raw = path.trim();
    if (raw.isEmpty) return null;
    final parsed = Uri.tryParse(raw);
    if (parsed != null && parsed.hasScheme) return parsed;

    final normalized = raw.startsWith('/') ? raw : '/$raw';
    return Uri.tryParse('${AppConfig.webBaseUrl}$normalized');
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _LibraryFormValue {
  const _LibraryFormValue({
    required this.studentId,
    required this.category,
    required this.title,
    required this.description,
    required this.file,
  });

  final int? studentId;
  final String category;
  final String title;
  final String description;
  final LibraryUploadFile? file;
}
