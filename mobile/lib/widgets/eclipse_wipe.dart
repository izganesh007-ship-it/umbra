// SPDX-License-Identifier: GPL-3.0-or-later
// Eclipse Wipe transition widget - Radial theme transition (600ms spring)

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/umbra_theme.dart';

/// A widget that performs a radial "eclipse" wipe transition when theme changes.
/// Uses a spring curve (cubic-bezier(0.34, 1.56, 0.64, 1)) for 600ms duration.
class EclipseWipe extends StatefulWidget {
  final Widget child;
  final UmbraThemeController controller;
  final Duration? duration;
  final Curve? curve;

  const EclipseWipe({
    super.key,
    required this.child,
    required this.controller,
    this.duration,
    this.curve,
  });

  @override
  State<EclipseWipe> createState() => _EclipseWipeState();
}

class _EclipseWipeState extends State<EclipseWipe> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Offset? _wipeCenter;
  bool _isWiping = false;
  bool _targetIsLight = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration ?? UmbraMotion.eclipseWipeDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.curve ?? UmbraMotion.easeSpring,
    );

    // Listen for theme changes
    widget.controller.addListener(_onThemeChanged);
  }

  @override
  void didUpdateWidget(covariant EclipseWipe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onThemeChanged);
      widget.controller.addListener(_onThemeChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onThemeChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    final controller = widget.controller;
    if (controller.isWiping && controller.wipeCenter != null) {
      setState(() {
        _wipeCenter = controller.wipeCenter;
        _targetIsLight = controller.isLight;
        _isWiping = true;
      });
      _animationController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _isWiping = false;
            _wipeCenter = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isWiping || _wipeCenter == null) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _EclipseWipePainter(
            progress: _animation.value,
            center: _wipeCenter!,
            isLight: _targetIsLight,
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Painter for the radial eclipse wipe effect
class _EclipseWipePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Offset center;
  final bool isLight;

  _EclipseWipePainter({
    required this.progress,
    required this.center,
    required this.isLight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final maxRadius = _calculateMaxRadius(size);
    final currentRadius = maxRadius * progress;

    // Create a circular clip path
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: currentRadius));

    // The new theme color expands from center
    final paint = Paint()
      ..color = isLight
          ? const Color(0xFFF5F1EA) // Sol paper
          : const Color(0xFF0E0F12); // Umbra paper

    // Use a blend mode to create the wipe effect
    canvas.saveLayer(null, Paint()..blendMode = BlendMode.srcOver);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  double _calculateMaxRadius(Size size) {
    // Calculate the maximum radius needed to cover the entire screen
    final corners = [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];

    double maxDist = 0;
    for (final corner in corners) {
      final dist = (corner - center).distance;
      if (dist > maxDist) maxDist = dist;
    }

    return maxDist;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _EclipseWipePainter &&
        oldDelegate.progress != progress &&
        oldDelegate.center != center &&
        oldDelegate.isLight != isLight;
  }
}

/// A simpler, more performant version using a radial gradient overlay
class EclipseWipeOverlay extends StatelessWidget {
  final Widget child;
  final UmbraThemeController controller;
  final Duration? duration;
  final Curve? curve;

  const EclipseWipeOverlay({
    super.key,
    required this.child,
    required this.controller,
    this.duration,
    this.curve,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller]),
      builder: (context, _) {
        if (!controller.isWiping || controller.wipeCenter == null) {
          return child;
        }

        return Stack(
          children: [
            child,
            CustomPaint(
              painter: _RadialWipePainter(
                progress: controller.wipeProgress,
                center: controller.wipeCenter!,
                isLight: controller.isLight,
                duration: duration ?? UmbraMotion.eclipseWipeDuration,
              ),
              size: Size.infinite,
            ),
          ],
        );
      },
    );
  }
}

class _RadialWipePainter extends CustomPainter {
  final double progress;
  final Offset center;
  final bool isLight;
  final Duration duration;

  _RadialWipePainter({
    required this.progress,
    required this.center,
    required this.isLight,
    required this.duration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final maxRadius = _calculateMaxRadius(size);
    final currentRadius = maxRadius * progress;

    // Draw the new theme background expanding from center
    final rect = Rect.fromCircle(center: center, radius: currentRadius);

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: isLight
          ? [
              const Color(0xFFF5F1EA), // Sol paper
              const Color(0xFFF5F1EA).withValues(alpha: 0),
            ]
          : [
              const Color(0xFF0E0F12), // Umbra paper
              const Color(0xFF0E0F12).withValues(alpha: 0),
            ],
      stops: const [0.0, 1.0],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawCircle(center, currentRadius, paint);
  }

  double _calculateMaxRadius(Size size) {
    final corners = [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];

    double maxDist = 0;
    for (final corner in corners) {
      final dist = (corner - center).distance;
      if (dist > maxDist) maxDist = dist;
    }

    return maxDist;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _RadialWipePainter &&
        oldDelegate.progress != progress &&
        oldDelegate.center != center &&
        oldDelegate.isLight != isLight;
  }
}

/// Extension to easily add eclipse wipe to any widget
extension EclipseWipeExtension on Widget {
  Widget withEclipseWipe(UmbraThemeController controller) {
    return EclipseWipeOverlay(
      controller: controller,
      child: this,
    );
  }
}
