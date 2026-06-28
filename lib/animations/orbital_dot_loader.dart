import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A compact orbital dot loader — dots orbit a center point, each pulsing
/// in size as they travel, giving a fluid, alive quality.
///
/// Used for short, focused wait states:
///   • Queue data loading
///   • User history loading
///   • AutoMod rule test running
///
/// NOT a global fullscreen overlay — keep it close to what's loading.
///
/// Usage:
/// ```dart
/// OrbitalDotLoader(
///   color: KyuubiColors.orange,
///   size: 36,
/// )
/// ```
///
/// Respects [MediaQuery.disableAnimations]: shows a static indicator.
class OrbitalDotLoader extends StatefulWidget {
  const OrbitalDotLoader({
    super.key,
    this.color,
    this.size = 36.0,
    this.dotCount = 4,
    this.duration = const Duration(milliseconds: 1100),
  });

  /// Dot color — defaults to theme primary.
  final Color? color;

  /// Overall diameter of the orbit circle.
  final double size;

  /// Number of dots on the orbit.
  final int dotCount;

  final Duration duration;

  @override
  State<OrbitalDotLoader> createState() => _OrbitalDotLoaderState();
}

class _OrbitalDotLoaderState extends State<OrbitalDotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final color =
        widget.color ?? Theme.of(context).colorScheme.primary;

    if (reduceMotion) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return CustomPaint(
            painter: _OrbitalPainter(
              progress: _ctrl.value,
              color: color,
              dotCount: widget.dotCount,
              size: widget.size,
            ),
          );
        },
      ),
    );
  }
}

class _OrbitalPainter extends CustomPainter {
  const _OrbitalPainter({
    required this.progress,
    required this.color,
    required this.dotCount,
    required this.size,
  });

  final double progress;
  final Color color;
  final int dotCount;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final centre = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final orbitRadius = size / 2 * 0.72;

    for (var i = 0; i < dotCount; i++) {
      // Each dot is evenly spaced + rotated by animation progress
      final fraction = i / dotCount;
      final angle = (fraction + progress) * 2 * math.pi - math.pi / 2;

      final dx = centre.dx + orbitRadius * math.cos(angle);
      final dy = centre.dy + orbitRadius * math.sin(angle);

      // Dot pulses: largest at top (angle = -π/2), smallest at bottom
      // Map angle to [0,1] pulse — front is biggest
      final pulseFraction = (math.sin(angle + math.pi / 2) + 1) / 2;
      final dotRadius = (size * 0.055) * (0.55 + pulseFraction * 0.65);
      final opacity = 0.35 + pulseFraction * 0.65;

      canvas.drawCircle(
        Offset(dx, dy),
        dotRadius,
        Paint()..color = color.withValues(alpha: opacity),
      );
    }

    // Subtle orbit track
    canvas.drawCircle(
      centre,
      orbitRadius,
      Paint()
        ..color = color.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_OrbitalPainter old) => old.progress != progress;
}

// ── Convenience: inline text + loader row ─────────────────────────────────────

/// A small loader with optional label — for in-context loading states.
///
/// ```dart
/// OrbitalDotLoaderLabel(label: 'Loading queue…')
/// ```
class OrbitalDotLoaderLabel extends StatelessWidget {
  const OrbitalDotLoaderLabel({
    super.key,
    required this.label,
    this.color,
    this.size = 24.0,
  });

  final String label;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OrbitalDotLoader(color: color, size: size),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color ??
                    Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }
}
