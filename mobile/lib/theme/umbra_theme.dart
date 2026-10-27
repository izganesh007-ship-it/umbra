// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra theme controller with radial eclipse wipe animation

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';
import '../l10n/l10n.dart';

/// Theme controller managing Sol/Umbra themes with eclipse wipe transition
class UmbraThemeController extends ChangeNotifier {
  UmbraThemeController._internal() {
    _loadPreference();
  }

  static final UmbraThemeController _instance = UmbraThemeController._internal();
  factory UmbraThemeController() => _instance;

  UmbraThemeMode _mode = UmbraThemeMode.system;
  bool _isLight = true;
  bool _reduceMotion = false;
  Timer? _wipeTimer;
  bool _isWiping = false;
  Offset _wipeCenter = Offset.zero;
  double _wipeProgress = 0.0;

  UmbraThemeMode get mode => _mode;
  bool get isLight => _isLight;
  bool get reduceMotion => _reduceMotion;
  bool get isWiping => _isWiping;
  Offset get wipeCenter => _wipeCenter;
  double get wipeProgress => _wipeProgress;

  UmbraSemanticColors get colors =>
      _isLight ? SolSemanticColors() : UmbraSemanticColorsImpl();

  /// Initialize with system theme and reduced motion setting
  Future<void> initialize() async {
    await _loadPreference();
    await _updateReduceMotion();
  }

  Future<void> _loadPreference() async {
    // In a real app, this would load from SharedPreferences
    // For now, we'll use system preference
    _mode = UmbraThemeMode.system;
    _updateThemeFromSystem();
    notifyListeners();
  }

  Future<void> _updateReduceMotion() async {
    // Check platform reduced motion setting
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    _reduceMotion = view.platformDispatcher.accessibilityFeatures.reduceMotion;
  }

  void _updateThemeFromSystem() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _isLight = brightness == Brightness.light;
  }

  /// Set theme mode
  Future<void> setThemeMode(UmbraThemeMode mode, {Offset? wipeCenter}) async {
    if (_mode == mode) return;

    final wasLight = _isLight;
    _mode = mode;

    switch (mode) {
      case UmbraThemeMode.sol:
        _isLight = true;
        break;
      case UmbraThemeMode.umbra:
        _isLight = false;
        break;
      case UmbraThemeMode.system:
        _updateThemeFromSystem();
        break;
    }

    if (_isLight != wasLight && !_reduceMotion) {
      _triggerEclipseWipe(wipeCenter);
    } else {
      notifyListeners();
    }
  }

  /// Toggle between Sol and Umbra
  Future<void> toggleTheme({Offset? wipeCenter}) async {
    final newMode = _isLight ? UmbraThemeMode.umbra : UmbraThemeMode.sol;
    await setThemeMode(newMode, wipeCenter: wipeCenter);
  }

  /// Trigger radial eclipse wipe animation
  void _triggerEclipseWipe(Offset? center) {
    _isWiping = true;
    _wipeCenter = center ?? Offset.zero;
    _wipeProgress = 0.0;
    notifyListeners();

    final duration = _reduceMotion
        ? UmbraMotion.durationInstant
        : UmbraMotion.eclipseWipeDuration;

    final curve = _reduceMotion ? Curves.linear : UmbraMotion.easeSpring;

    _wipeTimer?.cancel();
    _wipeTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsed = timer.tick * 16;
      final progress = (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
      _wipeProgress = curve.transform(progress);
      notifyListeners();

      if (progress >= 1.0) {
        _wipeTimer?.cancel();
        _wipeTimer = null;
        _isWiping = false;
        _wipeProgress = 0.0;
        notifyListeners();
      }
    });
  }

  /// Update system theme change (e.g., system theme changed)
  void onPlatformBrightnessChanged() {
    if (_mode == UmbraThemeMode.system) {
      _updateThemeFromSystem();
      notifyListeners();
    }
    _updateReduceMotion();
  }

  @override
  void dispose() {
    _wipeTimer?.cancel();
    super.dispose();
  }
}

/// InheritedWidget to provide theme to the widget tree
class UmbraTheme extends InheritedWidget {
  const UmbraTheme({
    super.key,
    required this.controller,
    required super.child,
  });

  final UmbraThemeController controller;

  static UmbraThemeController of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<UmbraTheme>();
    assert(inherited != null, 'No UmbraTheme found in context');
    return inherited!.controller;
  }

  static UmbraSemanticColors colorsOf(BuildContext context) {
    return of(context).colors;
  }

  @override
  bool updateShouldNotify(UmbraTheme oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// Theme-aware widget builder
class UmbraThemeBuilder extends StatelessWidget {
  const UmbraThemeBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext, UmbraThemeController) builder;

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    final controller = UmbraTheme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => builder(context, controller),
    );
  }
}

/// Eclipse Wipe Transition Widget
class EclipseWipe extends StatelessWidget {
  const EclipseWipe({
    super.key,
    required this.child,
    this.controller,
  });

  final Widget child;
  final UmbraThemeController? controller;

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    final themeController = controller ?? UmbraTheme.of(context);

    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        if (!themeController.isWiping) {
          return child;
        }

        return CustomPaint(
          painter: _EclipseWipePainter(
            progress: themeController.wipeProgress,
            center: themeController.wipeCenter,
            isLight: themeController.isLight,
          ),
          child: child,
        );
      },
    );
  }
}

class _EclipseWipePainter extends CustomPainter {
  _EclipseWipePainter({
    required this.progress,
    required this.center,
    required this.isLight,
  });

  final double progress;
  final Offset center;
  final bool isLight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = isLight ? SolColors.paper : UmbraColors.paper;

    // Draw the eclipse circle expanding from center
    final radius = progress * (size.width + size.height);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_EclipseWipePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.center != center ||
        oldDelegate.isLight != isLight;
  }
}

/// Material 3 theme data builder
ThemeData buildUmbraThemeData({
  required bool isLight,
  required bool reduceMotion,
  TextTheme? textTheme,
}) {
  final colors = isLight ? SolSemanticColors() : UmbraSemanticColorsImpl();
  final brightness = isLight ? Brightness.light : Brightness.dark;

  final base = isLight
      ? ThemeData.light(useMaterial3: true)
      : ThemeData.dark(useMaterial3: true);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: colors.accent,
    onPrimary: colors.accentOn,
    secondary: colors.accent,
    onSecondary: colors.accentOn,
    tertiary: colors.success,
    onTertiary: colors.textInverse,
    error: colors.error,
    onError: colors.textInverse,
    surface: colors.surface,
    onSurface: colors.textPrimary,
    surfaceContainerHighest: colors.surfaceHover,
    surfaceContainerHigh: colors.surfaceElevated,
    surfaceContainer: colors.surface,
    surfaceContainerLow: colors.surface,
    surfaceContainerLowest: colors.surface,
    surfaceTint: colors.accentSoft,
    outline: colors.separator,
    outlineVariant: colors.separator,
    shadow: Colors.black,
    scrim: Colors.black54,
    inverseSurface: colors.textInverse,
    onInverseSurface: colors.textPrimary,
    inversePrimary: isLight ? UmbraColors.accent : SolColors.accent,
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.surface,
    canvasColor: colors.surface,
    cardColor: colors.surfaceElevated,
    dividerColor: colors.separator,
    dividerTheme: DividerThemeData(
      color: colors.separator,
      thickness: 0.5,
      space: 1,
    ),
    textTheme: (textTheme ?? base.textTheme).copyWith(
      displayLarge: _textStyle(colors, size: UmbraTypography.text5xl, weight: UmbraTypography.weightBold),
      displayMedium: _textStyle(colors, size: UmbraTypography.text4xl, weight: UmbraTypography.weightBold),
      displaySmall: _textStyle(colors, size: UmbraTypography.text3xl, weight: UmbraTypography.weightSemibold),
      headlineLarge: _textStyle(colors, size: UmbraTypography.text2xl, weight: UmbraTypography.weightSemibold),
      headlineMedium: _textStyle(colors, size: UmbraTypography.textXl, weight: UmbraTypography.weightSemibold),
      headlineSmall: _textStyle(colors, size: UmbraTypography.textLg, weight: UmbraTypography.weightMedium),
      titleLarge: _textStyle(colors, size: UmbraTypography.textLg, weight: UmbraTypography.weightMedium),
      titleMedium: _textStyle(colors, size: UmbraTypography.textBase, weight: UmbraTypography.weightMedium),
      titleSmall: _textStyle(colors, size: UmbraTypography.textSm, weight: UmbraTypography.weightMedium),
      bodyLarge: _textStyle(colors, size: UmbraTypography.textBase, weight: UmbraTypography.weightNormal),
      bodyMedium: _textStyle(colors, size: UmbraTypography.textSm, weight: UmbraTypography.weightNormal),
      bodySmall: _textStyle(colors, size: UmbraTypography.textXs, weight: UmbraTypography.weightNormal),
      labelLarge: _textStyle(colors, size: UmbraTypography.textSm, weight: UmbraTypography.weightSemibold),
      labelMedium: _textStyle(colors, size: UmbraTypography.textXs, weight: UmbraTypography.weightMedium),
      labelSmall: _textStyle(colors, size: UmbraTypography.textXs, weight: UmbraTypography.weightNormal),
    ).apply(
      fontFamily: UmbraTypography.fontSans,
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.navBg,
      foregroundColor: colors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: _textStyle(
        colors,
        size: UmbraTypography.textXl,
        weight: UmbraTypography.weightSemibold,
      ),
      systemOverlayStyle: isLight
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.navBg,
      indicatorColor: colors.accentSoft,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _textStyle(colors, size: UmbraTypography.textXs, weight: UmbraTypography.weightSemibold, color: colors.accent);
        }
        return _textStyle(colors, size: UmbraTypography.textXs, weight: UmbraTypography.weightNormal, color: colors.textTertiary);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: colors.accent, size: 24);
        }
        return IconThemeData(color: colors.textTertiary, size: 24);
      }),
      height: UmbraComponentTokens.tabBarHeight,
      elevation: 0,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: colors.accent,
      unselectedLabelColor: colors.textTertiary,
      indicatorColor: colors.accent,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: _textStyle(colors, size: UmbraTypography.textSm, weight: UmbraTypography.weightSemibold),
      unselectedLabelStyle: _textStyle(colors, size: UmbraTypography.textSm, weight: UmbraTypography.weightNormal),
      dividerColor: colors.separator,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.inputBg,
      contentPadding: EdgeInsets.symmetric(
        horizontal: UmbraComponentTokens.inputBarPaddingX,
        vertical: UmbraComponentTokens.inputBarPaddingY,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UmbraComponentTokens.inputBarRadius),
        borderSide: BorderSide(color: colors.inputBorder, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UmbraComponentTokens.inputBarRadius),
        borderSide: BorderSide(color: colors.inputBorder, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UmbraComponentTokens.inputBarRadius),
        borderSide: BorderSide(color: colors.inputFocusBorder, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UmbraComponentTokens.inputBarRadius),
        borderSide: BorderSide(color: colors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UmbraComponentTokens.inputBarRadius),
        borderSide: BorderSide(color: colors.error, width: 1.5),
      ),
      labelStyle: _textStyle(colors, size: UmbraTypography.textBase, color: colors.textTertiary),
      hintStyle: _textStyle(colors, size: UmbraTypography.textBase, color: colors.textMuted),
      floatingLabelStyle: _textStyle(colors, size: UmbraTypography.textSm, weight: UmbraTypography.weightMedium, color: colors.accent),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: colors.accentOn,
        disabledBackgroundColor: colors.separator,
        disabledForegroundColor: colors.textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UmbraRadius.full),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: UmbraSpacing.UmbraSpacing.space4,
          vertical: UmbraSpacing.UmbraSpacing.space2,
        ),
        textStyle: _textStyle(colors, size: UmbraTypography.textSm, weight: UmbraTypography.weightSemibold),
        minimumSize: const Size(88, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.accent,
        disabledForegroundColor: colors.textMuted,
        side: BorderSide(color: colors.separator, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UmbraRadius.full),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: UmbraSpacing.UmbraSpacing.space4,
          vertical: UmbraSpacing.UmbraSpacing.space2,
        ),
        textStyle: _textStyle(colors, size: UmbraTypography.textSm, weight: UmbraTypography.weightSemibold),
        minimumSize: const Size(88, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.accent,
        disabledForegroundColor: colors.textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UmbraRadius.full),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: UmbraSpacing.UmbraSpacing.space3,
          vertical: UmbraSpacing.UmbraSpacing.space1,
        ),
        textStyle: _textStyle(colors, size: UmbraTypography.textSm, weight: UmbraTypography.weightMedium),
        minimumSize: const Size(64, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.surfaceElevated,
        foregroundColor: colors.textPrimary,
        disabledBackgroundColor: colors.surfaceHover,
        disabledForegroundColor: colors.textMuted,
        elevation: 0,
        shadowColor: Colors.transparent,
        side: BorderSide(color: colors.separator, width: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UmbraRadius.full),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: UmbraSpacing.UmbraSpacing.space4,
          vertical: UmbraSpacing.UmbraSpacing.space2,
        ),
        textStyle: _textStyle(colors, size: UmbraTypography.textSm, weight: UmbraTypography.weightSemibold),
        minimumSize: const Size(88, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colors.textPrimary,
        disabledForegroundColor: colors.textMuted,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UmbraRadius.full),
        ),
        padding: EdgeInsets.all(UmbraSpacing.UmbraSpacing.space2),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.accent,
      foregroundColor: colors.accentOn,
      disabledBackgroundColor: colors.separator,
      disabledForegroundColor: colors.textMuted,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UmbraRadius.radius3xl),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.surfaceHover,
      disabledColor: colors.separator,
      selectedColor: colors.accentSoft,
      secondarySelectedColor: colors.accentSoft,
      labelStyle: _textStyle(colors, size: UmbraTypography.textSm, weight: UmbraTypography.weightMedium),
      secondaryLabelStyle: _textStyle(colors, size: UmbraTypography.textSm, weight: UmbraTypography.weightMedium, color: colors.accentOn),
      padding: EdgeInsets.symmetric(horizontal: UmbraSpacing.UmbraSpacing.space2, vertical: UmbraSpacing.UmbraSpacing.space1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UmbraRadius.full),
        side: BorderSide(color: colors.separator, width: 0.5),
      ),
      side: BorderSide(color: colors.separator, width: 0.5),
      brightness: brightness,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surfaceElevated,
      surfaceTintColor: colors.accentSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UmbraRadius.radius3xl),
      ),
      titleTextStyle: _textStyle(colors, size: UmbraTypography.textLg, weight: UmbraTypography.weightSemibold),
      contentTextStyle: _textStyle(colors, size: UmbraTypography.textBase),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surfaceElevated,
      surfaceTintColor: colors.accentSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(UmbraRadius.radius3xl)),
      ),
      modalBackgroundColor: colors.surfaceElevated,
      elevation: 0,
      shadowColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.surfaceElevated,
      contentTextStyle: _textStyle(colors, size: UmbraTypography.textSm, color: colors.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UmbraRadius.radius2xl),
        side: BorderSide(color: colors.accent.withValues(alpha: 0.4), width: 0.5),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      actionTextColor: colors.accent,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.accent,
      linearTrackColor: colors.separator,
      circularTrackColor: colors.separator,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: colors.accent,
      inactiveTrackColor: colors.separator,
      thumbColor: colors.accent,
      overlayColor: colors.accentSoft,
      valueIndicatorColor: colors.accent,
      valueIndicatorTextStyle: _textStyle(colors, size: UmbraTypography.textXs, color: colors.accentOn),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colors.accent;
        return colors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colors.accentSoft;
        return colors.separator;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colors.accent;
        return colors.separator;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colors.accent;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(colors.accentOn),
      side: BorderSide(color: colors.separator, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UmbraRadius.sm)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colors.accent;
        return colors.textMuted;
      }),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: UmbraSpacing.UmbraSpacing.space4, vertical: UmbraSpacing.UmbraSpacing.space1),
      titleTextStyle: _textStyle(colors, size: UmbraTypography.textBase, weight: UmbraTypography.weightMedium),
      subtitleTextStyle: _textStyle(colors, size: UmbraTypography.textSm, color: colors.textSecondary),
      leadingAndTrailingTextStyle: _textStyle(colors, size: UmbraTypography.textSm, color: colors.textTertiary),
      iconColor: colors.textTertiary,
      textColor: colors.textPrimary,
      selectedColor: colors.accentSoft,
      selectedTileColor: colors.accentSoft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UmbraRadius.radius2xl)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colors.textPrimary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(UmbraRadius.md),
        boxShadow: colors.shadowMd,
      ),
      textStyle: _textStyle(colors, size: UmbraTypography.textXs, color: colors.textInverse),
      padding: EdgeInsets.symmetric(horizontal: UmbraSpacing.UmbraSpacing.space3, vertical: UmbraSpacing.UmbraSpacing.space2),
      preferBelow: true,
      verticalOffset: 8,
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: colors.surfaceHover,
    focusColor: colors.accentSoft,
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.android: const CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: const CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: const CupertinoPageTransitionsBuilder(),
    }),
  );
}

TextStyle _textStyle(
  UmbraSemanticColors colors, {
  required double size,
  FontWeight weight = UmbraTypography.weightNormal,
  Color? color,
  double height = UmbraTypography.leadingNormal,
  double letterSpacing = UmbraTypography.trackingNormal,
  FontStyle fontStyle = FontStyle.normal,
  String? fontFamily,
}) {
  return TextStyle(
    fontFamily: fontFamily ?? UmbraTypography.fontSans,
    fontSize: size,
    fontWeight: weight,
    fontStyle: fontStyle,
    color: color ?? colors.textPrimary,
    height: height,
    letterSpacing: letterSpacing,
  );
}

/// Animation duration helper for reduced motion
Duration getDuration(BuildContext context, Duration normalDuration) {
  final controller = UmbraTheme.of(context);
  return controller.reduceMotion ? Duration.zero : normalDuration;
}

/// Curve helper for reduced motion
Curve getCurve(BuildContext context, Curve normalCurve) {
  final controller = UmbraTheme.of(context);
  return controller.reduceMotion ? Curves.linear : normalCurve;
}
