// SPDX-License-Identifier: GPL-3.0-or-later
// the line under a bubble that holds a link: the bare domain, and the page
// title when the sender fetched one over tor and shipped it inside the
// message. the reader's phone never asks the network for anything here.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../link_preview.dart';
import '../theme/theme.dart';
import '../l10n/l10n.dart';

class LinkStub extends StatelessWidget {
  final String url;
  final String? title;
  final bool isOut;
  // the title came inside the message, fetched by the sender over tor
  final bool bySender;
  const LinkStub({
    super.key,
    required this.url,
    required this.isOut,
    this.title,
    this.bySender = false,
  });

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

  final colors = UmbraTheme.colorsOf(context);

    final fg = isOut ? colors.accentOn : colors.textPrimary;
    final soft = isOut
        ? colors.accentOn.withValues(alpha: 0.75)
        : colors.textSecondary;
    final t = title;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: (isOut ? colors.accentOn : colors.textPrimary).withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // the domain row opens the link, which is the reader's own doing
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              HapticFeedback.selectionClick();
              final u = Uri.tryParse(url);
              if (u != null && await canLaunchUrl(u)) {
                await launchUrl(u, mode: LaunchMode.externalApplication);
              }
            },
            child: Row(
              children: [
                Icon(Icons.link, size: 12, color: soft),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    domainOf(url),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 10.5, fontWeight: FontWeight.w500, color: soft, letterSpacing: 0.02),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: UmbraMotion.easeOut,
            alignment: AlignmentDirectional.topStart,
            child: t != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: 13, fontWeight: FontWeight.w600, color: fg, height: 1.3, letterSpacing: 0),
                        ),
                        if (bySender) ...[
                          const SizedBox(height: 3),
                          Text(
                            isOut
                                ? l10n.linkStubFetchedOverTorBy
                                : l10n.linkStubFetchedOverTorByTheirDevice,
                            style: TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: 9.5, fontWeight: FontWeight.w500, color: isOut
                                  ? colors.accentOn.withValues(alpha: 0.7, letterSpacing: 0.12)
                                  : colors.textTertiary,
                              letter: 0.02,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
