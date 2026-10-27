// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:umbra/theme/tokens.dart';

void main() {
  group('Umbra Theme Tokens', () {
    test('SolColors accent is Indigo #4C2F9E', () {
      expect(SolColors.accent.value, equals(0xFF4C2F9E));
    });

    test('UmbraColors accent is Corona Amber #F59E0B', () {
      expect(UmbraColors.accent.value, equals(0xFFF59E0B));
    });

    test('Bubble radius is 18px', () {
      expect(UmbraComponentTokens.bubbleRadius, equals(18.0));
    });

    test('Bubble tail width is 20px', () {
      expect(UmbraComponentTokens.bubbleTailWidth, equals(20.0));
    });

    test('Bubble tail height is 18px', () {
      expect(UmbraComponentTokens.bubbleTailHeight, equals(18.0));
    });

    test('Bubble max width is 75%', () {
      expect(UmbraComponentTokens.bubbleMaxWidth, equals(0.75));
    });

    test('Input bar height is 56px', () {
      expect(UmbraComponentTokens.inputBarHeight, equals(56.0));
    });

    test('Nav bar height large is 96px', () {
      expect(UmbraComponentTokens.navBarHeightLarge, equals(96.0));
    });

    test('Nav bar height is 56px', () {
      expect(UmbraComponentTokens.navBarHeight, equals(56.0));
    });

    test('Nav title size is 28px', () {
      expect(UmbraComponentTokens.navTitleSize, equals(28.0));
    });

    test('Motion durations match design tokens', () {
      expect(UmbraMotion.durationFast.inMilliseconds, equals(150));
      expect(UmbraMotion.durationNormal.inMilliseconds, equals(200));
      expect(UmbraMotion.durationSlow.inMilliseconds, equals(300));
    });

    test('Eclipse wipe duration is 600ms', () {
      expect(UmbraMotion.eclipseWipeDuration.inMilliseconds, equals(600));
    });

    test('Spring easing curve matches design', () {
      expect(UmbraMotion.easeSpring, equals(const Cubic(0.34, 1.56, 0.64, 1)));
    });
  });

  group('Umbra Theme Mode', () {
    test('Theme modes are defined', () {
      expect(UmbraThemeMode.values.length, equals(3));
      expect(UmbraThemeMode.values, containsAll([
        UmbraThemeMode.sol,
        UmbraThemeMode.umbra,
        UmbraThemeMode.system,
      ]));
    });
  });
}
