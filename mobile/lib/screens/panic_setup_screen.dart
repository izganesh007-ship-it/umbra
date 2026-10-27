// SPDX-License-Identifier: GPL-3.0-or-later
// the wipe pin. entered on the lock screen it silently wipes kryfo and exits,
// which looks like a crash. must differ from the real pin.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../lock_state.dart';
import '../widgets/fit_column.dart';
import '../theme/theme.dart';
import '../widgets/pin_pad.dart';
import '../l10n/l10n.dart';

class PanicSetupScreen extends StatefulWidget {
  const PanicSetupScreen({super.key});
  @override
  State<PanicSetupScreen> createState() => _PanicSetupScreenState();
}

class _PanicSetupScreenState extends State<PanicSetupScreen>
    with SingleTickerProviderStateMixin {
  String _first = '';
  String _pin = '';
  bool _confirming = false;
  String? _error;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _fail(String why) async {
    HapticFeedback.heavyImpact();
    setState(() => _error = why);
    await _shake.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _first = '';
      _pin = '';
      _confirming = false;
    });
  }

  // the moment between the fourth digit and the confirm step. taps are
  // ignored so a backspace cannot shorten the pin being kept
  bool _hold = false;

  Future<void> _onDigit(String d) async {
    if (_hold || _pin.length >= 4) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length != 4) return;
    if (!_confirming) {
      setState(() => _hold = true);
      await Future.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      setState(() {
        _first = _pin;
        _pin = '';
        _confirming = true;
        _hold = false;
      });
      return;
    }
    if (_pin != _first) {
      await _fail(l10n.panicSetupThoseWereDifferentFrom);
      return;
    }
    final ok = await lockState.setupPanicPin(_pin);
    if (!ok) {
      await _fail(l10n.panicSetupThatIsYourReal);
      return;
    }
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
  }

  void _back() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    final title = _confirming
        ? l10n.panicSetupOnceMore
        : l10n.panicSetupSetAWipePin;
    return Scaffold(
      backgroundColor: colors.ink,
      appBar: AppBar(
        backgroundColor: colors.ink,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
      ),
      body: SafeArea(
        child: FitColumn(
          children: [
            const Spacer(flex: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: UmbraMotion.easeOut,
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(a),
                  child: c,
                ),
              ),
              child: Text(
                title,
                key: ValueKey(title),
                style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 30, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ??
                  (_confirming
                      ? l10n.panicSetupTheSameFourDigits
                      : l10n.panicSetupTheSecondPinWipes),
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: _error != null ? colors.error : colors.textSecondary, height: 1.5, letterSpacing: 0),
            ),
            const SizedBox(height: 32),
            PinDots(
              filled: _pin.length,
              color: colors.error,
              wrong: _error != null,
              shake: _shake,
            ),
            const Spacer(flex: 3),
            PinPad(onDigit: _onDigit, onBack: _back, enabled: !_hold),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}
