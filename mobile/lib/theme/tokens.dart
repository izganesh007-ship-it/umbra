// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra design tokens ported from tokens.css
// Light theme: Sol (default) | Dark theme: Umbra

import 'dart:ui';

import 'package:flutter/material.dart';

/// Theme mode for Umbra app
enum UmbraThemeMode { sol, umbra, system }

/// Color tokens for Sol (light) theme
class SolColors {
  // Base neutrals
  static const Color ink = Color(0xFF1C1813);
  static const Color paper = Color(0xFFF5F1EA);
  static const Color surface = Color(0xFFEBE4D5);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceHover = Color(0xFFE2DAC8);
  static const Color separator = Color(0xFFCBBFA8);
  static const Color separatorStrong = Color(0xFFBAAC90);

  // Text hierarchy
  static const Color textPrimary = Color(0xFF1C1813);
  static const Color textSecondary = Color(0xFF57503F);
  static const Color textTertiary = Color(0xFF554E44);
  static const Color textMuted = Color(0xFF9B9486);
  static const Color textInverse = Color(0xFFF5F1EA);

  // Accent - Indigo
  static const Color accent = Color(0xFF4C2F9E);
  static const Color accentHover = Color(0xFF3D267E);
  static const Color accentSoft = Color(0x1F4C2F9E);
  static const Color accentOn = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF0E9D6C);
  static const Color successSoft = Color(0x1F0E9D6C);
  static const Color warning = Color(0xFFB66A07);
  static const Color warningSoft = Color(0x1FB66A07);
  static const Color error = Color(0xFFCE3F84);
  static const Color errorSoft = Color(0x1FCE3F84);

  // Bubbles
  static const Color bubbleIncoming = Color(0xFFF5F1EA);
  static const Color bubbleIncomingText = Color(0xFF1C1813);
  static const Color bubbleOutgoing = Color(0xFF4C2F9E);
  static const Color bubbleOutgoingText = Color(0xFFFFFFFF);
  static const Color bubbleFrosted = Color(0xD9EBE4D5); // 85% opacity
  static const Color bubbleFrostedBorder = Color(0x99CBBFA8); // 60% opacity

  // Input bar
  static const Color inputBg = Color(0xE6FFFFFF); // 90% opacity
  static const Color inputBorder = Color(0x80CBBFA8); // 50% opacity
  static const Color inputFocusBorder = Color(0xFF4C2F9E);

  // Navigation bar
  static const Color navBg = Color(0xD9FFFFFF); // 85% opacity
  static const Color navBorder = Color(0x66CBBFA8); // 40% opacity
  static const String navBlur = 'saturate(180%) blur(20px)';
}

/// Color tokens for Umbra (dark) theme
class UmbraColors {
  // Base neutrals
  static const Color ink = Color(0xFFF5F1EA);
  static const Color paper = Color(0xFF0E0F12);
  static const Color surface = Color(0xFF161310);
  static const Color surfaceElevated = Color(0xFF201C17);
  static const Color surfaceHover = Color(0xFF2A251F);
  static const Color separator = Color(0xFF2F2922);
  static const Color separatorStrong = Color(0xFF3D3629);

  // Text hierarchy
  static const Color textPrimary = Color(0xFFF5F1EA);
  static const Color textSecondary = Color(0xFFC8C0B5);
  static const Color textTertiary = Color(0xFFA79E92);
  static const Color textMuted = Color(0xFF7D766A);
  static const Color textInverse = Color(0xFF161310);

  // Accent - Corona Amber
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentHover = Color(0xFFD97706);
  static const Color accentSoft = Color(0x24F59E0B);
  static const Color accentOn = Color(0xFF1A0F04);

  // Status colors
  static const Color success = Color(0xFF34D399);
  static const Color successSoft = Color(0x2434D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0x24F59E0B);
  static const Color error = Color(0xFFF472B6);
  static const Color errorSoft = Color(0x24F472B6);

  // Bubbles
  static const Color bubbleIncoming = Color(0xFF3B332A);
  static const Color bubbleIncomingText = Color(0xFFF5F1EA);
  static const Color bubbleOutgoing = Color(0xFFF59E0B);
  static const Color bubbleOutgoingText = Color(0xFF1A0F04);
  static const Color bubbleFrosted = Color(0xD9201C17); // 85% opacity
  static const Color bubbleFrostedBorder = Color(0x993D3629); // 60% opacity

  // Input bar
  static const Color inputBg = Color(0xE6161310); // 90% opacity
  static const Color inputBorder = Color(0x803D3629); // 50% opacity
  static const Color inputFocusBorder = Color(0xFFF59E0B);

  // Navigation bar
  static const Color navBg = Color(0xD9161310); // 85% opacity
  static const Color navBorder = Color(0x663D3629); // 40% opacity
  static const String navBlur = 'saturate(180%) blur(20px)';
}

/// Typography tokens
class UmbraTypography {
  static const String fontSans = 'InterVariable';
  static const String fontMono = 'JetBrainsMono';
  static const String fontSerif = 'Fraunces';

  // Type scale
  static const double textXs = 12; // 0.75rem
  static const double textSm = 13; // 0.8125rem
  static const double textBase = 14; // 0.875rem
  static const double textMd = 16; // 1rem
  static const double textLg = 18; // 1.125rem
  static const double textXl = 20; // 1.25rem
  static const double text2xl = 24; // 1.5rem
  static const double text3xl = 30; // 1.875rem
  static const double text4xl = 36; // 2.25rem
  static const double text5xl = 48; // 3rem

  // Line heights
  static const double leadingTight = 1.1;
  static const double leadingSnug = 1.35;
  static const double leadingNormal = 1.5;
  static const double leadingRelaxed = 1.625;

  // Letter spacing
  static const double trackingTight = -0.02;
  static const double trackingNormal = 0;
  static const double trackingWide = 0.02;
  static const double trackingTabular = 0;

  // Font weights
  static const FontWeight weightLight = FontWeight.w300;
  static const FontWeight weightNormal = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;
}

/// Spacing tokens (4px base unit)
class UmbraSpacing {
  static const double space0 = 0;
  static const double space1 = 4; // 0.25rem
  static const double space2 = 8; // 0.5rem
  static const double space3 = 12; // 0.75rem
  static const double space4 = 16; // 1rem
  static const double space5 = 20; // 1.25rem
  static const double space6 = 24; // 1.5rem
  static const double space8 = 32; // 2rem
  static const double space10 = 40; // 2.5rem
  static const double space12 = 48; // 3rem
  static const double space16 = 64; // 4rem
  static const double space20 = 80; // 5rem
  static const double space24 = 96; // 6rem
}

/// Border radius tokens
class UmbraRadius {
  static const double none = 0;
  static const double sm = 4; // 0.25rem
  static const double md = 8; // 0.5rem
  static const double lg = 12; // 0.75rem
  static const double xl = 16; // 1rem
  static const double radius2xl = 18; // 1.125rem - bubble radius
  static const double radius3xl = 24; // 1.5rem
  static const double full = 9999;
}

/// Shadow tokens
class UmbraShadows {
  // Light theme shadows
  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x12000000), offset: Offset(0, 4), blurRadius: 6),
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 2), blurRadius: 4),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 10), blurRadius: 15),
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 4), blurRadius: 6),
  ];
  static const List<BoxShadow> xl = [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 20), blurRadius: 25),
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 10), blurRadius: 10),
  ];
  static const List<BoxShadow> frosted = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 8),
      blurRadius: 32,
    ),
    BoxShadow(
      color: Color(0x1AFFFFFF),
      offset: Offset(0, 1),
      blurRadius: 0,
    ),
  ];

  // Dark theme shadows
  static const List<BoxShadow> darkXs = [
    BoxShadow(color: Color(0x33000000), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> darkSm = [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(color: Color(0x33000000), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> darkMd = [
    BoxShadow(color: Color(0x59000000), offset: Offset(0, 4), blurRadius: 6),
    BoxShadow(color: Color(0x33000000), offset: Offset(0, 2), blurRadius: 4),
  ];
  static const List<BoxShadow> darkLg = [
    BoxShadow(color: Color(0x66000000), offset: Offset(0, 10), blurRadius: 15),
    BoxShadow(color: Color(0x40000000), offset: Offset(0, 4), blurRadius: 6),
  ];
  static const List<BoxShadow> darkFrosted = [
    BoxShadow(
      color: Color(0x80000000),
      offset: Offset(0, 8),
      blurRadius: 32,
    ),
    BoxShadow(
      color: Color(0x0DFFFFFF),
      offset: Offset(0, 1),
      blurRadius: 0,
    ),
  ];
}

/// Motion tokens
class UmbraMotion {
  static const Duration durationInstant = Duration(milliseconds: 0);
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 300);
  static const Duration durationSlower = Duration(milliseconds: 400);
  static const Duration eclipseWipeDuration = Duration(milliseconds: 600);

  // Spring easing - iMessage feel
  static const Cubic easeSpring = Cubic(0.34, 1.56, 0.64, 1);
  static const Cubic easeSpringGentle = Cubic(0.4, 1.3, 0.6, 1);
  static const Cubic easeOut = Cubic(0.25, 0.46, 0.45, 0.94);
  static const Cubic easeInOut = Cubic(0.4, 0, 0.2, 1);
  static const Cubic easeSharp = Cubic(0.4, 0, 0.6, 1);
}

/// Z-index tokens
class UmbraZIndex {
  static const int base = 0;
  static const int dropdown = 100;
  static const int sticky = 200;
  static const int fixed = 300;
  static const int modalBackdrop = 400;
  static const int modal = 500;
  static const int popover = 600;
  static const int tooltip = 700;
  static const int toast = 800;
}

/// Component-specific tokens
class UmbraComponentTokens {
  // Chat list
  static const double chatListItemHeight = 72;
  static const double chatListAvatarSize = 48;
  static const double chatListAvatarSizeLg = 56;

  // Message bubbles
  static const double bubbleRadius = 18; // 1.125rem
  static const double bubbleTailWidth = 20; // 1.25rem
  static const double bubbleTailHeight = 18; // 1.125rem
  static const double bubbleMaxWidth = 0.75; // 75%
  static const double bubbleMinWidth = 40; // 2.5rem
  static const double bubblePaddingX = 14; // 0.875rem
  static const double bubblePaddingY = 8; // 0.5rem
  static const double bubbleGroupGap = 6; // 0.375rem

  // Input bar
  static const double inputBarHeight = 56;
  static const double inputBarHeightExpanded = 120;
  static const double inputBarPaddingX = 16; // 1rem
  static const double inputBarPaddingY = 12; // 0.75rem
  static const double inputBarRadius = 24; // 1.5rem
  static const double inputTextSize = 16; // 1rem

  // Navigation bar
  static const double navBarHeight = 56;
  static const double navBarHeightLarge = 96;
  static const double navTitleSize = 28; // 1.75rem
  static const FontWeight navTitleWeight = FontWeight.w700;

  // Avatar
  static const double avatarXs = 24;
  static const double avatarSm = 32;
  static const double avatarMd = 40;
  static const double avatarLg = 48;
  static const double avatarXl = 56;
  static const double avatar2xl = 72;
  static const double avatar3xl = 96;

  // Tab bar
  static const double tabBarHeight = 83; // includes safe area
  static const double tabBarItemGap = 4;
}

/// Semantic color aliases that adapt to theme
abstract class UmbraSemanticColors {
  Color get ink;
  Color get paper;
  Color get surface;
  Color get surfaceElevated;
  Color get surfaceHover;
  Color get separator;
  Color get separatorStrong;

  Color get textPrimary;
  Color get textSecondary;
  Color get textTertiary;
  Color get textMuted;
  Color get textInverse;

  Color get accent;
  Color get accentHover;
  Color get accentSoft;
  Color get accentOn;

  Color get success;
  Color get successSoft;
  Color get warning;
  Color get warningSoft;
  Color get error;
  Color get errorSoft;

  Color get bubbleIncoming;
  Color get bubbleIncomingText;
  Color get bubbleOutgoing;
  Color get bubbleOutgoingText;
  Color get bubbleFrosted;
  Color get bubbleFrostedBorder;

  Color get inputBg;
  Color get inputBorder;
  Color get inputFocusBorder;

  Color get navBg;
  Color get navBorder;
  String get navBlur;

  List<BoxShadow> get shadowXs;
  List<BoxShadow> get shadowSm;
  List<BoxShadow> get shadowMd;
  List<BoxShadow> get shadowLg;
  List<BoxShadow> get shadowFrosted;
}

/// Semantic colors for Sol (light) theme
class SolSemanticColors implements UmbraSemanticColors {
  @override
  Color get ink => SolColors.ink;
  @override
  Color get paper => SolColors.paper;
  @override
  Color get surface => SolColors.surface;
  @override
  Color get surfaceElevated => SolColors.surfaceElevated;
  @override
  Color get surfaceHover => SolColors.surfaceHover;
  @override
  Color get separator => SolColors.separator;
  @override
  Color get separatorStrong => SolColors.separatorStrong;

  @override
  Color get textPrimary => SolColors.textPrimary;
  @override
  Color get textSecondary => SolColors.textSecondary;
  @override
  Color get textTertiary => SolColors.textTertiary;
  @override
  Color get textMuted => SolColors.textMuted;
  @override
  Color get textInverse => SolColors.textInverse;

  @override
  Color get accent => SolColors.accent;
  @override
  Color get accentHover => SolColors.accentHover;
  @override
  Color get accentSoft => SolColors.accentSoft;
  @override
  Color get accentOn => SolColors.accentOn;

  @override
  Color get success => SolColors.success;
  @override
  Color get successSoft => SolColors.successSoft;
  @override
  Color get warning => SolColors.warning;
  @override
  Color get warningSoft => SolColors.warningSoft;
  @override
  Color get error => SolColors.error;
  @override
  Color get errorSoft => SolColors.errorSoft;

  @override
  Color get bubbleIncoming => SolColors.bubbleIncoming;
  @override
  Color get bubbleIncomingText => SolColors.bubbleIncomingText;
  @override
  Color get bubbleOutgoing => SolColors.bubbleOutgoing;
  @override
  Color get bubbleOutgoingText => SolColors.bubbleOutgoingText;
  @override
  Color get bubbleFrosted => SolColors.bubbleFrosted;
  @override
  Color get bubbleFrostedBorder => SolColors.bubbleFrostedBorder;

  @override
  Color get inputBg => SolColors.inputBg;
  @override
  Color get inputBorder => SolColors.inputBorder;
  @override
  Color get inputFocusBorder => SolColors.inputFocusBorder;

  @override
  Color get navBg => SolColors.navBg;
  @override
  Color get navBorder => SolColors.navBorder;
  @override
  String get navBlur => SolColors.navBlur;

  @override
  List<BoxShadow> get shadowXs => UmbraShadows.xs;
  @override
  List<BoxShadow> get shadowSm => UmbraShadows.sm;
  @override
  List<BoxShadow> get shadowMd => UmbraShadows.md;
  @override
  List<BoxShadow> get shadowLg => UmbraShadows.lg;
  @override
  List<BoxShadow> get shadowFrosted => UmbraShadows.frosted;
}

/// Semantic colors for Umbra (dark) theme
class UmbraSemanticColorsImpl implements UmbraSemanticColors {
  @override
  Color get ink => UmbraColors.ink;
  @override
  Color get paper => UmbraColors.paper;
  @override
  Color get surface => UmbraColors.surface;
  @override
  Color get surfaceElevated => UmbraColors.surfaceElevated;
  @override
  Color get surfaceHover => UmbraColors.surfaceHover;
  @override
  Color get separator => UmbraColors.separator;
  @override
  Color get separatorStrong => UmbraColors.separatorStrong;

  @override
  Color get textPrimary => UmbraColors.textPrimary;
  @override
  Color get textSecondary => UmbraColors.textSecondary;
  @override
  Color get textTertiary => UmbraColors.textTertiary;
  @override
  Color get textMuted => UmbraColors.textMuted;
  @override
  Color get textInverse => UmbraColors.textInverse;

  @override
  Color get accent => UmbraColors.accent;
  @override
  Color get accentHover => UmbraColors.accentHover;
  @override
  Color get accentSoft => UmbraColors.accentSoft;
  @override
  Color get accentOn => UmbraColors.accentOn;

  @override
  Color get success => UmbraColors.success;
  @override
  Color get successSoft => UmbraColors.successSoft;
  @override
  Color get warning => UmbraColors.warning;
  @override
  Color get warningSoft => UmbraColors.warningSoft;
  @override
  Color get error => UmbraColors.error;
  @override
  Color get errorSoft => UmbraColors.errorSoft;

  @override
  Color get bubbleIncoming => UmbraColors.bubbleIncoming;
  @override
  Color get bubbleIncomingText => UmbraColors.bubbleIncomingText;
  @override
  Color get bubbleOutgoing => UmbraColors.bubbleOutgoing;
  @override
  Color get bubbleOutgoingText => UmbraColors.bubbleOutgoingText;
  @override
  Color get bubbleFrosted => UmbraColors.bubbleFrosted;
  @override
  Color get bubbleFrostedBorder => UmbraColors.bubbleFrostedBorder;

  @override
  Color get inputBg => UmbraColors.inputBg;
  @override
  Color get inputBorder => UmbraColors.inputBorder;
  @override
  Color get inputFocusBorder => UmbraColors.inputFocusBorder;

  @override
  Color get navBg => UmbraColors.navBg;
  @override
  Color get navBorder => UmbraColors.navBorder;
  @override
  String get navBlur => UmbraColors.navBlur;

  @override
  List<BoxShadow> get shadowXs => UmbraShadows.darkXs;
  @override
  List<BoxShadow> get shadowSm => UmbraShadows.darkSm;
  @override
  List<BoxShadow> get shadowMd => UmbraShadows.darkMd;
  @override
  List<BoxShadow> get shadowLg => UmbraShadows.darkLg;
  @override
  List<BoxShadow> get shadowFrosted => UmbraShadows.darkFrosted;
}
