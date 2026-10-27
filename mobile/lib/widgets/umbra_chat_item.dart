// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra Chat List Item widget - iMessage-calibrated

import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum UmbraChatItemType {
  contact,
  group,
  room,
}

class UmbraChatItem extends StatelessWidget {
  final String id;
  final String name;
  final String? preview;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final bool isArchived;
  final bool isOnline;
  final UmbraChatItemType type;
  final String? avatarSeed;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onPin;
  final VoidCallback? onMute;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const UmbraChatItem({
    super.key,
    required this.id,
    required this.name,
    this.preview,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.isArchived = false,
    this.isOnline = false,
    this.type = UmbraChatItemType.contact,
    this.avatarSeed,
    this.avatarUrl,
    this.onTap,
    this.onLongPress,
    this.onPin,
    this.onMute,
    this.onArchive,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final reduceMotion = UmbraTheme.of(context).controller.reduceMotion;

    final timeString = _formatTime(lastMessageTime);
    final showUnread = unreadCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(UmbraRadius.lg),
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : UmbraMotion.durationFast,
          curve: UmbraMotion.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: UmbraSpacing.space4,
            vertical: UmbraSpacing.space3,
          ),
          decoration: BoxDecoration(
            color: isPinned ? colors.accentSoft.withValues(alpha: 0.1) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: colors.separator.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              _buildAvatar(colors),
              SizedBox(width: UmbraSpacing.space3),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header row: name + time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: UmbraTypography.textBase,
                              fontWeight: showUnread ? FontWeight.w600 : FontWeight.w400,
                              color: colors.textPrimary,
                              fontFamily: UmbraTypography.fontSans,
                              height: UmbraTypography.leadingTight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeString.isNotEmpty) ...[
                          SizedBox(width: UmbraSpacing.space2),
                          Text(
                            timeString,
                            style: TextStyle(
                              fontSize: UmbraTypography.textXs,
                              fontWeight: FontWeight.w400,
                              color: showUnread ? colors.accent : colors.textMuted,
                              fontFamily: UmbraTypography.fontMono,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              height: UmbraTypography.leadingTight,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Preview row
                    if (preview != null && preview!.isNotEmpty) ...[
                      SizedBox(height: UmbraSpacing.space1),
                      Row(
                        children: [
                          // Status indicator (delivered/read)
                          if (type == UmbraChatItemType.contact) ...[
                            _buildStatusIcon(colors),
                            SizedBox(width: UmbraSpacing.space1),
                          ],
                          Expanded(
                            child: Text(
                              preview!,
                              style: TextStyle(
                                fontSize: UmbraTypography.textSm,
                                fontWeight: showUnread ? FontWeight.w500 : FontWeight.w400,
                                color: showUnread ? colors.textPrimary : colors.textSecondary,
                                fontFamily: UmbraTypography.fontSans,
                                height: UmbraTypography.leadingNormal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Muted/archived indicators
                    if (isMuted || isArchived) ...[
                      SizedBox(height: UmbraSpacing.space1),
                      Row(
                        children: [
                          if (isMuted)
                            _buildBadge(
                              context,
                              colors,
                              Icons.notifications_off_rounded,
                              'Muted',
                              colors.textMuted,
                            ),
                          if (isMuted && isArchived) SizedBox(width: UmbraSpacing.space2),
                          if (isArchived)
                            _buildBadge(
                              context,
                              colors,
                              Icons.archive_rounded,
                              'Archived',
                              colors.textMuted,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Unread badge
              if (showUnread)
                _buildUnreadBadge(colors, unreadCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(UmbraSemanticColors colors) {
    final size = UmbraComponentTokens.chatListAvatarSize;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        UmbraAvatar(
          seed: avatarSeed,
          name: name,
          size: size,
          isOnline: isOnline && type == UmbraChatItemType.contact,
          isGroup: type == UmbraChatItemType.group || type == UmbraChatItemType.room,
        ),
        // Pinned indicator
        if (isPinned)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowSm.color,
                    blurRadius: colors.shadowSm.blurRadius,
                    offset: colors.shadowSm.offset,
                  ),
                ],
              ),
              child: Icon(
                Icons.push_pin_rounded,
                size: 10,
                color: colors.accentOn,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIcon(UmbraSemanticColors colors) {
    // In a real implementation, this would show delivered/read status
    return Icon(
      Icons.done_all_rounded,
      size: UmbraTypography.textXs * 1.2,
      color: colors.textMuted,
    );
  }

  Widget _buildBadge(
    BuildContext context,
    UmbraSemanticColors colors,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: UmbraSpacing.space2,
        vertical: UmbraSpacing.space0,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(UmbraRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          SizedBox(width: UmbraSpacing.space1),
          Text(
            label,
            style: TextStyle(
              fontSize: UmbraTypography.textXs,
              fontWeight: FontWeight.w500,
              color: color,
              fontFamily: UmbraTypography.fontSans,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnreadBadge(UmbraSemanticColors colors, int count) {
    final displayCount = count > 99 ? '99+' : count.toString();
    final isLarge = count > 9;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? UmbraSpacing.space2 : UmbraSpacing.space1,
        vertical: UmbraSpacing.space0,
      ),
      constraints: BoxConstraints(
        minWidth: isLarge ? 22 : 18,
        minHeight: 18,
      ),
      decoration: BoxDecoration(
        color: colors.accent,
        borderRadius: BorderRadius.circular(UmbraRadius.full),
      ),
      child: Center(
        child: Text(
          displayCount,
          style: TextStyle(
            fontSize: UmbraTypography.textXs,
            fontWeight: FontWeight.w700,
            color: colors.accentOn,
            fontFamily: UmbraTypography.fontMono,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(time.year, time.month, time.day);
    final diff = today.difference(messageDay).inDays;

    if (diff == 0) {
      // Today - show time
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (diff == 1) {
      return 'Yesterday';
    } else if (diff < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[time.weekday - 1];
    } else {
      // Older - show date
      final day = time.day.toString().padLeft(2, '0');
      final month = time.month.toString().padLeft(2, '0');
      return '$day/$month';
    }
  }
}

// Pinned chats section header
class UmbraPinnedSection extends StatelessWidget {
  final int count;
  final VoidCallback? onManage;

  const UmbraPinnedSection({
    super.key,
    required this.count,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: UmbraSpacing.space4,
        vertical: UmbraSpacing.space2,
      ),
      child: Row(
        children: [
          Icon(
            Icons.push_pin_rounded,
            size: 16,
            color: colors.accent,
          ),
          SizedBox(width: UmbraSpacing.space2),
          Text(
            'Pinned',
            style: TextStyle(
              fontSize: UmbraTypography.textSm,
              fontWeight: FontWeight.w600,
              color: colors.accent,
              fontFamily: UmbraTypography.fontSans,
              letterSpacing: UmbraTypography.trackingWide,
            ),
          ),
          SizedBox(width: UmbraSpacing.space2),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: UmbraSpacing.space2,
              vertical: UmbraSpacing.space0,
            ),
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(UmbraRadius.full),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: UmbraTypography.textXs,
                fontWeight: FontWeight.w700,
                color: colors.accent,
                fontFamily: UmbraTypography.fontMono,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const Spacer(),
          if (onManage != null)
            TextButton(
              onPressed: onManage,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: UmbraSpacing.space2,
                  vertical: UmbraSpacing.space1,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Manage',
                style: TextStyle(
                  fontSize: UmbraTypography.textXs,
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                  fontFamily: UmbraTypography.fontSans,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Section header for chat list
class UmbraSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final VoidCallback? onAction;
  final String? actionLabel;

  const UmbraSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: UmbraSpacing.space4,
        vertical: UmbraSpacing.space3,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: UmbraTypography.textSm,
              fontWeight: FontWeight.w600,
              color: colors.textTertiary,
              fontFamily: UmbraTypography.fontSans,
              letterSpacing: UmbraTypography.trackingWide,
            ),
          ),
          if (count != null) ...[
            SizedBox(width: UmbraSpacing.space2),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: UmbraSpacing.space2,
                vertical: UmbraSpacing.space0,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceHover,
                borderRadius: BorderRadius.circular(UmbraRadius.full),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: UmbraTypography.textXs,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                  fontFamily: UmbraTypography.fontMono,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
          const Spacer(),
          if (onAction != null && actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: UmbraSpacing.space2,
                  vertical: UmbraSpacing.space1,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: UmbraTypography.textXs,
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                  fontFamily: UmbraTypography.fontSans,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Empty state widget
class UmbraEmptyChats extends StatelessWidget {
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;

  const UmbraEmptyChats({
    super.key,
    this.title = 'No conversations yet',
    this.description = 'Start a new conversation to get started',
    this.actionLabel = 'New Chat',
    required this.onAction,
    this.icon = Icons.chat_bubble_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(UmbraSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: UmbraComponentTokens.avatar2xl,
              height: UmbraComponentTokens.avatar2xl,
              decoration: BoxDecoration(
                color: colors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: UmbraComponentTokens.avatarLg,
                color: colors.accent,
              ),
            ),
            SizedBox(height: UmbraSpacing.space4),
            Text(
              title,
              style: TextStyle(
                fontSize: UmbraTypography.textLg,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                fontFamily: UmbraTypography.fontSans,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: UmbraSpacing.space2),
            Text(
              description,
              style: TextStyle(
                fontSize: UmbraTypography.textBase,
                fontWeight: FontWeight.w400,
                color: colors.textSecondary,
                fontFamily: UmbraTypography.fontSans,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: UmbraSpacing.space6),
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(Icons.add_rounded, size: 20),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.accentOn,
                padding: EdgeInsets.symmetric(
                  horizontal: UmbraSpacing.space6,
                  vertical: UmbraSpacing.space3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(UmbraRadius.full),
                ),
                textStyle: TextStyle(
                  fontSize: UmbraTypography.textBase,
                  fontWeight: FontWeight.w600,
                  fontFamily: UmbraTypography.fontSans,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
