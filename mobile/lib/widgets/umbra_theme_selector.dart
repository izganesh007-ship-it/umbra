// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra theme selector: Sol/Umbra preview cards with bubble samples

import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Theme mode selector with preview cards showing bubble samples
class UmbraThemeSelector extends StatelessWidget {
  const UmbraThemeSelector({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  final UmbraThemeMode selectedMode;
  final ValueChanged<UmbraThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appearance',
          style: TextStyle(
            fontFamily: UmbraTypography.fontMono,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: colors.textTertiary,
            letterSpacing: 0.14,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ThemeOption(
                mode: UmbraThemeMode.sol,
                isSelected: selectedMode == UmbraThemeMode.sol,
                onTap: () => onChanged(UmbraThemeMode.sol),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ThemeOption(
                mode: UmbraThemeMode.umbra,
                isSelected: selectedMode == UmbraThemeMode.umbra,
                onTap: () => onChanged(UmbraThemeMode.umbra),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final UmbraThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    final isSol = mode == UmbraThemeMode.sol;

    // Preview colors based on theme
    final previewBg = isSol ? const Color(0xFFFFFFFF) : const Color(0xFF0A0A0A);
    final previewSurface = isSol ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
    final previewAccent = isSol ? const Color(0xFF4C2F9E) : const Color(0xFFF59E0B);
    final previewBubbleIn = isSol ? const Color(0xFFE8E8ED) : const Color(0xFF2A2A2E);
    final previewBubbleOut = previewAccent;
    final previewTextPrimary = isSol ? const Color(0xFF1D1D1F) : const Color(0xFFFFFFFF);
    final previewTextSecondary = isSol ? const Color(0xFF6E6E73) : const Color(0xFF8E8E93);

    final borderColor = isSelected
        ? previewAccent
        : colors.separator;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: UmbraMotion.durationNormal,
        curve: UmbraMotion.easeSpring,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: previewSurface,
          borderRadius: BorderRadius.circular(UmbraRadius.xl),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: previewAccent.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: -8,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: previewAccent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isSol ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: isSol ? const Color(0xFF4C2F9E) : const Color(0xFF0A0A0A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSol ? 'Sol' : 'Umbra',
                        style: TextStyle(
                          fontFamily: UmbraTypography.fontSerif,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: previewTextPrimary,
                          fontStyle: FontStyle.italic,
                          height: 1.05,
                          letterSpacing: -0.015,
                        ),
                      ),
                      Text(
                        isSol ? 'Light' : 'Dark',
                        style: TextStyle(
                          fontFamily: UmbraTypography.fontMono,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: previewTextSecondary,
                          letterSpacing: 0.12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: previewAccent,
                    size: 22,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Bubble preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: previewBg,
                borderRadius: BorderRadius.circular(UmbraRadius.lg),
                border: Border.all(
                  color: isSol
                      ? const Color(0xFFE0E0E0)
                      : const Color(0xFF2A2A2E),
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  // Incoming bubble
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: previewBubbleIn,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(UmbraComponentTokens.bubbleRadius),
                              topRight: Radius.circular(UmbraComponentTokens.bubbleRadius),
                              bottomRight: Radius.circular(UmbraComponentTokens.bubbleRadius),
                              bottomLeft: const Radius.circular(4), // Tail
                            ),
                          ),
                          child: Text(
                            'Hey, how are you?',
                            style: TextStyle(
                              fontFamily: UmbraTypography.fontSans,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: isSol ? const Color(0xFF1D1D1F) : const Color(0xFFFFFFFF),
                              height: 1.4,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Space for outgoing
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Outgoing bubble
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: previewBubbleOut,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(UmbraComponentTokens.bubbleRadius),
                              topRight: Radius.circular(UmbraComponentTokens.bubbleRadius),
                              bottomLeft: Radius.circular(UmbraComponentTokens.bubbleRadius),
                              bottomRight: const Radius.circular(4), // Tail
                            ),
                          ),
                          child: Text(
                            'I\'m doing great!',
                            style: TextStyle(
                              fontFamily: UmbraTypography.fontSans,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: isSol ? const Color(0xFFFFFFFF) : const Color(0xFF0A0A0A),
                              height: 1.4,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              isSol
                  ? 'Bright, clean, and calm. Perfect for daylight.'
                  : 'Deep, private, and easy on the eyes at night.',
              style: TextStyle(
                fontFamily: UmbraTypography.fontSans,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: previewTextSecondary,
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
