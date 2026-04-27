import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class BottomDock extends StatelessWidget {
  const BottomDock({
    super.key,
    required this.onOpenPlan,
    required this.onOpenPlacement,
    required this.onOpenTutors,
    required this.onLogin,
    required this.onOpenTrial,
  });

  final Future<void> Function({bool initial}) onOpenPlan;
  final VoidCallback onOpenPlacement;
  final VoidCallback onOpenTutors;
  final VoidCallback onLogin;
  final VoidCallback onOpenTrial;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNight.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _DockItem(
              icon: Icons.tune_rounded,
              label: 'Plan',
              onTap: () => onOpenPlan(),
            ),
          ),
          Expanded(
            child: _DockItem(
              icon: Icons.verified_rounded,
              label: 'Test',
              onTap: onOpenPlacement,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: onOpenTrial,
                child: Text(AppStrings.code == 'tr' ? 'Deneme' : 'Trial'),
              ),
            ),
          ),
          Expanded(
            child: _DockItem(
              icon: Icons.groups_rounded,
              label: 'Tutor',
              onTap: onOpenTutors,
            ),
          ),
          Expanded(
            child: _DockItem(
              icon: Icons.login_rounded,
              label: 'Giris',
              onTap: onLogin,
            ),
          ),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.ink),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
