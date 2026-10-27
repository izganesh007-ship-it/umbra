// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra accent color grid selector

import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Accent color grid selector with swatches
class UmbraAccentGrid extends StatelessWidget {
  const UmbraAccentGrid({
    super.key,
    required this.selectedAccent,
    required this.onChanged,
    this.mode = UmbraThemeMode.umbra, // Show accents for this mode
  });

  final UmbraAccent selectedAccent;
  final ValueChanged<UmbraAccent> onChanged;
  final UmbraThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    final accents = mode == UmbraThemeMode.sol ? UmbraAccent.solAccents : UmbraAccent.umbraAccents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accent Color',
          style: TextStyle(
            fontFamily: UmbraTypography.fontMono,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: colors.textTertiary,
            letterSpacing: 0.14,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: accents.map((accent) {
            final isSelected = accent == selectedAccent;
            return _AccentOption(
              accent: accent,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(accent);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Predefined accent colors for Sol and Umbra modes
enum UmbraAccent {
  // Sol accents
  indigo,      // #4C2F9E - Default Sol
  blue,        // #007AFF
  purple,      // #AF52DE
  pink,        // #FF2D92
  teal,        // #34C759
  orange,      // #FF9F0A

  // Umbra accents
  amber,       // #F59E0B - Default Umbra
  gold,        // #FFD700
  coral,       // #FF6B6B
  emerald,     // #10B981
  violet,      // #8B5CF6
  rose,        // #F43F5E;

  static const List<UmbraAccent> solAccents = [
    UmbraAccent.indigo,
    UmbraAccent.blue,
    UmbraAccent.purple,
    UmbraAccent.pink,
    UmbraAccent.teal,
    UmbraAccent.orange,
  ];

  static const List<UmbraAccent> umbraAccents = [
    UmbraAccent.amber,
    UmbraAccent.gold,
    UmbraAccent.coral,
    UmbraAccent.emerald,
    UmbraAccent.violet,
    UmbraAccent.rose,
  ];

  Color get color {
    return switch (this) {
      UmbraAccent.indigo => const Color(0xFF4C2F9E),
      UmbraAccent.blue => const Color(0xFF007AFF),
      UmbraAccent.purple => const Color(0xFFAF52DE),
      UmbraAccent.pink => const Color(0xFFFF2D92),
      UmbraAccent.teal => const Color(0xFF34C759),
      UmbraAccent.orange => const Color(0xFFFF9F0A),
      UmbraAccent.amber => const Color(0xFFF59E0B),
      UmbraAccent.gold => const Color(0xFFFFD700),
      UmbraAccent.coral => const Color(0xFFFF6B6B),
      UmbraAccent.emerald => const Color(0xFF10B981),
      UmbraAccent.violet => const Color(0xFF8B5CF6),
      UmbraAccent.rose => const Color(0xFFF43F5E),
    };
  }

  String get label {
    return switch (this) {
      UmbraAccent.indigo => 'Indigo',
      UmbraAccent.blue => 'Blue',
      UmbraAccent.purple => 'Purple',
      UmbraAccent.pink => 'Pink',
      UmbraAccent.teal => 'Teal',
      UmbraAccent.orange => 'Orange',
      UmbraAccent.amber => 'Amber',
      UmbraAccent.gold => 'Gold',
      UmbraAccent.coral => 'Coral',
      UmbraAccent.emerald => 'Emerald',
      UmbraAccent.violet => 'Violet',
      UmbraAccent.rose => 'Rose',
    };
  }
}

class _AccentOption extends StatelessWidget {
  const _AccentOption({
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  final UmbraAccent accent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final accentColor = accent.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: UmbraMotion.durationFast,
        curve: UmbraMotion.easeSpring,
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: accentColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colors.textPrimary : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: isSelected ? 16 : 8,
              spreadRadius: isSelected ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isSelected
            ? Center(
                child: Icon(
                  Icons.check_rounded,
                  color: _isLightColor(accentColor) ? const Color(0xFF1D1D1F) : const Color(0xFFFFFFFF),
                  size: 28,
                ),
              )
            : null,
      ),
    );
  }

  bool _isLightColor(Color color) {
    // Calculate relative luminance
    final r = color.r / 255.0;
    final g = color.g / 255.0;
    final b = color.b / 255.0;

    final luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    return luminance > 0.5;
  }
}
