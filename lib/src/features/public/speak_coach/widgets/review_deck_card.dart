import 'package:flutter/material.dart';

class ReviewDeckCard extends StatelessWidget {
  const ReviewDeckCard({
    super.key,
    required this.title,
    required this.phrase,
    required this.onTap,
  });

  final String title;
  final String phrase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3EAF7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.layers_rounded, color: Color(0xFF3656FF)),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 8),
            Text(
              phrase,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
