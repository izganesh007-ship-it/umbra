// SPDX-License-Identifier: GPL-3.0-or-later
// speed and privacy modes. private, over tor, is the default; balanced
// exists because mandatory tor is the app's biggest usability cost.

import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../main.dart';
import '../widgets/halo_sheet.dart';
import '../widgets/sheet_handle.dart';
import 'package:flutter/services.dart';
import '../widgets/stagger_in.dart';
import '../widgets/fit_column.dart';
import '../l10n/l10n.dart';
import '../l10n/marked.dart';

class ModesScreen extends StatefulWidget {
  const ModesScreen({super.key});
  @override
  State<ModesScreen> createState() => _ModesScreenState();
}

class _ModesScreenState extends State<ModesScreen> {
  String _mode = 'private';

  @override
  void initState() {
    super.initState();
    _sync();
  }

  Future<void> _sync() async {
    await appState.loadSendMode();
    if (appState.sendMode == 'normal') await appState.setSendMode('private');
    if (mounted) setState(() => _mode = appState.sendMode);
  }

  void _pick(String m) {
    setState(() => _mode = m);
    appState.setSendMode(m);
  }

  // fast is the one mode that costs something, so it says so first
  Future<void> _pickFast() async {
    if (_mode == 'fast') return;
    final ok = await showFastGateSheet(context);
    if (ok && mounted) {
      HapticFeedback.mediumImpact();
      _pick('fast');
    }
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        // fits or scrolls: a plain column runs past the body on a short
        // phone and whatever sits below the fold cannot be tapped
        child: FitColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // the spacer stays a direct child of the column: wrapped by the
            // stagger it throws a parent-data error, which release paints as
            // a light box
            ...staggerAll([
              _BackBar(onBack: () => Navigator.pop(context)),
              const _Head(),
              const SizedBox(height: 6),
              _ModeCard(
                name: l10n.modesOnion,
                accent: '·',
                active: _mode == 'private',
                desc: l10n.modesFullOnionRoutingThree,
                speed: l10n.modesSlower,
                hops: '3',
                ipVisible: false,
                onTap: () => _pick('private'),
              ),
              _ModeCard(
                name: l10n.modesRelay,
                active: _mode == 'balanced',
                desc: l10n.modesOneSealedConnectionTo,
                speed: l10n.modesQuick,
                hops: '1',
                ipVisible: false,
                ipText: l10n.modesRelayOnly,
                ipWarn: true,
                onTap: () => _pick('balanced'),
              ),
              _ModeCard(
                name: l10n.modesFast,
                active: _mode == 'fast',
                desc: l10n.modesPlainConnectionsToEvery,
                speed: l10n.modesInstant,
                hops: '0',
                ipVisible: true,
                warning: l10n.modesEveryRelayYouUse,
                onTap: _pickFast,
              ),
            ]),
            const Spacer(),
            const StaggerIn(
              index: 5,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _Footnote(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackBar extends StatelessWidget {
  final VoidCallback onBack;
  const _BackBar({required this.onBack});
  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 0, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.commonBack,
            onPressed: onBack,
            icon: Icon(Icons.chevron_left, color: colors.textSecondary, size: 26),
          ),
        ],
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head();
  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                l10n.modesSpeed,
                style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 30, fontWeight: FontWeight.w400, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.modesPrivacy,
                style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 30, fontWeight: FontWeight.w300, color: colors.accent, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.modesChangeGloballyOrPer,
            style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 11, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String name;
  final String? accent;
  final bool active;
  final bool soon = false;
  final String desc;
  final String speed;
  final String hops;
  final bool ipVisible;
  // some tiers aren't a clean hidden/visible: 'relay only' is its own
  final String? ipText;
  final bool ipWarn;
  final String? warning;
  final VoidCallback onTap;
  const _ModeCard({
    required this.name,
    this.accent,
    required this.active,
    required this.desc,
    required this.speed,
    required this.hops,
    required this.ipVisible,
    this.ipText,
    this.ipWarn = false,
    this.warning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: GestureDetector(
        onTap: soon ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: active
                ? colors.accent.withValues(alpha: 0.10)
                : colors.surface,
            border: Border.all(
              color: active ? colors.accent : colors.separator,
              width: active ? 1 : 0.5,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 18, fontWeight: FontWeight.w400, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
                  ),
                  if (soon) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceHover,
                        borderRadius: BorderRadius.circular(UmbraRadius.sm),
                      ),
                      child: Text(
                        l10n.modesSoon,
                        style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 9, fontWeight: FontWeight.w500, color: colors.accent, letterSpacing: 0.6),
                      ),
                    ),
                  ],
                  if (active && accent != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      accent!,
                      style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 18, fontWeight: FontWeight.w400, color: colors.accent, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
                    ),
                  ],
                  const Spacer(),
                  if (active)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.modesActive,
                        style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.accentOn, letterSpacing: 0.12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 11, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Meta(k: l10n.modesSpeed2, v: speed),
                  const SizedBox(width: 14),
                  _Meta(k: l10n.modesHops, v: hops),
                  const SizedBox(width: 14),
                  _Meta(
                    k: l10n.modesIp,
                    v:
                        ipText ??
                        (ipVisible ? l10n.modesVisible : l10n.modesHidden),
                    red: ipVisible,
                    warn: ipWarn,
                  ),
                ],
              ),
              if (warning != null && active) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.10),
                    border: Border.all(
                      color: colors.error.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(UmbraRadius.md),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 10, fontWeight: FontWeight.w400, color: colors.error, height: 1.4, letterSpacing: 0),
                      children: markedSpans(
                        l10n.modesHeadsUp(warning!),
                        TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 10, fontWeight: FontWeight.w500, color: colors.error, height: 1.5, letterSpacing: 0),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final String k;
  final String v;
  final bool red;
  final bool warn;
  const _Meta({
    required this.k,
    required this.v,
    this.red = false,
    this.warn = false,
  });
  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return Row(
      children: [
        Text(k, style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12)),
        const SizedBox(width: 4),
        Text(
          v,
          style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 10, fontWeight: FontWeight.w500, color: red
                ? colors.error
                : warn
                ? colors.accent
                : colors.textPrimary, height: 1.5, letterSpacing: 0),
        ),
      ],
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote();
  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return Text(
      l10n.modesOnionIsTheDefault,
      style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
    );
  }
}

// what fast costs, in plain words. shown by every way into it: the modes
// screen and the home's "our relay is quiet" shortcut alike
Future<bool> showFastGateSheet(BuildContext context) async {
  final ok = await showHaloSheet<bool>(
    context,
    scroll: true,
    builder: (_) => const _FastGateSheet(),
  );
  return ok == true;
}

class _FastGateSheet extends StatelessWidget {
  const _FastGateSheet();

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 12),
            Text(
              l10n.modesFastMode,
              style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 20, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.modesPlainConnectionsToEveryRelayQuicker,
              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.45, letterSpacing: 0),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => Navigator.pop(context, true),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  l10n.modesTurnOnFastMode,
                  style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w600, color: colors.accentOn, height: 1.5, letterSpacing: 0),
                ),
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => Navigator.pop(context, false),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    l10n.modesKeepItOff,
                    style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
