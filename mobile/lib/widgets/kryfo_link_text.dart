// SPDX-License-Identifier: GPL-3.0-or-later
// message text that knows a kryfo link when it holds one. a message that is
// only a room link is drawn as an invitation with a button; a link among
// other words is drawn short and can be tapped. the text on the wire is the
// same, so an older kryfo shows it as plain text.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart' show handleHaloUri, parseHaloUri;
import '../rooms.dart';
import '../theme/theme.dart';
import 'confirm_sheet.dart';
import '../l10n/l10n.dart';

/// takes a tapped link through the one door every link goes through, and
/// says what came of it. a room opens itself once joined.
Future<void> followKryfoLink(BuildContext context, String link) async {
  final room = RoomLink.parse(link);
  if (room == null) {
    final who = parseHaloUri(link)?['id'];
    if (who == null) {
      showHaloToast(context, l10n.kryfoLinkTextThatLinkIsNot);
      return;
    }
    final ok = await showConfirmSheet(
      context,
      title: l10n.kryfoLinkTextAdd(who),
      line: l10n.kryfoLinkTextThisIsAnInvite(who),
      yes: l10n.kryfoLinkTextAddThem,
      keep: l10n.kryfoLinkTextNotNow,
      rose: false,
    );
    if (!ok || !context.mounted) return;
  }
  HapticFeedback.selectionClick();
  final r = await handleHaloUri(link);
  if (context.mounted) showHaloToast(context, r);
}

class KryfoLinkText extends StatefulWidget {
  final String text;
  final TextStyle style;
  // on an amber bubble amber does not read; the caller says what does
  final Color linkColor;
  final bool onAmber;
  const KryfoLinkText({
    super.key,
    required this.text,
    required this.style,
    required this.linkColor,
    this.onAmber = false,
  });
  @override
  State<KryfoLinkText> createState() => _KryfoLinkTextState();
}

class _KryfoLinkTextState extends State<KryfoLinkText> {
  final List<TapGestureRecognizer> _taps = [];

  void _drop() {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _drop();
    super.dispose();
  }

  static String _label(String link) {
    final room = RoomLink.parse(link);
    if (room != null) return l10n.kryfoLinkTextJoin(room.name);
    final who = parseHaloUri(link)?['id'];
    return who == null
        ? l10n.kryfoLinkTextKryfoLink
        : l10n.kryfoLinkTextAdd2(who);
  }

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    final text = widget.text;
    if (!text.contains('kryfo://')) return Text(text, style: widget.style);
    final only = text.trim();
    final room = RoomLink.parse(only);
    if (room != null && firstKryfoLink(only) == only) {
      return RoomInviteCard(room: room, link: only, onAmber: widget.onAmber);
    }
    _drop();
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in kryfoLinksIn(text)) {
      if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
      final link = m.group(0)!;
      final tap = TapGestureRecognizer()
        ..onTap = () => followKryfoLink(context, link);
      _taps.add(tap);
      spans.add(
        TextSpan(
          text: _label(link),
          recognizer: tap,
          style: TextStyle(
            color: widget.linkColor,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: widget.linkColor,
          ),
        ),
      );
      at = m.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}

/// a room link on its own in a message
class RoomInviteCard extends StatelessWidget {
  final RoomLink room;
  final String link;
  final bool onAmber;
  const RoomInviteCard({
    super.key,
    required this.room,
    required this.link,
    this.onAmber = false,
  });

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    final fg = onAmber ? colors.accentOn : colors.textPrimary;
    final sub = onAmber ? colors.accentOn : colors.textSecondary;
    final closed = room.expiresAt <= DateTime.now().millisecondsSinceEpoch;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.kryfoLinkTextBurnerRoom,
            style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 9.5, fontWeight: FontWeight.w500, color: sub, letterSpacing: 0.9),
          ),
          const SizedBox(height: 3),
          Text(
            room.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: 19, fontWeight: FontWeight.w400, color: fg, fontStyle: FontStyle.normal, height: 1.05, letterSpacing: -0.015),
          ),
          const SizedBox(height: 4),
          if (closed)
            Text(
              l10n.kryfoLinkTextThisRoomHasClosed,
              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 12.5, fontWeight: FontWeight.w400, color: sub, height: 1.5, letterSpacing: 0),
            )
          else
            // said once, in the bubble's own colour: the ticking countdown
            // picks its tone from the theme and vanishes on an amber bubble
            Text(
              room.cap != null
                  ? l10n.kryfoLinkTextClosesInUpTo(room.cap!, _left(room))
                  : l10n.kryfoLinkTextClosesIn(_left(room)),
              style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10, fontWeight: FontWeight.w500, color: sub, letterSpacing: 0.12),
            ),
          if (!closed) ...[
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => followKryfoLink(context, link),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: onAmber ? colors.accentOn : colors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.kryfoLinkTextJoin2,
                  style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13.5, fontWeight: FontWeight.w600, color: onAmber ? colors.accent : colors.accentOn, height: 1.5, letterSpacing: 0),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.kryfoLinkTextYouJoinUnderA,
              style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 11.5, fontWeight: FontWeight.w400, color: sub, height: 1.35, letterSpacing: 0),
            ),
          ],
        ],
      ),
    );
  }
}

String _left(RoomLink room) => countdownLabel(
  DateTime.fromMillisecondsSinceEpoch(
    room.expiresAt,
  ).difference(DateTime.now()),
);
