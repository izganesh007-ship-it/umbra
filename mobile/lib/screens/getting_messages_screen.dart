// SPDX-License-Identifier: GPL-3.0-or-later
// how new messages reach this phone, in words a person who has never heard
// of tor can choose between.
import 'dart:async';

import 'package:flutter/material.dart';

import '../delivery_mode.dart';
import '../lock_state.dart';
import '../main.dart' show appState;
import '../miui_autostart.dart';
import '../notifications.dart';
import '../theme/theme.dart';
import '../widgets/motion.dart';
import '../widgets/press_scale.dart';
import '../widgets/halo_switch.dart';
import '../widgets/stagger_in.dart';
import '../l10n/l10n.dart';

class GettingMessagesScreen extends StatefulWidget {
  const GettingMessagesScreen({super.key});

  @override
  State<GettingMessagesScreen> createState() => _GettingMessagesScreenState();
}

class _GettingMessagesScreenState extends State<GettingMessagesScreen> {
  Timer? _tick;
  bool _busy = false;
  // what a notification shows on the lock screen: how messages arrive and
  // what they say when they do are the same question
  bool _hidePreview = true;

  @override
  void initState() {
    super.initState();
    // no .then() without a catch: a throw here must not break the page
    loadHideNotifContent()
        .then((v) {
          if (mounted) setState(() => _hidePreview = v);
        })
        .catchError((_) {});
    appState.addListener(_changed);
    // "4 min ago" has to become "5 min ago" on its own
    _tick = Timer.periodic(const Duration(seconds: 20), (_) => _changed());
  }

  @override
  void dispose() {
    _tick?.cancel();
    appState.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _pick(DeliveryMode m) async {
    if (_busy || m == appState.deliveryMode) return;
    setState(() => _busy = true);
    await appState.setDeliveryMode(m);
    if (!mounted) return;
    setState(() => _busy = false);
    if (m == DeliveryMode.checkins) {
      // a check-in is a background job. a phone that stops background work
      // stops check-ins too, so the same ask applies.
      unawaited(forceShowBackgroundPrompt(context));
    }
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    final mode = appState.deliveryMode;
    final s = appState.torStatus;
    final status = deliveryStatus(
      mode: mode,
      connected: s == TorStatus.reachable || s == TorStatus.publishing,
      connecting: s == TorStatus.starting || s == TorStatus.bootstrapped,
      lastCheckMs: appState.lastCheckAt,
      lastWakeMs: appState.lastWakeAt,
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: staggerAll([
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: l10n.commonBack,
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.chevron_left,
                        color: colors.textSecondary,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.gettingMessagesGettingMessages,
                      style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 30, fontWeight: FontWeight.w400, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.gettingMessagesHowNewMessagesReach,
                      style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.45, letterSpacing: 0),
                    ),
                  ],
                ),
              ),
              _ModeCard(
                title: l10n.gettingMessagesAlwaysOn,
                tag: l10n.gettingMessagesMostPrivate,
                body: l10n.gettingMessagesMessagesArriveInstantlyNothing,
                on: mode == DeliveryMode.always,
                onTap: () => _pick(DeliveryMode.always),
              ),
              _ModeCard(
                title: l10n.gettingMessagesCheckIns,
                tag: l10n.gettingMessagesLightest,
                body: l10n.gettingMessagesKryfoLooksForMessages,
                on: mode == DeliveryMode.checkins,
                onTap: () => _pick(DeliveryMode.checkins),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 2),
                child: Text(
                  l10n.gettingMessagesOnTheLockScreen,
                  style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10.5, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.06),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.gettingMessagesHideMessagePreview,
                            style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w400, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.gettingMessagesAGenericAlertWith,
                            style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12, fontWeight: FontWeight.w400, color: colors.textTertiary, height: 1.5, letterSpacing: 0),
                          ),
                          // a pin turns previews off. if someone turns them
                          // back on, say what that gives away.
                          if (lockState.enabled && !_hidePreview) ...[
                            const SizedBox(height: 6),
                            Text(
                              l10n.gettingMessagesShowsMessageTextIn,
                              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12, fontWeight: FontWeight.w400, color: colors.error, height: 1.5, letterSpacing: 0),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    HaloSwitch(
                      value: _hidePreview,
                      onChanged: (v) {
                        setState(() => _hidePreview = v);
                        setHideNotifContent(v);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: Row(
                  children: [
                    if (status.live)
                      BreathDot(color: colors.success, size: 6)
                    else
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          status.text,
                          style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 12, fontWeight: FontWeight.w500, color: status.live
                                ? colors.success
                                : colors.textPrimary, letterSpacing: 0.12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (mode == DeliveryMode.checkins)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                  child: Text(
                    l10n.gettingMessagesWhenThePhoneSits,
                    style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12.5, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String? tag;
  final String body;
  final bool on;
  final VoidCallback onTap;
  const _ModeCard({
    required this.title,
    this.tag,
    required this.body,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Semantics(
        selected: on,
        button: true,
        child: PressScale(
          label: '$title. $body',
          onTap: onTap,
          scale: 0.98,
          child: ExcludeSemantics(
            child: AnimatedContainer(
              duration: const UmbraMotion.durationNormal,
              curve: UmbraMotion.easeOut,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
              decoration: BoxDecoration(
                color: on
                    ? colors.accent.withValues(alpha: 0.08)
                    : colors.surfaceElevated,
                borderRadius: BorderRadius.circular(UmbraRadius.xl),
                border: Border.all(
                  color: on ? colors.accent : colors.separator,
                  width: on ? 1.4 : 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 15.5, fontWeight: FontWeight.w600, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
                        ),
                      ),
                      if (tag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tag!,
                            style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.accent, letterSpacing: 0.06),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
