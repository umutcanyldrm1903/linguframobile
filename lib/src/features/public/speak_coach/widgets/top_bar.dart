import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.onOpenPlan, required this.onLogin});

  final Future<void> Function({bool initial}) onOpenPlan;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3EBF7)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/icon/app_icon_source.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.language_rounded,
                color: AppColors.brand,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LinguFranca',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(
                AppStrings.code == 'tr'
                    ? 'Gunluk ders akisi'
                    : 'Daily lesson flow',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => onOpenPlan(),
          icon: const Icon(Icons.tune_rounded),
        ),
        TextButton(
          onPressed: onLogin,
          child: Text(AppStrings.code == 'tr' ? 'Giris' : 'Login'),
        ),
      ],
    );
  }
}
