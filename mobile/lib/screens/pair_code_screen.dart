// six digits read out loud, for when holding two phones together is awkward.
// both sides derive the same address from the digits alone and the invite
// passes through it sealed. the code burns after a few minutes.
import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/theme.dart';
import '../widgets/stagger_in.dart';
import '../widgets/pair_code_panel.dart';
import '../l10n/l10n.dart';

class PairCodeScreen extends StatefulWidget {
  // open on the entering side: the other person read their code out
  final bool entering;
  const PairCodeScreen({super.key, this.entering = false});
  @override
  State<PairCodeScreen> createState() => _PairCodeScreenState();
}

class _PairCodeScreenState extends State<PairCodeScreen> {
  late bool _sharing = !widget.entering;

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 20, 0),
              child: Row(
                children: staggerAll([
                  IconButton(
                    tooltip: l10n.commonBack,
                    icon: Icon(Icons.arrow_back, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    l10n.pairCodePairingCode,
                    style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 22, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
                  ),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  _Tab(
                    label: l10n.pairCodeShowACode,
                    on: _sharing,
                    onTap: () => setState(() => _sharing = true),
                  ),
                  const SizedBox(width: 8),
                  _Tab(
                    label: l10n.pairCodeEnterOne,
                    on: !_sharing,
                    onTap: () => setState(() => _sharing = false),
                  ),
                ],
              ),
            ),
            Expanded(child: _sharing ? const _ShareSide() : const _JoinSide()),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: on ? colors.accent.withValues(alpha: 0.14) : null,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: on
                ? colors.accent.withValues(alpha: 0.4)
                : colors.separator,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11, fontWeight: FontWeight.w500, color: on ? colors.accent : colors.textTertiary, letterSpacing: 0.12),
        ),
      ),
    );
  }
}

// ───────── show a code ─────────

class _ShareSide extends StatelessWidget {
  const _ShareSide();
  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      children: const [PairCodePanel()],
    );
  }
}

// ───────── enter one ─────────

class _JoinSide extends StatefulWidget {
  const _JoinSide();
  @override
  State<_JoinSide> createState() => _JoinSideState();
}

class _JoinSideState extends State<_JoinSide> {
  final _ctrl = TextEditingController();
  String _status = '';
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _ctrl.text.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6) {
      setState(() => _status = l10n.pairCodeSixDigits);
      return;
    }
    setState(() {
      _busy = true;
      _status = l10n.pairCodeLooking;
    });

    // the other side may not have pressed share yet, so give it a few goes
    for (var attempt = 0; attempt < 3; attempt++) {
      final res = await engine.pairCodeFetch(code);
      if (!mounted) return;
      if (res.startsWith('kryfo://')) {
        final status = await handleHaloUri(res);
        await appState.refreshContacts();
        if (!mounted) return;
        setState(() => _busy = false);
        showHaloToast(context, status);
        Navigator.of(context).pop();
        return;
      }
      if (res.startsWith('error')) {
        setState(() {
          _busy = false;
          _status = res.replaceFirst('error: ', '');
        });
        return;
      }
      if (attempt < 2) {
        setState(() => _status = l10n.pairCodeNothingThereYetTrying);
        await Future<void>.delayed(const Duration(seconds: 4));
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = l10n.pairCodeNothingAtThatCode;
    });
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      children: [
        Text(
          l10n.pairCodeTypeTheSixDigits,
          style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13.5, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
        ),
        const SizedBox(height: 20),
        TextField(
          textDirection: TextDirection.ltr,
          controller: _ctrl,
          keyboardType: TextInputType.number,
          maxLength: 7,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 28, fontWeight: FontWeight.w600, color: colors.textPrimary, letterSpacing: 0.14),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 28, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
            filled: true,
            fillColor: colors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(UmbraRadius.lg),
              borderSide: BorderSide(color: colors.separator),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(UmbraRadius.lg),
              borderSide: BorderSide(color: colors.separator),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _busy ? null : _join,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _busy ? colors.surfaceElevated : colors.accent,
              borderRadius: BorderRadius.circular(UmbraRadius.lg),
            ),
            child: Text(
              _busy ? l10n.pairCodeLooking : l10n.pairCodeAddThem,
              style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 12, fontWeight: FontWeight.w600, color: _busy ? colors.textTertiary : colors.accentOn, letterSpacing: 0.12),
            ),
          ),
        ),
        if (_status.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            _status,
            style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
          ),
        ],
      ],
    );
  }
}
