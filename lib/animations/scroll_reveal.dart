import 'package:flutter/material.dart';

/// Slides a widget in from below with a gentle fade — used when new queue
/// items appear, list results arrive, or Modmail threads load.
///
/// The motion is smooth and directional (upward entry), communicating
/// that content has arrived from a data source below.
///
/// Usage — individual item:
/// ```dart
/// ScrollReveal(
///   delay: Duration(milliseconds: i * 60), // stagger in a list
///   child: CaseCard(case: c),
/// )
/// ```
///
/// Usage — controller-driven (reveal on demand):
/// ```dart
/// final ctrl = ScrollRevealController();
/// ScrollReveal.controlled(controller: ctrl, child: ...)
/// ctrl.reveal(); // trigger later
/// ```
///
/// Respects [MediaQuery.disableAnimations]: child shown immediately.
class ScrollReveal extends StatefulWidget {
  /// Auto-plays on first build, with optional [delay] for staggering.
  const ScrollReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 340),
    this.slideOffset = 28.0,
    this.controller,
  });

  /// Controller-driven variant — does not auto-play; call [ScrollRevealController.reveal].
  const ScrollReveal.controlled({
    super.key,
    required this.child,
    required ScrollRevealController this.controller,
    this.duration = const Duration(milliseconds: 340),
    this.slideOffset = 28.0,
  }) : delay = Duration.zero;

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// How many logical pixels the child travels upward during the reveal.
  final double slideOffset;

  final ScrollRevealController? controller;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideOffset / 100), // fractional offset
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.controller != null) {
      widget.controller!._attach(this);
    } else {
      // Auto-play after delay
      Future.delayed(widget.delay, () {
        if (mounted) {
          final reduceMotion = MediaQuery.of(context).disableAnimations;
          if (reduceMotion) {
            _ctrl.value = 1.0;
          } else {
            _ctrl.forward();
          }
        }
      });
    }
  }

  void _reveal() {
    if (!mounted) return;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _ctrl.value = 1.0;
    } else {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        if (_ctrl.value >= 1.0) return child!;
        return FadeTransition(
          opacity: _fade,
          child: Transform.translate(
            offset: Offset(0, _slide.value.dy * 100),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Controller for [ScrollReveal.controlled].
class ScrollRevealController {
  _ScrollRevealState? _state;

  void _attach(_ScrollRevealState s) => _state = s;
  void _detach() => _state = null;

  /// Triggers the reveal animation.
  void reveal() => _state?._reveal();

  void dispose() => _detach();
}

// ── Convenience: auto-staggered list wrapper ──────────────────────────────────

/// Wraps a list of widgets so each reveals with a staggered delay.
///
/// ```dart
/// ScrollRevealList(
///   children: cases.map((c) => CaseCard(c)).toList(),
/// )
/// ```
class ScrollRevealList extends StatelessWidget {
  const ScrollRevealList({
    super.key,
    required this.children,
    this.staggerMs = 55,
    this.duration = const Duration(milliseconds: 320),
    this.slideOffset = 24.0,
  });

  final List<Widget> children;

  /// Delay between each child's reveal in milliseconds.
  final int staggerMs;

  final Duration duration;
  final double slideOffset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++)
          ScrollReveal(
            delay: Duration(milliseconds: i * staggerMs),
            duration: duration,
            slideOffset: slideOffset,
            child: children[i],
          ),
      ],
    );
  }
}
