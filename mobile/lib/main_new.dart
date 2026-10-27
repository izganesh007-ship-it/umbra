// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra messenger - new entry point with Umbra design system
// This replaces the HaloApp in main.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/l10n.dart';
import 'theme/theme.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_screen_new.dart';

/// Global theme controller instance
final UmbraThemeController umbraThemeController = UmbraThemeController();

/// Global scaffold messenger key for toasts
final GlobalKey<ScaffoldMessengerState> umbraMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Umbra app with new design system
class UmbraApp extends StatefulWidget {
  const UmbraApp({super.key});

  @override
  State<UmbraApp> createState() => _UmbraAppState();
}

class _UmbraAppState extends State<UmbraApp> {
  @override
  void initState() {
    super.initState();
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    await umbraThemeController.initialize();
    // Listen for platform brightness changes
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
      umbraThemeController.onPlatformBrightnessChanged();
    };
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return AnimatedBuilder(
      animation: umbraThemeController,
      builder: (context, _) {
        final isLight = umbraThemeController.isLight;
        final reduceMotion = umbraThemeController.reduceMotion;

        return MaterialApp(
          title: 'Umbra',
          theme: buildUmbraThemeData(
            isLight: true,
            reduceMotion: reduceMotion,
          ),
          darkTheme: buildUmbraThemeData(
            isLight: false,
            reduceMotion: reduceMotion,
          ),
          themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
          locale: l10nLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          scaffoldMessengerKey: umbraMessengerKey,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                // Respect system text scaling but clamp for readability
                textScaler: TextScaler.linear(
                  mediaQuery.textScaler.scale(1.0).clamp(0.85, 1.6),
                ),
                disableAnimations: reduceMotion,
              ),
              child: ScrollConfiguration(
                behavior: _UmbraScrollBehavior(),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: UmbraTheme(
            controller: umbraThemeController,
            child: const _AppRoot(),
          ),
        );
      },
    );
  }
}

/// Root app widget that handles boot state
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    // This would connect to your existing AppState
    // For now, we'll show the chat list screen directly
    return const ChatListScreen();
  }
}

/// Custom scroll behavior for iOS-style bounce
class _UmbraScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}

/// Main entry point - replace the existing main() in main.dart with this
Future<void> umbraMain() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  unawaited(
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  );

  // Load locale
  await loadAppLocale();

  // Initialize theme controller
  await umbraThemeController.initialize();

  // Run the app
  runApp(const UmbraApp());
}

/// Show a toast message
void showUmbraToast(BuildContext context, String message) {
  umbraMessengerKey.currentState?.clearSnackBars();
  umbraMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          fontFamily: UmbraTypography.fontSans,
          fontSize: UmbraTypography.textSm,
          color: UmbraTheme.colorsOf(context).textPrimary,
        ),
      ),
      backgroundColor: UmbraTheme.colorsOf(context).surfaceElevated,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      duration: const Duration(milliseconds: 3500),
      margin: EdgeInsets.only(
        left: UmbraSpacing.space4,
        right: UmbraSpacing.space4,
        bottom: MediaQuery.of(context).size.height - 170,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UmbraRadius.radius2xl),
        side: BorderSide(
          color: UmbraTheme.colorsOf(context).accent.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
    ),
  );
}

/// Route builder with iOS-style transitions
PageRouteBuilder<dynamic> umbraRoute(Widget page) {
  return PageRouteBuilder<dynamic>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final reduceMotion = umbraThemeController.reduceMotion;
      if (reduceMotion) return child;

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: UmbraMotion.easeOut,
        )),
        child: child,
      );
    },
    transitionDuration: UmbraMotion.durationNormal,
    reverseTransitionDuration: UmbraMotion.durationFast,
  );
}

/// Bottom sheet route
PageRouteBuilder<dynamic> umbraSheet(Widget page) {
  return PageRouteBuilder<dynamic>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final reduceMotion = umbraThemeController.reduceMotion;
      if (reduceMotion) return child;

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: UmbraMotion.easeSpringGentle,
        )),
        child: child,
      );
    },
    transitionDuration: UmbraMotion.durationNormal,
    reverseTransitionDuration: UmbraMotion.durationFast,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    opaque: false,
  );
}
