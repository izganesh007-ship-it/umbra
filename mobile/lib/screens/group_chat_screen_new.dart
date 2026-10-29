// SPDX-License-Identifier: GPL-3.0-or-later
// Umbra group chat screen matching groups.html design

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../lock_state.dart';
import '../picked.dart';
import '../open_file.dart';
import '../atmosphere.dart';
import 'shield_sheet.dart';
import '../scam_shield.dart';
import '../notifications.dart' show clearNotificationsFor;
import '../main.dart';
    show
        appState,
        db,
        currentChatPeer,
        newMsgUid,
        torStrictGetOnIsolate,
        shredFile;
import '../theme/theme.dart';
import '../media_progress.dart';
import '../media_send.dart' show cancelMediaSend;
import '../image_strip.dart';
import '../mp4_strip.dart';
import '../widgets/kryfo_avatar.dart';
import '../widgets/burn_fade.dart';
import 'group_info_screen_new.dart';
import '../widgets/motion.dart';
    show haloRoute, SendPill, PrivacyMode, TorStatus;
import '../rooms.dart';
import '../widgets/notice_banner.dart';
import '../widgets/room_countdown.dart';
import '../widgets/swipe_to_reply.dart';
import 'room_link_sheet.dart';
import '../dlog.dart';
import '../widgets/sheet_handle.dart';
import '../widgets/menu_backdrop.dart';
import '../mentions.dart';
import '../widgets/link_stub.dart';
import 'camera_screen.dart';
import '../link_preview.dart' show titleFromHtml, senderPreview;
import '../widgets/preview_strip.dart';
import '../widgets/halo_sheet.dart';
import '../widgets/moved_strip.dart';
import '../l10n/l10n.dart';
import '../l10n/dates.dart';
import '../l10n/marked.dart';
import '../l10n/numbers.dart';
import '../widgets/video_viewer.dart';
import '../bidi_safe.dart';
import '../lock_guard.dart' show lockGuard;
import '../widgets/umbra_bubble.dart';
import '../widgets/umbra_input_bar.dart';
import '../widgets/umbra_nav_bar.dart';
import '../widgets/umbra_avatar.dart';
import '../widgets/eclipse_wipe.dart';
import '../widgets/umbra_reaction_picker.dart';

final Map<String, String> _draftPerGroup = {};

String? _senderLabel(Map<String, String> nickById, String peer) =>
    nickById[peer] ?? (looksLikeRoomKey(peer) ? roomTag(peer) : null);

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  const GroupChatScreen({super.key, required this.groupId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen>
    with WidgetsBindingObserver {
  final _msgCtrl = TextEditingController();
  List<MentionCandidate> _mentionable = const [];
  final _scrollCtrl = ScrollController();
  final List<_GMsg> _messages = [];
  bool _showScrollDown = false;
  int _seenCount = 0;
  String _groupName = '';
  int _memberCount = 0;
  int? _roomExpiresAt;
  bool _roomBanner = false;
  bool get _isRoom => _roomExpiresAt != null;
  bool _isAdmin = false;
  bool _sending = false;
  _GMsg? _replyTo;
  VoidCallback? _menuClose;
  String? _liftedUid;
  final GlobalKey _jumpKey = GlobalKey();
  String? _jumpUid;
  String? _rippleUid;
  final Map<String, GlobalKey> _dayKeys = {};
  final Map<String, int> _dayMsOf = {};
  final GlobalKey _listKey = GlobalKey();
  final ValueNotifier<String?> _stickyLabel = ValueNotifier(null);
  final ValueNotifier<bool> _stickyShown = ValueNotifier(false);
  int? _stickyDayMs;
  Timer? _stickyHideTimer;
  bool _suppressSticky = true;
  DateTime _lastSticky = DateTime.fromMillisecondsSinceEpoch(0);
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  List<int> _matches = [];
  int _matchPos = 0;
  Atmo _atmosphere = Atmo.none;
  static const _pageSize = 60;
  bool _hasMore = true;
  bool _loadingOlder = false;
  bool _pagedOut = false;
  bool _ghost = false;
  bool _disguise = false;
  int _burnSeconds = 300;
  Timer? _burnTick;
  int _lastBurnSec = 0;
  bool _loading = false;
  bool _reloadQueued = false;
  bool _loaded = false;
  int _seenRev = -1;
  final Map<String, ShieldFlag> _shieldFlags = {};
  int _seenShieldRev = -1;
  Timer? _autoRetryTimer;

  double _pixels = 0;
  double _maxScroll = 0;
  bool _scrollReady = false;

  @override
  void initState() {
    super.initState();
    currentChatPeer = 'group:${widget.groupId}';
    WidgetsBinding.instance.addObserver(this);
    lockState.addListener(_lockLifted);
    _scrollCtrl.addListener(_onScroll);

    db.getGroup(widget.groupId).then((g) async {
      if (!mounted || g == null) return;
      setState(() {
        _roomExpiresAt = g['room_pub'] != null ? g['expires_at'] as int? : null;
        _roomBanner = (g['room_seen'] as int? ?? 0) == 0;
      });
      if (_roomExpiresAt != null) {
        appState.forceSecure(true);
        if (_roomBanner && (g['is_admin'] as int? ?? 0) == 1) {
          await Future.delayed(const Duration(milliseconds: 450));
          final link = await appState.roomLinkFor(widget.groupId);
          if (link != null && mounted) await showRoomLinkSheet(context, link);
        }
      }
    });

    db.clearGroupUnread(widget.groupId).then((_) => appState.refreshGroups());
    unawaited(clearNotificationsFor('group:${widget.groupId}'));
    _msgCtrl.text = _draftPerGroup[widget.groupId] ?? '';
    _msgCtrl.addListener(() {
      final t = _msgCtrl.text;
      if (t.trim().isEmpty) {
        _draftPerGroup.remove(widget.groupId);
      } else {
        _draftPerGroup[widget.groupId] = t;
      }
    });

    _scrollCtrl.addListener(_updateSticky);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _suppressSticky = false;
    });

    _load();
    appState.loadDisguisePref().then((d) {
      if (mounted) setState(() => _disguise = d);
    });
    appState.addListener(_onAppStateChanged);

    _autoRetryTimer = Timer.periodic(const Duration(seconds: 30), (_) => _autoRetryTick());
    _burnTick = Timer.periodic(const UmbraMotion.durationFast, (_) {
      if (!mounted) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      List<_GMsg>? expired;
      var anyGhost = false;
      for (final m in _messages) {
        if (m.burnAt == null) continue;
        anyGhost = true;
        if (m.burnAt! <= now && !m.removing && !m.sending && !m.failed) {
          (expired ??= []).add(m);
        }
      }
      if (!anyGhost) return;
      if (expired != null) {
        for (final m in expired) {
          m.removing = true;
          Future.delayed(const Duration(milliseconds: 560), () {
            if (mounted) setState(() => _messages.remove(m));
            if (m.msgUid != null) db.deleteMessage(m.msgUid!);
          });
        }
        HapticFeedback.lightImpact();
      }
      final sec = now ~/ 1000;
      if (expired != null || sec != _lastBurnSec) {
        _lastBurnSec = sec;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _burnTick?.cancel();
    _autoRetryTimer?.cancel();
    _stickyHideTimer?.cancel();
    lockState.removeListener(_lockLifted);
    appState.removeListener(_onAppStateChanged);
    WidgetsBinding.instance.removeObserver(this);
    currentChatPeer = null;
    super.dispose();
  }

  void _lockLifted() {
    if (lockState.unlocked && _reloadQueued) {
      _reloadQueued = false;
      _load();
    }
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    _pixels = _scrollCtrl.offset;
    _maxScroll = _scrollCtrl.position.maxScrollExtent;
    _scrollReady = true;

    final fromBottom = _maxScroll - _pixels;
    final show = fromBottom > 240;
    if (!show) _seenCount = _messages.length;
    if (show != _showScrollDown && mounted) {
      setState(() => _showScrollDown = show);
    }
    if (_suppressSticky) return;
    if (_pixels < 400) _loadOlder();
  }

  Future<void> _loadOlder() async {
    if (_loadingOlder || !_hasMore || _searching) return;
    _loadingOlder = true;
    try {
      final oldestRowid = _messages.isEmpty ? null : _messages.first.rowid;
      _blocked = await db.blockedIds();
      final rows0 = await db.groupMessagesPage(
        widget.groupId,
        beforeRowid: oldestRowid,
        limit: _pageSize + 1,
      );
      _hasMore = rows0.length > _pageSize;
      final rows = _withoutBlocked(rows0);
      if (!mounted) return;
      if (_hasMore && rows.isNotEmpty && rows.length == rows0.length) {
        rows.removeAt(0);
      }
      if (!_hasMore) _pagedOut = true;
      if (rows.isEmpty) return;
      final uids = rows
          .map((r) => r['msg_uid'] as String?)
          .where((u) => u != null && u.isNotEmpty)
          .cast<String>()
          .toList();
      final reactions = await db.loadReactionsFor(uids);
      if (!mounted) return;
      final nickById = <String, String>{};
      for (final c in appState.contacts) {
        final n = c.nickname;
        if (n != null && n.isNotEmpty) nickById[c.haloId] = n;
      }
      final older = <_GMsg>[];
      for (final r in rows) {
        final uid = r['msg_uid'] as String?;
        final rxMap = <String, String>{};
        if (uid != null && reactions[uid] != null) {
          for (final e in reactions[uid]!) {
            rxMap[e.key] = e.value;
          }
        }
        final dir = r['direction'] as String;
        final m = _GMsg(
          sender: r['peer_id'] as String,
          senderName: _senderLabel(nickById, r['peer_id'] as String),
          direction: dir,
          text: r['plaintext'] as String,
          when: DateTime.fromMillisecondsSinceEpoch(r['sent_at'] as int),
          burnAt: r['burn_at'] as int?,
          msgUid: uid,
          replyTo: r['reply_to'] as String?,
          mediaPath: r['media_path'] as String?,
          filePath: r['file_path'] as String?,
          fileName: r['file_name'] as String?,
          voiceDisguised: ((r['voice_disguised'] as int?) ?? 0) == 1,
          pinned: ((r['pinned'] as int?) ?? 0) == 1,
          rowid: r['rowid'] as int,
        );
        older.add(m);
      }
      setState(() {
        _messages.insertAll(0, older);
      });
    } finally {
      _loadingOlder = false;
    }
  }

  Set<String> _blocked = {};

  List<Map<String, Object?>> _withoutBlocked(List<Map<String, Object?>> rows) {
    if (_blocked.isEmpty) return rows;
    return [for (final r in rows) if (!_blocked.contains(r['peer_id'])) r];
  }

  Future<void> _load() async {
    if (_loading) {
      _reloadQueued = true;
      return;
    }
    _loading = true;
    try {
      final g = await db.getGroup(widget.groupId);
      final members = await db.getGroupMembers(widget.groupId);
      final rows = await db.groupMessagesPage(widget.groupId, limit: _pageSize + 1);
      _hasMore = rows.length > _pageSize;
      if (_hasMore) rows.removeAt(0);
      _blocked = await db.blockedIds();
      final filtered = _withoutBlocked(rows);
      final uids = filtered
          .map((r) => r['msg_uid'] as String?)
          .where((u) => u != null && u.isNotEmpty)
          .cast<String>()
          .toList();
      final reactions = await db.loadReactionsFor(uids);
      if (!mounted) return;
      final nickById = <String, String>{};
      for (final c in appState.contacts) {
        final n = c.nickname;
        if (n != null && n.isNotEmpty) nickById[c.haloId] = n;
      }
      final msgs = <_GMsg>[];
      for (final r in filtered) {
        final uid = r['msg_uid'] as String?;
        final rxMap = <String, String>{};
        if (uid != null && reactions[uid] != null) {
          for (final e in reactions[uid]!) {
            rxMap[e.key] = e.value;
          }
        }
        final dir = r['direction'] as String;
        msgs.add(_GMsg(
          sender: r['peer_id'] as String,
          senderName: _senderLabel(nickById, r['peer_id'] as String),
          direction: dir,
          text: r['plaintext'] as String,
          when: DateTime.fromMillisecondsSinceEpoch(r['sent_at'] as int),
          burnAt: r['burn_at'] as int?,
          msgUid: uid,
          replyTo: r['reply_to'] as String?,
          mediaPath: r['media_path'] as String?,
          filePath: r['file_path'] as String?,
          fileName: r['file_name'] as String?,
          voiceDisguised: ((r['voice_disguised'] as int?) ?? 0) == 1,
          pinned: ((r['pinned'] as int?) ?? 0) == 1,
          rowid: r['rowid'] as int,
        ));
      }
      msgs.sort((a, b) => a.when.compareTo(b.when));
      setState(() {
        _groupName = (g?['name'] as String?) ?? l10n.groupInfoGroup;
        _isAdmin = ((g?['is_admin'] as int?) ?? 0) == 1;
        _memberCount = members.length;
        _messages
          ..clear()
          ..addAll(msgs);
        _seenCount = _messages.length;
        _loaded = true;
        _seenRev = g?['rev'] as int? ?? -1;
      });
      _loadShieldFlags();
    } finally {
      _loading = false;
    }
  }

  Future<void> _loadShieldFlags() async {
    final members = await db.getGroupMembers(widget.groupId);
    final flags = <String, ShieldFlag>{};
    for (final m in members) {
      if (m == appState.myId) continue;
      final flag = await appState.scamShieldCheck(m);
      if (flag != ShieldFlag.none) flags[m] = flag;
    }
    if (!mounted) return;
    setState(() {
      _shieldFlags.clear();
      _shieldFlags.addAll(flags);
      _seenShieldRev = await db.getGroupRev(widget.groupId);
    });
  }

  void _autoRetryTick() {
    if (!mounted) return;
    var any = false;
    for (final m in _messages) {
      if (m.failed && !m.sending && m.direction == 'out') {
        any = true;
        _retry(m);
      }
    }
    if (any) setState(() {});
  }

  Future<void> _retry(_GMsg m) async {
    m.failed = false;
    m.sending = true;
    setState(() {});
    // TODO: Implement retry logic
  }

  void _updateSticky() {
    if (!_scrollCtrl.hasClients) return;
    final offset = _scrollCtrl.offset;
    String? newLabel;
    int? newDayMs;
    for (int i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      final key = _dayKeys[m.msgUid ?? ''];
      if (key?.currentContext != null) {
        final box = key.currentContext!.findRenderObject() as RenderBox?;
        if (box != null) {
          final pos = box.localToGlobal(Offset.zero).dy;
          if (pos <= 100) {
            newLabel = formatDateShort(m.when, context);
            newDayMs = m.when.millisecondsSinceEpoch ~/ 86400000 * 86400000;
            break;
          }
        }
      }
    }
    if (newLabel != _stickyLabel.value || newDayMs != _stickyDayMs) {
      _stickyLabel.value = newLabel;
      _stickyDayMs = newDayMs;
      _stickyShown.value = newLabel != null;
      _stickyHideTimer?.cancel();
      if (newLabel != null) {
        _stickyHideTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) _stickyShown.value = false;
        });
      }
    }
  }

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    // TODO: Implement send
  }

  void _scrollToEnd() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final l10n = l10n;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Collapsed nav bar
            UmbraNavBar(
              title: _groupName,
              leading: IconButton(
                icon: Icon(Icons.chevron_left, color: colors.textSecondary, size: 26),
                onPressed: () => Navigator.of(context).pop(),
              ),
              trailing: [
                IconButton(
                  icon: Icon(Icons.more_vert_rounded, color: colors.textSecondary, size: 24),
                  onPressed: () => _showGroupMenu(),
                ),
              ],
              collapsed: true,
            ),
            // Search bar
            if (_searching) _buildSearchBar(),
            // Messages
            Expanded(
              child: Stack(
                children: [
                  _buildMessageList(),
                  if (_stickyShown.value && _stickyLabel.value != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: colors.separator, width: 0.5),
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadowSm.first.color,
                                blurRadius: colors.shadowSm.first.blurRadius,
                                offset: colors.shadowSm.first.offset,
                              ),
                            ],
                          ),
                          child: Text(
                            _stickyLabel.value!,
                            style: TextStyle(
                              fontFamily: UmbraTypography.fontMono,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                              letterSpacing: 0.12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_showScrollDown) _buildScrollDownButton(),
                ],
              ),
            ),
            // Input bar
            UmbraInputBar(
              controller: _msgCtrl,
              onSend: _sendText,
              onAttach: _showAttachMenu,
              onVoice: _startVoiceRecording,
              onGhostToggle: () => setState(() => _ghost = !_ghost),
              onBurnToggle: _showBurnPicker,
              onDisguiseToggle: () => setState(() => _disguise = !_disguise),
              ghostMode: _ghost,
              burnSeconds: _ghost ? _burnSeconds : null,
              disguiseMode: _disguise,
              replyTo: _replyTo,
              onReplyClose: () => setState(() => _replyTo = null),
              mentionCandidates: _mentionable,
              onMentionSelected: (c) {
                _msgCtrl.text += '@${c.label} ';
                _msgCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: _msgCtrl.text.length),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final colors = UmbraTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.separator, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: TextStyle(
                fontFamily: UmbraTypography.fontSans,
                fontSize: 15,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search messages...',
                hintStyle: TextStyle(color: colors.textTertiary),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: colors.textTertiary, size: 20),
              ),
              onChanged: (v) => _performSearch(v),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: colors.textSecondary),
            onPressed: () => setState(() => _searching = false),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _matches = [];
        _matchPos = 0;
      });
      return;
    }
    final matches = <int>[];
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].text.toLowerCase().contains(query.toLowerCase())) {
        matches.add(i);
      }
    }
    setState(() {
      _matches = matches;
      _matchPos = matches.isNotEmpty ? matches.length - 1 : 0;
    });
    if (matches.isNotEmpty) _scrollToMatch(matches.last);
  }

  void _scrollToMatch(int index) {
    final key = _dayKeys[_messages[index].msgUid ?? ''];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(key.currentContext!, duration: Duration(milliseconds: 300));
    }
  }

  Widget _buildMessageList() {
    final colors = UmbraTheme.colorsOf(context);

    return ListView.builder(
      key: _listKey,
      controller: _scrollCtrl,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: _messages.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildLoadMore();
        }
        final msg = _messages[index];
        final showDay = _shouldShowDay(index);
        return Column(
          key: msg.msgUid != null ? _dayKeys[msg.msgUid!] : null,
          children: [
            if (showDay) _buildDayDivider(msg.when),
            _buildMessage(msg),
          ],
        );
      },
    );
  }

  Widget _buildLoadMore() {
    if (_loadingOlder) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: colors.accent, strokeWidth: 2),
        ),
      );
    }
    if (!_hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: TextButton(
          onPressed: _loadOlder,
          child: Text(
            'Load more messages',
            style: TextStyle(
              fontFamily: UmbraTypography.fontSans,
              fontSize: 13,
              color: colors.accent,
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowDay(int index) {
    if (index == 0) return true;
    final prev = _messages[index - 1];
    final curr = _messages[index];
    return prev.when.day != curr.when.day ||
        prev.when.month != curr.when.month ||
        prev.when.year != curr.when.year;
  }

  Widget _buildDayDivider(DateTime when) {
    final colors = UmbraTheme.colorsOf(context);
    final label = formatDateShort(when, context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: colors.separator, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: UmbraTypography.fontMono,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
                letterSpacing: 0.14,
              ),
            ),
          ),
          Expanded(child: Divider(color: colors.separator, thickness: 0.5)),
        ],
      ),
    );
  }

  Widget _buildMessage(_GMsg msg) {
    final colors = UmbraTheme.colorsOf(context);
    final isOut = msg.direction == 'out';
    final showName = !isOut && (msg.senderName != null || _shieldFlags[msg.sender] != null);
    final shieldFlag = _shieldFlags[msg.sender];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isOut ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOut) ...[
            UmbraAvatar(seed: msg.sender, size: UmbraAvatarSize.sm),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isOut ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showName)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg.senderName ?? msg.sender,
                          style: TextStyle(
                            fontFamily: UmbraTypography.fontSans,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                        if (shieldFlag != null && shieldFlag != ShieldFlag.none) ...[
                          const SizedBox(width: 6),
                          _ShieldBadge(flag: shieldFlag),
                        ],
                      ],
                    ),
                  ),
                UmbraBubble(
                  text: msg.text,
                  isOutgoing: isOut,
                  time: msg.when,
                  status: msg.failed ? MessageStatus.failed : msg.sending ? MessageStatus.sending : MessageStatus.sent,
                  replyTo: msg.replyTo != null ? _findReply(msg.replyTo!) : null,
                  burnAt: msg.burnAt,
                  reactions: msg.reactions,
                  onReactionTap: (emoji) => _addReaction(msg, emoji),
                  onLongPress: () => _showMessageMenu(msg),
                  onReply: () => setState(() => _replyTo = msg),
                ),
              ],
            ),
          ),
          if (isOut) ...[
            const SizedBox(width: 8),
            UmbraAvatar(seed: appState.myId, size: UmbraAvatarSize.sm),
          ],
        ],
      ),
    );
  }

  _ReplyInfo? _findReply(String uid) {
    // TODO: Find reply message
    return null;
  }

  void _addReaction(_GMsg msg, String emoji) {
    // TODO: Add reaction
  }

  void _showMessageMenu(_GMsg msg) {
    // TODO: Show message menu
  }

  void _showGroupMenu() {
    showHaloSheet(
      context,
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.info_outline_rounded, color: UmbraTheme.colorsOf(context).textPrimary),
            title: Text(l10n.appGroupInfo, style: TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: UmbraTypography.textBase, color: UmbraTheme.colorsOf(context).textPrimary)),
            onTap: () {
              Navigator.pop(sheetCtx);
              Navigator.push(context, haloRoute(GroupInfoScreen(groupId: widget.groupId)));
            },
          ),
        ],
      ),
    );
  }

  void _showAttachMenu() {
    // TODO: Show attach menu
  }

  void _startVoiceRecording() {
    // TODO: Start voice recording
  }

  void _showBurnPicker() {
    // TODO: Show burn time picker
  }

  Widget _buildScrollDownButton() {
    final colors = UmbraTheme.colorsOf(context);
    final unread = _messages.length - _seenCount;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 12,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _seenCount = _messages.length);
                _scrollToEnd();
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceElevated,
                  border: Border.all(color: colors.accent.withValues(alpha: 0.5), width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.18),
                      blurRadius: 14,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(Icons.keyboard_arrow_down_rounded, color: colors.accent, size: 22),
              ),
            ),
            if (unread > 0)
              PositionedDirectional(
                top: -3,
                end: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 17),
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: colors.surface, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$unread',
                    style: TextStyle(
                      fontFamily: UmbraTypography.fontMono,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: colors.accentOn,
                      letterSpacing: 0.12,
                      height: 1.2,
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

class _GMsg {
  _GMsg({
    required this.sender,
    this.senderName,
    required this.direction,
    required this.text,
    required this.when,
    this.burnAt,
    this.msgUid,
    this.replyTo,
    this.mediaPath,
    this.filePath,
    this.fileName,
    this.voiceDisguised = false,
    this.pinned = false,
    this.rowid = 0,
  });

  final String sender;
  final String? senderName;
  final String direction;
  final String text;
  final DateTime when;
  final int? burnAt;
  final String? msgUid;
  final String? replyTo;
  final String? mediaPath;
  final String? filePath;
  final String? fileName;
  final bool voiceDisguised;
  final bool pinned;
  final int rowid;

  Map<String, String> reactions = {};
  bool sending = false;
  bool failed = false;
  bool removing = false;
}

class _ShieldBadge extends StatelessWidget {
  final ShieldFlag flag;

  const _ShieldBadge({required this.flag});

  @override
  Widget build(BuildContext context) {
    final colors = UmbraTheme.colorsOf(context);
    final (label, color) = switch (flag) {
      ShieldFlag.scam => ('Scam', colors.error),
      ShieldFlag.spam => ('Spam', colors.warning),
      ShieldFlag.suspicious => ('Suspicious', colors.accent),
      _ => ('', colors.textTertiary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: UmbraTypography.fontMono,
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
