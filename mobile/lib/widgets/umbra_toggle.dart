// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra animated toggle switch matching components.css .toggle

import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// An animated toggle switch matching the design system toggle style
class UmbraToggle extends StatefulWidget {
  const UmbraToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.size = UmbraToggleSize.md,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final UmbraToggleSize size;

  @override
  State<UmbraToggle> createState() => _UmbraToggleState();
}

enum UmbraToggleSize {
  sm,  // 36x20
  md,  // 44x24
  lg,  // 52x28
}

class _UmbraToggleState extends State<UmbraToggle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: UmbraMotion.durationFast,
      value: widget.value ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant UmbraToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final reduceMotion = UmbraTheme.of(context).reduceMotion;

    final (trackWidth, trackHeight, thumbSize, thumbOffset) = switch (widget.size) {
      UmbraToggleSize.sm => (36.0, 20.0, 16.0, 2.0),
      UmbraToggleSize.md => (44.0, 24.0, 20.0, 2.0),
      UmbraToggleSize.lg => (52.0, 28.0, 24.0, 2.0),
    };

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = reduceMotion ? (_controller.value > 0.5 ? 1.0 : 0.0) : _controller.value;

        // Interpolate track color
        final trackColor = Color.lerp(
          colors.surfaceHover,
          colors.accent,
          t,
        )!;

        // Interpolate border color
        final borderColor = Color.lerp(
          colors.separator,
          colors.accent,
          t,
        )!;

        // Calculate thumb position
        final thumbX = thumbOffset + t * (trackWidth - thumbSize - 2 * thumbOffset);

        return Semantics(
          toggled: widget.value,
          enabled: widget.enabled,
          child: GestureDetector(
            onTap: widget.enabled
                ? () {
                    widget.onChanged(!widget.value);
                    HapticFeedback.selectionClick();
                  }
                : null,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: reduceMotion ? Duration.zero : UmbraMotion.durationFast,
              curve: reduceMotion ? Curves.linear : UmbraMotion.easeSpring,
              width: trackWidth,
              height: trackHeight,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(trackHeight / 2),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Stack(
                children: [
                  // Thumb
                  Positioned(
                    left: thumbX,
                    top: thumbOffset,
                    child: AnimatedContainer(
                      duration: reduceMotion ? Duration.zero : UmbraMotion.durationFast,
                      curve: reduceMotion ? Curves.linear : UmbraMotion.easeSpring,
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadowSm.first.color,
                            blurRadius: colors.shadowSm.first.blurRadius,
                            offset: colors.shadowSm.first.offset,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Focus ring (when enabled and focused)
                  if (widget.enabled)
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: reduceMotion ? Duration.zero : UmbraMotion.durationFast,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(trackHeight / 2),
                          border: Border.all(
                            color: t > 0.5
                                ? colors.accent.withValues(alpha: 0.5)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A toggle row that combines a settings item with a toggle
class UmbraToggleRow extends StatelessWidget {
  const UmbraToggleRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.isDestructive = false,
  });

  final List<String> icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final iconColor = isDestructive ? colors.error : colors.accent;

    return Semantics(
      toggled: value,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.separatorStrong,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.alphaBlend(iconColor.withValues(alpha: 0.10), colors.surface),
                      colors.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.22),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: StrokeIcon(
                  icon,
                  size: 22,
                  color: iconColor,
                  stroke: 1.9,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontSans,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? colors.error : colors.textPrimary,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontFamily: UmbraTypography.fontSans,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: colors.textSecondary,
                          height: 1.5,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              UmbraToggle(
                value: value,
                onChanged: onChanged,
                enabled: enabled,
                size: UmbraToggleSize.md,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
