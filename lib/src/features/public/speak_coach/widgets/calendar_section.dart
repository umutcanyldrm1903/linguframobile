import 'package:flutter/material.dart';
import '../models/speak_coach_models.dart';
import '../../../../core/theme/app_colors.dart';

class CalendarSection extends StatelessWidget {
  const CalendarSection({
    super.key,
    required this.days,
    required this.streak,
    required this.bestStreak,
  });

  final List<CalendarDay> days;
  final int streak;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Seri: $streak',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'En iyi: $bestStreak',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: days.map((day) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CalendarDayTile(day: day),
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _CalendarDayTile extends StatelessWidget {
  const _CalendarDayTile({required this.day});

  final CalendarDay day;

  @override
  Widget build(BuildContext context) {
    final label =
        '${day.date.day.toString().padLeft(2, '0')}/${day.date.month.toString().padLeft(2, '0')}';
    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: day.active ? AppColors.brand : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: day.isToday ? AppColors.brandNight : const Color(0xFFE3EAF7),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: day.active ? Colors.white : AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Icon(
            day.active ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: day.active ? Colors.white : AppColors.muted,
          ),
        ],
      ),
    );
  }
}
