import 'package:flutter/material.dart';

import '../design/app_design.dart';
import '../motion/app_motion.dart';
import '../theme/app_colors.dart';

/// Standart yükseltilmiş beyaz kart. Tüm yeni ekranların temel yüzeyi.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.radius = AppRadius.lg,
    this.onTap,
    this.color,
    this.border = true,
    this.shadow,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final bool border;
  final List<BoxShadow>? shadow;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: AppMotion.fast,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? Colors.white) : null,
        gradient: gradient,
        borderRadius: AppRadius.all(radius),
        border: border
            ? Border.all(color: AppPalette.line, width: 1.2)
            : null,
        boxShadow: shadow ?? AppShadows.card,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return PressableScale(onTap: onTap, child: card);
  }
}

/// Gradyanlı "kahraman" kartı — köşelerde yumuşak ışık lekeleri ile.
class GradientHero extends StatelessWidget {
  const GradientHero({
    super.key,
    required this.child,
    this.gradient = AppGradients.hero,
    this.padding = const EdgeInsets.all(AppSpace.xl),
    this.radius = AppRadius.xxl,
    this.glowColor,
    this.onTap,
  });

  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? glowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glow = glowColor ?? Colors.white;
    final hero = DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.all(radius),
        boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.30),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.all(radius),
        child: Stack(
          children: [
            Positioned(
              top: -34,
              right: -20,
              child: _Blob(color: glow.withValues(alpha: 0.18), size: 150),
            ),
            Positioned(
              bottom: -40,
              left: -30,
              child: _Blob(color: glow.withValues(alpha: 0.12), size: 160),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
    if (onTap == null) return hero;
    return PressableScale(onTap: onTap, child: hero);
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

/// Animasyonlu marka zemini: yumuşak gradyan + sürüklenen ışık küreleri.
/// Detay sayfalarının (shell dışı) arka planı.
class AppGlowBackground extends StatelessWidget {
  const AppGlowBackground({
    super.key,
    required this.child,
    this.accent = AppColors.brand,
  });

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.14),
            AppColors.background,
            Colors.white,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -30,
            child: _Blob(color: accent.withValues(alpha: 0.16), size: 240),
          ),
          Positioned(
            bottom: 60,
            left: -70,
            child: _Blob(
                color: AppPalette.violet.withValues(alpha: 0.12), size: 240),
          ),
          child,
        ],
      ),
    );
  }
}

/// Bölüm başlığı + opsiyonel "tümü/aksiyon" düğmesi.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.12),
                borderRadius: AppRadius.all(AppRadius.sm),
              ),
              child: Icon(icon, size: 19, color: AppColors.brand),
            ),
            const SizedBox(width: AppSpace.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}
