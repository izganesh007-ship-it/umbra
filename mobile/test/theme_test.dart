// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra theme system test

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import '../lib/theme/tokens.dart';
import '../lib/theme/umbra_theme.dart';

void main() {
  group('Umbra Theme Tokens', () {
    test('SolColors has correct accent color', () {
      expect(SolColors.accent, equals(const Color(0xFF4C2F9E)));
    });

    test('UmbraColors has correct accent color', () {
      expect(UmbraColors.accent, equals(const Color(0xFFF59E0B)));
    });

    test('Typography constants are correct', () {
      expect(UmbraTypography.textBase, equals(14));
      expect(UmbraTypography.textXl, equals(20));
      expect(UmbraTypography.fontSans, equals('InterVariable'));
    });

    test('Spacing constants are correct', () {
      expect(UmbraSpacing.space4, equals(16));
      expect(UmbraSpacing.space6, equals(24));
    });

    test('Radius constants are correct', () {
      expect(UmbraRadius.radius2xl, equals(18));
      expect(UmbraRadius.full, equals(9999));
    });

    test('Component tokens are correct', () {
      expect(UmbraComponentTokens.bubbleRadius, equals(18));
      expect(UmbraComponentTokens.bubbleTailWidth, equals(20));
      expect(UmbraComponentTokens.bubbleTailHeight, equals(18));
      expect(UmbraComponentTokens.bubbleMaxWidth, equals(0.75));
      expect(UmbraComponentTokens.inputBarHeight, equals(56));
      expect(UmbraComponentTokens.navBarHeightLarge, equals(96));
      expect(UmbraComponentTokens.navTitleSize, equals(28));
    });
  });

  group('Umbra Semantic Colors', () {
    test('SolSemanticColors provides correct colors', () {
      final colors = SolSemanticColors();
      expect(colors.accent, equals(SolColors.accent));
      expect(colors.surface, equals(SolColors.surface));
      expect(colors.bubbleIncoming, equals(SolColors.bubbleIncoming));
      expect(colors.bubbleOutgoing, equals(SolColors.bubbleOutgoing));
    });

    test('UmbraSemanticColorsImpl provides correct colors', () {
      final colors = UmbraSemanticColorsImpl();
      expect(colors.accent, equals(UmbraColors.accent));
      expect(colors.surface, equals(UmbraColors.surface));
      expect(colors.bubbleIncoming, equals(UmbraColors.bubbleIncoming));
      expect(colors.bubbleOutgoing, equals(UmbraColors.bubbleOutgoing));
    });
  });

  group('Umbra Motion', () {
    test('Durations are correct', () {
      expect(UmbraMotion.durationFast, equals(const Duration(milliseconds: 150)));
      expect(UmbraMotion.durationNormal, equals(const Duration(milliseconds: 200)));
      expect(UmbraMotion.durationSlow, equals(const Duration(milliseconds: 300)));
      expect(UmbraMotion.eclipseWipeDuration, equals(const Duration(milliseconds: 600)));
    });

    test('Curves are defined', () {
      expect(UmbraMotion.easeSpring, isA<Cubic>());
      expect(UmbraMotion.easeOut, isA<Cubic>());
    });
  });

  group('buildUmbraThemeData', () {
    test('Builds light theme correctly', () {
      final theme = buildUmbraThemeData(isLight: true, reduceMotion: false);
      expect(theme.colorScheme.brightness, equals(Brightness.light));
      expect(theme.colorScheme.primary, equals(SolColors.accent));
      expect(theme.scaffoldBackgroundColor, equals(SolColors.surface));
    });

    test('Builds dark theme correctly', () {
      final theme = buildUmbraThemeData(isLight: false, reduceMotion: false);
      expect(theme.colorScheme.brightness, equals(Brightness.dark));
      expect(theme.colorScheme.primary, equals(UmbraColors.accent));
      expect(theme.scaffoldBackgroundColor, equals(UmbraColors.surface));
    });

    test('Reduced motion affects animations', () {
      final theme = buildUmbraThemeData(isLight: true, reduceMotion: true);
      // When reduceMotion is true, page transitions should be instant
      expect(theme.pageTransitionsTheme, isA<PageTransitionsTheme>());
    });
  });
}
