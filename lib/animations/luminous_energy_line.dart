import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A glowing, moving energy line that runs along the bottom (or top) edge
/// of a widget — used to show claim/lease pressure and live queue activity.
///
/// Behavior mapped to use cases (§3.1, §3.2 of Motion Grammar):
///   • Queue active, new data   → `mode: LuminousMode.calm` (slow, cool)
///   • Lease active             → `mode: LuminousMode.pressure` (medium)
///   • Lease expiring soon      → `mode: LuminousMode.urgent` (fast, warm)
///   • Rule activated           → brief `LuminousMode.pulse` then dims
///
/// Usage — wrap any widget:
/// ```dart
/// LuminousEnergyLine(
///   mode: isExpiring ? LuminousMode.urgent : LuminousMode.pressure,
///   active: hasClaim,
///   child: CaseCard(case: c),
/// )
/// ```
///
/// Respects [MediaQuery.disableAnimations]: static colored border shown.
enum LuminousMode {
  /// Slow, cool — background queue activity.
  calm,

  /// Medium speed — active lease or claim ownership.
  pressure,

  /// Fast, warm — lease near expiry; needs attention now.
  urgent,

  /// Single pulse then fade — rule toggle / momentary activation.
  pulse,
}

class LuminousEnergyLine extends StatefulWidget {
  const LuminousEnergyLine({
    super.key,
    required this.child,
    required this.active,
    this.mode = LuminousMode.calm,
    this.edge = LuminousEdge.bottom,
    this.lineWidth = 2.5,
    this.glowWidth = 8.0,
  });

  final Widget child;
  final bool active;
  final LuminousMode mode;

  /// Which edge the line runs along.
  final LuminousEdge edge;

  final double lineWidth;
  final double glowWidth;

  @override
  State<LuminousEnergyLine> createState() => _LuminousEnergyLineState();
}

enum LuminousEdge { top, bottom, left, right }

class _LuminousEnergyLineState extends State<LuminousEnergyLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  Duration get _duration {
    switch (widget.mode) {
      case LuminousMode.calm:
        return const Duration(milliseconds: 3200);
      case LuminousMode.pressure:
        return const Duration(milliseconds: 1800);
      case LuminousMode.urgent:
        return const Duration(milliseconds: 800);
      case LuminousMode.pulse:
        return const Duration(milliseconds: 1200);
    }
  }

  Color get _color {
    switch (widget.mode) {
      case LuminousMode.calm:
        return const Color(0xFF3EC4D0); // cool cyan
      case LuminousMode.pressure:
        return const Color(0xFFFF9D3E); // warm orange
      case LuminousMode.urgent:
        return const Color(0xFFFF5757); // coral red
      case LuminousMode.pulse:
        return const Color(0xFF8B9FE8); // periwinkle
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _duration);
    if (widget.active) _start();
  }

  @override
  void didUpdateWidget(LuminousEnergyLine old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active || widget.mode != old.mode) {
      _ctrl.duration = _duration;
      if (widget.active) {
        _start();
      } else {
        _stop();
      }
    }
  }

  void _start() {
    final reduceMotion = WidgetsBinding.instance.platformDispatcher
        .accessibilityFeatures.reduceMotion;
    if (reduceMotion) return;
    if (widget.mode == LuminousMode.pulse) {
      _ctrl.forward(from: 0);
    } else {
      _ctrl.repeat();
    }
  }

  void _stop() {
    _ctrl.stop();
    _ctrl.reset();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (!widget.active) return widget.child;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        double effectiveProgress = _ctrl.value;
        if (widget.mode == LuminousMode.pulse) {
          // Single sweep then fade
          effectiveProgress = _ctrl.value;
        }
        return CustomPaint(
          foregroundPainter: _EnergyLinePainter(
            progress: effectiveProgress,
            color: _color,
            mode: widget.mode,
            edge: widget.edge,
            lineWidth: widget.lineWidth,
            glowWidth: widget.glowWidth,
            reduceMotion: reduceMotion,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _EnergyLinePainter extends CustomPainter {
  const _EnergyLinePainter({
    required this.progress,
    required this.color,
    required this.mode,
    required this.edge,
    required this.lineWidth,
    required this.glowWidth,
    required this.reduceMotion,
  });

  final double progress;
  final Color color;
  final LuminousMode mode;
  final LuminousEdge edge;
  final double lineWidth;
  final double glowWidth;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    if (reduceMotion) {
      // Static line when reduce-motion
      final p1 = _edgeStart(size);
      final p2 = _edgeEnd(size);
      canvas.drawLine(p1, p2,
          Paint()
            ..color = color.withValues(alpha: 0.5)
            ..strokeWidth = lineWidth
            ..strokeCap = StrokeCap.round);
      return;
    }

    final p1 = _edgeStart(size);
    final p2 = _edgeEnd(size);

    if (mode == LuminousMode.pulse) {
      // Single sweep: bright point moves from p1 to p2 then fades
      final t = progress;
      final pos = Offset.lerp(p1, p2, t)!;
      final opacity = t < 0.7 ? 1.0 : (1.0 - t) / 0.3;

      // Trail behind the bright point
      final trailStart = Offset.lerp(p1, pos, math.max(0, 1 - 0.4 / t))!;
      canvas.drawLine(
          trailStart,
          pos,
          Paint()
            ..color = color.withValues(alpha: opacity * 0.6)
            ..strokeWidth = lineWidth
            ..strokeCap = StrokeCap.round);

      // Bright head
      canvas.drawCircle(
          pos,
          lineWidth * 1.4,
          Paint()
            ..color = color.withValues(alpha: opacity)
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, glowWidth * 0.5));
    } else {
      // Continuous sweep: a segment of the line moves back and forth
      // or wraps — chosen by mode (calm: gentle, urgent: rapid back-and-forth)
      final t = mode == LuminousMode.urgent
          ? (math.sin(progress * 2 * math.pi) + 1) / 2 // oscillate
          : progress; // linear sweep

      // Segment: leading 60% of the edge length is lit
      final segLen = 0.60;
      final segStart = (t - segLen).clamp(0.0, 1.0);
      final segEnd = t;

      final pStart = Offset.lerp(p1, p2, segStart)!;
      final pEnd = Offset.lerp(p1, p2, segEnd)!;

      // Base line (dim, full width)
      canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = color.withValues(alpha: 0.15)
            ..strokeWidth = lineWidth * 0.5
            ..strokeCap = StrokeCap.round);

      // Moving segment glow
      canvas.drawLine(
          pStart,
          pEnd,
          Paint()
            ..color = color.withValues(alpha: 0.35)
            ..strokeWidth = glowWidth
            ..strokeCap = StrokeCap.round
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, glowWidth * 0.6));

      // Bright core of moving segment
      canvas.drawLine(
          pStart,
          pEnd,
          Paint()
            ..color = color.withValues(alpha: 0.85)
            ..strokeWidth = lineWidth
            ..strokeCap = StrokeCap.round);

      // Bright tip at leading edge
      canvas.drawCircle(
          pEnd,
          lineWidth * 1.2,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7));
    }
  }

  Offset _edgeStart(Size s) {
    switch (edge) {
      case LuminousEdge.bottom:
        return Offset(0, s.height);
      case LuminousEdge.top:
        return Offset.zero;
      case LuminousEdge.left:
        return Offset.zero;
      case LuminousEdge.right:
        return Offset(s.width, 0);
    }
  }

  Offset _edgeEnd(Size s) {
    switch (edge) {
      case LuminousEdge.bottom:
        return Offset(s.width, s.height);
      case LuminousEdge.top:
        return Offset(s.width, 0);
      case LuminousEdge.left:
        return Offset(0, s.height);
      case LuminousEdge.right:
        return Offset(s.width, s.height);
    }
  }

  @override
  bool shouldRepaint(_EnergyLinePainter old) => old.progress != progress;
}
