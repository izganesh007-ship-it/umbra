// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra danger button for destructive actions

import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// A danger button for destructive actions (delete, wipe, leave, etc.)
class UmbraDangerButton extends StatelessWidget {
  const UmbraDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.enabled = true,
    this.fullWidth = false,
    this.style = UmbraDangerButtonStyle.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final List<String>? icon;
  final bool isLoading;
  final bool enabled;
  final bool fullWidth;
  final UmbraDangerButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    final bgColor = switch (style) {
      UmbraDangerButtonStyle.filled => colors.error,
      UmbraDangerButtonStyle.outlined => Colors.transparent,
      UmbraDangerButtonStyle.tonal => colors.error.withValues(alpha: 0.12),
    };

    final fgColor = switch (style) {
      UmbraDangerButtonStyle.filled => colors.errorOn,
      UmbraDangerButtonStyle.outlined => colors.error,
      UmbraDangerButtonStyle.tonal => colors.error,
    };

    final borderColor = switch (style) {
      UmbraDangerButtonStyle.filled => Colors.transparent,
      UmbraDangerButtonStyle.outlined => colors.error,
      UmbraDangerButtonStyle.tonal => colors.error.withValues(alpha: 0.3),
    };

    final isEnabled = enabled && !isLoading && onPressed != null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: isEnabled ? onPressed : null,
        child: AnimatedContainer(
          duration: UmbraMotion.durationFast,
          curve: UmbraMotion.easeOut,
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isEnabled ? bgColor : bgColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(UmbraRadius.lg),
            border: Border.all(
              color: isEnabled ? borderColor : borderColor.withValues(alpha: 0.5),
              width: style == UmbraDangerButtonStyle.filled ? 0 : 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(fgColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      StrokeIcon(
                        icon!,
                        size: 18,
                        color: fgColor,
                        stroke: 2,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontSans,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? fgColor : fgColor.withValues(alpha: 0.5),
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

enum UmbraDangerButtonStyle {
  filled,
  outlined,
  tonal,
}

/// A danger button row for settings (icon + label + button)
class UmbraDangerActionRow extends StatelessWidget {
  const UmbraDangerActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
    this.buttonStyle = UmbraDangerButtonStyle.filled,
  });

  final List<String> icon;
  final String title;
  final String? subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;
  final UmbraDangerButtonStyle buttonStyle;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.separatorStrong, width: 0.5),
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
                  Color.alphaBlend(colors.error.withValues(alpha: 0.10), colors.surface),
                  colors.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.error.withValues(alpha: 0.22),
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: StrokeIcon(
              icon,
              size: 22,
              color: colors.error,
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
                    color: colors.error,
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
          UmbraDangerButton(
            label: buttonLabel,
            onPressed: onPressed,
            style: buttonStyle,
          ),
        ],
      ),
    );
  }
}
