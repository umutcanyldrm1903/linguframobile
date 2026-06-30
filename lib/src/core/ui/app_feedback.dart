import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../features/practice/screens/practice_visuals.dart';
import '../design/app_design.dart';
import '../motion/app_motion.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

/// Maskotlu boş durum — sıcak ve markalı.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brand.withValues(alpha: 0.10),
                ),
                child: Icon(icon, size: 42, color: AppColors.brand),
              )
            else
              const PracticeMascot(size: 96, mood: PracticeMascotMood.thinking),
            const SizedBox(height: AppSpace.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpace.xl),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Maskotlu yükleme durumu.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(child: MascotLoading(message: message));
  }
}

/// Hata durumu — tekrar dene aksiyonu ile.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Tekrar dene',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.danger.withValues(alpha: 0.10),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 38, color: AppPalette.danger),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpace.xl),
              AppGhostButton(
                label: retryLabel,
                onPressed: onRetry,
                expand: false,
                icon: Icons.refresh_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Başarı/kutlama overlay'i: konfeti + madalya + mesaj. Önemli anlarda çağır
/// (ödeme başarısı, quiz geçme, sertifika, ders bitişi).
Future<void> showCelebration(
  BuildContext context, {
  required String title,
  String? subtitle,
  IconData icon = Icons.emoji_events_rounded,
  Color color = AppPalette.gold,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final completer = Completer<void>();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CelebrationBody(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      onDismiss: () {
        if (entry.mounted) entry.remove();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );
  overlay.insert(entry);
  return completer.future;
}

class _CelebrationBody extends StatefulWidget {
  const _CelebrationBody({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onDismiss,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onDismiss;

  @override
  State<_CelebrationBody> createState() => _CelebrationBodyState();
}

class _CelebrationBodyState extends State<_CelebrationBody> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _confetti.play();
    Future<void>.delayed(const Duration(milliseconds: 2800), _close);
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: GestureDetector(
        onTap: _close,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.45),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 22,
                  maxBlastForce: 22,
                  minBlastForce: 8,
                  gravity: 0.25,
                  colors: const [
                    AppColors.brand,
                    AppPalette.gold,
                    AppPalette.success,
                    AppPalette.streak,
                    AppPalette.violet,
                  ],
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (context, v, child) => Transform.scale(
                  scale: v.clamp(0, 1.2),
                  child: child,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(AppSpace.xxl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.hero,
                    boxShadow: AppShadows.pop,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SpinningMedal(icon: widget.icon, color: widget.color),
                      const SizedBox(height: AppSpace.lg),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpinningMedal extends StatefulWidget {
  const _SpinningMedal({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_SpinningMedal> createState() => _SpinningMedalState();
}

class _SpinningMedalState extends State<_SpinningMedal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final shine = (math.sin(_c.value * 2 * math.pi) + 1) / 2;
        return Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.pair(
              widget.color,
              AchievementColor.darken(widget.color),
            ),
            boxShadow: AppShadows.glow(
              widget.color,
              opacity: 0.30 + shine * 0.25,
            ),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Icon(widget.icon, size: 44, color: Colors.white),
        );
      },
    );
  }
}

/// Renk koyulaştırma yardımcısı (madalya kenarı vb.).
class AchievementColor {
  const AchievementColor._();
  static Color darken(Color c) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - 0.18).clamp(0.0, 1.0)).toColor();
  }
}
