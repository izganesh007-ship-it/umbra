// SPDX-License-Identifier: GPL-3.0-or-later
// the toggle: an amber pill and a thumb that slides with a little overshoot,
// to match the rest of the app rather than Material.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

class HaloSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const HaloSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    final on = value;
    final enabled = onChanged != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onChanged!(!on);
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: AnimatedContainer(
          duration: const UmbraMotion.durationNormal,
          curve: UmbraMotion.easeOut,
          width: 46,
          height: 26,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: on ? colors.accent : colors.surfaceHover,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: on ? colors.accent : colors.separatorStrong,
              width: 0.6,
            ),
          ),
          child: AnimatedAlign(
            duration: const UmbraMotion.durationNormal,
            curve: Curves.easeOutBack,
            alignment: on
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? colors.accentOn : colors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
