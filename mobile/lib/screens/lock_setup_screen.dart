// SPDX-License-Identifier: GPL-3.0-or-later
// set or change the pin: four digits, then the same four again
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../lock_state.dart';
import '../widgets/fit_column.dart';
import '../theme/theme.dart';
import '../widgets/halo_sheet.dart';
import '../widgets/pin_pad.dart';
import '../widgets/sheet_handle.dart';
import '../l10n/l10n.dart';

class LockSetupScreen extends StatefulWidget {
  const LockSetupScreen({super.key});
  @override
  State<LockSetupScreen> createState() => _LockSetupScreenState();
}

class _LockSetupScreenState extends State<LockSetupScreen>
    with SingleTickerProviderStateMixin {
  String _first = '';
  String _pin = '';
  bool _confirming = false;
  bool _mismatch = false;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  // the moment between the fourth digit and the confirm step. taps are
  // ignored so a backspace cannot shorten the pin being kept
  bool _hold = false;

  Future<void> _onDigit(String d) async {
    if (_hold || _pin.length >= 4) return;
    setState(() {
      _pin += d;
      _mismatch = false;
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
      HapticFeedback.heavyImpact();
      setState(() => _mismatch = true);
      await _shake.forward(from: 0);
      if (!mounted) return;
      setState(() {
        _first = '';
        _pin = '';
        _confirming = false;
      });
      return;
    }
    final ok = await lockState.setupPin(_pin);
    if (!ok) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      showHaloToast(context, l10n.lockSetupThatIsYourWipe);
      setState(() {
        _first = '';
        _pin = '';
        _confirming = false;
      });
      return;
    }
    HapticFeedback.mediumImpact();
    if (mounted && lockState.bioSupported && !lockState.biometric) {
      final useBio = await showHaloSheet<bool>(
        context,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetHandle(),
                const SizedBox(height: 12),
                Text(
                  l10n.lockSetupUnlockWithFingerprint,
                  style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 20, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.lockSetupThePinStillWorks,
                  style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx, true),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      l10n.lockSetupUseFingerprint,
                      style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w600, color: colors.accentOn, height: 1.5, letterSpacing: 0),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        l10n.lockSetupPinOnly,
                        style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (useBio == true) await lockState.setBiometric(true);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _back() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    final title = _confirming ? l10n.lockSetupOnceMore : l10n.lockSetupSetAPin;
    final hint = _mismatch
        ? l10n.lockSetupThoseWereDifferentFrom
        : _confirming
        ? l10n.lockSetupTheSameFourDigits
        : l10n.lockSetupFourDigitsAnythingYou;
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
              hint,
              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: _mismatch ? colors.error : colors.textSecondary, height: 1.5, letterSpacing: 0),
            ),
            const SizedBox(height: 32),
            PinDots(
              filled: _pin.length,
              color: colors.accent,
              wrong: _mismatch,
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
