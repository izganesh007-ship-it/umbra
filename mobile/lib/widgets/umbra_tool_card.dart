// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra tool card for tools screen

import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'umbra_progress_bar.dart';

/// Tool card for the tools screen
class UmbraToolCard extends StatelessWidget {
  const UmbraToolCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor,
    this.iconBgColor,
    this.actions = const [],
    this.content,
    this.status,
    this.isWarning = false,
    this.isSuccess = false,
    this.isError = false,
  });

  final List<String> icon;
  final String title;
  final String description;
  final Color? iconColor;
  final Color? iconBgColor;
  final List<Widget> actions;
  final Widget? content;
  final Widget? status;
  final bool isWarning;
  final bool isSuccess;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    final effectiveIconColor = iconColor ?? _getIconColor(colors);
    final effectiveIconBgColor = iconBgColor ?? _getIconBgColor(colors);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(UmbraRadius.xl),
        border: Border.all(color: colors.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.alphaBlend(effectiveIconColor.withValues(alpha: 0.15), effectiveIconBgColor),
                      effectiveIconBgColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: effectiveIconColor.withValues(alpha: 0.22),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: StrokeIcon(
                  icon,
                  size: 24,
                  color: effectiveIconColor,
                  stroke: 1.9,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: UmbraTypography.fontSans,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        height: 1.2,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
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
                ),
              ),
              if (status != null) status!,
            ],
          ),
          // Optional content (progress, verification list, etc.)
          if (content != null) ...[
            const SizedBox(height: 16),
            content!,
          ],
          // Actions
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }

  Color _getIconColor(UmbraSemanticColors colors) {
    if (isError) return colors.error;
    if (isWarning) return colors.warning;
    if (isSuccess) return colors.success;
    return colors.accent;
  }

  Color _getIconBgColor(UmbraSemanticColors colors) {
    if (isError) return colors.errorSoft;
    if (isWarning) return colors.warningSoft;
    if (isSuccess) return colors.successSoft;
    return colors.surfaceElevated;
  }
}

/// Tool card header section (used in tools screen)
class UmbraToolCardHeader extends StatelessWidget {
  const UmbraToolCardHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor,
    this.iconBgColor,
    this.onTap,
  });

  final List<String> icon;
  final String title;
  final String description;
  final Color? iconColor;
  final Color? iconBgColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    final effectiveIconColor = iconColor ?? colors.accent;
    final effectiveIconBgColor = iconBgColor ?? colors.surfaceElevated;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(effectiveIconColor.withValues(alpha: 0.15), effectiveIconBgColor),
                  effectiveIconBgColor,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: effectiveIconColor.withValues(alpha: 0.22),
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: StrokeIcon(
              icon,
              size: 24,
              color: effectiveIconColor,
              stroke: 1.9,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: UmbraTypography.fontSans,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
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
            ),
          ),
          if (onTap != null)
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: colors.separatorStrong, width: 0.5),
              ),
              alignment: Alignment.center,
              child: StrokeIcon(
                const ['M9 5l7 7-7 7'],
                size: 14,
                color: colors.textPrimary,
                stroke: 1.9,
                pointing: true,
              ),
            ),
        ],
      ),
    );
  }
}

/// Tool card action button
class UmbraToolAction extends StatelessWidget {
  const UmbraToolAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final List<String>? icon;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    final bgColor = filled ? colors.accent : Colors.transparent;
    final fgColor = filled ? colors.accentOn : colors.accent;
    final borderColor = filled ? Colors.transparent : colors.accent.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 42,
        padding: EdgeInsets.symmetric(horizontal: filled ? 16 : 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(UmbraRadius.lg),
          border: filled ? null : Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              StrokeIcon(icon!, size: 17, color: fgColor, stroke: 1.9),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: UmbraTypography.fontSans,
                fontSize: 13.5,
                fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
                color: fgColor,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
