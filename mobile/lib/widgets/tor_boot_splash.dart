// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import '../dlog.dart';
import '../main.dart' show appState;
import '../theme/theme.dart';
import 'onion_loader.dart';
import '../l10n/l10n.dart';

// startup screen while the engine warms up tor. it says plainly that tor is
// starting, so the wait reads as purposeful, not stuck.
class TorBootSplash extends StatefulWidget {
  const TorBootSplash({super.key});

  @override
  State<TorBootSplash> createState() => _TorBootSplashState();
}

class _TorBootSplashState extends State<TorBootSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _hop(double phase) {
    final d = (_c.value - phase) % 1.0;
    if (d < 0.15) return 0.25 + (d / 0.15) * 0.75;
    if (d < 0.35) return 1.0 - ((d - 0.15) / 0.20) * 0.75;
    return 0.25;
  }

  @override
  void initState() {
    super.initState();
    dlog('LAUNCH splash');
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.ink,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const OnionLoader(size: 132),
            const SizedBox(height: 26),
            Text(
              l10n.torBootSplashNoShortcutsNoTraces,
              style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 23, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
            ),
            const SizedBox(height: 20),
            ListenableBuilder(
              listenable: appState,
              builder: (_, _) {
                final tor = appState.bootPhase == l10n.appStartingTor;
                return Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        appState.bootPhase,
                        key: ValueKey(appState.bootPhase),
                        style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 12, fontWeight: FontWeight.w500, color: colors.accent, letterSpacing: 0.12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        tor
                            ? l10n.torBootSplashTheNetworkThatKeeps
                            : l10n.torBootSplashMadeOnThisPhone,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            AnimatedBuilder(
              animation: _c,
              builder: (_, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _hopDot('guard', 0.0),
                  _link(),
                  _hopDot('relay', 0.33),
                  _link(),
                  _hopDot('exit', 0.66),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Text(
                l10n.torBootSplashFirstLaunchTakesA,
                style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hopDot(String label, double phase) {
    return Column(
      children: [
        Opacity(
          opacity: _hop(phase),
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accent,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(label, style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.textSecondary, letterSpacing: 0.12)),
      ],
    );
  }

  Widget _link() => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Container(width: 22, height: 1, color: colors.separator),
  );
}
