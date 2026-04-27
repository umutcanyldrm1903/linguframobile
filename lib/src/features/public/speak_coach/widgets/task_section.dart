import 'package:flutter/material.dart';

class TaskSection extends StatelessWidget {
  const TaskSection({
    super.key,
    required this.tasks,
  });

  final List<Widget> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tasks,
    );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.title,
    required this.detail,
    required this.icon,
    required this.done,
    required this.onTap,
  });

  final String title;
  final String detail;
  final IconData icon;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: done ? Colors.green.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: done ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE3EAF7),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: done ? Colors.green : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              done ? Icons.check_circle : Icons.circle_outlined,
              color: done ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
