import 'package:flutter/material.dart';

/// An animated light beam that sweeps around the border of a widget —
/// used to mark claimed/owned items in the moderation queue.
///
/// A bright arc travels continuously around the card's border, making
/// ownership immediately visible without occupying layout space.
///
/// Usage:
/// ```dart
/// BorderBeam(
///   active: case.claimedByMe,
///   color: KyuubiColors.orange,
///   child: CaseCard(case: case),
/// )
/// ```
///
/// [active] drives whether the beam animates or rests.
/// When [active] becomes false, the beam fades out gracefully.
///
/// Respects [MediaQuery.disableAnimations]: static border shown when claimed.
class BorderBeam extends StatefulWidget {
  const BorderBeam({
    super.key,
    required this.child,
    required this.active,
    this.color = const Color(0xFFF97316), // orange default
    this.borderRadius = 12.0,
    this.beamWidth = 2.5,
    this.beamLength = 0.28,   // fraction of total perimeter
    this.duration = const Duration(milliseconds: 2200),
    this.borderWidth = 1.5,
  });

  final Widget child;

  /// Whether the beam is actively animating (item is claimed).
  final bool active;

  final Color color;
  final double borderRadius;

  /// Width of the moving beam stroke.
  final double beamWidth;

  /// Length of the beam as a fraction of the total perimeter [0, 1].
  final double beamLength;

  final Duration duration;

  /// Width of the static border shown while active.
  final double borderWidth;

  @override
  State<BorderBeam> createState() => _BorderBeamState();
}

class _BorderBeamState extends State<BorderBeam>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    if (widget.active) _start();
  }

  @override
  void didUpdateWidget(BorderBeam old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      widget.active ? _start() : _stop();
    }
  }

  void _start() {
    final reduceMotion = WidgetsBinding.instance.platformDispatcher
            .accessibilityFeatures
            .reduceMotion;
    if (reduceMotion) return;
    _ctrl.repeat();
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
        return CustomPaint(
          foregroundPainter: _BeamPainter(
            progress: _ctrl.value,
            color: widget.color,
            borderRadius: widget.borderRadius,
            beamWidth: widget.beamWidth,
            beamLength: widget.beamLength,
            borderWidth: widget.borderWidth,
            reduceMotion: reduceMotion,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ── _BeamPainter ──────────────────────────────────────────────────────────────

class _BeamPainter extends CustomPainter {
  _BeamPainter({
    required this.progress,
    required this.color,
    required this.borderRadius,
    required this.beamWidth,
    required this.beamLength,
    required this.borderWidth,
    required this.reduceMotion,
  });

  final double progress;
  final Color color;
  final double borderRadius;
  final double beamWidth;
  final double beamLength;
  final double borderWidth;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      borderWidth / 2,
      borderWidth / 2,
      size.width - borderWidth,
      size.height - borderWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Static dim base border (always visible while active)
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    if (reduceMotion) return;

    // Build the full border path and get its length
    final fullPath = Path()..addRRect(rrect);
    final metrics = fullPath.computeMetrics().first;
    final totalLen = metrics.length;

    // Beam: a segment of length [beamLength * totalLen] that sweeps around
    final beamLen = totalLen * beamLength;
    final headPos = (progress * totalLen) % totalLen;
    final tailPos = (headPos - beamLen + totalLen) % totalLen;

    // Extract the beam path (may wrap around)
    final Path beamPath;
    if (headPos > tailPos) {
      beamPath = metrics.extractPath(tailPos, headPos);
    } else {
      // Wrap: two segments
      final p1 = metrics.extractPath(tailPos, totalLen);
      final p2 = metrics.extractPath(0, headPos);
      beamPath = p1..addPath(p2, Offset.zero);
    }

    // Draw beam with gradient-like fade: bright head, fading tail
    // We do a simple approach: draw the full beam bright, then mask with opacity
    canvas.drawPath(
      beamPath,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = beamWidth
        ..strokeCap = StrokeCap.round,
    );

    // Glow effect around the beam
    canvas.drawPath(
      beamPath,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = beamWidth * 3.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..strokeCap = StrokeCap.round,
    );

    // Bright tip at the head of the beam
    final headTangent = metrics.getTangentForOffset(headPos);
    if (headTangent != null) {
      canvas.drawCircle(
        headTangent.position,
        beamWidth * 0.9,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(_BeamPainter old) =>
      old.progress != progress || old.reduceMotion != reduceMotion;
}
