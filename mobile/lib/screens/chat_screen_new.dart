// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra Chat Screen - iMessage-calibrated design

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';
import '../theme/umbra_theme.dart';
import '../widgets/widgets.dart';
import '../app_state.dart';
import '../message_envelope.dart';
import '../dlog.dart';
import '../atmosphere.dart';

class ChatScreen extends StatefulWidget {
  final String peerName;
  final String peerHaloId;
  final String? peerOnion;
  final String? peerXPub;
  final int? peerAvatarSeed;
  final String? avatarChoice;
  final bool isGroup;
  final List<MessageEnvelope>? initialMessages;
  final int? jumpToUid;

  const ChatScreen({
    super.key,
    required this.peerName,
    required this.peerHaloId,
    this.peerOnion,
    this.peerXPub,
    this.peerAvatarSeed,
    this.avatarChoice,
    this.isGroup = false,
    this.initialMessages,
    this.jumpToUid,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  UmbraNavBarVariant _navVariant = UmbraNavBarVariant.collapsed;
  bool _showScrollDown = false;
  bool _isComposing = false;

  List<UmbraChatMessage> _messages = [];
  int _pageSize = 50;
  bool _hasMore = true;
  bool _loadingOlder = false;
  bool _pagedOut = false;
  bool _loaded = false;

  // Message options
  bool _ghost = false;
  bool _secureNext = false;
  bool _disguise = false;
  int? _burnSeconds;
  int? _burnTick;
  int? _lastBurnSec;

  // Reply
  UmbraChatMessage? _replyTo;
  MessageEnvelope? _pendingPreview;

  // Search
  bool _searching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  List<int> _matches = [];
  int _matchPos = -1;
  List<int> _matchKeys = [];

  // Peer info
  String _nickname = '';
  String _peerFace = '';
  bool _blocked = false;
  bool _muted = false;
  bool _verified = false;
  String _peerBadge = '';
  bool _keyChanged = false;
  bool _accepted = false;
  bool _peerEngaged = false;

  // Group
  List<String> _groupMembers = [];
  Map<String, String> _memberNicknames = {};
  bool _amAdmin = false;
  bool _groupLoaded = false;

  // Encryption
  Future<void>? _encryptGate;
  String? _peerXPub;
  bool _backPaired = false;

  // Atmosphere
  Atmo _atmosphere = Atmo.none;
  String? _wallpaperPath;

  // Draft persistence
  static final Map<String, String> _draftPerPeer = {};
  static final Map<String, int> _lastReadPerPeer = {};

  // Date separators
  final Map<int, String> _dayKeys = {};
  int? _dayMsOf(int uid) => _dayKeys[uid];

  final GlobalKey _listKey = GlobalKey();
  final ValueNotifier<String?> _stickyLabel = ValueNotifier(null);
  final ValueNotifier<bool> _stickyShown = ValueNotifier(false);
  int? _stickyDayMs;
  int? _revealedUid;
  Timer? _stickyHideTimer;
  bool _suppressSticky = false;

  // Reactions
  UmbraChatMessage? _reactionTarget;
  Timer? _reactionDismiss;

  // Polling
  Timer? _pollTimer;
  Timer? _autoRetryTimer;

  // Status
  String _status = '';
  bool _sending = false;
  bool _reloadPending = false;
  int _lastRev = 0;

  // Vouches
  List<String> _voucherNames = [];
  int? _voucherSeed;
  String? _voucherAvatar;
  bool _voucherVerified = false;

  // Shield
  bool _shieldClean = true;
  bool _requestPending = false;
  bool _requestLocked = false;
  bool _incomingRequest = false;

  // Flags
  int _flag = 0;
  int _sentCount = 0;
  int _recvCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _nickname = widget.peerName;
    _peerFace = widget.avatarChoice ?? '';
    _peerXPub = widget.peerXPub;

    _scrollController.addListener(_onScroll);
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    _loadInitialData();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _searchCtrl.dispose();
    _pollTimer?.cancel();
    _autoRetryTimer?.cancel();
    _stickyHideTimer?.cancel();
    _reactionDismiss?.cancel();
    _burnTick?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDelivered();
      _checkInbox();
    }
  }

  Future<void> _loadInitialData() async {
    await _loadContactInfo();
    await _loadVouches();
    await _loadShield();
    await _loadAtmosphere();
    await _loadSession();
    await _loadBlockMuteVerified();
    await _loadRequestState();

    if (widget.isGroup) {
      await _loadGroupMembers();
    }

    _loadMessages(initial: true);

    // Restore draft
    final draft = _draftPerPeer[widget.peerHaloId];
    if (draft != null && draft.isNotEmpty) {
      _textController.text = draft;
      _isComposing = true;
    }

    // Jump to message if needed
    if (widget.jumpToUid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpToUid(widget.jumpToUid!);
      });
    }

    setState(() => _loaded = true);
  }

  Future<void> _loadContactInfo() async {
    // TODO: Implement contact info loading
  }

  Future<void> _loadVouches() async {
    // TODO: Implement vouches loading
  }

  Future<void> _loadShield() async {
    // TODO: Implement shield loading
  }

  Future<void> _loadAtmosphere() async {
    // TODO: Implement atmosphere loading
  }

  Future<void> _loadSession() async {
    // TODO: Implement session loading
  }

  Future<void> _loadBlockMuteVerified() async {
    // TODO: Implement block/mute/verified loading
  }

  Future<void> _loadRequestState() async {
    // TODO: Implement request state loading
  }

  Future<void> _loadGroupMembers() async {
    // TODO: Implement group members loading
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;

    setState(() {
      _showScrollDown = offset < maxScroll - 100;
    });

    // Load older messages when near top
    if (offset < 200 && _hasMore && !_loadingOlder) {
      _loadOlder();
    }
  }

  void _onTextChanged() {
    final text = _textController.text;
    final isComposing = text.trim().isNotEmpty;

    if (isComposing != _isComposing) {
      setState(() => _isComposing = isComposing);
    }

    _draftPerPeer[widget.peerHaloId] = text;
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _hideStickyLabel();
    }
  }

  void _onScrollPage() {
    // Pagination handled in _onScroll
  }

  Future<void> _loadMessages({bool initial = false}) async {
    // TODO: Implement message loading from database
    // For now, use initial messages if provided
    if (initial && widget.initialMessages != null) {
      _messages = widget.initialMessages!
          .map((e) => _rowToChatMessage(e))
          .whereType<UmbraChatMessage>()
          .toList();
      _normaliseMessages();
      setState(() {});
    }
  }

  Future<void> _loadOlder() async {
    if (_loadingOlder || !_hasMore) return;

    setState(() => _loadingOlder = true);

    // TODO: Implement older message loading

    setState(() => _loadingOlder = false);
  }

  UmbraChatMessage? _rowToChatMessage(MessageEnvelope row) {
    // TODO: Convert MessageEnvelope to UmbraChatMessage
    return null;
  }

  void _normaliseMessages() {
    // Group messages by sender and time proximity
    _dayKeys.clear();
    _byUid.clear();

    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      _byUid[msg.msgUid] = msg;

      // Check if same day as previous
      if (i > 0) {
        final prev = _messages[i - 1];
        if (!_isSameDay(msg.time, prev.time)) {
          _dayKeys[msg.msgUid] = _getDateLabel(msg.time);
        }
      } else {
        _dayKeys[msg.msgUid] = _getDateLabel(msg.time);
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDateLabel(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(time.year, time.month, time.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[time.weekday - 1];
    }
    return '${time.day}/${time.month}/${time.year}';
  }

  final Map<int, UmbraChatMessage> _byUid = {};

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // TODO: Implement actual message sending
    _textController.clear();
    setState(() => _isComposing = false);
  }

  void _onVoicePressed() {
    // TODO: Implement voice recording
  }

  void _onAttachPressed() {
    // TODO: Implement attachment picker
  }

  void _showAttachSheet() {
    // TODO: Implement attachment sheet
  }

  void _toggleDisguise() {
    setState(() => _disguise = !_disguise);
  }

  void _onVoiceComplete(String path, int duration) {
    // TODO: Send voice message
  }

  void _sendVoice(String path, int duration) {
    // TODO: Implement voice sending
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkInbox();
    });
  }

  void _checkInbox() {
    // TODO: Implement inbox checking
  }

  void _refreshDelivered() {
    // TODO: Refresh delivered status
  }

  void _retryFailedOnReconnect() {
    // TODO: Retry failed messages
  }

  void _autoRetryTick() {
    // TODO: Auto retry logic
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _query = '';
        _matches.clear();
        _matchPos = -1;
        _searchCtrl.clear();
      }
    });
  }

  void _buildSearchBar() {
    // TODO: Implement search bar
  }

  void _onSearchChanged(String query) {
    // TODO: Implement search
  }

  void _nextMatch() {}
  void _prevMatch() {}
  void _scrollToMatch(int index) {}

  void _openKeyVerification() {
    // TODO: Open key verification
  }

  Widget _buildReplyQuoteBar() {
    if (_replyTo == null) return const SizedBox.shrink();

    final colors = UmbraTheme.colorsOf(context);

    return Container(
      padding: EdgeInsets.all(UmbraSpacing.space3),
      decoration: BoxDecoration(
        color: colors.surfaceHover,
        border: Border(
          bottom: BorderSide(color: colors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: colors.accent,
              borderRadius: BorderRadius.circular(UmbraRadius.sm),
            ),
          ),
          SizedBox(width: UmbraSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyTo!.senderName ?? 'Unknown',
                  style: TextStyle(
                    fontSize: UmbraTypography.textXs,
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                    fontFamily: UmbraTypography.fontSans,
                  ),
                ),
                SizedBox(height: UmbraSpacing.space1),
                Text(
                  _replyTo!.text,
                  style: TextStyle(
                    fontSize: UmbraTypography.textSm,
                    color: colors.textSecondary,
                    fontFamily: UmbraTypography.fontSans,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 20, color: colors.textMuted),
            onPressed: () => setState(() => _replyTo = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _startReply(UmbraChatMessage msg) {
    setState(() => _replyTo = msg);
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyTo = null);
  }

  void _editMessage(UmbraChatMessage msg) {
    // TODO: Implement message editing
  }

  void _unsendMessage(UmbraChatMessage msg) {
    // TODO: Implement message unsend
  }

  void _showReactionPicker(UmbraChatMessage msg) {
    _reactionTarget = msg;
    _reactionDismiss?.cancel();
    _reactionDismiss = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _reactionTarget = null);
    });
    setState(() {});
  }

  void _toggleReaction(UmbraChatMessage msg, String emoji) {
    // TODO: Implement reaction toggle
  }

  void _jumpToUid(int uid) {
    // TODO: Implement jump to message
  }

  Future<bool> _onBackPressed() {
    if (_searching) {
      setState(() => _searching = false);
      return false;
    }
    if (_replyTo != null) {
      _cancelReply();
      return false;
    }
    return true;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(time.year, time.month, time.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[time.weekday - 1];
    }
    return '${time.day}/${time.month}/${time.year}';
  }

  void _showStickyLabel(String label, int dayMs) {
    _stickyLabel.value = label;
    _stickyDayMs = dayMs;
    _stickyShown.value = true;
    _stickyHideTimer?.cancel();
    _stickyHideTimer = Timer(const Duration(seconds: 3), _hideStickyLabel);
  }

  void _hideStickyLabel() {
    _stickyShown.value = false;
    _stickyHideTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final reduceMotion = UmbraTheme.of(context).controller.reduceMotion;

    return Scaffold(
      backgroundColor: colors.surface,
      body: EclipseWipeOverlay(
        controller: UmbraTheme.of(context).controller,
        child: WillPopScope(
          onWillPop: _onBackPressed,
          child: CustomScrollView(
            controller: _scrollController,
            key: _listKey,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Collapsed nav bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _ChatNavBarDelegate(
                  variant: _navVariant,
                  title: widget.peerName,
                  subtitle: _status,
                  backStyle: UmbraNavBarBackStyle.back,
                  onBack: () => Navigator.of(context).maybePop(),
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
                    // More actions
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: colors.textPrimary),
                      onSelected: _handleMenuAction,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'search',
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded, size: 20, color: colors.textPrimary),
                              SizedBox(width: UmbraSpacing.space2),
                              Text('Search', style: TextStyle(fontFamily: UmbraTypography.fontSans)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'verify',
                          child: Row(
                            children: [
                              Icon(Icons.verified_rounded, size: 20, color: colors.textPrimary),
                              SizedBox(width: UmbraSpacing.space2),
                              Text('Verify Key', style: TextStyle(fontFamily: UmbraTypography.fontSans)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(_blocked ? Icons.block_outlined : Icons.block_rounded, size: 20, color: colors.textPrimary),
                              SizedBox(width: UmbraSpacing.space2),
                              Text(_blocked ? 'Unblock' : 'Block', style: TextStyle(fontFamily: UmbraTypography.fontSans)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'mute',
                          child: Row(
                            children: [
                              Icon(_muted ? Icons.notifications_off_outlined : Icons.notifications_outlined, size: 20, color: colors.textPrimary),
                              SizedBox(width: UmbraSpacing.space2),
                              Text(_muted ? 'Unmute' : 'Mute', style: TextStyle(fontFamily: UmbraTypography.fontSans)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Reply quote bar
              if (_replyTo != null)
                SliverToBoxAdapter(child: _buildReplyQuoteBar()),

              // Search bar
              if (_searching)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ChatSearchBarDelegate(
                    controller: _searchCtrl,
                    onClose: _toggleSearch,
                    onChanged: _onSearchChanged,
                    onNext: _nextMatch,
                    onPrev: _prevMatch,
                    matchCount: _matches.length,
                    currentMatch: _matchPos,
                  ),
                ),

              // Messages
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _messages.length) return null;

                    final msg = _messages[index];
                    final isFirst = index == 0 || _messages[index - 1].msgUid != msg.msgUid;
                    final isLast = index == _messages.length - 1 || _messages[index + 1].msgUid != msg.msgUid;
                    final showDate = _dayKeys[msg.msgUid] != null;

                    return Column(
                      children: [
                        if (showDate)
                          _buildDateSeparator(_dayKeys[msg.msgUid]!),
                        _buildMessage(msg, isFirst, isLast),
                      ],
                    );
                  },
                  childCount: _messages.length,
                ),
              ),

              // Loading indicator
              if (_loadingOlder)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(UmbraSpacing.space4),
                      child: CircularProgressIndicator(
                        color: colors.accent,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),

              // Empty state
              if (_messages.isEmpty && _loaded)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: colors.textMuted,
                        ),
                        SizedBox(height: UmbraSpacing.space3),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: UmbraTypography.textLg,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                            fontFamily: UmbraTypography.fontSans,
                          ),
                        ),
                        SizedBox(height: UmbraSpacing.space2),
                        Text(
                          'Start the conversation',
                          style: TextStyle(
                            fontSize: UmbraTypography.textBase,
                            color: colors.textMuted,
                            fontFamily: UmbraTypography.fontSans,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom padding for input bar
              SliverToBoxAdapter(
                child: SizedBox(height: UmbraComponentTokens.inputBarHeight + UmbraSpacing.space4),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildInputBar(),
    );
  }

  Widget _buildDateSeparator(String label) {
    final colors = UmbraTheme.colorsOf(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: UmbraSpacing.space3),
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: UmbraSpacing.space3,
          vertical: UmbraSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceHover,
          borderRadius: BorderRadius.circular(UmbraRadius.full),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: UmbraTypography.textXs,
            fontWeight: FontWeight.w600,
            color: colors.textTertiary,
            fontFamily: UmbraTypography.fontSans,
            letterSpacing: UmbraTypography.trackingWide,
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(UmbraChatMessage msg, bool isFirst, bool isLast) {
    final colors = UmbraTheme.colorsOf(context);
    final isOutgoing = msg.direction == UmbraBubbleDirection.outgoing;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: UmbraSpacing.space4,
        vertical: UmbraSpacing.space1,
      ),
      child: Row(
        mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOutgoing && isFirst) ...[
            UmbraAvatar(
              seed: widget.peerAvatarSeed?.toString(),
              name: widget.peerName,
              size: UmbraComponentTokens.avatarSm,
            ),
            SizedBox(width: UmbraSpacing.space2),
          ] else if (!isOutgoing) ...[
            SizedBox(width: UmbraComponentTokens.avatarSm + UmbraSpacing.space2),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender name for group incoming
                if (!isOutgoing && widget.isGroup && isFirst && msg.senderName != null) ...[
                  Padding(
                    padding: EdgeInsets.only(
                      left: isOutgoing ? 0 : UmbraSpacing.space3,
                      right: isOutgoing ? UmbraSpacing.space3 : 0,
                    ),
                    child: Text(
                      msg.senderName!,
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

                // Message bubble
                UmbraBubble(
                  text: msg.text,
                  direction: msg.direction,
                  time: msg.time,
                  status: msg.status,
                  showTime: isLast,
                  showStatus: isLast && isOutgoing,
                  isFirstInGroup: isFirst,
                  isLastInGroup: isLast,
                  replyPreview: msg.replyTo != null
                      ? _ReplyPreviewWidget(
                          senderName: msg.replyTo!.senderName ?? 'Unknown',
                          text: msg.replyTo!.text,
                        )
                      : null,
                  reactions: msg.reactions
                      .map((r) => UmbraReaction(emoji: r.emoji, isOwn: r.isOwn))
                      .toList(),
                  onLongPress: () => _showReactionPicker(msg),
                  onTap: () {},
                  highlighted: msg.msgUid == _revealedUid,
                  isSecure: msg.secure,
                  burnSeconds: msg.burnSecs,
                  senderName: msg.senderName,
                  showSenderName: widget.isGroup && !isOutgoing && isFirst,
                ),
              ],
            ),
          ),

          if (isOutgoing && isFirst) ...[
            SizedBox(width: UmbraSpacing.space2),
            UmbraAvatar(
              seed: 'me', // Current user
              name: 'You',
              size: UmbraComponentTokens.avatarSm,
            ),
          ] else if (isOutgoing) ...[
            SizedBox(width: UmbraComponentTokens.avatarSm + UmbraSpacing.space2),
          ],
        ],
      ),
    );
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'search':
        setState(() => _searching = true);
        break;
      case 'verify':
        _openKeyVerification();
        break;
      case 'block':
        // TODO: Implement block/unblock
        break;
      case 'mute':
        // TODO: Implement mute/unmute
        break;
    }
  }

  Widget _buildInputBar() {
    final colors = UmbraTheme.colorsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.separator, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: UmbraInputBar(
          onSend: (text, {bool secure = false, bool disguise = false, int? burnSeconds}) {
            // TODO: Implement message sending with options
            _sendMessage();
          },
          onAttach: _onAttachPressed,
          onVoice: _onVoicePressed,
          hintText: 'Message',
          isSecure: _secureNext,
          isDisguised: _disguise,
          burnSeconds: _burnSeconds,
          onSecureToggle: () => setState(() => _secureNext = !_secureNext),
          onDisguiseToggle: _toggleDisguise,
          onBurnToggle: () {
            // TODO: Show burn timer picker
          },
          trailingActions: [
            // Secure toggle
            _InputActionButton(
              icon: _secureNext ? Icons.lock_rounded : Icons.lock_open_rounded,
              onPressed: () => setState(() => _secureNext = !_secureNext),
              enabled: true,
              isActive: _secureNext,
              activeColor: colors.accent,
            ),
            // Disguise toggle
            _InputActionButton(
              icon: Icons.face_rounded,
              onPressed: _toggleDisguise,
              enabled: true,
              isActive: _disguise,
              activeColor: colors.warning,
            ),
            // Burn timer
            _InputActionButton(
              icon: Icons.timer_rounded,
              onPressed: () {}, // TODO: Show burn timer picker
              enabled: true,
              isActive: _burnSeconds != null && _burnSeconds! > 0,
              activeColor: colors.warning,
            ),
          ],
        ),
      ),
    );
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

class _ChatNavBarDelegate extends SliverPersistentHeaderDelegate {
  final UmbraNavBarVariant variant;
  final String title;
  final String? subtitle;
  final UmbraNavBarBackStyle backStyle;
  final VoidCallback onBack;
  final List<Widget> trailingActions;

  _ChatNavBarDelegate({
    required this.variant,
    required this.title,
    this.subtitle,
    required this.backStyle,
    required this.onBack,
    required this.trailingActions,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return UmbraNavBar(
      variant: variant,
      title: title,
      subtitle: subtitle,
      backStyle: backStyle,
      onBack: onBack,
      trailingActions: trailingActions,
    );
  }

  @override
  double get maxExtent => UmbraComponentTokens.navBarHeight + MediaQuery.of(context).padding.top;

  @override
  double get minExtent => UmbraComponentTokens.navBarHeight + MediaQuery.of(context).padding.top;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate is _ChatNavBarDelegate &&
        oldDelegate.variant != variant &&
        oldDelegate.title != title;
  }
}

class _ChatSearchBarDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController controller;
  final VoidCallback onClose;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final int matchCount;
  final int currentMatch;

  _ChatSearchBarDelegate({
    required this.controller,
    required this.onClose,
    required this.onChanged,
    required this.onNext,
    required this.onPrev,
    required this.matchCount,
    required this.currentMatch,
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
                  hintText: 'Search in conversation...',
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
          SizedBox(width: UmbraSpacing.space2),
          if (matchCount > 0) ...[
            Text(
              '${currentMatch + 1} / $matchCount',
              style: TextStyle(
                fontSize: UmbraTypography.textSm,
                color: colors.textSecondary,
                fontFamily: UmbraTypography.fontMono,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            SizedBox(width: UmbraSpacing.space2),
            IconButton(
              icon: Icon(Icons.keyboard_arrow_up_rounded, color: colors.textPrimary),
              onPressed: onPrev,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            IconButton(
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.textPrimary),
              onPressed: onNext,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            SizedBox(width: UmbraSpacing.space2),
          ],
          _NavActionButton(
            icon: Icons.close_rounded,
            onPressed: onClose,
            tooltip: 'Close search',
          ),
        ],
      );
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

class _InputActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  final bool isActive;
  final Color? activeColor;
  final String? tooltip;

  const _InputActionButton({
    required this.icon,
    required this.onPressed,
    required this.enabled,
    this.isActive = false,
    this.activeColor,
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
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(UmbraRadius.full),
          child: AnimatedContainer(
            duration: UmbraMotion.durationFast,
            curve: UmbraMotion.easeSpring,
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? (activeColor ?? colors.accent).withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: Icon(
              icon,
              size: 22,
              color: enabled
                  ? (isActive ? activeColor ?? colors.accent : colors.textSecondary)
                  : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
