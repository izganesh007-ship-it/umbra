// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra Chat List Screen - iMessage-calibrated design

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';
import '../theme/umbra_theme.dart';
import '../widgets/widgets.dart';
import '../app_state.dart';
import '../dlog.dart';
import '../wipe.dart';

class ChatListScreen extends StatefulWidget {
  final String? haloId;
  final List<ContactPreview> contacts;
  final List<GroupPreview> groups;
  final int pendingCount;
  final VoidCallback? onAddContact;
  final VoidCallback? onNewGroup;
  final VoidCallback? onNewRoom;
  final String? expiredRoomName;
  final VoidCallback? onOpenSettings;
  final Function(String peerHaloId, {String? peerOnion, String? peerXPub, int? avatarSeed, String? avatarChoice})? onOpenChat;
  final Function(String groupId)? onOpenGroup;

  const ChatListScreen({
    super.key,
    this.haloId,
    required this.contacts,
    required this.groups,
    required this.pendingCount,
    this.onAddContact,
    this.onNewGroup,
    this.onNewRoom,
    this.expiredRoomName,
    this.onOpenSettings,
    this.onOpenChat,
    this.onOpenGroup,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  UmbraNavBarVariant _navVariant = UmbraNavBarVariant.large;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Chat data
  List<_ChatItemData> _pinnedChats = [];
  List<_ChatItemData> _chats = [];

  // Animation for nav bar transition
  late AnimationController _navAnimationController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _navAnimationController = AnimationController(
      duration: UmbraMotion.durationNormal,
      vsync: this,
    );

    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    _refreshChats();
    _listenToAppState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _navAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshChats();
    }
  }

  void _listenToAppState() {
    appState.addListener(_onAppStateChanged);
  }

  void _onAppStateChanged() {
    if (mounted) {
      _refreshChats();
    }
  }

  void _refreshChats() {
    final pinned = <_ChatItemData>[];
    final regular = <_ChatItemData>[];

    // Add contacts
    for (final contact in widget.contacts) {
      if (contact.archived) continue;

      final data = _ChatItemData(
        id: contact.haloId,
        name: contact.nickname ?? contact.haloId,
        preview: contact.preview,
        lastMessageTime: contact.when != null
            ? DateTime.fromMillisecondsSinceEpoch(contact.when! * 1000)
            : null,
        unreadCount: contact.unread ?? 0,
        isPinned: contact.pinned ?? false,
        isMuted: contact.muted ?? false,
        isArchived: contact.archived ?? false,
        isOnline: _isContactOnline(contact.haloId),
        type: UmbraChatItemType.contact,
        avatarSeed: contact.avatarSeed?.toString(),
        onTap: () => widget.onOpenChat?.call(
          contact.haloId,
          peerOnion: contact.haloId, // Simplified
          avatarSeed: contact.avatarSeed,
          avatarChoice: contact.avatar,
        ),
        onPin: () => _togglePin(contact.haloId),
        onMute: () => _toggleMute(contact.haloId),
        onArchive: () => _archiveChat(contact.haloId),
        onDelete: () => _deleteChat(contact.haloId),
      );

      if (data.isPinned) {
        pinned.add(data);
      } else {
        regular.add(data);
      }
    }

    // Add groups
    for (final group in widget.groups) {
      if (group.groupId.startsWith('room_')) continue; // Skip rooms for now

      final data = _ChatItemData(
        id: group.groupId,
        name: group.name,
        preview: null, // Would need group preview
        lastMessageTime: group.expiresAt != null
            ? DateTime.fromMillisecondsSinceEpoch(group.expiresAt! * 1000)
            : null,
        unreadCount: group.unread ?? 0,
        isPinned: false, // Groups don't support pin yet
        isMuted: false,
        isArchived: false,
        isOnline: false,
        type: UmbraChatItemType.group,
        onTap: () => widget.onOpenGroup?.call(group.groupId),
      );

      regular.add(data);
    }

    // Sort by last message time (newest first)
    regular.sort((a, b) => _compareByTime(b, a));

    setState(() {
      _pinnedChats = pinned;
      _chats = regular;
    });
  }

  int _compareByTime(_ChatItemData a, _ChatItemData b) {
    final aTime = a.lastMessageTime?.millisecondsSinceEpoch ?? 0;
    final bTime = b.lastMessageTime?.millisecondsSinceEpoch ?? 0;
    return bTime.compareTo(aTime);
  }

  bool _isContactOnline(String haloId) {
    // TODO: Implement actual online status
    return false;
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    setState(() {
      _scrollOffset = offset;
    });

    // Update nav bar variant based on scroll
    final shouldBeLarge = offset <= 50;
    final newVariant = shouldBeLarge ? UmbraNavBarVariant.large : UmbraNavBarVariant.collapsed;

    if (newVariant != _navVariant) {
      setState(() => _navVariant = newVariant);
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchQuery = '';
        _refreshChats();
      }
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _refreshChats();
    });
  }

  bool _matchesQuery(_ChatItemData chat) {
    if (_searchQuery.isEmpty) return true;
    return chat.name.toLowerCase().contains(_searchQuery) ||
        (chat.preview?.toLowerCase().contains(_searchQuery) ?? false);
  }

  void _onChatTap(_ChatItemData chat) {
    chat.onTap?.call();
  }

  void _onNewChat() {
    widget.onAddContact?.call();
  }

  void _onNewGroup() {
    widget.onNewGroup?.call();
  }

  void _onSettings() {
    widget.onOpenSettings?.call();
  }

  void _togglePin(String haloId) {
    appState.setPinned(haloId, !_pinnedChats.any((c) => c.id == haloId));
  }

  void _toggleMute(String haloId) {
    final isMuted = _chats.any((c) => c.id == haloId && c.isMuted) ||
        _pinnedChats.any((c) => c.id == haloId && c.isMuted);
    appState.setMuted(haloId, !isMuted);
  }

  void _archiveChat(String haloId) {
    appState.archive(haloId);
  }

  void _deleteChat(String haloId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              appState.deleteConversation(haloId);
            },
            style: TextButton.styleFrom(foregroundColor: UmbraTheme.colorsOf(context).error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final reduceMotion = UmbraTheme.of(context).controller.reduceMotion;

    // Filter chats based on search
    final filteredPinned = _pinnedChats.where(_matchesQuery).toList();
    final filteredChats = _chats.where(_matchesQuery).toList();

    return Scaffold(
      backgroundColor: colors.surface,
      body: EclipseWipeOverlay(
        controller: UmbraTheme.of(context).controller,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Large title nav bar
            SliverPersistentHeader(
              pinned: true,
              floating: true,
              delegate: _NavBarDelegate(
                variant: _navVariant,
                scrollOffset: _scrollOffset,
                title: 'Messages',
                subtitle: widget.haloId != null ? '@${widget.haloId!.substring(0, 8)}' : null,
                backStyle: UmbraNavBarBackStyle.none,
                trailingActions: [
                  // Connection status
                  UmbraConnectionStatus(
                    state: appState.torUsable
                        ? UmbraConnectionState.connected
                        : appState.torStatus == TorStatus.connecting
                            ? UmbraConnectionState.torConnecting
                            : UmbraConnectionState.offline,
                  ),
                  SizedBox(width: UmbraSpacing.space2),
                  // Search button
                  _NavActionButton(
                    icon: Icons.search_rounded,
                    onPressed: _toggleSearch,
                    tooltip: 'Search',
                  ),
                  SizedBox(width: UmbraSpacing.space1),
                  // Settings button
                  _NavActionButton(
                    icon: Icons.settings_rounded,
                    onPressed: _onSettings,
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),

            // Search bar (when active)
            if (_showSearch)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SearchBarDelegate(
                  controller: _searchController,
                  onClose: _toggleSearch,
                  onChanged: _onSearchChanged,
                ),
              ),

            // Pinned chats section
            if (filteredPinned.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: UmbraPinnedSection(
                  count: filteredPinned.length,
                  onManage: () {}, // TODO: Implement manage pinned
                ),
              ),
              SliverList.separated(
                itemCount: filteredPinned.length,
                separatorBuilder: (context, index) => Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: colors.separator.withValues(alpha: 0.5),
                  indent: UmbraSpacing.space4 + UmbraComponentTokens.chatListAvatarSize + UmbraSpacing.space3,
                ),
                itemBuilder: (context, index) {
                  final chat = filteredPinned[index];
                  return UmbraChatItem(
                    id: chat.id,
                    name: chat.name,
                    preview: chat.preview,
                    lastMessageTime: chat.lastMessageTime,
                    unreadCount: chat.unreadCount,
                    isPinned: chat.isPinned,
                    isMuted: chat.isMuted,
                    isArchived: chat.isArchived,
                    isOnline: chat.isOnline,
                    type: chat.type,
                    avatarSeed: chat.avatarSeed,
                    onTap: () => _onChatTap(chat),
                    onLongPress: () => _showChatMenu(chat),
                    onPin: chat.onPin,
                    onMute: chat.onMute,
                    onArchive: chat.onArchive,
                    onDelete: chat.onDelete,
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.separator,
                ),
              ),
            ],

            // Regular chats section
            if (filteredChats.isNotEmpty)
              SliverList.separated(
                itemCount: filteredChats.length,
                separatorBuilder: (context, index) => Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: colors.separator.withValues(alpha: 0.5),
                  indent: UmbraSpacing.space4 + UmbraComponentTokens.chatListAvatarSize + UmbraSpacing.space3,
                ),
                itemBuilder: (context, index) {
                  final chat = filteredChats[index];
                  return UmbraChatItem(
                    id: chat.id,
                    name: chat.name,
                    preview: chat.preview,
                    lastMessageTime: chat.lastMessageTime,
                    unreadCount: chat.unreadCount,
                    isPinned: chat.isPinned,
                    isMuted: chat.isMuted,
                    isArchived: chat.isArchived,
                    isOnline: chat.isOnline,
                    type: chat.type,
                    avatarSeed: chat.avatarSeed,
                    onTap: () => _onChatTap(chat),
                    onLongPress: () => _showChatMenu(chat),
                    onPin: chat.onPin,
                    onMute: chat.onMute,
                    onArchive: chat.onArchive,
                    onDelete: chat.onDelete,
                  );
                },
              ),

            // Empty state
            if (filteredPinned.isEmpty && filteredChats.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: UmbraEmptyChats(
                  title: _searchQuery.isNotEmpty ? 'No matches found' : 'No conversations yet',
                  description: _searchQuery.isNotEmpty
                      ? 'Try a different search term'
                      : 'Start a new conversation to get started',
                  actionLabel: 'New Chat',
                  onAction: _onNewChat,
                ),
              ),

            // Bottom padding for tab bar
            SliverToBoxAdapter(
              child: SizedBox(height: UmbraComponentTokens.tabBarHeight + UmbraSpacing.space4),
            ),
          ],
        ),
      ),
      floatingActionButton: !_showSearch
          ? FloatingActionButton(
              onPressed: _onNewChat,
              backgroundColor: colors.accent,
              foregroundColor: colors.accentOn,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UmbraRadius.full),
              ),
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildTabBar(),
    );
  }

  void _showChatMenu(_ChatItemData chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(UmbraRadius.xl)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: UmbraSpacing.space3),
              decoration: BoxDecoration(
                color: colors.separator,
                borderRadius: BorderRadius.circular(UmbraRadius.full),
              ),
            ),
            ListTile(
              leading: Icon(
                chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                color: colors.textPrimary,
              ),
              title: Text(
                chat.isPinned ? 'Unpin' : 'Pin',
                style: TextStyle(
                  fontFamily: UmbraTypography.fontSans,
                  color: colors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                chat.onPin?.call();
              },
            ),
            ListTile(
              leading: Icon(
                chat.isMuted ? Icons.notifications_off_outlined : Icons.notifications_outlined,
                color: colors.textPrimary,
              ),
              title: Text(
                chat.isMuted ? 'Unmute' : 'Mute',
                style: TextStyle(
                  fontFamily: UmbraTypography.fontSans,
                  color: colors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                chat.onMute?.call();
              },
            ),
            ListTile(
              leading: Icon(Icons.archive_outlined, color: colors.textPrimary),
              title: Text(
                'Archive',
                style: TextStyle(
                  fontFamily: UmbraTypography.fontSans,
                  color: colors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                chat.onArchive?.call();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.error),
              title: Text(
                'Delete',
                style: TextStyle(
                  fontFamily: UmbraTypography.fontSans,
                  color: colors.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                chat.onDelete?.call();
              },
            ),
            SizedBox(height: UmbraSpacing.space4),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final colors = UmbraTheme.colorsOf(context);

    return Container(
      height: UmbraComponentTokens.tabBarHeight,
      decoration: BoxDecoration(
        color: colors.navBg,
        border: Border(
          top: BorderSide(
            color: colors.navBorder,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowFrosted.color,
            blurRadius: colors.shadowFrosted.blurRadius,
            offset: colors.shadowFrosted.offset,
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                _TabBarButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Chats',
                  isActive: true,
                  onTap: () {},
                ),
                _TabBarButton(
                  icon: Icons.group_outlined,
                  activeIcon: Icons.group_rounded,
                  label: 'Groups',
                  isActive: false,
                  onTap: _onNewGroup,
                ),
                _TabBarButton(
                  icon: Icons.star_outline_rounded,
                  activeIcon: Icons.star_rounded,
                  label: 'Saved',
                  isActive: false,
                  onTap: () {}, // TODO: Navigate to saved messages
                ),
                _TabBarButton(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                  isActive: false,
                  onTap: _onSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatItemData {
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
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final VoidCallback? onMute;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  _ChatItemData({
    required this.id,
    required this.name,
    this.preview,
    this.lastMessageTime,
    required this.unreadCount,
    required this.isPinned,
    required this.isMuted,
    required this.isArchived,
    required this.isOnline,
    required this.type,
    this.avatarSeed,
    this.onTap,
    this.onPin,
    this.onMute,
    this.onArchive,
    this.onDelete,
  });
}

class _NavBarDelegate extends SliverPersistentHeaderDelegate {
  final UmbraNavBarVariant variant;
  final double scrollOffset;
  final String title;
  final String? subtitle;
  final UmbraNavBarBackStyle backStyle;
  final List<Widget> trailingActions;

  _NavBarDelegate({
    required this.variant,
    required this.scrollOffset,
    required this.title,
    this.subtitle,
    required this.backStyle,
    required this.trailingActions,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / 50).clamp(0.0, 1.0);
    final effectiveVariant = progress > 0.5 ? UmbraNavBarVariant.collapsed : variant;

    return UmbraNavBar(
      variant: effectiveVariant,
      title: title,
      subtitle: subtitle,
      backStyle: backStyle,
      trailingActions: trailingActions,
      scrollOffset: shrinkOffset,
    );
  }

  @override
  double get maxExtent => UmbraComponentTokens.navBarHeightLarge + MediaQuery.of(context).padding.top;

  @override
  double get minExtent => UmbraComponentTokens.navBarHeight + MediaQuery.of(context).padding.top;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate is _NavBarDelegate &&
        oldDelegate.variant != variant &&
        oldDelegate.scrollOffset != scrollOffset;
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController controller;
  final VoidCallback onClose;
  final ValueChanged<String> onChanged;

  _SearchBarDelegate({
    required this.controller,
    required this.onClose,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colors = UmbraTheme.colorsOf(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: UmbraSpacing.space4,
        vertical: UmbraSpacing.space2,
      ),
      color: colors.navBg,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(UmbraRadius.full),
                border: Border.all(color: colors.inputBorder),
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(
                  fontSize: UmbraTypography.textBase,
                  fontFamily: UmbraTypography.fontSans,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(
                    fontSize: UmbraTypography.textBase,
                    fontFamily: UmbraTypography.fontSans,
                    color: colors.textMuted,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: colors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: UmbraSpacing.space4,
                    vertical: UmbraSpacing.space2,
                  ),
                ),
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(width: UmbraSpacing.space3),
          _NavActionButton(
            icon: Icons.close_rounded,
            onPressed: onClose,
            tooltip: 'Close search',
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 64;

  @override
  double get minExtent => 64;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _NavActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const _NavActionButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(UmbraRadius.full),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 22,
              color: colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBarButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabBarButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive ? colors.accent : colors.textMuted,
              ),
              SizedBox(height: UmbraSpacing.space1),
              Text(
                label,
                style: TextStyle(
                  fontSize: UmbraTypography.textXs,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? colors.accent : colors.textMuted,
                  fontFamily: UmbraTypography.fontSans,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
