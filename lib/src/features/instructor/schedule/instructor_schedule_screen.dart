import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ui.dart';
import 'instructor_schedule_repository.dart';

class InstructorScheduleScreen extends StatefulWidget {
  const InstructorScheduleScreen({super.key});

  @override
  State<InstructorScheduleScreen> createState() => _InstructorScheduleScreenState();
}

class _InstructorScheduleScreenState extends State<InstructorScheduleScreen> {
  final InstructorScheduleRepository _repository = InstructorScheduleRepository();
  final Map<String, int> _availabilityIds = {};
  final Set<String> _busyKeys = {};
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadAvailabilities();
  }

  Future<void> _loadAvailabilities() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final items = await _repository.fetchAvailabilities();
      _availabilityIds
        ..clear()
        ..addEntries(
          items
              .where((item) => item.isActive)
              .map((item) => MapEntry(item.key, item.id)),
        );
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = AppStrings.t('Something went wrong');
      });
    }
  }

  Future<void> _toggleSlot(int dayIndex, String slotLabel) async {
    final parts = slotLabel.split('-');
    if (parts.length != 2) return;
    final startTime = parts[0];
    final endTime = parts[1];
    final key = _slotKey(dayIndex, slotLabel);

    if (_busyKeys.contains(key)) return;
    setState(() => _busyKeys.add(key));

    try {
      if (_availabilityIds.containsKey(key)) {
        final id = _availabilityIds[key]!;
        await _repository.deleteAvailability(id);
        _availabilityIds.remove(key);
      } else {
        final id = await _repository.createAvailability(
          dayOfWeek: dayIndex,
          startTime: startTime,
          endTime: endTime,
        );
        if (id != null) {
          _availabilityIds[key] = id;
        } else {
          _showErrorSnack();
        }
      }
    } catch (_) {
      _showErrorSnack();
    }

    if (mounted) {
      setState(() => _busyKeys.remove(key));
    }
  }

  void _showErrorSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.t('Something went wrong'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final week = _buildWeek();

    if (_loading) {
      return AppLoader(message: AppStrings.t('Schedule'));
    }

    if (_loadError != null) {
      return AppErrorState(
        message: _loadError!,
        onRetry: _loadAvailabilities,
        retryLabel: AppStrings.t('Try Again'),
      );
    }

    final selectedCount = _availabilityIds.length;

    return AnimatedPageEntrance(
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.xl),
        children: [
          GradientHero(
            gradient: AppGradients.hero,
            glowColor: AppColors.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: AppRadius.all(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        AppStrings.t('Schedule'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    AppStatPill(
                      icon: Icons.check_circle_rounded,
                      label: '$selectedCount',
                      color: AppColors.accent,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  AppStrings.t(
                    'Please click to indicate your available hours so that we can create your course calendar.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          SectionHeader(
            title: AppStrings.t('Schedule'),
            subtitle: AppStrings.t(
              'Please click to indicate your available hours so that we can create your course calendar.',
            ),
            icon: Icons.touch_app_rounded,
          ),
          SizedBox(
            height: 520,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) {
                final day = week[index];
                return _DayColumn(
                  label: day.label,
                  date: day.date,
                  slots: _defaultSlots,
                  isSelected: (slotIndex) =>
                      _availabilityIds.containsKey(_slotKey(index, _defaultSlots[slotIndex])),
                  isBusy: (slotIndex) =>
                      _busyKeys.contains(_slotKey(index, _defaultSlots[slotIndex])),
                  onTap: (slotIndex) => _toggleSlot(index, _defaultSlots[slotIndex]),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: AppSpace.md),
              itemCount: week.length,
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          AppButton(
            label: AppStrings.t('Update'),
            onPressed: _loadAvailabilities,
            tone: AppButtonTone.brand,
            icon: Icons.refresh_rounded,
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
    required this.isSelected,
    required this.isBusy,
    required this.onTap,
  });

  final String label;
  final String date;
  final List<String> slots;
  final bool Function(int) isSelected;
  final bool Function(int) isBusy;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 168,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.12),
                    borderRadius: AppRadius.all(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    size: 16,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        date,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Expanded(
              child: ListView.separated(
                itemCount: slots.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpace.sm),
                itemBuilder: (_, index) {
                  final selected = isSelected(index);
                  final busy = isBusy(index);
                  return _SlotTile(
                    label: slots[index],
                    selected: selected,
                    busy: busy,
                    onTap: busy ? null : () => onTap(index),
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

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.label,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    if (selected) {
      textColor = Colors.white;
    } else if (busy) {
      textColor = AppColors.muted;
    } else {
      textColor = AppColors.ink;
    }

    final tile = AnimatedContainer(
      duration: AppMotion.fast,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      decoration: BoxDecoration(
        gradient: selected ? AppGradients.brand : null,
        color: selected
            ? null
            : busy
                ? AppPalette.line
                : AppPalette.cloud,
        borderRadius: AppRadius.all(AppRadius.sm),
        border: Border.all(
          color: selected ? Colors.transparent : AppPalette.line,
          width: 1.2,
        ),
        boxShadow: selected
            ? AppShadows.glow(AppColors.brand, opacity: 0.26)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.muted),
                ),
              ),
            )
          else if (selected)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.check_rounded, size: 14, color: Colors.white),
            ),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: textColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;
    return PressableScale(onTap: onTap, child: tile);
  }
}

class _WeekDay {
  const _WeekDay({required this.label, required this.date});

  final String label;
  final String date;
}

List<_WeekDay> _buildWeek() {
  final now = DateTime.now();
  final start = now.subtract(Duration(days: now.weekday - 1));
  final labels = [
    AppStrings.t('Monday'),
    AppStrings.t('Tuesday'),
    AppStrings.t('Wednesday'),
    AppStrings.t('Thursday'),
    AppStrings.t('Friday'),
    AppStrings.t('Saturday'),
    AppStrings.t('Sunday'),
  ];
  return List.generate(7, (index) {
    final day = start.add(Duration(days: index));
    final date = '${day.day.toString().padLeft(2, '0')} ${_monthName(day.month)}';
    return _WeekDay(label: labels[index], date: date);
  });
}

String _monthName(int month) {
  const months = [
    'Ocak',
    '�ubat',
    'Mart',
    'Nisan',
    'May�s',
    'Haziran',
    'Temmuz',
    'A�ustos',
    'Eyl�l',
    'Ekim',
    'Kas�m',
    'Aral�k',
  ];
  return months[month - 1];
}

const List<String> _defaultSlots = [
  '00:00-00:40',
  '00:50-01:30',
  '01:40-02:20',
  '02:30-03:10',
  '03:20-04:00',
  '04:10-04:50',
  '05:00-05:40',
  '05:50-06:30',
  '06:40-07:20',
  '07:30-08:10',
  '08:20-09:00',
  '09:10-09:50',
  '10:00-10:40',
  '10:50-11:30',
  '11:40-12:20',
  '12:30-13:10',
  '13:20-14:00',
  '14:10-14:50',
  '15:00-15:40',
  '15:50-16:30',
  '16:40-17:20',
  '17:30-18:10',
  '18:20-19:00',
  '19:10-19:50',
  '20:00-20:40',
  '20:50-21:30',
  '21:40-22:20',
  '22:30-23:10',
  '23:20-00:00',
];

String _slotKey(int dayIndex, String slotLabel) {
  final parts = slotLabel.split('-');
  if (parts.length != 2) return '$dayIndex|$slotLabel';
  return '$dayIndex|${parts[0]}|${parts[1]}';
}
