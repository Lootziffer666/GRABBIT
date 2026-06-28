import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A button with gooey, physical deformation on press.
///
/// The button squishes vertically on press and springs back on release.
/// For destructive hold-to-confirm actions (Ban), the button grows slowly
/// over the hold period then commits with a full-body compress + release.
///
/// Visual feel: a soft, liquid body — like a jelly creature.  Not a spinner,
/// not a ripple alone — the button BODY physically reacts.
///
/// Usage — quick tap (Approve, Remove, primary actions):
/// ```dart
/// GooeyButton(
///   label: 'Approve',
///   color: KyuubiColors.lime,
///   onTap: _handleApprove,
/// )
/// ```
///
/// Usage — hold-to-confirm (Ban):
/// ```dart
/// GooeyButton(
///   label: 'Ban User',
///   color: KyuubiColors.coral,
///   requireHold: true,
///   holdDuration: const Duration(seconds: 2),
///   onConfirm: _executeBan,
/// )
/// ```
///
/// Respects [MediaQuery.disableAnimations]: plain ElevatedButton rendering.
class GooeyButton extends StatefulWidget {
  const GooeyButton({
    super.key,
    required this.label,
    this.color,
    this.onTap,
    this.onPressed,
    this.onConfirm,
    this.requireHold = false,
    this.holdDuration = const Duration(milliseconds: 1800),
    this.isLoading = false,
    this.isSuccess = false,
    this.icon,
    this.width,
    this.height = 52.0,
    this.minHeight,
  }) : assert(
          requireHold
              ? onConfirm != null
              : (onTap != null || onPressed != null || isLoading || isSuccess),
          'Provide onTap/onPressed for tap mode, onConfirm for hold mode',
        );

  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onPressed;
  final VoidCallback? onConfirm;
  final bool requireHold;
  final Duration holdDuration;
  final IconData? icon;
  final bool isLoading;
  final bool isSuccess;
  final double? width;
  final double height;
  final double? minHeight;

  /// Effective callback: [onPressed] takes precedence over [onTap].
  VoidCallback? get effectiveOnTap => onPressed ?? onTap;

  /// Effective height respects [minHeight] if provided.
  double get effectiveHeight => math.max(minHeight ?? 0, height);

  @override
  State<GooeyButton> createState() => _GooeyButtonState();
}

class _GooeyButtonState extends State<GooeyButton>
    with TickerProviderStateMixin {
  // Squish/bounce animation for tap feedback
  late final AnimationController _squishCtrl;
  late final Animation<double> _squishY; // scale Y: 1.0 → 0.88 → 1.05 → 1.0
  late final Animation<double> _squishX; // scale X: 1.0 → 1.06 → 0.97 → 1.0

  // Hold-fill animation
  late final AnimationController _holdCtrl;

  bool _pressing = false;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();

    _squishCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    // Vertical squish: compress then overshoot spring-back
    _squishY = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.87)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.87, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 45,
      ),
    ]).animate(_squishCtrl);

    // Horizontal counter-squish (conservation of volume feel)
    _squishX = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.07)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.07, end: 0.97)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.97, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 45,
      ),
    ]).animate(_squishCtrl);

    _holdCtrl = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    );
    _holdCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_confirmed) {
        _confirmed = true;
        _squishCtrl.forward(from: 0);
        HapticFeedback.heavyImpact();
        widget.onConfirm?.call();
      }
    });
  }

  @override
  void dispose() {
    _squishCtrl.dispose();
    _holdCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.requireHold) return;
    if (widget.isLoading || widget.isSuccess) return;
    _squishCtrl.forward(from: 0);
    widget.effectiveOnTap?.call();
  }

  void _onPressStart(PointerDownEvent _) {
    if (widget.isLoading || widget.isSuccess) return;
    setState(() => _pressing = true);
    if (widget.requireHold) {
      _confirmed = false;
      _holdCtrl.forward(from: 0);
      HapticFeedback.selectionClick();
    } else {
      _squishCtrl.forward(from: 0);
    }
  }

  void _onPressEnd(PointerUpEvent _) {
    setState(() => _pressing = false);
    if (widget.requireHold && !_confirmed) {
      _holdCtrl.stop();
      _holdCtrl.reverse();
    }
  }

  void _onPressCancel(PointerCancelEvent _) {
    setState(() => _pressing = false);
    if (widget.requireHold) {
      _holdCtrl.stop();
      _holdCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final effectiveColor = widget.color ?? Theme.of(context).colorScheme.primary;

    if (reduceMotion) {
      final h = widget.effectiveHeight;
      return SizedBox(
        width: widget.width,
        height: h,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: effectiveColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(h / 2),
            ),
          ),
          icon: widget.isLoading
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white,
                  ),
                )
              : widget.isSuccess
                  ? const Icon(Icons.check_rounded)
                  : widget.icon != null
                      ? Icon(widget.icon)
                      : const SizedBox.shrink(),
          label: Text(widget.label),
          onPressed: (widget.isLoading || widget.isSuccess || widget.requireHold)
              ? null
              : widget.effectiveOnTap,
        ),
      );
    }

    return Listener(
      onPointerDown: _onPressStart,
      onPointerUp: _onPressEnd,
      onPointerCancel: _onPressCancel,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_squishCtrl, _holdCtrl]),
          builder: (_, __) {
            // Hold-to-confirm: button swells slightly during hold
            final holdScale = 1.0 + _holdCtrl.value * 0.05;

            return Transform.scale(
              scaleX: _squishX.value * holdScale,
              scaleY: _squishY.value * holdScale,
              child: _GooeyButtonBody(
                label: widget.label,
                color: effectiveColor,
                icon: widget.icon,
                width: widget.width,
                height: widget.effectiveHeight,
                holdProgress: _holdCtrl.value,
                pressing: _pressing,
                isLoading: widget.isLoading,
                isSuccess: widget.isSuccess,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GooeyButtonBody extends StatelessWidget {
  const _GooeyButtonBody({
    required this.label,
    required this.color,
    required this.holdProgress,
    required this.pressing,
    required this.height,
    this.isLoading = false,
    this.isSuccess = false,
    this.icon,
    this.width,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final double? width;
  final double height;
  final double holdProgress;
  final bool pressing;
  final bool isLoading;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final radius = height / 2;
    return CustomPaint(
      painter: _GooeyPainter(
        color: color,
        holdProgress: holdProgress,
        pressing: pressing,
        borderRadius: radius,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ] else if (isSuccess) ...[
                const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ] else ...[
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
              // Hold progress arc on the right
              if (holdProgress > 0) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    value: holdProgress,
                    strokeWidth: 2,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GooeyPainter extends CustomPainter {
  _GooeyPainter({
    required this.color,
    required this.holdProgress,
    required this.pressing,
    required this.borderRadius,
  });

  final Color color;
  final double holdProgress;
  final bool pressing;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = borderRadius;
    final w = size.width;
    final h = size.height;

    // Gooey blob shape: slightly organic rounded rect
    // The edges breathe slightly based on hold progress
    final wobble = holdProgress * 3.0;
    final path = _buildGooeyPath(w, h, r, wobble);

    // Fill with a subtle vertical gradient for depth
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color,
          Color.lerp(color, Colors.black, 0.15)!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Hold fill overlay
    if (holdProgress > 0) {
      final fillPath = _buildGooeyPath(w * holdProgress, h, r, wobble);
      canvas.drawPath(
        fillPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill,
      );
    }

    // Subtle top highlight
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  Path _buildGooeyPath(double w, double h, double r, double wobble) {
    final rr = math.min(r, math.min(w / 2, h / 2));
    final path = Path();

    // Slightly organic: mid-edges bow out a touch when wobbling
    final bow = wobble * 0.4;

    path.moveTo(rr, 0);
    path.quadraticBezierTo(w / 2, -bow, w - rr, 0); // top edge bows up
    path.arcToPoint(Offset(w, rr), radius: Radius.circular(rr));
    path.quadraticBezierTo(w + bow, h / 2, w, h - rr); // right edge bows out
    path.arcToPoint(Offset(w - rr, h), radius: Radius.circular(rr));
    path.quadraticBezierTo(w / 2, h + bow, rr, h); // bottom bows down
    path.arcToPoint(Offset(0, h - rr), radius: Radius.circular(rr));
    path.quadraticBezierTo(-bow, h / 2, 0, rr); // left bows out
    path.arcToPoint(Offset(rr, 0), radius: Radius.circular(rr));
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(_GooeyPainter old) =>
      old.holdProgress != holdProgress || old.pressing != pressing;
}
