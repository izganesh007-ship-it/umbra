// SPDX-License-Identifier: GPL-3.0-or-later
// claim a public handle. the one screen that makes someone findable by
// strangers, so it says what that costs first and is off until asked for.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart' show appState, engine, buildHaloUriV3;
import '../theme/theme.dart';
import '../widgets/stagger_in.dart';
import '../l10n/l10n.dart';

class HandleScreen extends StatefulWidget {
  const HandleScreen({super.key});
  @override
  State<HandleScreen> createState() => _HandleScreenState();
}

class _HandleScreenState extends State<HandleScreen> {
  final _ctrl = TextEditingController();
  final _bio = TextEditingController();
  Timer? _debounce;
  String _state = ''; // '', checking, free, taken, error text
  bool _busy = false;
  String? _claimed;

  @override
  void initState() {
    super.initState();
    _claimed = appState.myHandle;
    if (_claimed != null) {
      _ctrl.text = _claimed!;
      // ask the registry whose it is, so the card below tells the truth
      appState.checkHandle().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _onTyped(String v) {
    _debounce?.cancel();
    final h = v.trim().toLowerCase();
    if (h.isEmpty) {
      setState(() => _state = '');
      return;
    }
    setState(() => _state = 'checking');
    // wait for typing to stop before asking the registry
    _debounce = Timer(const UmbraMotion.durationSlower, () async {
      final r = await engine.handleCheck(h);
      if (!mounted) return;
      setState(() => _state = r);
    });
  }

  Future<void> _claim() async {
    final h = _ctrl.text.trim().toLowerCase();
    if (h.isEmpty || _state != 'free') return;
    setState(() => _busy = true);
    // same invite the qr code carries, so the registry only holds what is
    // already public
    final uri = await buildHaloUriV3(
      appState.myId,
      appState.myOnion,
      appState.fcCounter,
    );
    final r = await engine.handleClaim(h, uri, _bio.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (r == 'ok') {
      await appState.setMyHandle(h, bio: _bio.text.trim());
      if (!mounted) return;
      setState(() => _claimed = h);
      showHaloToast(context, l10n.handleYouAre(h));
    } else {
      showHaloToast(context, r.replaceFirst('error: ', ''));
    }
  }

  // the name is on this phone and under another key at the registry.
  // nothing here can release it; all that can be done is stop claiming it.
  Future<void> _forget() async {
    await appState.setMyHandle(null);
    if (!mounted) return;
    setState(() {
      _claimed = null;
      _ctrl.clear();
      _state = '';
    });
  }

  Future<void> _release() async {
    final h = _claimed;
    if (h == null) return;
    setState(() => _busy = true);
    final r = await engine.handleRelease(h);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r == 'ok') {
      await appState.setMyHandle(null);
      if (!mounted) return;
      setState(() {
        _claimed = null;
        _ctrl.clear();
        _state = '';
      });
      showHaloToast(context, l10n.handleHandleDeletedThePage);
    } else {
      showHaloToast(context, r.replaceFirst('error: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(l10n.handlePublicHandle, style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 18, fontWeight: FontWeight.w400, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: staggerAll([
          if (_claimed != null && appState.handleForeign) ...[
            _ForeignCard(handle: _claimed!, onForget: _forget),
            const SizedBox(height: 22),
          ] else if (_claimed != null) ...[
            _ClaimedCard(handle: _claimed!, onRelease: _busy ? null : _release),
            const SizedBox(height: 22),
          ] else ...[
            Text(
              l10n.handleOptionalYourThreeWords,
              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13.5, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
            ),
            const SizedBox(height: 20),
            _Field(
              ctrl: _ctrl,
              hint: l10n.handleWren,
              prefix: '@',
              onChanged: _onTyped,
              max: 20,
            ),
            const SizedBox(height: 8),
            _Availability(state: _state),
            const SizedBox(height: 18),
            _Field(
              ctrl: _bio,
              hint: l10n.handleALineAboutYou,
              max: 200,
              lines: 2,
            ),
            const SizedBox(height: 22),
            const _RiskBlock(),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: (_state == 'free' && !_busy) ? _claim : null,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _state == 'free'
                      ? colors.accent
                      : colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _state == 'free'
                        ? Colors.transparent
                        : colors.separator,
                  ),
                ),
                child: Text(
                  _busy ? l10n.handleClaiming : l10n.handleClaimThisHandle,
                  style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 12.5, fontWeight: FontWeight.w600, color: _state == 'free' ? colors.ink : colors.textTertiary, letterSpacing: 0.12),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _ClaimedCard extends StatelessWidget {
  final String handle;
  final VoidCallback? onRelease;
  const _ClaimedCard({required this.handle, this.onRelease});

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    final url = 'https://relay.kryfo.app/@$handle';
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(UmbraRadius.xl),
        border: Border.all(color: colors.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 16, color: colors.success),
              const SizedBox(width: 8),
              Text(
                ltr('@$handle'),
                style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 20, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.handleAnyoneWithThisLink,
            style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              copySensitive(url);
              showHaloToast(context, l10n.handleLinkCopied);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.separator),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      url,
                      style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11, fontWeight: FontWeight.w500, color: colors.textSecondary, letterSpacing: 0.12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.copy, size: 14, color: colors.textTertiary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRelease,
            behavior: HitTestBehavior.opaque,
            child: Text(
              l10n.handleDeleteThisHandle,
              style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11.5, fontWeight: FontWeight.w500, color: colors.error, letterSpacing: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Availability extends StatelessWidget {
  final String state;
  const _Availability({required this.state});

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    if (state.isEmpty) return const SizedBox(height: 16);
    late final String txt;
    late final Color c;
    if (state == 'checking') {
      txt = l10n.handleChecking;
      c = colors.textTertiary;
    } else if (state == 'free') {
      txt = l10n.handleAvailable;
      c = colors.success;
    } else if (state == 'taken') {
      txt = l10n.handleAlreadyTaken;
      c = colors.error;
    } else {
      txt = state.replaceFirst('error: ', '');
      c = colors.accent;
    }
    return SizedBox(
      height: 16,
      child: Text(txt, style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11, fontWeight: FontWeight.w500, color: c, letterSpacing: 0.12)),
    );
  }
}

class _RiskBlock extends StatelessWidget {
  const _RiskBlock();

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.handleWhatAHandleDoes,
            style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 11, fontWeight: FontWeight.w600, color: colors.accent, letterSpacing: 0.1),
          ),
          const SizedBox(height: 9),
          Text(
            l10n.handleAnyoneWhoKnowsIt,
            style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12.5, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final String? prefix;
  final ValueChanged<String>? onChanged;
  final int max;
  final int lines;
  const _Field({
    required this.ctrl,
    required this.hint,
    this.prefix,
    this.onChanged,
    this.max = 40,
    this.lines = 1,
  });

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(UmbraRadius.lg),
        border: Border.all(color: colors.separator),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prefix != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 14, end: 2),
              child: Text(
                prefix!,
                style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 14, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
              ),
            ),
          Expanded(
            child: TextField(
              textDirection: TextDirection.ltr,
              controller: ctrl,
              onChanged: onChanged,
              maxLength: max,
              minLines: lines,
              maxLines: lines,
              style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary, letterSpacing: 0.12),
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: hint,
                hintStyle: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 14, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// shown in place of the claimed card when the registry holds the name
// under a key that is not this phone's
class _ForeignCard extends StatelessWidget {
  final String handle;
  final VoidCallback onForget;
  const _ForeignCard({required this.handle, required this.onForget});

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.error, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.handleIsNotYoursOn(handle),
            style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 19, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.handleTheRegistryHoldsIt(handle),
            style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onForget,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.separator),
              ),
              child: Text(
                l10n.handleForgetItOnThis,
                style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13.5, fontWeight: FontWeight.w600, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
