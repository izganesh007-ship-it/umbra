// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra swipe-to-reply widget - swipe right on a bubble to reply

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import '../theme/umbra_theme.dart';

/// Swipe-to-reply widget for message bubbles
class UmbraSwipeToReply extends StatefulWidget {
  const UmbraSwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
  });

  final Widget child;
  final VoidCallback onReply;

  @override
  State<UmbraSwipeToReply> createState() => _UmbraSwipeToReplyState();
}

class _UmbraSwipeToReplyState extends State<UmbraSwipeToReply>
    with SingleTickerProviderStateMixin {
  double _dx = 0;
  bool _armed = false;
  static const double _trigger = 56;
  static const double _max = 80;

  late final AnimationController _spring;
  Animation<double> _back = const AlwaysStoppedAnimation(0);

  @override
  void initState() {
    super.initState();
    _spring = AnimationController(
      vsync: this,
      duration: UmbraMotion.durationNormal,
    );
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _settle() {
    _back = Tween(begin: _dx, end: 0.0).animate(
      CurvedAnimation(parent: _spring, curve: UmbraMotion.easeOut),
    )..addListener(() {
        if (mounted) {
          setState(() => _dx = _back.value);
        }
      });
    _spring
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    final colors = UmbraTheme.colorsOf(context);
    final reduceMotion = UmbraTheme.of(context).reduceMotion;

    final progress = (_dx / _trigger).clamp(0.0, 1.0);
    // the reply arrow sits at the start edge: a swipe away from it, to the
    // right, or to the left in a right-to-left language
    final way = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) {
        if (_spring.isAnimating) return;
        var nx = _dx + way * d.delta.dx;
        if (nx < 0) nx = 0;
        if (nx > _trigger) nx = _trigger + (nx - _trigger) * 0.35;
        if (nx > _max) nx = _max;
        final wasArmed = _armed;
        _armed = nx >= _trigger;
        if (_armed && !wasArmed) HapticFeedback.selectionClick();
        setState(() => _dx = nx);
      },
      onHorizontalDragEnd: (_) {
        if (_armed) widget.onReply();
        _armed = false;
        _settle();
      },
      child: Stack(
        children: [
          PositionedDirectional(
            start: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: progress,
                duration: reduceMotion ? Duration.zero : UmbraMotion.durationFast,
                child: Transform.scale(
                  scale: 0.6 + 0.4 * progress,
                  child: Icon(
                    Icons.reply_rounded,
                    size: 20,
                    color: colors.accent,
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(way * _dx, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
