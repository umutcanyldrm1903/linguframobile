import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../practice_sound_service.dart';
import 'practice_visuals.dart';

/// Power-up aktive edilince tam ekran flaş efekti gösterir.
/// Kullanım: `showPowerUpOverlay(context, type: 'hint')`
Future<void> showPowerUpOverlay(
  BuildContext context, {
  required String type,
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => _PowerUpOverlay(type: type),
    ),
  );
}

class _PowerUpOverlay extends StatefulWidget {
  const _PowerUpOverlay({required this.type});
  final String type;

  @override
  State<_PowerUpOverlay> createState() => _PowerUpOverlayState();
}

class _PowerUpOverlayState extends State<_PowerUpOverlay> {
  @override
  void initState() {
    super.initState();
    PracticeSoundService.onXpEarned();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  ({String emoji, String label, Color color}) get _spec => switch (widget.type) {
        'hint' => (emoji: '💡', label: 'İPUCU!', color: practiceYellow),
        'shield' => (emoji: '🛡️', label: 'KALKAN!', color: practiceBlue),
        'boost' => (emoji: '⚡', label: '2X XP!', color: practiceOrange),
        'heart' => (
            emoji: '❤️',
            label: '+CAN!',
            color: const Color(0xFFFF4B4B)
          ),
        _ => (emoji: '⭐', label: 'GÜÇ!', color: practiceGreen),
      };

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Tam ekran renk flaşı ──
          Container(color: spec.color.withValues(alpha: 0.32))
              .animate()
              .fadeIn(duration: 100.ms)
              .then(delay: 900.ms)
              .fadeOut(duration: 600.ms),

          // ── Merkez ikon + yazı ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(spec.emoji, style: const TextStyle(fontSize: 100))
                    .animate()
                    .scaleXY(
                      begin: 0.1,
                      end: 1.35,
                      duration: 360.ms,
                      curve: Curves.elasticOut,
                    )
                    .then()
                    .scaleXY(begin: 1.35, end: 1.0, duration: 200.ms),
                const SizedBox(height: 14),
                Text(
                  spec.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: spec.color.withValues(alpha: 0.7),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ).animate(delay: 180.ms).fadeIn(duration: 250.ms).slideY(begin: 0.4),
              ],
            ),
          ),

          // ── Köşe ikonları ──
          for (final pos in const [
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ])
            Align(
              alignment: pos,
              child: Padding(
                padding: const EdgeInsets.all(38),
                child: Text(spec.emoji, style: const TextStyle(fontSize: 40))
                    .animate()
                    .fadeIn(duration: 280.ms, delay: 80.ms)
                    .scaleXY(begin: 0.2, end: 1)
                    .then(delay: 600.ms)
                    .fadeOut(duration: 500.ms),
              ),
            ),
        ],
      ),
    );
  }
}
