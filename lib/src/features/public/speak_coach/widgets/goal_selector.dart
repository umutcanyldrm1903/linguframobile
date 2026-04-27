import 'package:flutter/material.dart';
import '../models/speak_coach_models.dart';

class GoalSelector extends StatelessWidget {
  const GoalSelector({
    super.key,
    required this.currentGoalId,
    required this.goals,
    required this.onSelectGoal,
  });

  final String currentGoalId;
  final List<GoalSpec> goals;
  final Function(String) onSelectGoal;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: goals.map((goal) {
        final isSelected = goal.id == currentGoalId;
        return GoalChip(
          goal: goal,
          isSelected: isSelected,
          onTap: () => onSelectGoal(goal.id),
        );
      }).toList(),
    );
  }
}

class GoalChip extends StatelessWidget {
  const GoalChip({
    super.key,
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  final GoalSpec goal;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? goal.icon as Color? ?? Colors.blue : Colors.white,
          border: Border.all(
            color: isSelected
                ? (goal.icon as Color? ?? Colors.blue)
                : const Color(0xFFE3EBF7),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              goal.icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              goal.id,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
