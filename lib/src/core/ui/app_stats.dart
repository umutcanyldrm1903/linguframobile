import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/app_design.dart';
import '../theme/app_colors.dart';
import 'app_surfaces.dart';

/// 0'dan hedefe sayan, animasyonlu sayaç.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.fractionDigits = 0,
    this.duration = const Duration(milliseconds: 900),
    this.style,
  });

  final num value;
  final String prefix;
  final String suffix;
  final int fractionDigits;
  final Duration duration;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final text = fractionDigits > 0
            ? v.toStringAsFixed(fractionDigits)
            : v.round().toString();
        return Text(
          '$prefix$text$suffix',
          style: style ??
              Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
        );
      },
    );
  }
}

/// İkon + sayan değer + etiket; opsiyonel trend yüzdesi ve mini grafik.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.brand,
    this.suffix = '',
    this.prefix = '',
    this.fractionDigits = 0,
    this.trend,
    this.spark,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final num value;
  final Color color;
  final String suffix;
  final String prefix;
  final int fractionDigits;

  /// Pozitif/negatif trend yüzdesi (örn. +12 / -5). null ise gizli.
  final double? trend;

  /// Mini sparkline değerleri (örn. son 7 gün). null ise gizli.
  final List<double>? spark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.all(AppRadius.sm),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
              if (trend != null) _TrendPill(trend: trend!),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          AnimatedCounter(
            value: value,
            prefix: prefix,
            suffix: suffix,
            fractionDigits: fractionDigits,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (spark != null && spark!.length > 1) ...[
            const SizedBox(height: AppSpace.md),
            SizedBox(
              height: 28,
              width: double.infinity,
              child: CustomPaint(painter: _SparkPainter(spark!, color)),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.trend});

  final double trend;

  @override
  Widget build(BuildContext context) {
    final up = trend >= 0;
    final c = up ? AppPalette.success : AppPalette.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 13, color: c),
          const SizedBox(width: 3),
          Text(
            '${up ? '+' : ''}${trend.toStringAsFixed(0)}%',
            style: TextStyle(
                color: c, fontWeight: FontWeight.w800, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);
    final dx = size.width / (values.length - 1);

    final path = Path();
    final fill = Path();
    for (var i = 0; i < values.length; i++) {
      final x = dx * i;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    // Son nokta
    final lastX = dx * (values.length - 1);
    final lastY =
        size.height - ((values.last - minV) / range) * size.height;
    canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.values != values || old.color != color;
}

/// Animasyonlu daire ilerleme halkası; ortasında etiket/çocuk.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 88,
    this.stroke = 9,
    this.color = AppColors.brand,
    this.trackColor,
    this.center,
    this.gradient,
  });

  /// 0..1
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Color? trackColor;
  final Widget? center;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) {
          return CustomPaint(
            painter: _RingPainter(
              value: v,
              stroke: stroke,
              color: color,
              track: trackColor ?? AppPalette.line,
              gradient: gradient,
            ),
            child: Center(
              child: center ??
                  Text(
                    '${(v * 100).round()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.22,
                      color: AppColors.ink,
                    ),
                  ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.color,
    required this.track,
    this.gradient,
  });

  final double value;
  final double stroke;
  final Color color;
  final Color track;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (gradient != null) {
      arc.shader = gradient!.createShader(rect);
    } else {
      arc.color = color;
    }
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color;
}
