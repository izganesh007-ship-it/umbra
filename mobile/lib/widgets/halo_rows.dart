// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../theme/theme.dart';

class HaloSection extends StatelessWidget {
  final String label;
  const HaloSection(this.label, {super.key});
  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 4, 8),
      child: Text(
        label,
        style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10.5, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.06),
      ),
    );
  }
}

// one rounded surface holding a section's rows, a hairline between each
class HaloGroup extends StatelessWidget {
  final List<Widget> children;
  final bool rose;
  const HaloGroup({super.key, required this.children, this.rose = false});
  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    final line = rose
        ? colors.error.withValues(alpha: 0.35)
        : colors.separator;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: rose
            ? colors.error.withValues(alpha: 0.05)
            : colors.surfaceElevated,
        borderRadius: BorderRadius.circular(UmbraRadius.xl),
        border: Border.all(color: line, width: 0.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 58),
                child: Container(height: 0.5, color: line),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class HaloRow extends StatelessWidget {
  final String label;
  final String? value;
  // one plain line under the label saying what the switch does
  final String? hint;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool rose;
  const HaloRow({
    super.key,
    required this.label,
    this.value,
    this.hint,
    this.onTap,
    this.icon,
    this.rose = false,
  });

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    // once the 14pt label renders past ~19 two columns stop fitting on a
    // phone, so a long value goes under the label instead of wrapping
    final v = value ?? '';
    final stacked =
        v.length > 16 || MediaQuery.of(context).textScaler.scale(14) > 19;
    final fg = rose ? colors.error : colors.textPrimary;
    final tile = rose
        ? colors.error.withValues(alpha: 0.12)
        : colors.accentSoft;
    final ink = rose ? colors.error : colors.accent;
    return InkWell(
      onTap: onTap,
      splashColor: ink.withValues(alpha: 0.08),
      highlightColor: ink.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tile,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(icon ?? Icons.circle_outlined, size: 17, color: ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w400, color: fg, height: 1.5, letterSpacing: 0)),
                  if (hint != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: 3,
                        end: 10,
                      ),
                      child: Text(
                        hint!,
                        style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10.5, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
                      ),
                    ),
                  if (v.isNotEmpty && stacked)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: 4,
                        end: 10,
                      ),
                      child: Text(
                        v,
                        style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
                      ),
                    ),
                ],
              ),
            ),
            if (v.isNotEmpty && !stacked) ...[
              const SizedBox(width: 8),
              Text(v, style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0)),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                color: rose ? ink : colors.textTertiary,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
