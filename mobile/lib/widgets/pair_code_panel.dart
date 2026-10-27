// SPDX-License-Identifier: GPL-3.0-or-later
// six digits you read out loud. the code points at your invite for five
// minutes, works once, then the address is gone. shared by the invite page
// and the pairing screen.
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart' show appState, engine, buildHaloUriV3;
import '../theme/theme.dart';
import 'motion.dart' show BreathDot;
import '../l10n/l10n.dart';
import '../l10n/numbers.dart';

class PairCodePanel extends StatefulWidget {
  // compact drops the explanatory lines, for use under a qr
  final bool compact;
  const PairCodePanel({super.key, this.compact = false});
  @override
  State<PairCodePanel> createState() => _PairCodePanelState();
}

class _PairCodePanelState extends State<PairCodePanel> {
  String? _code;
  String _status = '';
  int _left = 0;
  Timer? _tick;
  bool _busy = false;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _make() async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    setState(() {
      _busy = true;
      _status = l10n.pairCodePanelPuttingYourInviteIn;
    });
    // Random.secure: a guessable code is one someone else can stand in
    // front of
    final r = Random.secure();
    final code = List.generate(6, (_) => r.nextInt(10)).join();
    if (appState.myOnion.isEmpty) {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = l10n.pairCodePanelYourInviteIsNot;
        });
      }
      return;
    }
    final uri = await buildHaloUriV3(
      appState.myId,
      appState.myOnion,
      appState.fcCounter,
    );
    final res = await engine.pairCodePublish(code, uri);
    if (!mounted) return;
    if (res.startsWith('error')) {
      setState(() {
        _busy = false;
        _status = res.replaceFirst('error: ', '');
      });
      return;
    }
    setState(() {
      _busy = false;
      _code = code;
      _left = 300;
      _status = '';
    });
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        setState(() => _code = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    return AnimatedSwitcher(
      duration: const UmbraMotion.durationNormal,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: UmbraMotion.easeSharp,
      transitionBuilder: (c, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: a, child: c),
      ),
      child: _code == null ? _idle() : _live(),
    );
  }

  Widget _idle() {
    return Column(
      key: const ValueKey('idle'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.compact) ...[
          Text(
            l10n.pairCodePanelReadSixDigitsOut,
            style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13.5, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
          ),
          const SizedBox(height: 22),
        ],
        GestureDetector(
          onTap: _make,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _busy ? colors.surfaceElevated : colors.surfaceHover,
              borderRadius: BorderRadius.circular(UmbraRadius.lg),
              border: Border.all(
                color: _busy
                    ? colors.separator
                    : colors.accent.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Text(
              _busy ? l10n.pairCodePanelWorking : l10n.pairCodePanelOrMakeASix,
              style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11.5, fontWeight: FontWeight.w600, color: _busy ? colors.textTertiary : colors.accent, letterSpacing: 0.12),
            ),
          ),
        ),
        if (_status.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10.5, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
          ),
        ],
      ],
    );
  }

  Widget _live() {
    final mm = whole(_left ~/ 60);
    final ss = twoDigits(_left % 60);
    return Column(
      key: const ValueKey('live'),
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            copySensitive(_code!);
            showHaloToast(context, l10n.pairCodePanelCodeCopied);
          },
          child: Text(
            '${_code!.substring(0, 3)} ${_code!.substring(3)}',
            style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: widget.compact ? 34 : 40, fontWeight: FontWeight.w600, color: colors.accent, letterSpacing: 0.16),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BreathDot(color: colors.accent, size: 6),
            const SizedBox(width: 8),
            Text(
              l10n.pairCodePanelBurnsIn(mm, ss),
              style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.compact
              ? l10n.pairCodePanelTheyTapAddChoose
              : l10n.pairCodePanelTheyOpenKryfoTap,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12.5, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
        ),
      ],
    );
  }
}
