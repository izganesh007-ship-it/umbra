// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra reaction picker - emoji picker bubble for message reactions

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/umbra_theme.dart';
import '../l10n/l10n.dart';

/// Emoji button in the reaction picker
class _UmbraEmojiTap extends StatefulWidget {
  const _UmbraEmojiTap({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_UmbraEmojiTap> createState() => _UmbraEmojiTapState();
}

class _UmbraEmojiTapState extends State<_UmbraEmojiTap> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    final colors = UmbraTheme.colorsOf(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.85),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: UmbraMotion.durationFast,
        curve: UmbraMotion.easeOut,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: widget.selected ? colors.accentSoft : colors.surfaceElevated,
            border: Border.all(
              color: widget.selected ? colors.accent : colors.separator,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(UmbraRadius.xl),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.emoji,
            style: TextStyle(fontSize: UmbraTypography.text2xl),
          ),
        ),
      ),
    );
  }
}

/// Action button in the reaction picker (e.g., reply)
class _UmbraActionTap extends StatefulWidget {
  const _UmbraActionTap({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  State<_UmbraActionTap> createState() => _UmbraActionTapState();
}

class _UmbraActionTapState extends State<_UmbraActionTap> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
  final colors = UmbraTheme.colorsOf(context);

    final colors = UmbraTheme.colorsOf(context);

    return Semantics(
      label: widget.tooltip,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.85),
        onTapUp: (_) {
          setState(() => _scale = 1.0);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _scale = 1.0),
        child: AnimatedScale(
          scale: _scale,
          duration: UmbraMotion.durationFast,
          curve: UmbraMotion.easeOut,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              border: Border.all(
                color: colors.separator,
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(UmbraRadius.xl),
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: 22,
              color: colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Reaction picker bubble that appears above a long-pressed message
class UmbraReactionPicker extends StatefulWidget {
  const UmbraReactionPicker({
    super.key,
    required this.emojis,
    required this.selected,
    required this.onPick,
    required this.onReply,
    this.onEdit,
    this.onUnsend,
    this.isOwnMessage = false,
  });

  final List<String> emojis;
  final String? selected;
  final void Function(String) onPick;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onUnsend;
  final bool isOwnMessage;

  @override
  State<UmbraReactionPicker> createState() => _UmbraReactionPickerState();
}

class _UmbraReactionPickerState extends State<UmbraReactionPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: UmbraMotion.durationNormal,
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final l10n = l10n;

    final scale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.easeOutBack)).animate(_ctrl);

    return Material(
      color: Colors.transparent,
      child: ScaleTransition(
        scale: scale,
        alignment: Alignment.bottomCenter,
        child: FadeTransition(
          opacity: _ctrl,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: UmbraSpacing.UmbraSpacing.UmbraSpacing.space2,
              vertical: UmbraSpacing.UmbraSpacing.UmbraSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              border: Border.all(color: colors.separator, width: 0.5),
              borderRadius: BorderRadius.circular(UmbraRadius.full),
              boxShadow: colors.shadowLg,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...widget.emojis.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final n = widget.emojis.length;
                  final start = (i / n) * 0.55;
                  final pop = CurvedAnimation(
                    parent: _ctrl,
                    curve: Interval(
                      start,
                      (start + 0.45).clamp(0.0, 1.0),
                      curve: Curves.easeOutBack,
                    ),
                  );
                  return ScaleTransition(
                    scale: pop,
                    child: _UmbraEmojiTap(
                      emoji: e,
                      selected: e == widget.selected,
                      onTap: () => widget.onPick(e),
                    ),
                  ),
                }),
                if (widget.isOwnMessage) ...[
                  Container(
                    width: 0.5,
                    height: 28,
                    margin: EdgeInsets.symmetric(horizontal: UmbraSpacing.UmbraSpacing.UmbraSpacing.space2),
                    color: colors.separator,
                  ),
                  if (widget.onEdit != null)
                    _UmbraActionTap(
                      icon: Icons.edit_outlined,
                      onTap: widget.onEdit!,
                      tooltip: l10n.commonEdit,
                    ),
                  if (widget.onUnsend != null)
                    _UmbraActionTap(
                      icon: Icons.delete_outline_rounded,
                      onTap: widget.onUnsend!,
                      tooltip: l10n.commonUnsend,
                    ),
                ] else ...[
                  Container(
                    width: 0.5,
                    height: 28,
                    margin: EdgeInsets.symmetric(horizontal: UmbraSpacing.UmbraSpacing.UmbraSpacing.space2),
                    color: colors.separator,
                  ),
                  _UmbraActionTap(
                    icon: Icons.reply_rounded,
                    onTap: widget.onReply,
                    tooltip: l10n.chatReply,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay entry for showing the reaction picker
class UmbraReactionOverlay {
  UmbraReactionOverlay._();

  static OverlayEntry? _entry;

  static void show({
    required BuildContext context,
    required RenderBox bubbleBox,
    required Offset globalPosition,
    required List<String> emojis,
    required String? selected,
    required void Function(String) onPick,
    required VoidCallback onReply,
    VoidCallback? onEdit,
    VoidCallback? onUnsend,
    required bool isOwnMessage,
    required VoidCallback onDismiss,
  }) {
    dismiss();

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final safeBottom = mediaQuery.padding.bottom;

    // Calculate position - above the bubble
    final bubbleTop = globalPosition.dy;
    final bubbleBottom = globalPosition.dy + bubbleBox.size.height;
    final bubbleCenterX = globalPosition.dx + bubbleBox.size.width / 2;

    const pickerHeight = 54.0;
    const pickerWidth = 200.0;

    // Try to show above the bubble
    var top = bubbleTop - pickerHeight - 10;
    var alignRight = false;

    // Check if there's space above
    final safeTop = mediaQuery.padding.top;
    if (top < safeTop) {
      // Show below the bubble instead
      top = bubbleBottom + 10;
    }

    // Check horizontal bounds
    var left = bubbleCenterX - pickerWidth / 2;
    if (left < 12) {
      left = 12;
      alignRight = false;
    } else if (left + pickerWidth > screenSize.width - 12) {
      left = screenSize.width - pickerWidth - 12;
      alignRight = true;
    }

    // Check if picker would go off bottom
    if (top + pickerHeight > screenSize.height - safeBottom) {
      top = screenSize.height - safeBottom - pickerHeight;
    }

    _entry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            // Backdrop to dismiss on tap outside
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                onDismiss();
                dismiss();
              },
              child: Container(
                color: Colors.transparent,
                child: const Center(child: SizedBox.shrink()),
              ),
            ),
            // Reaction picker positioned above/below bubble
            Positioned(
              left: left,
              top: top,
              width: pickerWidth,
              child: Material(
                color: Colors.transparent,
                child: UmbraReactionPicker(
                  emojis: emojis,
                  selected: selected,
                  onPick: (e) {
                    onPick(e);
                    onDismiss();
                    dismiss();
                  },
                  onReply: () {
                    onReply();
                    onDismiss();
                    dismiss();
                  },
                  onEdit: onEdit != null
                      ? () {
                          onEdit();
                          onDismiss();
                          dismiss();
                        }
                      : null,
                  onUnsend: onUnsend != null
                      ? () {
                          onUnsend();
                          onDismiss();
                          dismiss();
                        }
                      : null,
                  isOwnMessage: isOwnMessage,
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_entry!);
  }

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

/// Default emoji set for reactions
const List<String> kDefaultReactionEmojis = [
  '❤️',
  '👍',
  '😂',
  '😮',
  '😢',
  '🔥',
];
