// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'press_scale.dart';

class HaloPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const HaloPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    final on = onTap != null;
    return PressScale(
      label: label,
      onTap: onTap,
      scale: 0.96,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? colors.accent : colors.surfaceHover,
          borderRadius: BorderRadius.circular(13),
        ),
        child: ExcludeSemantics(
          child: Text(
            label,
            style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w600, color: on ? colors.accentOn : colors.textTertiary, height: 1.5, letterSpacing: 0),
          ),
        ),
      ),
    );
  }
}

class HaloGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool quiet;
  const HaloGhostButton({
    super.key,
    required this.label,
    required this.onTap,
    this.quiet = false,
  });

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return PressScale(
      label: label,
      onTap: onTap,
      scale: 0.96,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: quiet
              ? Border.all(color: colors.separator)
              : Border.all(color: colors.accent, width: 1),
        ),
        child: ExcludeSemantics(
          child: Text(
            label,
            style: quiet
                ? TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0)
                : TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w600, color: colors.accent, height: 1.5, letterSpacing: 0),
          ),
        ),
      ),
    );
  }
}
