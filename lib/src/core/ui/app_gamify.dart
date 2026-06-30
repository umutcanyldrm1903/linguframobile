import 'package:flutter/material.dart';

import '../design/app_design.dart';
import '../motion/app_motion.dart';
import '../theme/app_colors.dart';

/// Genel amaçlı küçük "pill" rozet (ikon + metin + renk).
class AppStatPill extends StatelessWidget {
  const AppStatPill({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.brand,
    this.onLight = false,
  });

  final IconData icon;
  final String label;
  final Color color;

  /// Açık zeminde mi (kart üstü) yoksa gradyan/koyu zeminde mi.
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final bg = onLight
        ? color.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.20);
    final fg = onLight ? color : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: fg, fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seri (streak) rozeti — alev + gün sayısı.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days, this.onLight = true});

  final int days;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppGradients.streak,
        borderRadius: AppRadius.pill,
        boxShadow: AppShadows.glow(AppPalette.streak, opacity: 0.30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$days',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Seviye çipi (örn. "Seviye 5").
class LevelChip extends StatelessWidget {
  const LevelChip({super.key, required this.level, this.title});

  final int level;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppGradients.violet,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            title ?? 'Lv $level',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// XP rozeti.
class XpPill extends StatelessWidget {
  const XpPill({super.key, required this.xp, this.onLight = true});

  final int xp;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final bg = onLight
        ? AppPalette.xp.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.20);
    final fg = onLight ? AppPalette.goldDeep : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 15, color: fg),
          const SizedBox(width: 4),
          Text('$xp XP',
              style: TextStyle(
                  color: fg, fontWeight: FontWeight.w900, fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// Sıralama rozeti (#127).
class RankPill extends StatelessWidget {
  const RankPill({super.key, required this.rank, this.trendUp});

  final int rank;
  final bool? trendUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.leaderboard_rounded,
              size: 14, color: AppColors.brand),
          const SizedBox(width: 5),
          Text('#$rank',
              style: const TextStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5)),
          if (trendUp != null) ...[
            const SizedBox(width: 3),
            Icon(
              trendUp! ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 12,
              color: trendUp! ? AppPalette.success : AppPalette.danger,
            ),
          ],
        ],
      ),
    );
  }
}

/// Başarı/rozet madalyonu — kilitli/açık durumlu.
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.icon,
    required this.label,
    this.unlocked = true,
    this.color = AppPalette.gold,
    this.onTap,
    this.size = 64,
  });

  final IconData icon;
  final String label;
  final bool unlocked;
  final Color color;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: unlocked
                ? AppGradients.pair(color, _darken(color))
                : null,
            color: unlocked ? null : const Color(0xFFEAEFF7),
            boxShadow:
                unlocked ? AppShadows.glow(color, opacity: 0.34) : null,
            border: Border.all(
              color: unlocked ? Colors.white : const Color(0xFFD7DEEC),
              width: 2.5,
            ),
          ),
          child: Icon(
            unlocked ? icon : Icons.lock_rounded,
            color: unlocked ? Colors.white : const Color(0xFFAEB8CC),
            size: size * 0.42,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: size + 16,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: unlocked ? AppColors.ink : AppColors.muted,
            ),
          ),
        ),
      ],
    );
    if (onTap == null) return body;
    return PressableScale(onTap: onTap, child: body);
  }

  static Color _darken(Color c) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - 0.18).clamp(0.0, 1.0)).toColor();
  }
}

/// Seçilebilir filtre çipi (kategori/etiket).
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color = AppColors.brand,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.brand : null,
          color: selected ? null : Colors.white,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: selected ? Colors.transparent : AppPalette.line,
            width: 1.4,
          ),
          boxShadow: selected ? AppShadows.glow(color, opacity: 0.28) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 15, color: selected ? Colors.white : AppColors.muted),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
