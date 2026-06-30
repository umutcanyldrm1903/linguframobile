import 'package:flutter/material.dart';

import '../design/app_design.dart';
import '../theme/app_colors.dart';

enum AppButtonTone { brand, success, gold, violet, danger, neutral }

extension _ToneStyle on AppButtonTone {
  Gradient get gradient {
    switch (this) {
      case AppButtonTone.brand:
        return AppGradients.brand;
      case AppButtonTone.success:
        return AppGradients.success;
      case AppButtonTone.gold:
        return AppGradients.gold;
      case AppButtonTone.violet:
        return AppGradients.violet;
      case AppButtonTone.danger:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B6B), Color(0xFFE23B3B)],
        );
      case AppButtonTone.neutral:
        return const LinearGradient(colors: [Color(0xFFEDF1FA), Color(0xFFE2E8F5)]);
    }
  }

  Color get glow {
    switch (this) {
      case AppButtonTone.brand:
        return AppColors.brand;
      case AppButtonTone.success:
        return AppPalette.success;
      case AppButtonTone.gold:
        return AppPalette.goldDeep;
      case AppButtonTone.violet:
        return AppPalette.violet;
      case AppButtonTone.danger:
        return AppPalette.danger;
      case AppButtonTone.neutral:
        return AppColors.muted;
    }
  }

  Color get fg => this == AppButtonTone.neutral ? AppColors.ink : Colors.white;
}

/// Basınca zıplayan gradyan ana buton — uygulama genelinde tutarlı CTA.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = AppButtonTone.brand,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonTone tone;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final double height;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final tone = widget.tone;
    final content = widget.loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation<Color>(tone.fg),
            ),
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: tone.fg, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tone.fg,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.55,
          duration: const Duration(milliseconds: 160),
          child: Container(
            height: widget.height,
            width: widget.expand ? double.infinity : null,
            padding: widget.expand
                ? null
                : const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: tone.gradient,
              borderRadius: AppRadius.all(AppRadius.md),
              boxShadow:
                  enabled ? AppShadows.glow(tone.glow, opacity: 0.38) : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// İkincil/çerçeveli buton.
class AppGhostButton extends StatelessWidget {
  const AppGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.brand,
    this.expand = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.55), width: 1.6),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.all(AppRadius.md),
          ),
          backgroundColor: color.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
