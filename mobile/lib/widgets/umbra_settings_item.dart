// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra settings item: icon, title, subtitle, trailing (chevron/toggle/value)

import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// A settings list item with icon, title, subtitle, and trailing content.
class UmbraSettingsItem extends StatelessWidget {
  const UmbraSettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    this.isWarning = false,
    this.isSuccess = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
  });

  /// The leading icon (SVG path strings for StrokeIcon)
  final List<String> icon;

  /// The main title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Optional trailing widget (chevron, toggle, value text, etc.)
  final Widget? trailing;

  /// Tap callback - makes the item behave like a button
  final VoidCallback? onTap;

  /// Whether this is a destructive action (red icon)
  final bool isDestructive;

  /// Whether this is a warning action (amber icon)
  final bool isWarning;

  /// Whether this is a success action (green icon)
  final bool isSuccess;

  /// Internal padding
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    final iconColor = isDestructive
        ? colors.error
        : isWarning
            ? colors.warning
            : isSuccess
                ? colors.success
                : colors.accent;

    final tileColor = isDestructive
        ? colors.error.withValues(alpha: 0.08)
        : isWarning
            ? colors.warning.withValues(alpha: 0.08)
            : isSuccess
                ? colors.success.withValues(alpha: 0.08)
                : colors.surface;

    final borderColor = isDestructive
        ? colors.error.withValues(alpha: 0.3)
        : isWarning
            ? colors.warning.withValues(alpha: 0.3)
            : isSuccess
                ? colors.success.withValues(alpha: 0.3)
                : colors.separatorStrong;

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: subtitle != null ? '$title. $subtitle' : title,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tileColor,
            border: Border(
              bottom: BorderSide(color: borderColor, width: 0.5),
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
                      Color.alphaBlend(iconColor.withValues(alpha: 0.10), tileColor),
                      tileColor,
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
              trailing ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A chevron trailing widget for navigation items
class UmbraSettingsChevron extends StatelessWidget {
  const UmbraSettingsChevron({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Container(
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
    );
  }
}

/// A value text trailing widget (e.g., "On", "Off", "English")
class UmbraSettingsValue extends StatelessWidget {
  const UmbraSettingsValue({
    super.key,
    required this.value,
    this.style,
  });

  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Text(
      value,
      style: style ??
          TextStyle(
            fontFamily: UmbraTypography.fontMono,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colors.textTertiary,
            letterSpacing: 0.12,
          ),
    );
  }
}

/// A section header for settings groups
class UmbraSettingsSection extends StatelessWidget {
  const UmbraSettingsSection({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.fromLTRB(22, 24, 22, 8),
  });

  final String title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Padding(
      padding: padding,
      child: Text(
        title,
        style: TextStyle(
          fontFamily: UmbraTypography.fontMono,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colors.textTertiary,
          letterSpacing: 0.14,
        ),
      ),
    );
  }
}
