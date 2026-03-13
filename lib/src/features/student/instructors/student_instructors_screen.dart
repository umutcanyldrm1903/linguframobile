import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import 'instructor_repository.dart';

class StudentInstructorsScreen extends StatefulWidget {
  const StudentInstructorsScreen({super.key, this.standalone = false});

  final bool standalone;

  @override
  State<StudentInstructorsScreen> createState() =>
      _StudentInstructorsScreenState();
}

class _StudentInstructorsScreenState extends State<StudentInstructorsScreen> {
  final _repo = InstructorRepository();
  final _searchController = TextEditingController();
  final List<String> _selectedTags = [];
  late Future<List<InstructorCardData>> _future;

  static const _filters = [
    'Turkish',
    'Foreign',
    'Speaking Lessons',
    'Business English',
    'IELTS & TOEFL',
  ];

  @override
  void initState() {
    super.initState();
    _future = _loadInstructors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<InstructorCardData>> _loadInstructors() async {
    final list = await _repo.fetchInstructors(
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      tags: _selectedTags,
    );

    return list
        .map(
          (item) => InstructorCardData(
            id: item.id,
            name: item.name,
            role: item.jobTitle.isNotEmpty
                ? item.jobTitle
                : AppStrings.t('Instructor'),
            tags: item.tags,
            about: item.shortBio.isNotEmpty ? item.shortBio : item.bio,
            rating: item.avgRating,
            courseCount: item.courseCount,
            imageUrl: item.imageUrl,
          ),
        )
        .toList();
  }

  void _refresh() {
    setState(() {
      _future = _loadInstructors();
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
      _future = _loadInstructors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      onRefresh: () async {
        _refresh();
        await _future;
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SearchBar(
            controller: _searchController,
            onSubmitted: (_) => _refresh(),
            onClear: () {
              _searchController.clear();
              _refresh();
            },
          ),
          const SizedBox(height: 14),
          _FilterRow(
            filters: _filters,
            selectedTags: _selectedTags,
            onToggle: _toggleTag,
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<InstructorCardData>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return _EmptyState(
                  message: _extractError(snapshot.error),
                  onRetry: _refresh,
                );
              }

              final instructors = snapshot.data ?? [];
              if (instructors.isEmpty) {
                return _EmptyState(
                  message: AppStrings.t('No instructors found.'),
                );
              }

              return Column(
                children: instructors
                    .map(
                      (instructor) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _InstructorCard(
                          data: instructor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentInstructorDetailScreen(
                                  data: instructor,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );

    if (!widget.standalone) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t('Instructors')),
      ),
      body: content,
    );
  }
}

class StudentInstructorDetailScreen extends StatefulWidget {
  const StudentInstructorDetailScreen({super.key, required this.data});

  final InstructorCardData data;

  @override
  State<StudentInstructorDetailScreen> createState() =>
      _StudentInstructorDetailScreenState();
}

class _StudentInstructorDetailScreenState
    extends State<StudentInstructorDetailScreen> {
  final _repo = InstructorRepository();
  String? _selectedSlot;
  bool _booking = false;
  late Future<InstructorSchedule> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _scheduleFuture = _repo.fetchSchedule(instructorId: widget.data.id);
  }

  void _loadSchedule({String? start}) {
    setState(() {
      _selectedSlot = null;
      _scheduleFuture = _repo.fetchSchedule(
        instructorId: widget.data.id,
        start: start,
      );
    });
  }

  Future<void> _promptLoginRequired() async {
    if (!mounted) return;
    final goLogin = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppStrings.t('Login Required')),
            content: Text(
              AppStrings.t('You need to log in before booking a reservation.'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppStrings.t('Cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppStrings.t('Login')),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) return;
    if (goLogin) {
      Navigator.pushNamed(context, '/login');
    }
  }

  Future<bool> _canBook() async {
    final token = await SecureStorage.getToken();
    if (!mounted) return false;
    if (token == null || token.isEmpty) {
      await _promptLoginRequired();
      return false;
    }

    final role = await SecureStorage.getRole();
    if (!mounted) return false;
    if (role == 'instructor') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.t(
              'You must log in with a student account to book a reservation.',
            ),
          ),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _bookSlot(InstructorSchedule schedule) async {
    if (_selectedSlot == null) return;
    if (!await _canBook()) return;
    setState(() => _booking = true);
    try {
      final response = await _repo.bookSchedule(
        instructorId: widget.data.id,
        slot: _selectedSlot!,
      );
      final message = response['message']?.toString() ??
          AppStrings.t('Reservation received.');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
      _loadSchedule(start: schedule.weekStart);
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 401) {
        await _promptLoginRequired();
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_extractError(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _booking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data.name),
      ),
      body: FutureBuilder<InstructorSchedule>(
        future: _scheduleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _EmptyState(
              message: _extractError(snapshot.error),
              onRetry: () => _loadSchedule(),
            );
          }

          final schedule = snapshot.data!;
          final rangeLabel =
              _weekRangeLabel(schedule.weekStart, schedule.weekEnd);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _InstructorHeader(data: widget.data),
              const SizedBox(height: 18),
              Text(
                AppStrings.t('Lesson Reservation'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.t(
                  'Pick one of the available time slots to create a reservation.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => _loadSchedule(start: schedule.prevStart),
                    child: Text(AppStrings.t('Previous')),
                  ),
                  Text(
                    rangeLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  TextButton(
                    onPressed: () => _loadSchedule(start: schedule.nextStart),
                    child: Text(AppStrings.t('Next')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 360,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, index) {
                    final day = schedule.days[index];
                    final dayLabel = _dayLabel(day.date);
                    final dateLabel = _formatDateShort(day.date);
                    final slots = schedule.slotsByDate[day.date] ?? [];
                    return _DayColumn(
                      label: dayLabel,
                      date: dateLabel,
                      slots: slots,
                      selectedSlot: _selectedSlot,
                      onSelect: (slotValue) {
                        setState(() => _selectedSlot = slotValue);
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: schedule.days.length,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedSlot == null || _booking
                      ? null
                      : () => _bookSlot(schedule),
                  child: Text(
                    _selectedSlot == null
                        ? AppStrings.t('Select Time')
                        : _booking
                            ? '${AppStrings.t('Submitting')}...'
                            : AppStrings.t('Book Reservation'),
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

class _InstructorHeader extends StatelessWidget {
  const _InstructorHeader({required this.data});

  final InstructorCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(imageUrl: data.imageUrl, name: data.name, radius: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.name, style: Theme.of(context).textTheme.titleLarge),
                Text(data.role, style: Theme.of(context).textTheme.bodyMedium),
                if (data.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: data.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brand.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.label,
    required this.date,
    required this.slots,
    required this.selectedSlot,
    required this.onSelect,
  });

  final String label;
  final String date;
  final List<ScheduleSlot> slots;
  final String? selectedSlot;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleLarge),
          Text(date, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Expanded(
            child: slots.isEmpty
                ? Center(
                    child: Text(
                      AppStrings.t('No available time slots'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    itemCount: slots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final slot = slots[index];
                      final isSelected = slot.value == selectedSlot;
                      return _SlotButton(
                        label: slot.label,
                        isSelected: isSelected,
                        available: slot.available,
                        onTap:
                            slot.available ? () => onSelect(slot.value) : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SlotButton extends StatelessWidget {
  const _SlotButton({
    required this.label,
    required this.isSelected,
    required this.available,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool available;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final background = isSelected
        ? AppColors.brand
        : available
            ? const Color(0xFFF1F5F9)
            : const Color(0xFFE2E8F0);
    final borderColor = isSelected
        ? AppColors.brand
        : available
            ? const Color(0xFFE2E8F0)
            : const Color(0xFFD1D5DB);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: available ? AppColors.ink : AppColors.muted,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: AppStrings.t('Find your instructor'),
        filled: true,
        fillColor: AppColors.surface,
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClear,
              ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filters,
    required this.selectedTags,
    required this.onToggle,
  });

  final List<String> filters;
  final List<String> selectedTags;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map(
              (text) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    AppStrings.t(text),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  selected: selectedTags.contains(text),
                  onSelected: (_) => onToggle(text),
                  selectedColor: AppColors.brand.withValues(alpha: 0.2),
                  backgroundColor: AppColors.surface,
                  shape: const StadiumBorder(
                    side: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InstructorCard extends StatelessWidget {
  const _InstructorCard({required this.data, required this.onTap});

  final InstructorCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(imageUrl: data.imageUrl, name: data.name, radius: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(data.role,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const Icon(Icons.favorite_border, color: AppColors.muted),
              ],
            ),
            if (data.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: data.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Text(data.about, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: AppColors.brand),
                const SizedBox(width: 4),
                Text(
                  '${data.rating.toStringAsFixed(1)} / 5 • ${data.courseCount} ${AppStrings.t('Courses')}',
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onTap,
                  child: Text(AppStrings.t('Book Reservation')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(
      {required this.imageUrl, required this.name, required this.radius});

  final String? imageUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl ?? '').trim();
    final fallbackLetter =
        name.trim().isNotEmpty ? name.trim().substring(0, 1) : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.brand.withValues(alpha: 0.2),
      child: url.isEmpty
          ? Text(
              fallbackLetter,
              style: const TextStyle(fontWeight: FontWeight.w700),
            )
          : ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    fallbackLetter,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
    );
  }
}

class InstructorCardData {
  const InstructorCardData({
    required this.id,
    required this.name,
    required this.role,
    required this.tags,
    required this.about,
    required this.rating,
    required this.courseCount,
    required this.imageUrl,
  });

  final int id;
  final String name;
  final String role;
  final List<String> tags;
  final String about;
  final double rating;
  final int courseCount;
  final String? imageUrl;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(AppStrings.t('Try Again')),
            ),
          ]
        ],
      ),
    );
  }
}

String _dayLabel(String dateValue) {
  final parsed = DateTime.tryParse(dateValue);
  if (parsed == null) return '';
  return DateFormat('EEE', _localeName()).format(parsed);
}

String _formatDateShort(String dateValue) {
  final parsed = DateTime.tryParse(dateValue);
  if (parsed == null) return dateValue;
  return DateFormat('dd MMM', _localeName()).format(parsed);
}

String _weekRangeLabel(String start, String end) {
  final parsedStart = DateTime.tryParse(start);
  final parsedEnd = DateTime.tryParse(end);
  if (parsedStart == null || parsedEnd == null) return '';
  return '${DateFormat('dd MMM', _localeName()).format(parsedStart)} - ${DateFormat('dd MMM yyyy', _localeName()).format(parsedEnd)}';
}

String _extractError(Object? error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String) {
        return message;
      }
      if (message is Map) {
        return message.values.map((value) => value.toString()).join('\n');
      }
    }
  }
  return AppStrings.t('An unexpected error occurred. Please try again.');
}

String _localeName() => AppStrings.code == 'tr' ? 'tr_TR' : 'en_US';
