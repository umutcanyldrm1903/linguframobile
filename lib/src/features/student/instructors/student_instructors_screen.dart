import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/analytics/app_event_logger.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import '../../auth/auth_repository.dart';
import '../../public/public_page_scaffold.dart';
import '../packages/student_packages_screen.dart';
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
        padding: const EdgeInsets.all(AppSpace.xl),
        children: [
          AnimatedPageEntrance(
            child: GradientHero(
              gradient: AppGradients.hero,
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_rounded,
                          color: Colors.white, size: 26),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          AppStrings.t('Instructors'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
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
                    AppStrings.t('Find your instructor'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          _SearchBar(
            controller: _searchController,
            onSubmitted: (_) => _refresh(),
            onClear: () {
              _searchController.clear();
              _refresh();
            },
          ),
          const SizedBox(height: AppSpace.md),
          _FilterRow(
            filters: _filters,
            selectedTags: _selectedTags,
            onToggle: _toggleTag,
          ),
          const SizedBox(height: AppSpace.lg),
          FutureBuilder<List<InstructorCardData>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpace.huge),
                  child: AppLoader(message: 'Ogretmenler yükleniyor...'),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
                  child: AppErrorState(
                    message: _extractError(snapshot.error),
                    onRetry: _refresh,
                    retryLabel: AppStrings.t('Try Again'),
                  ),
                );
              }

              final instructors = snapshot.data ?? [];
              if (instructors.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
                  child: AppEmptyState(
                    icon: Icons.person_search_rounded,
                    title: AppStrings.t('No instructors found.'),
                  ),
                );
              }

              return StaggeredReveal(
                children: instructors
                    .map(
                      (instructor) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.md),
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
      body: AppGlowBackground(
        child: publicAppViewport(context, content, expandHeight: true),
      ),
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
  bool _trialLessonAvailable = false;
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

  Future<void> _promptPackageRequired() async {
    if (!mounted) return;
    final openPackages = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppStrings.t('Package Required')),
            content: Text(
              AppStrings.t(
                'You need an active package with lesson credits to book a reservation.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppStrings.t('Cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppStrings.t('View Packages')),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted || !openPackages) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentPackagesScreen()),
    );
  }

  Future<void> _showTrialLessonInfo() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t('Free trial lesson')),
        content: Text(
          AppStrings.t(
            'You can book one free trial lesson before purchasing a package.',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.t('Continue')),
          ),
        ],
      ),
    );
  }

  Future<bool> _ensureStudentHasCredits() async {
    try {
      final profile = await AuthRepository().profile();
      final data = profile['data'];
      if (data is! Map) {
        return true;
      }

      final plan = data['plan'];
      if (plan is! Map) {
        final trialAvailable = data['trial_lesson_available'] == true;
        if (trialAvailable) {
          _trialLessonAvailable = true;
          await _showTrialLessonInfo();
          return true;
        }
        await _promptPackageRequired();
        return false;
      }

      final lessonsRemainingRaw = plan['lessons_remaining'];
      final lessonsRemaining = lessonsRemainingRaw is num
          ? lessonsRemainingRaw.toInt()
          : int.tryParse('${lessonsRemainingRaw ?? ''}') ?? 0;

      if (lessonsRemaining > 0) {
        _trialLessonAvailable = false;
        return true;
      }

      final trialAvailable = data['trial_lesson_available'] == true;
      if (trialAvailable) {
        _trialLessonAvailable = true;
        await _showTrialLessonInfo();
        return true;
      }

      await _promptPackageRequired();
      return false;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _promptLoginRequired();
        return false;
      }
      // Do not block booking on profile-check network issues.
      return true;
    } catch (_) {
      return true;
    }
  }

  String? _extractBackendErrorCode(Object error) {
    if (error is! DioException) return null;
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final code = data['error_code'];
      if (code is String && code.trim().isNotEmpty) {
        return code.trim();
      }
    }
    return null;
  }

  Future<bool> _handleBookingError(Object error) async {
    if (error is DioException && error.response?.statusCode == 401) {
      await _promptLoginRequired();
      return true;
    }

    final code = _extractBackendErrorCode(error);
    if (code == 'no_credits') {
      await _promptPackageRequired();
      return true;
    }

    return false;
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

    return _ensureStudentHasCredits();
  }

  Future<void> _bookSlot(InstructorSchedule schedule) async {
    if (_selectedSlot == null) return;
    if (!await _canBook()) return;
    setState(() => _booking = true);
    try {
      await AppEventLogger.instance.log(
        'reservation_started',
        properties: {
          'instructor_id': '${widget.data.id}',
          'trial_available': _trialLessonAvailable ? '1' : '0',
        },
      );
      final response = await _repo.bookSchedule(
        instructorId: widget.data.id,
        slot: _selectedSlot!,
      );
      final message = response['message']?.toString() ??
          AppStrings.t('Reservation received.');
      final data = response['data'];
      final isTrial = data is Map && data['is_trial'] == true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTrial
                  ? AppStrings.t(
                      'Your free trial lesson reservation has been created.',
                    )
                  : message,
            ),
          ),
        );
        if (isTrial) {
          setState(() => _trialLessonAvailable = false);
        }
      }
      await AppEventLogger.instance.log(
        'reservation_completed',
        properties: {
          'instructor_id': '${widget.data.id}',
          'is_trial': isTrial ? '1' : '0',
        },
      );
      if (isTrial) {
        await AppEventLogger.instance.log(
          'trial_requested',
          properties: {'instructor_id': '${widget.data.id}'},
        );
      }
      _loadSchedule(start: schedule.weekStart);
    } catch (error) {
      final handled = await _handleBookingError(error);
      if (handled) {
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
      body: AppGlowBackground(
        child: publicAppViewport(
          context,
          FutureBuilder<InstructorSchedule>(
            future: _scheduleFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoader(message: 'Takvim hazirlaniyor...');
              }
              if (snapshot.hasError) {
                return AppErrorState(
                  message: _extractError(snapshot.error),
                  onRetry: () => _loadSchedule(),
                  retryLabel: AppStrings.t('Try Again'),
                );
              }

              final schedule = snapshot.data!;
              final rangeLabel =
                  _weekRangeLabel(schedule.weekStart, schedule.weekEnd);

              return ListView(
                padding: const EdgeInsets.all(AppSpace.xl),
                children: [
                  AnimatedPageEntrance(
                    child: _InstructorHeader(data: widget.data),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  SectionHeader(
                    icon: Icons.event_available_rounded,
                    title: AppStrings.t('Lesson Reservation'),
                    subtitle: AppStrings.t(
                      'Pick one of the available time slots to create a reservation.',
                    ),
                  ),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: AppSpace.xs,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () =>
                              _loadSchedule(start: schedule.prevStart),
                          icon: const Icon(Icons.chevron_left_rounded),
                          color: AppColors.brand,
                          tooltip: AppStrings.t('Previous'),
                        ),
                        Expanded(
                          child: Text(
                            rangeLabel,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _loadSchedule(start: schedule.nextStart),
                          icon: const Icon(Icons.chevron_right_rounded),
                          color: AppColors.brand,
                          tooltip: AppStrings.t('Next'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
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
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpace.md),
                      itemCount: schedule.days.length,
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  AppButton(
                    tone: _trialLessonAvailable
                        ? AppButtonTone.success
                        : AppButtonTone.brand,
                    icon: _selectedSlot == null
                        ? Icons.touch_app_rounded
                        : _trialLessonAvailable
                            ? Icons.card_giftcard_rounded
                            : Icons.event_available_rounded,
                    loading: _booking,
                    onPressed: _selectedSlot == null || _booking
                        ? null
                        : () => _bookSlot(schedule),
                    label: _selectedSlot == null
                        ? AppStrings.t('Select Time')
                        : _booking
                            ? '${AppStrings.t('Submitting')}...'
                            : _trialLessonAvailable
                                ? AppStrings.t('Book free trial lesson')
                                : AppStrings.t('Book Reservation'),
                  ),
                ],
              );
            },
          ),
          expandHeight: true,
        ),
      ),
    );
  }
}

class _InstructorHeader extends StatelessWidget {
  const _InstructorHeader({required this.data});

  final InstructorCardData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(imageUrl: data.imageUrl, name: data.name, radius: 32),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(data.role,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            )),
                    const SizedBox(height: AppSpace.sm),
                    AppStatPill(
                      icon: Icons.star_rounded,
                      label: '${data.rating.toStringAsFixed(1)} / 5',
                      color: AppPalette.gold,
                      onLight: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (data.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: 6,
              children: data.tags
                  .map(
                    (tag) => AppChip(
                      label: tag,
                      selected: false,
                      onTap: () {},
                    ),
                  )
                  .toList(),
            ),
          ],
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
    return SizedBox(
      width: 160,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpace.md),
        radius: AppRadius.md,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleLarge),
            Text(date,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: AppSpace.sm),
            Expanded(
              child: slots.isEmpty
                  ? Center(
                      child: Text(
                        AppStrings.t('No available time slots'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: slots.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpace.sm),
                      itemBuilder: (_, index) {
                        final slot = slots[index];
                        final isSelected = slot.value == selectedSlot;
                        return _SlotButton(
                          label: slot.label,
                          isSelected: isSelected,
                          available: slot.available,
                          onTap: slot.available
                              ? () => onSelect(slot.value)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
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
    final borderColor = isSelected
        ? Colors.transparent
        : available
            ? AppPalette.line
            : const Color(0xFFD1D5DB);

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.brand : null,
          color: isSelected
              ? null
              : available
                  ? AppPalette.cloud
                  : const Color(0xFFE2E8F0),
          borderRadius: AppRadius.all(AppRadius.sm),
          border: Border.all(color: borderColor, width: 1.4),
          boxShadow:
              isSelected ? AppShadows.glow(AppColors.brand, opacity: 0.28) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isSelected
                  ? Colors.white
                  : available
                      ? AppColors.ink
                      : AppColors.muted,
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
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.brand),
        hintText: AppStrings.t('Find your instructor'),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.pill,
          borderSide: const BorderSide(color: AppPalette.line, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.pill,
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.pill,
          borderSide: const BorderSide(color: AppPalette.line, width: 1.2),
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
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
                padding: const EdgeInsets.only(right: AppSpace.sm),
                child: AppChip(
                  label: AppStrings.t(text),
                  selected: selectedTags.contains(text),
                  onTap: () => onToggle(text),
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
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(imageUrl: data.imageUrl, name: data.name, radius: 28),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(data.role,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            )),
                  ],
                ),
              ),
              AppStatPill(
                icon: Icons.star_rounded,
                label: data.rating.toStringAsFixed(1),
                color: AppPalette.gold,
                onLight: true,
              ),
            ],
          ),
          if (data.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: 6,
              children: data.tags
                  .map(
                    (tag) => AppChip(
                      label: tag,
                      selected: true,
                      onTap: onTap,
                    ),
                  )
                  .toList(),
            ),
          ],
          if (data.about.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              data.about,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          AppButton(
            label: AppStrings.t('Book Reservation'),
            onPressed: onTap,
            icon: Icons.event_available_rounded,
            expand: false,
            height: 46,
          ),
        ],
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
    required this.imageUrl,
  });

  final int id;
  final String name;
  final String role;
  final List<String> tags;
  final String about;
  final double rating;
  final String? imageUrl;
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
