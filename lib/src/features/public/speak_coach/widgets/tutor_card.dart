import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TutorCard extends StatelessWidget {
  const TutorCard({
    super.key,
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.tags,
    required this.availabilityLabel,
    required this.ctaLabel,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final String name;
  final String role;
  final String imageUrl;
  final List<String> tags;
  final String availabilityLabel;
  final String ctaLabel;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE3EAF7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.surfaceSoft,
                  backgroundImage: imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.person, color: AppColors.muted)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleMedium),
                      Text(role, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : AppColors.muted,
                  ),
                  onPressed: onToggleFavorite,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: tags.map((tag) => Chip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
            const SizedBox(height: 12),
            Text(availabilityLabel, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                child: Text(ctaLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
