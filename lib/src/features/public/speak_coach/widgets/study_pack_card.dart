import 'package:flutter/material.dart';

class StudyPackCard extends StatelessWidget {
  const StudyPackCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String duration;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accentColor, size: 28),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(duration, style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            )),
          ],
        ),
      ),
    );
  }
}
