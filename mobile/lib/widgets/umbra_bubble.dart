// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra Message Bubble widget - iMessage-calibrated with tail

import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum UmbraBubbleDirection {
  incoming,
  outgoing,
}

enum UmbraBubbleStyle {
  normal,
  frosted,
}

class UmbraBubble extends StatelessWidget {
  final String text;
  final UmbraBubbleDirection direction;
  final UmbraBubbleStyle style;
  final DateTime time;
  final String? status; // pending, sent, delivered, read
  final bool showTime;
  final bool showStatus;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final Widget? replyPreview;
  final List<UmbraReaction> reactions;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final bool highlighted;
  final bool isSecure;
  final int? burnSeconds;
  final String? senderName; // For group chats
  final bool showSenderName;

  const UmbraBubble({
    super.key,
    required this.text,
    required this.direction,
    required this.time,
    this.style = UmbraBubbleStyle.normal,
    this.status,
    this.showTime = true,
    this.showStatus = true,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.replyPreview,
    this.reactions = const [],
    this.onLongPress,
    this.onTap,
    this.highlighted = false,
    this.isSecure = false,
    this.burnSeconds,
    this.senderName,
    this.showSenderName = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final isOutgoing = direction == UmbraBubbleDirection.outgoing;
    final isFrosted = style == UmbraBubbleStyle.frosted;

    // Bubble colors
    Color bubbleColor;
    Color textColor;
    Color timeColor;

    if (isFrosted) {
      bubbleColor = colors.bubbleFrosted;
      textColor = colors.textPrimary;
      timeColor = colors.textTertiary;
    } else if (isOutgoing) {
      bubbleColor = colors.bubbleOutgoing;
      textColor = colors.bubbleOutgoingText;
      timeColor = colors.bubbleOutgoingText.withValues(alpha: 0.7);
    } else {
      bubbleColor = colors.bubbleIncoming;
      textColor = colors.bubbleIncomingText;
      timeColor = colors.bubbleIncomingText.withValues(alpha: 0.7);
    }

    final radius = UmbraComponentTokens.bubbleRadius;
    final tailWidth = UmbraComponentTokens.bubbleTailWidth;
    final tailHeight = UmbraComponentTokens.bubbleTailHeight;
    final maxWidth = MediaQuery.of(context).size.width * UmbraComponentTokens.bubbleMaxWidth;
    final horizontalPadding = UmbraComponentTokens.bubblePaddingX;
    final verticalPadding = UmbraComponentTokens.bubblePaddingY;

    // Build the bubble content
    final content = Column(
      crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reply preview
        if (replyPreview != null) ...[
          _buildReplyPreview(colors, isOutgoing, textColor),
          SizedBox(height: UmbraSpacing.space2),
        ],

        // Sender name (for group incoming)
        if (showSenderName && senderName != null && !isOutgoing && isFirstInGroup) ...[
          Padding(
            padding: EdgeInsets.only(
              left: isOutgoing ? 0 : horizontalPadding,
              right: isOutgoing ? horizontalPadding : 0,
            ),
            child: Text(
              senderName!,
              style: TextStyle(
                fontSize: UmbraTypography.textXs,
                fontWeight: FontWeight.w600,
                color: colors.accent,
                fontFamily: UmbraTypography.fontSans,
              ),
            ),
          ),
          SizedBox(height: UmbraSpacing.space1),
        ],

        // Message text
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: SelectableText(
              text,
              style: TextStyle(
                fontSize: UmbraTypography.textBase,
                height: UmbraTypography.leadingNormal,
                color: textColor,
                fontFamily: UmbraTypography.fontSans,
              ),
            ),
          ),
        ),

        // Burn timer indicator
        if (burnSeconds != null && burnSeconds! > 0) ...[
          SizedBox(height: UmbraSpacing.space1),
          _buildBurnTimer(colors, isOutgoing, textColor),
        ],

        // Reactions
        if (reactions.isNotEmpty) ...[
          SizedBox(height: UmbraSpacing.space2),
          _buildReactions(colors, isOutgoing),
        ],

        // Time and status
        if (showTime || (showStatus && isOutgoing)) ...[
          SizedBox(height: UmbraSpacing.space1),
          _buildMetaRow(colors, isOutgoing, timeColor, bubbleColor),
        ],
      ],
    );

    // Wrap in custom painter for tail and background
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: CustomPaint(
        painter: _BubblePainter(
          direction: direction,
          color: bubbleColor,
          radius: radius,
          tailWidth: tailWidth,
          tailHeight: tailHeight,
          isFirstInGroup: isFirstInGroup,
          isLastInGroup: isLastInGroup,
          isFrosted: isFrosted,
          frostedBorderColor: colors.bubbleFrostedBorder,
          highlighted: highlighted,
          highlightColor: colors.accentSoft,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: isOutgoing ? 0 : tailWidth,
            right: isOutgoing ? tailWidth : 0,
            top: isFirstInGroup ? UmbraSpacing.space2 : 0,
            bottom: isLastInGroup ? UmbraSpacing.space2 : 0,
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildReplyPreview(UmbraSemanticColors colors, bool isOutgoing, Color textColor) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
      child: Container(
        padding: EdgeInsets.all(UmbraSpacing.space2),
        decoration: BoxDecoration(
          color: isOutgoing
              ? colors.accentSoft.withValues(alpha: 0.3)
              : colors.surfaceHover,
          borderRadius: BorderRadius.circular(UmbraRadius.md),
          border: Border.all(
            color: colors.separator.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyPreview is _ReplyPreviewWidget) ...[
              Text(
                (replyPreview as _ReplyPreviewWidget).senderName,
                style: TextStyle(
                  fontSize: UmbraTypography.textXs,
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                  fontFamily: UmbraTypography.fontSans,
                ),
              ),
              SizedBox(height: UmbraSpacing.space1),
              Text(
                (replyPreview as _ReplyPreviewWidget).text,
                style: TextStyle(
                  fontSize: UmbraTypography.textSm,
                  color: textColor.withValues(alpha: 0.8),
                  fontFamily: UmbraTypography.fontSans,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else if (replyPreview != null) ...[
              DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: UmbraTypography.textSm,
                  color: textColor.withValues(alpha: 0.8),
                  fontFamily: UmbraTypography.fontSans,
                ),
                child: replyPreview!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBurnTimer(UmbraSemanticColors colors, bool isOutgoing, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer_rounded,
          size: UmbraTypography.textXs * 1.2,
          color: colors.warning,
        ),
        SizedBox(width: UmbraSpacing.space1),
        Text(
          _formatBurnTime(burnSeconds!),
          style: TextStyle(
            fontSize: UmbraTypography.textXs,
            fontWeight: FontWeight.w500,
            color: colors.warning,
            fontFamily: UmbraTypography.fontMono,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildReactions(UmbraSemanticColors colors, bool isOutgoing) {
    // Group reactions by emoji
    final Map<String, List<UmbraReaction>> grouped = {};
    for (final reaction in reactions) {
      grouped.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }

    return Wrap(
      spacing: UmbraSpacing.space1,
      runSpacing: UmbraSpacing.space1,
      alignment: isOutgoing ? WrapAlignment.end : WrapAlignment.start,
      children: grouped.entries.map((entry) {
        final emoji = entry.key;
        final reactors = entry.value;
        final isOwn = reactors.any((r) => r.isOwn);
        final count = reactors.length;

        return GestureDetector(
          onTap: () {}, // TODO: Show reaction picker
          child: AnimatedContainer(
            duration: UmbraMotion.durationFast,
            curve: UmbraMotion.easeSpring,
            padding: EdgeInsets.symmetric(
              horizontal: UmbraSpacing.space2,
              vertical: UmbraSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: isOwn
                  ? colors.accentSoft
                  : colors.surfaceHover,
              borderRadius: BorderRadius.circular(UmbraRadius.full),
              border: Border.all(
                color: isOwn
                    ? colors.accent.withValues(alpha: 0.3)
                    : colors.separator,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: TextStyle(fontSize: UmbraTypography.textSm),
                ),
                if (count > 1) ...[
                  SizedBox(width: UmbraSpacing.space1),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: UmbraTypography.textXs,
                      fontWeight: FontWeight.w600,
                      color: isOwn ? colors.accent : colors.textSecondary,
                      fontFamily: UmbraTypography.fontMono,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetaRow(UmbraSemanticColors colors, bool isOutgoing, Color timeColor, Color bubbleColor) {
    final timeStr = _formatTime(time);

    if (!isOutgoing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTime) ...[
            Text(
              timeStr,
              style: TextStyle(
                fontSize: UmbraTypography.textXs,
                color: timeColor,
                fontFamily: UmbraTypography.fontMono,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      );
    }

    // Outgoing: time + status
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTime) ...[
          Text(
            timeStr,
            style: TextStyle(
              fontSize: UmbraTypography.textXs,
              color: timeColor,
              fontFamily: UmbraTypography.fontMono,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
        if (showTime && showStatus) SizedBox(width: UmbraSpacing.space2),
        if (showStatus) _buildStatusIcon(colors, timeColor),
      ],
    );
  }

  Widget _buildStatusIcon(UmbraSemanticColors colors, Color timeColor) {
    IconData icon;
    Color iconColor;

    switch (status) {
      case 'pending':
        icon = Icons.schedule_rounded;
        iconColor = colors.warning;
        break;
      case 'sent':
        icon = Icons.check_rounded;
        iconColor = timeColor;
        break;
      case 'delivered':
        icon = Icons.done_all_rounded;
        iconColor = timeColor;
        break;
      case 'read':
        icon = Icons.done_all_rounded;
        iconColor = colors.accent;
        break;
      case 'failed':
        icon = Icons.error_outline_rounded;
        iconColor = colors.error;
        break;
      default:
        icon = Icons.check_rounded;
        iconColor = timeColor;
    }

    return Icon(
      icon,
      size: UmbraTypography.textXs * 1.2,
      color: iconColor,
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatBurnTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).floor()}m';
    return '${(seconds / 3600).floor()}h';
  }
}

class _ReplyPreviewWidget extends StatelessWidget {
  final String senderName;
  final String text;

  const _ReplyPreviewWidget({
    required this.senderName,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(senderName),
        Text(text),
      ],
    );
  }
}

class UmbraReaction {
  final String emoji;
  final bool isOwn;

  const UmbraReaction({
    required this.emoji,
    this.isOwn = false,
  });
}

/// Chat message model for the new chat screen
class UmbraChatMessage {
  final int msgUid;
  final String text;
  final UmbraBubbleDirection direction;
  final DateTime time;
  final String? senderName;
  final String? status; // pending, sent, delivered, read, failed
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final List<UmbraReaction> reactions;
  final bool highlighted;
  final int? rowid;
  final int? when;
  final int? burnAt;
  final int? burnSecs;
  final UmbraChatMessage? replyTo;
  final bool secure;
  final bool sending;
  final bool failed;
  final bool parked;
  final String? mediaPath;
  final String? filePath;
  final String? fileName;
  final bool voiceDisguised;
  final bool saved;
  final String? preview;
  final bool removing;
  final bool edited;
  final bool pinned;
  final int autoRetries;
  final bool gaveUp;

  UmbraChatMessage({
    required this.msgUid,
    required this.text,
    required this.direction,
    required this.time,
    this.senderName,
    this.status,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.reactions = const [],
    this.highlighted = false,
    this.rowid,
    this.when,
    this.burnAt,
    this.burnSecs,
    this.replyTo,
    this.secure = false,
    this.sending = false,
    this.failed = false,
    this.parked = false,
    this.mediaPath,
    this.filePath,
    this.fileName,
    this.voiceDisguised = false,
    this.saved = false,
    this.preview,
    this.removing = false,
    this.edited = false,
    this.pinned = false,
    this.autoRetries = 0,
    this.gaveUp = false,
  });

  UmbraChatMessage copyWith({
    int? msgUid,
    String? text,
    UmbraBubbleDirection? direction,
    DateTime? time,
    String? senderName,
    String? status,
    bool? isFirstInGroup,
    bool? isLastInGroup,
    List<UmbraReaction>? reactions,
    bool? highlighted,
    int? rowid,
    int? when,
    int? burnAt,
    int? burnSecs,
    UmbraChatMessage? replyTo,
    bool? secure,
    bool? sending,
    bool? failed,
    bool? parked,
    String? mediaPath,
    String? filePath,
    String? fileName,
    bool? voiceDisguised,
    bool? saved,
    String? preview,
    bool? removing,
    bool? edited,
    bool? pinned,
    int? autoRetries,
    bool? gaveUp,
  }) {
    return UmbraChatMessage(
      msgUid: msgUid ?? this.msgUid,
      text: text ?? this.text,
      direction: direction ?? this.direction,
      time: time ?? this.time,
      senderName: senderName ?? this.senderName,
      status: status ?? this.status,
      isFirstInGroup: isFirstInGroup ?? this.isFirstInGroup,
      isLastInGroup: isLastInGroup ?? this.isLastInGroup,
      reactions: reactions ?? this.reactions,
      highlighted: highlighted ?? this.highlighted,
      rowid: rowid ?? this.rowid,
      when: when ?? this.when,
      burnAt: burnAt ?? this.burnAt,
      burnSecs: burnSecs ?? this.burnSecs,
      replyTo: replyTo ?? this.replyTo,
      secure: secure ?? this.secure,
      sending: sending ?? this.sending,
      failed: failed ?? this.failed,
      parked: parked ?? this.parked,
      mediaPath: mediaPath ?? this.mediaPath,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      voiceDisguised: voiceDisguised ?? this.voiceDisguised,
      saved: saved ?? this.saved,
      preview: preview ?? this.preview,
      removing: removing ?? this.removing,
      edited: edited ?? this.edited,
      pinned: pinned ?? this.pinned,
      autoRetries: autoRetries ?? this.autoRetries,
      gaveUp: gaveUp ?? this.gaveUp,
    );
  }
}

class _BubblePainter extends CustomPainter {
  final UmbraBubbleDirection direction;
  final Color color;
  final double radius;
  final double tailWidth;
  final double tailHeight;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool isFrosted;
  final Color frostedBorderColor;
  final bool highlighted;
  final Color highlightColor;

  _BubblePainter({
    required this.direction,
    required this.color,
    required this.radius,
    required this.tailWidth,
    required this.tailHeight,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.isFrosted,
    required this.frostedBorderColor,
    required this.highlighted,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isOutgoing = direction == UmbraBubbleDirection.outgoing;
    final paint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = frostedBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    final r = radius;

    // Calculate bubble rect (accounting for tail)
    final bubbleRect = Rect.fromLTRB(
      isOutgoing ? 0 : tailWidth,
      0,
      isOutgoing ? size.width - tailWidth : size.width,
      size.height,
    );

    // Draw bubble with rounded corners and tail
    _drawBubblePath(path, bubbleRect, r, isOutgoing);

    // Fill
    canvas.drawPath(path, paint);

    // Frosted border
    if (isFrosted) {
      canvas.drawPath(path, borderPaint);
    }

    // Highlight for search match
    if (highlighted) {
      final highlightPaint = Paint()
        ..color = highlightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, highlightPaint);
    }
  }

  void _drawBubblePath(Path path, Rect rect, double r, bool isOutgoing) {
    final tailOffset = isOutgoing ? rect.right : rect.left;

    if (isOutgoing) {
      // Top-left
      path.moveTo(rect.left, rect.top + r);
      path.arcToPoint(
        Offset(rect.left + r, rect.top),
        radius: Radius.circular(r),
        clockwise: false,
      );

      // Top edge to tail
      path.lineTo(tailOffset - tailWidth, rect.top);

      // Tail
      path.lineTo(tailOffset, -tailHeight);
      path.lineTo(tailOffset + tailWidth, rect.top);

      // Top-right
      path.lineTo(rect.right - r, rect.top);
      path.arcToPoint(
        Offset(rect.right, rect.top + r),
        radius: Radius.circular(r),
        clockwise: false,
      );

      // Right edge
      if (isLastInGroup) {
        path.lineTo(rect.right, rect.bottom - r);
        path.arcToPoint(
          Offset(rect.right - r, rect.bottom),
          radius: Radius.circular(r),
          clockwise: false,
        );
      } else {
        path.lineTo(rect.right, rect.bottom);
      }

      // Bottom edge
      path.lineTo(rect.left + r, rect.bottom);
      path.arcToPoint(
        Offset(rect.left, rect.bottom - r),
        radius: Radius.circular(r),
        clockwise: false,
      );

      // Left edge
      path.close();
    } else {
      // Incoming - mirrored
      // Top-right
      path.moveTo(rect.right, rect.top + r);
      path.arcToPoint(
        Offset(rect.right - r, rect.top),
        radius: Radius.circular(r),
        clockwise: true,
      );

      // Top edge to tail
      path.lineTo(tailOffset + tailWidth, rect.top);

      // Tail
      path.lineTo(tailOffset, -tailHeight);
      path.lineTo(tailOffset - tailWidth, rect.top);

      // Top-left
      path.lineTo(rect.left + r, rect.top);
      path.arcToPoint(
        Offset(rect.left, rect.top + r),
        radius: Radius.circular(r),
        clockwise: true,
      );

      // Left edge
      if (isLastInGroup) {
        path.lineTo(rect.left, rect.bottom - r);
        path.arcToPoint(
          Offset(rect.left + r, rect.bottom),
          radius: Radius.circular(r),
          clockwise: true,
        );
      } else {
        path.lineTo(rect.left, rect.bottom);
      }

      // Bottom edge
      path.lineTo(rect.right - r, rect.bottom);
      path.arcToPoint(
        Offset(rect.right, rect.bottom - r),
        radius: Radius.circular(r),
        clockwise: true,
      );

      // Right edge
      path.close();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _BubblePainter &&
        oldDelegate.direction != direction ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.tailWidth != tailWidth ||
        oldDelegate.tailHeight != tailHeight ||
        oldDelegate.isFirstInGroup != isFirstInGroup ||
        oldDelegate.isLastInGroup != isLastInGroup ||
        oldDelegate.isFrosted != isFrosted ||
        oldDelegate.frostedBorderColor != frostedBorderColor ||
        oldDelegate.highlighted != highlighted ||
        oldDelegate.highlightColor != highlightColor;
  }
}
