import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/practice/screens/practice_visuals.dart';
import '../localization/app_strings.dart';
import '../theme/app_colors.dart';

class AppMotion {
  const AppMotion._();

  // Daha snappy his için süreler kısaltıldı (sayfa girişleri/geçişler hızlandı).
  static const fast = Duration(milliseconds: 130);
  static const normal = Duration(milliseconds: 230);
  static const page = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 380);

  static const curve = Curves.easeOutCubic;
  static const spring = Curves.easeOutBack;
}

class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: AppMotion.curve);
    final secondary = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.curve,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0, -0.015),
            ).animate(secondary),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AnimatedPageEntrance extends StatefulWidget {
  const AnimatedPageEntrance({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.duration = AppMotion.normal,
    this.offset = const Offset(0, 0.035),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<AnimatedPageEntrance> createState() => _AnimatedPageEntranceState();
}

class _AnimatedPageEntranceState extends State<AnimatedPageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.curve,
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.offset,
          end: Offset.zero,
        ).animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(animation),
          child: widget.child,
        ),
      ),
    );
  }
}

class StaggeredReveal extends StatelessWidget {
  const StaggeredReveal({
    required this.children,
    super.key,
    this.interval = const Duration(milliseconds: 70),
  });

  final List<Widget> children;
  final Duration interval;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i++)
          AnimatedPageEntrance(
            delay: interval * i,
            child: children[i],
          ),
      ],
    );
  }
}

class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    super.key,
    this.onTap,
    this.scale = 0.96,
    this.duration = AppMotion.fast,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;
  final BorderRadius? borderRadius;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              _setPressed(false);
              widget.onTap?.call();
            },
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: widget.duration,
        curve: AppMotion.spring,
        child: widget.child,
      ),
    );
  }
}

class MascotLoading extends StatefulWidget {
  const MascotLoading({
    super.key,
    this.message,
    this.size = 82,
  });

  final String? message;
  final double size;

  @override
  State<MascotLoading> createState() => _MascotLoadingState();
}

class _MascotLoadingState extends State<MascotLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final wave = math.sin(_controller.value * math.pi * 2);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, wave * 7),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: widget.size * 1.18,
                    height: widget.size * 1.18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEAF4FF),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.18),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                  ),
                  // Marka maskotu: akıllı kalem (mezuniyet şapkası değil).
                  PracticeMascot(
                    size: widget.size,
                    mood: PracticeMascotMood.happy,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: widget.size,
              child: LinearProgressIndicator(
                minHeight: 6,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: const Color(0xFFE5ECF6),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF1D7CFF)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.message ??
                  (isTr ? 'Hazirlaniyor...' : 'Preparing your flow...'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        );
      },
    );
  }
}

class RewardBurst extends StatefulWidget {
  const RewardBurst({
    required this.child,
    super.key,
    this.active = true,
  });

  final Widget child;
  final bool active;

  @override
  State<RewardBurst> createState() => _RewardBurstState();
}

class _RewardBurstState extends State<RewardBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow);
    if (widget.active) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant RewardBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final value = Curves.easeOutCubic.transform(_controller.value);
              return Opacity(
                opacity: (1 - value).clamp(0, 1),
                child: Stack(
                  children: [
                    for (var i = 0; i < 8; i++)
                      Transform.translate(
                        offset: Offset.fromDirection(
                          (math.pi * 2 / 8) * i,
                          24 + (42 * value),
                        ),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i.isEven
                                ? const Color(0xFF63D60F)
                                : const Color(0xFF1D7CFF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
