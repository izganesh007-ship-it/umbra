// SPDX-License-Identifier: GPL-3.0-or-later
// "introduce <B> to...": pick an accepted contact, add a line if you like,
// and both get the other's card. a sheet, not a screen: one decision made
// from inside a conversation.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../intro_budget.dart';
import '../main.dart' show appState;
import '../screens/home_screen.dart' show ContactPreview;
import '../theme/theme.dart';
import '../vouch_text.dart';
import '../widgets/kryfo_avatar.dart';
import '../widgets/notice_banner.dart';
import '../widgets/halo_sheet.dart';
import '../widgets/sheet_handle.dart';
import '../l10n/l10n.dart';

const _noteMax = 40;

// the sheet hands back what to say; the toast is shown from here, after
// the sheet is gone, so the messenger never sees a half-popped scaffold.
Future<void> showIntroduceSheet(
  BuildContext context, {
  required String peerId,
  required String peerName,
}) async {
  final toast = await showHaloSheet<String>(
    context,
    scroll: true,
    builder: (_) => _IntroduceSheet(peerId: peerId, peerName: peerName),
  );
  if (toast != null && context.mounted) showHaloToast(context, toast);
}

class _IntroduceSheet extends StatefulWidget {
  final String peerId;
  final String peerName;
  const _IntroduceSheet({required this.peerId, required this.peerName});
  @override
  State<_IntroduceSheet> createState() => _IntroduceSheetState();
}

class _IntroduceSheetState extends State<_IntroduceSheet> {
  final _noteCtrl = TextEditingController();
  String? _picked;
  IntroBudget? _budget;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    IntroBudget.load().then((b) {
      if (mounted) setState(() => _budget = b);
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  List<ContactPreview> get _others => appState.contacts
      .where((c) => c.haloId != widget.peerId && !c.blocked)
      .toList();

  int get _now => DateTime.now().millisecondsSinceEpoch;
  int get _left => _budget?.leftAt(_now) ?? 0;
  bool get _canSend =>
      _picked != null && !_sending && _budget != null && _left > 0;

  String _nameOf(String id) {
    for (final c in appState.contacts) {
      if (c.haloId == id) return c.nickname ?? id;
    }
    return id;
  }

  Future<void> _go() async {
    final other = _picked;
    if (other == null || !_canSend) return;
    HapticFeedback.mediumImpact();
    setState(() => _sending = true);
    final r = await appState.introduce(
      widget.peerId,
      other,
      note: _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    final any = r.toFirst || r.toSecond;
    if (any) {
      final b = _budget!.recordAt(_now);
      await b.save(_now);
      if (!mounted) return;
      _budget = b;
    }
    final b = widget.peerName;
    final c = _nameOf(other);
    if (r.toFirst && r.toSecond) {
      Navigator.of(context).pop('introduced');
    } else if (any) {
      Navigator.of(context).pop(
        r.toFirst
            ? l10n.introduceGotItButCould(b, c)
            : l10n.introduceGotItButCouldNotBe(c, b),
      );
    } else {
      setState(() => _sending = false);
      showHaloToast(context, l10n.introduceCouldNotReachEither);
    }
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    final others = _others;
    final maxH = MediaQuery.of(context).size.height * 0.82;
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: UmbraMotion.easeOut,
      padding: EdgeInsets.only(bottom: insets),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Text(
                l10n.introduceIntroduceTo(widget.peerName),
                style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 20, fontWeight: FontWeight.w400, color: colors.textPrimary, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.introduceBothOfThemGet,
                style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
              ),
            ),
            Flexible(
              child: others.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Text(
                        l10n.introduceNoOneElseTo,
                        style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary, height: 1.5, letterSpacing: 0),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: others.length,
                      itemBuilder: (_, i) {
                        final c = others[i];
                        return _FadeRight(
                          index: i,
                          child: _PickRow(
                            contact: c,
                            picked: _picked == c.haloId,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(
                                () => _picked = _picked == c.haloId
                                    ? null
                                    : c.haloId,
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
            Divider(color: colors.separator, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: TextField(
                controller: _noteCtrl,
                maxLength: _noteMax,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.none,
                style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w400, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
                cursorColor: colors.accent,
                decoration: InputDecoration(
                  hintText: l10n.introduceANoteLikeMy,
                  hintStyle: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 14, fontWeight: FontWeight.w400, color: colors.textTertiary, fontStyle: FontStyle.italic, height: 1.05, letterSpacing: -0.015),
                  counterText: '',
                  suffixText: _noteCtrl.text.isEmpty
                      ? null
                      : '${_noteCtrl.text.length}/$_noteMax',
                  suffixStyle: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 9, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
                  isDense: true,
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(UmbraRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            // the one warning there is. no approval step behind it, on
            // purpose: the introducer could forward an invite by hand anyway.
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: UmbraMotion.easeOut,
              alignment: Alignment.topCenter,
              child: _picked == null
                  ? const SizedBox(width: double.infinity, height: 0)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: NoticeBanner(
                        key: ValueKey(_picked),
                        glyph: NoticeGlyph.link,
                        text: shareWarning(widget.peerName, _nameOf(_picked!)),
                        color: colors.accent,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: _GoButton(
                enabled: _canSend,
                sending: _sending,
                onTap: _go,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                14 + MediaQuery.of(context).padding.bottom,
              ),
              child: Center(child: _caption()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _caption() {
    final b = _budget;
    if (b == null) return const SizedBox(height: 14);
    final String text;
    final refill = b.refillAt(_now);
    if (refill == null) {
      text = l10n.introduceOfIntroductionsLeftThis(_left, introBudgetMax);
    } else {
      final until = Duration(milliseconds: refill - _now);
      text = l10n.introduceNoIntroductionsLeftNext(refillPhrase(until));
    }
    return AnimatedSwitcher(
      duration: const UmbraMotion.durationNormal,
      child: Text(
        text,
        key: ValueKey(text),
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: refill == null ? colors.textTertiary : colors.accent, letterSpacing: 0.12),
      ),
    );
  }
}

// one contact to pick. the face grows and gets an amber ring when chosen.
class _PickRow extends StatelessWidget {
  final ContactPreview contact;
  final bool picked;
  final VoidCallback onTap;
  const _PickRow({
    required this.contact,
    required this.picked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    final name = contact.nickname;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            AnimatedScale(
              scale: picked ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: UmbraMotion.easeOut,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: picked ? colors.accent : Colors.transparent,
                    width: 1.6,
                  ),
                ),
                child: KryfoAvatar(
                  seed: contact.avatarSeed,
                  size: 38,
                  choice: contact.avatar,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? contact.haloId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: name == null
                        ? TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 12, fontWeight: FontWeight.w500, color: colors.textPrimary, letterSpacing: 0.12)
                        : TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary, height: 1.5, letterSpacing: 0),
                  ),
                  if (name != null)
                    Text(
                      contact.haloId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: colors.textTertiary, letterSpacing: 0.12),
                    ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: picked ? colors.accent : Colors.transparent,
                border: Border.all(
                  color: picked ? colors.accent : colors.separatorStrong,
                  width: 1.4,
                ),
              ),
              alignment: Alignment.center,
              child: picked
                  ? Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: colors.accentOn,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// primary amber button. dims when there is nothing to send, shows a small
// spinner while the two frames are out.
class _GoButton extends StatefulWidget {
  final bool enabled;
  final bool sending;
  final VoidCallback onTap;
  const _GoButton({
    required this.enabled,
    required this.sending,
    required this.onTap,
  });
  @override
  State<_GoButton> createState() => _GoButtonState();
}

class _GoButtonState extends State<_GoButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    final on = widget.enabled;
    return GestureDetector(
      onTapDown: on ? (_) => setState(() => _down = true) : null,
      onTapUp: on ? (_) => setState(() => _down = false) : null,
      onTapCancel: on ? () => setState(() => _down = false) : null,
      onTap: on ? widget.onTap : null,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: UmbraMotion.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on || widget.sending
                ? colors.accent
                : colors.surfaceHover,
            borderRadius: BorderRadius.circular(14),
          ),
          child: widget.sending
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.accentOn,
                  ),
                )
              : Text(
                  l10n.introduceIntroduce,
                  style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 15, fontWeight: FontWeight.w600, color: on ? colors.accentOn : colors.textTertiary, height: 1.5, letterSpacing: 0),
                ),
        ),
      ),
    );
  }
}

// staggered slide in from the right, one row after the other.
class _FadeRight extends StatefulWidget {
  final int index;
  final Widget child;
  const _FadeRight({required this.index, required this.child});
  @override
  State<_FadeRight> createState() => _FadeRightState();
}

class _FadeRightState extends State<_FadeRight> {
  double _t = 0;
  @override
  void initState() {
    super.initState();
    final delay = 80 + (widget.index * 40).clamp(0, 360);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) setState(() => _t = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    return AnimatedOpacity(
      opacity: _t,
      duration: const UmbraMotion.durationSlow,
      curve: UmbraMotion.easeOut,
      child: AnimatedSlide(
        offset: Offset((1 - _t) * 0.06, 0),
        duration: const Duration(milliseconds: 280),
        curve: UmbraMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}
